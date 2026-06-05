`timescale 1ns / 1ps

module hdmi_display_top(
    input wire clk100MHz,
    input wire cpu_resetn,
    // HDMI Out (J8)
    output wire hdmi_out_clk_p,
    output wire hdmi_out_clk_n,
    output wire [2:0] hdmi_out_data_p,
    output wire [2:0] hdmi_out_data_n,
    output wire hdmi_txen,
    // Audio Codec (ADAU1761)
    output wire audio_mclk,
    output wire audio_sda,
    output wire audio_scl,
    // Debug
    output wire [0:0] led_debug
);

    // --- Parámetros Estándar VGA 640x480 @ 60Hz ---
    parameter H_ACTIVE = 640;
    parameter H_FP     = 16;
    parameter H_SYNC   = 96;
    parameter H_BP     = 48;
    parameter H_TOTAL  = 800;
    
    parameter V_ACTIVE = 480;
    parameter V_FP     = 10;
    parameter V_SYNC   = 2;
    parameter V_BP     = 33;
    parameter V_TOTAL  = 525;

    // Señales de Reloj y Reset
    wire pixel_clk;
    wire pixel_clk_5x;
    wire clk_12MHz;
    wire locked;
    wire serdes_reset;
    
    // El reset del sistema es asíncrono desde el botón (activo bajo)
    wire sys_reset = ~cpu_resetn;

    // 1. Generador de Relojes (Ajustado a 480p y Audio MCLK)
    clk_generator clk_gen_inst (
        .clk_in(clk100MHz),
        .reset(sys_reset),
        .pixel_clk(pixel_clk),
        .pixel_clk_5x(pixel_clk_5x),
        .clk_12MHz(clk_12MHz),
        .locked(locked)
    );

    // 2. Puente de Reset para Serializadores
    reset_bridge rst_bridge_inst (
        .clk(pixel_clk),
        .locked(locked),
        .sync_reset(serdes_reset) 
    );

    // 3. Inicializador de Audio (I2C)
    // Conectamos el reloj de 12MHz y el MCLK de salida
    assign audio_mclk = clk_12MHz;
    
    audio_config_init audio_init_inst (
        .clk(pixel_clk),
        .reset(serdes_reset),
        .sda(audio_sda),
        .scl(audio_scl),
        .done() // LED opcional para indicar fin de config
    );

    // Configuración HDMI
    assign hdmi_txen = 1'b1; // Habilitar transmisor físico
    assign led_debug[0] = locked;

    // 4. Lógica de Sincronización de Video
    reg [10:0] h_count = 0;
    reg [10:0] v_count = 0;
    wire h_sync, v_sync, video_active;

    always @(posedge pixel_clk) begin
        if (serdes_reset) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count < H_TOTAL - 1)
                h_count <= h_count + 1;
            else begin
                h_count <= 0;
                if (v_count < V_TOTAL - 1)
                    v_count <= v_count + 1;
                else
                    v_count <= 0;
            end
        end
    end

    // hdmi_display_top.v - Cambiar a Polaridad Negativa
    assign h_sync = ~((h_count >= (H_ACTIVE + H_FP)) && (h_count < (H_ACTIVE + H_FP + H_SYNC)));
    assign v_sync = ~((v_count >= (V_ACTIVE + V_FP)) && (v_count < (V_ACTIVE + V_FP + V_SYNC)));
    assign video_active = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

    // 5. Generador de Color de Prueba (Barras de colores o Rojo Sólido)
    wire [7:0] red, green, blue;
    video_generator pattern_gen (
        .clk(pixel_clk),
        .reset(serdes_reset),
        .x_pos(h_count),
        .y_pos(v_count),
        .video_active(video_active),
        .red(red),
        .green(green),
        .blue(blue)
    );

    // 6. Encoders TMDS
    wire [9:0] tmds_red, tmds_green, tmds_blue;
    tmds_encoder enc_r (.clk(pixel_clk), .reset(serdes_reset), .data_in(red),   .c0(0),      .c1(0),      .de(video_active), .tmds_out(tmds_red));
    tmds_encoder enc_g (.clk(pixel_clk), .reset(serdes_reset), .data_in(green), .c0(0),      .c1(0),      .de(video_active), .tmds_out(tmds_green));
    tmds_encoder enc_b (.clk(pixel_clk), .reset(serdes_reset), .data_in(blue),  .c0(h_sync), .c1(v_sync), .de(video_active), .tmds_out(tmds_blue));

    // 7. Serializador Final OSERDES
    hdmi_serializer serializer_inst (
        .pixel_clk(pixel_clk),
        .pixel_clk_5x(pixel_clk_5x),
        .reset(serdes_reset),
        .tmds_red(tmds_red),
        .tmds_green(tmds_green),
        .tmds_blue(tmds_blue),
        .hdmi_clk_p(hdmi_out_clk_p),
        .hdmi_clk_n(hdmi_out_clk_n),
        .hdmi_data_p(hdmi_out_data_p),
        .hdmi_data_n(hdmi_out_data_n)
    );

endmodule