// ============================================================================
// MODULO: hdmi_top
// DESCRIZIONE: Top level per output HDMI parametrizzabile.
// NOTA CLOCK: Richiede un clk_pixel (es. 6.3 MHz) e un clk_tmds (es. 63 MHz).
// Sulla Tang Nano 9K questi devono essere generati da un modulo rPLL.
// ============================================================================

module hdmi_top #(
    // Parametri Orizzontali (Pixel)   | ACTIVE | FRONT | SYNC | BACK |
    parameter int H_ACTIVE   = 640,  
    parameter int H_FRONT    = 16,
    parameter int H_SYNC     = 96,
    parameter int H_BACK     = 106,
    parameter int H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK,

    // Parametri Verticali (Linee)     | ACTIVE | FRONT | SYNC | BACK |    
    parameter int V_ACTIVE   = 480,
    parameter int V_FRONT    = 10,
    parameter int V_SYNC     = 2,
    parameter int V_BACK     = 33,
    parameter int V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK,

    //Polarity
    parameter bit H_SYNC_POL = 1'b0,
    parameter bit V_SYNC_POL = 1'b0,

    //$clog2(H_TOTAL)
    parameter int H_BITS = $clog2(H_TOTAL),
    parameter int V_BITS = $clog2(V_TOTAL)
)(
    input  logic rst_n,       // Reset asincrono attivo basso
    input  logic clk_27MHz,   // Clock del pixel (es. ~6.3 MHz)
    
    // Uscite differenziali (Nella Tang Nano vanno mappate sui pin TLVDS/LVCMOS33)
    output logic tmds_clk_p,  output logic tmds_clk_n,
    output logic tmds_d0_p,   output logic tmds_d0_n,  // Blue
    output logic tmds_d1_p,   output logic tmds_d1_n,  // Green
    output logic tmds_d2_p,   output logic tmds_d2_n   // Red
);

    // --- Segnali Interni ---
    logic clk_pixel;   // Clock del pixel (es. ~6.3 MHz)
    logic clk_tmds;    // TMDS clock 5x (es. ~31.5 MHz)
    logic [H_BITS-1:0] cx;   //counter x
    logic [V_BITS-1:0] cy;   //counter y
    logic hsync, vsync, vde;
    logic [7:0] red, green, blue;
    logic [9:0] tmds_r, tmds_g, tmds_b;

    Gowin_rPLL PLL(
        .clkout(clk_tmds), //output clkout x5   36 MHz
        //.clkoutd(clk_pixel), //output clkoutd    6 Mhz
        .reset(~rst_n),     //input reset
        .clkin(clk_27MHz)    //input clkin   27 MHz
    );
    assign clk_pixel= clk_27MHz;

    // 1. Generatore di Sincronismi (Timings)
    video_timing #(
        .H_ACTIVE(H_ACTIVE), .H_FRONT(H_FRONT), .H_SYNC(H_SYNC), .H_BACK(H_BACK), .H_TOTAL(H_TOTAL), .H_SYNC_POL(H_SYNC_POL), .H_BITS(H_BITS),
        .V_ACTIVE(V_ACTIVE), .V_FRONT(V_FRONT), .V_SYNC(V_SYNC), .V_BACK(V_BACK), .V_TOTAL(V_TOTAL), .V_SYNC_POL(V_SYNC_POL), .V_BITS(V_BITS)
    ) timing_inst (
        .clk(clk_pixel),
        .rst_n(rst_n),
        .cx(cx),
        .cy(cy),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde)
    );

    /*// 2. Generatore di Pattern Video (Test pattern XOR)
    always_comb begin
        if (vde) begin
            red   = {cx[7:0]};              // Gradiente X
            green = {cy[7:0]};              // Gradiente Y
            blue  = cx[7:0] ^ cy[7:0];      // Pattern XOR
        end 
        else begin
            red = 8'h00; green = 8'h00; blue = 8'h00;
        end
    end
    */

    // =========================================================
    // 2. Generatore di Pattern Video (Salvaschermo DVD)
    // =========================================================

    // La ROM è 40x20. Vogliamo farla grande il doppio? 
    // Moltiplichiamo per 2! Larghezza = 80, Altezza = 40 (non 60)
    localparam int LOGO_W = 80;
    localparam int LOGO_H = 40;

    // Registri di stato: Posizione e Direzione
    logic [9:0] logo_x;
    logic [9:0] logo_y;
    logic       dir_x; // 1 = vai a destra, 0 = vai a sinistra
    logic       dir_y; // 1 = vai in giù,   0 = vai in su
    
    // Un registro per far cambiare colore al logo ad ogni rimbalzo
    logic [7:0] color_seed; 

    // MOTORE FISICO: Aggiorna la posizione una sola volta per fotogramma
    always_ff @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n) begin
            // Posizione e stato iniziale
            logo_x     <= 10'd100;
            logo_y     <= 10'd100;
            dir_x      <= 1'b1;
            dir_y      <= 1'b1;
            color_seed <= 8'hFF; 
        end 
        else if (cx == 0 && cy == 0) begin
            // ------------------------------------------------
            // Asse Orizzontale (X)
            // ------------------------------------------------
            if (dir_x == 1'b1) begin
                // Sto andando a destra. Ho toccato il bordo destro?
                if (logo_x + LOGO_W >= H_ACTIVE - 1) begin
                    dir_x <= 1'b0; // Inverti direzione (sinistra)
                    color_seed <= color_seed + 8'h33; // Cambia colore
                end else begin
                    logo_x <= logo_x + 10'd2; // Velocità: 2 pixel a frame
                end
            end else begin
                // Sto andando a sinistra. Ho toccato il bordo sinistro?
                if (logo_x <= 1) begin
                    dir_x <= 1'b1; // Inverti direzione (destra)
                    color_seed <= color_seed + 8'h55;
                end else begin
                    logo_x <= logo_x - 10'd2;
                end
            end

            // ------------------------------------------------
            // Asse Verticale (Y)
            // ------------------------------------------------
            if (dir_y == 1'b1) begin
                // Sto andando in giù. Ho toccato il fondo?
                if (logo_y + LOGO_H >= V_ACTIVE - 1) begin
                    dir_y <= 1'b0; // Inverti direzione (su)
                    color_seed <= color_seed + 8'h77;
                end else begin
                    logo_y <= logo_y + 10'd2;
                end
            end else begin
                // Sto andando in su. Ho toccato la cima?
                if (logo_y <= 1) begin
                    dir_y <= 1'b1; // Inverti direzione (giù)
                    color_seed <= color_seed + 8'h99;
                end else begin
                    logo_y <= logo_y - 10'd2;
                end
            end
        end
    end

    // RENDERER: Il pixel corrente (cx, cy) si trova DENTRO il logo?
    logic is_logo;
    assign is_logo = (cx >= logo_x) && (cx < logo_x + LOGO_W) && 
                     (cy >= logo_y) && (cy < logo_y + LOGO_H);

    // Segnale che esce dalla ROM
    logic rom_pixel;

    // Istanza della ROM con SCALING 2x (Divisione per 2)
    // Facendo >> 1, il pixel dello schermo avanzerà di 2 posizioni 
    // prima che la ROM cambi indirizzo. Risultato: ingrandimento 2x perfetto!
    dvd_rom logo_storage (
        .addr_x( (cx - logo_x) >> 1 ), // Scala X per 2
        .addr_y( (cy - logo_y) >> 1 ), // Scala Y per 2
        .pixel_out(rom_pixel)
    );

    always_comb begin
        if (vde) begin
            // Se siamo dentro il rettangolo DEL LOGO...
            if (is_logo) begin
                // ...e se la ROM dice che quel pixel fa parte della scritta
                if (rom_pixel) begin
                    red   = color_seed;
                    green = ~color_seed;
                    blue  = 8'hFF;
                end else begin
                    // Sfondo del rettangolo (nero o semitrasparente)
                    red = 8'h20; green = 8'h20; blue = 8'h20;
                end
            end else begin
                // Sfondo dello schermo
                red = 8'h00; green = 8'h00; blue = 8'h1A;
            end
        end else begin
            red = 8'h00; green = 8'h00; blue = 8'h00;
        end
    end

    // 3. Encoder TMDS (3 canali)
    // Il canale BLU (D0) trasporta HSYNC e VSYNC durante il blanking (vde=0)
    tmds_encoder enc_b (.clk(clk_pixel), .rst_n(rst_n), .data_in(blue),  .ctrl({vsync, hsync}), .vde(vde), .tmds_out(tmds_b));
    tmds_encoder enc_g (.clk(clk_pixel), .rst_n(rst_n), .data_in(green), .ctrl(2'b00),          .vde(vde), .tmds_out(tmds_g));
    tmds_encoder enc_r (.clk(clk_pixel), .rst_n(rst_n), .data_in(red),   .ctrl(2'b00),          .vde(vde), .tmds_out(tmds_r));

    // 4. Serializzatori 10:1 (spingono i bit sul clock veloce)
    logic s_clk, s_d0, s_d1, s_d2;

    serializer_10to1 ser_b   (.rst_n(rst_n), .clk_pixel(clk_pixel), .clk_tmds(clk_tmds), .data_in(tmds_b),     .serial_out(s_d0));
    serializer_10to1 ser_g   (.rst_n(rst_n), .clk_pixel(clk_pixel), .clk_tmds(clk_tmds), .data_in(tmds_g),     .serial_out(s_d1));
    serializer_10to1 ser_r   (.rst_n(rst_n), .clk_pixel(clk_pixel), .clk_tmds(clk_tmds), .data_in(tmds_r),     .serial_out(s_d2));
    serializer_10to1 ser_clk (.rst_n(rst_n), .clk_pixel(clk_pixel), .clk_tmds(clk_tmds), .data_in(10'b1111100000), .serial_out(s_clk));

    // Per generare HW differenziale è necessaria la primitiva TLVDS_OBUF
    ELVDS_OBUF obuf_d0 (
    .I (s_d0),
    .O (tmds_d0_p),
    .OB(tmds_d0_n)
    );

    ELVDS_OBUF obuf_d1 (
    .I (s_d1),
    .O (tmds_d1_p),
    .OB(tmds_d1_n)
    );

    ELVDS_OBUF obuf_d2 (
    .I (s_d2),
    .O (tmds_d2_p),
    .OB(tmds_d2_n)
    );

    ELVDS_OBUF obuf_clk (
    .I (s_clk),
    .O (tmds_clk_p),
    .OB(tmds_clk_n)
    );

endmodule
