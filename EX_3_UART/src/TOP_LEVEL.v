`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ = 27_000_000,   // Clock Tang Nano 9K (27 MHz)
    parameter BAUD_RATE = 115200       
)(
    input  logic       clk,
    input  logic       reset_ext,          // Reset asincrono attivo alto
    input  logic       tx_start_ext,       // Impulso per avviare la trasmissione
    input  logic [7:0] tx_data,        // Byte da trasmettere
    output logic       tx_out,         // Pin fisico collegato all'RX del PC
    output logic       tx_busy         // Segnala se è in corso una trasmissione
);

    // Calcolo dei cicli di clock necessari per un singolo bit
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;  //27.000.000/115.200 = ~234 clk cycle
    //localparam HALF_DELAY_WAIT = (CLKS_PER_BIT / 2);  //per metterci al centro del bit

    // --- DEFINIZIONE DEGLI STATI (Tipi Enumerati) ---
    typedef enum logic [1:0] {
        IDLE      = 2'b00,
        START_BIT = 2'b01,
        DATA_BITS = 2'b10,
        STOP_BIT  = 2'b11
    } state_t;

    state_t stato_corrente, stato_futuro;

    // Registri per il percorso dati (Datapath)
    logic [15:0] clk_count;  // Contatore per la durata di un bit
    logic [2:0]  bit_index;  // Indice del bit da inviare (da 0 a 7)
    logic [7:0]  data_reg;   // Registro per "congelare" il dato da inviare

    logic reset;
    logic tx_start;

    // =========================================================
    // 1. REGISTRO DI STATO (Logica Sequenziale)
    // =========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            stato_corrente <= IDLE;
        end else begin
            stato_corrente <= stato_futuro;
        end
    end

    // =========================================================
    // GESTIONE DEI CONTATORI (Datapath Sequenziale)
    // =========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_count <= 0;
            bit_index <= 0;
            data_reg  <= 8'd0;
        end 
        else begin
            case (stato_corrente)
                IDLE: begin
                    clk_count <= 0;   
                    bit_index <= 0;
                    if (tx_start) begin
                        data_reg <= tx_data; // Salva il dato in ingresso per evitare che cambi durante la trasmissione
                    end
                end
                
                START_BIT, DATA_BITS, STOP_BIT: begin
                    // Contatore per generare il baud rate corretto
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end 
                    else begin
                        clk_count <= 0; // Resetta il contatore alla fine del bit
                        // Se stiamo inviando i dati, passa al bit successivo
                        if (stato_corrente == DATA_BITS && bit_index != 3'd7) begin
                            bit_index <= bit_index + 1;
                        end
                    end
                 end
               default: begin
                   clk_count <= 0;
                   bit_index <= 0;
               end
            endcase
        end
    end

    // =========================================================
    // 2. LOGICA DELLO STATO FUTURO (Logica Combinatoria)
    // =========================================================
    always_comb begin
        // Assegnazione di default per evitare la generazione di latch
        stato_futuro = stato_corrente; 

        case (stato_corrente)
            IDLE: begin
                if (tx_start) begin
                    stato_futuro = START_BIT;
                end
            end

            START_BIT: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    stato_futuro = DATA_BITS;
                end
            end

            DATA_BITS: begin
                // Se è trascorso il tempo dell'ultimo bit (il settimo)
                if (clk_count == CLKS_PER_BIT - 1) begin 
                    if(bit_index == 3'd7) begin
                       stato_futuro = STOP_BIT;
                    end
                end
            end

            STOP_BIT: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    stato_futuro = IDLE;
                end
            end
            
            default: stato_futuro = IDLE; // Stato di sicurezza
        endcase
    end

    // =========================================================
    // 3. LOGICA DI USCITA (Logica Combinatoria / Mealy-Moore)
    // =========================================================
    always_comb begin
        // La linea UART a riposo è tenuta alta (1)
        tx_out  = 1'b1; 
        tx_busy = (stato_corrente != IDLE); // Occupato se non in IDLE

        case (stato_corrente)
            IDLE:      tx_out = 1'b1;
            START_BIT: tx_out = 1'b0; // Lo Start Bit è uno 0
            DATA_BITS: tx_out = data_reg[bit_index]; // Invia bit per bit (LSB per primo)
            STOP_BIT:  tx_out = 1'b1; // Lo Stop Bit è un 1
            default:   tx_out = 1'b1;
        endcase
    end

assign reset=~reset_ext;
assign tx_start=~tx_start_ext;

endmodule