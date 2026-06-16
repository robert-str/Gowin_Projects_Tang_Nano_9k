// ============================================================================
// MODULE: tmds_encoder pipelined (Algorithm 8b/10b for DVI/HDMI)
// ============================================================================
module tmds_encoder (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        vde,        // data enable (1 = video, 0 = control)
    input  logic [1:0]  ctrl,       // {vsync, hsync}
    input  logic [7:0]  data_in,    // pixel data

    output logic [9:0]  tmds_out
);

    // Running disparity (signed)
    logic signed [5:0] disparity;   

    // Stage 1 signals
    logic [8:0] q_m_comb;
    logic [3:0] n1_data;
    logic       use_xnor;

    // Pipeline register between Stage 1 and Stage 2
    logic [8:0] q_m_pipe;
    logic       vde_pipe;
    logic [1:0] ctrl_pipe;

    // Stage 2 signals
    logic [3:0]        n1_qm;
    logic signed [5:0] balance;

    logic [9:0]        next_tmds;
    logic signed [5:0] next_disparity;

    // ===================================
    // COUNT ONES FUNCTION
    // ===================================
    function automatic [3:0] count_ones(input logic [7:0] x);
        begin
            count_ones = 4'd0;
            count_ones = {3'b000, x[0]} + {3'b000, x[1]} +
                {3'b000, x[2]} + {3'b000, x[3]} +
                {3'b000, x[4]} + {3'b000, x[5]} +
                {3'b000, x[6]} + {3'b000, x[7]};
        end
    endfunction

    //=========================================================
    // STAGE 1: Transition minimization (8b → 9b)
    //=========================================================

    always_comb begin
        n1_data = count_ones(data_in);

        // decision XOR / XNOR
        use_xnor = (n1_data > 4'd4) || ((n1_data == 4'd4) && (data_in[0] == 1'b0));

        // build q_m
        q_m_comb[0] = data_in[0];

        for (int i = 1; i < 8; i++) begin
            if (use_xnor)
                q_m_comb[i] = q_m_comb[i-1] ~^ data_in[i];
            else
                q_m_comb[i] = q_m_comb[i-1] ^  data_in[i];
        end

        // flag bit: 1 for XOR, 0 for XNOR
        q_m_comb[8] = ~use_xnor;   // use_xnor? 1'b0 : 1'b1
    end

    // =========================================================
    // PIPELINE REGISTER
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_m_pipe  <= 9'd0;
            vde_pipe   <= 1'b0;
            ctrl_pipe <= 2'b00;
        end
        else begin
            q_m_pipe  <= q_m_comb;
            vde_pipe   <= vde;
            ctrl_pipe <= ctrl;
        end
    end

    // =========================================================
    // STAGE 2: DC balancing (9b → 10b)
    // ========================================================= 

    always_comb begin
        n1_qm = count_ones(q_m_pipe[7:0]);
        // Balance= disparity of current data : (N1 - N0) = n1_qm - (8 - n1_qm) = 2*n1_qm - 8
        balance = ($signed({2'b00,n1_qm}) << 1) - 6'sd8;    //$ for casting n1_qm to signed
    end

    // =========================================================
    // COMBINATIONAL NEXT CALCULATION (Uses pipelined vde/ctrl/q_m)
    // =========================================================

    always_comb begin
        // DEFAULT: to avoid latch
        next_tmds      = 10'b1101010100;  //default state
        next_disparity = disparity; 

        // LOGICA DECISIONALE
        if (!vde_pipe) begin
            // -- Modalità Blanking --
            next_disparity = 6'sd0;
            case (ctrl_pipe)
                2'b00:   next_tmds = 10'b1101010100;
                2'b01:   next_tmds = 10'b0010101011;
                2'b10:   next_tmds = 10'b0101010100;
                2'b11:   next_tmds = 10'b1010101011;
                default: next_tmds = 10'b1101010100;
            endcase
        end 
        else begin
            // -- Video Mode--
            if ((disparity == 6'sd0) || (balance == 6'sd0)) begin
                next_tmds[9]   = ~q_m_pipe[8];        //The two header bits must different for the std HDMI to avoid imbalance issues
                next_tmds[8]   =  q_m_pipe[8];
                next_tmds[7:0] =  q_m_pipe[8] ? q_m_pipe[7:0] : ~q_m_pipe[7:0];    // if q_m[8]=0 => next[9]=1 => reverse the data

                if (q_m_pipe[8] == 1'b0)
                    next_disparity = disparity - balance;
                else
                    next_disparity = disparity + balance;
            end
            else if ((disparity > 6'sd0 && balance > 6'sd0) ||
                     (disparity < 6'sd0 && balance < 6'sd0)) begin       //the disparity will get even worse => the data must be reversed

                next_tmds[9]   = 1'b1;
                next_tmds[8]   = q_m_pipe[8];
                next_tmds[7:0] = ~q_m_pipe[7:0];

                next_disparity = disparity + (q_m_pipe[8] ? 6'sd2 : 6'sd0) - balance;  //the condition takes into account the header bits disparity
            end
            else begin
                next_tmds[9]   = 1'b0;
                next_tmds[8]   = q_m_pipe[8];
                next_tmds[7:0] = q_m_pipe[7:0];

                next_disparity = disparity - (q_m_pipe[8] ? 6'sd0 : 6'sd2) + balance;
            end

        end
    end

    // =========================================================
    // OUTPUT REGISTER (only Flip-Flop)
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            disparity <= 0;
            tmds_out  <= 10'b1101010100;
        end
        else begin
            disparity <= next_disparity;
            tmds_out  <= next_tmds;
        end
    end    

endmodule