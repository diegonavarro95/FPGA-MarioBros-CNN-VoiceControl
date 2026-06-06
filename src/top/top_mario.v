module top_mario (
    input wire clk_100mhz,
    input wire reset_n,
    input wire btn_left,
    input wire btn_right,
    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n,
    output wire hdmi_txen,
    
    // Puertos físicos del ADAU1761
    output wire audio_mclk,
    output wire audio_bclk,
    output wire audio_lrclk,
    output wire audio_dac_sdata,
    inout wire audio_scl,
    inout wire audio_sda
);
    wire pclk, pclk_x5, pclk_x3, locked;
    wire hsync, vsync, video_on;
    wire [9:0] pixel_x, pixel_y;

    wire sys_reset = (~reset_n) | (~locked);
    assign hdmi_txen = 1'b1;
    
    // Reloj de audio desde tu MMCM (Configurado a 12.295 MHz)
    wire clk_12_288m = pclk_x3; 
    assign audio_mclk = clk_12_288m;

    clk_wiz_0 clk_inst (
        .clk_in1(clk_100mhz),
        .clk_out1(pclk),
        .clk_out2(pclk_x5),
        .clk_out3(pclk_x3),
        .locked(locked)
    );

    // -------------------------------------------------------------------------
    // FLUJO DE CONTROL DE AUDIO (I2C)
    // -------------------------------------------------------------------------
    wire audio_init_done;
    
    audio_config_init audio_init (
        .clk(pclk),
        .reset(sys_reset),
        .scl(audio_scl),
        .sda(audio_sda),
        .done(audio_init_done)
    );

    vga_sync vga_inst (
        .clk(pclk),
        .reset(sys_reset),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .p_tick(),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    wire [15:0] rom_data_jump, rom_data_coin;
    wire [15:0] addr_jump, addr_coin;
    wire [15:0] pcm_mixed;
    wire next_audio_sample;
    
    blk_mem_gen_salto rom_salto_inst (
        .clka(clk_12_288m),
        .addra(addr_jump),
        .douta(rom_data_jump)
    );

    blk_mem_gen_moneda rom_moneda_inst (
        .clka(clk_12_288m),
        .addra(addr_coin),
        .douta(rom_data_coin)
    );

    audio_controller dsp_mixer (
        .clk_12m(clk_12_288m),
        .reset(sys_reset),
        .btn_jump(btn_left),  
        .btn_coin(btn_right),
        .next_sample(next_audio_sample),
        .addr_jump(addr_jump),
        .addr_coin(addr_coin),
        .data_jump(rom_data_jump),
        .data_coin(rom_data_coin),
        .audio_out(pcm_mixed)
    );

    i2s_master tx_i2s (
        .clk_12m(clk_12_288m),
        .reset(sys_reset),
        .audio_in(audio_init_done ? pcm_mixed : 16'd0),
        .bclk(audio_bclk),
        .lrclk(audio_lrclk),
        .sdata(audio_dac_sdata),
        .next_sample(next_audio_sample)
    );

    reg [7:0] scroll_offset = 8'd0;
    reg vsync_prev;
    reg [2:0] frame_counter;

    always @(posedge pclk) begin
        if (sys_reset) begin
            scroll_offset <= 8'd0;
            frame_counter <= 0;
            vsync_prev <= 0;
        end else begin
            vsync_prev <= vsync;
            if (vsync_prev && !vsync) begin
                frame_counter <= frame_counter + 1;
                if (frame_counter == 0) begin
                    if (btn_right && scroll_offset < 192)
                        scroll_offset <= scroll_offset + 1;
                    else if (btn_left && scroll_offset > 0)
                        scroll_offset <= scroll_offset - 1;
                end
            end
        end
    end

    // =========================================================================
    // FIX 1: GENERADOR DE COORDENADAS VERDADERAS (Evita bugs de pantalla cortada)
    // =========================================================================
    reg [9:0] draw_x = 0;
    reg [9:0] draw_y = 0;
    
    always @(posedge pclk) begin
        if (sys_reset) begin
            draw_x <= 0;
            draw_y <= 0;
        end else if (video_on) begin
            if (draw_x == 639) begin
                draw_x <= 0;
                if (draw_y == 479) draw_y <= 0;
                else draw_y <= draw_y + 1;
            end else begin
                draw_x <= draw_x + 1;
            end
        end else begin
            draw_x <= 0;
            if (!vsync) draw_y <= 0;
        end
    end

    // =========================================================================
    // FIX 2 y 3: ESCALADO 32x32 y RETRASO DE PIPELINE
    // =========================================================================
    wire [4:0] tile_x = draw_x[9:5];
    wire [3:0] tile_y = draw_y[8:5];

    // Latencia de 1 ciclo para que los píxeles esperen a la memoria RAM
    reg [4:0] chunk_pixel_x_delay;
    reg [4:0] chunk_pixel_y_delay;
    
    always @(posedge pclk) begin
        chunk_pixel_x_delay <= draw_x[4:0]; // Ahora usa 5 bits para 32x32
        chunk_pixel_y_delay <= draw_y[4:0];
    end

    wire [7:0] chunk_id;
    wire is_solid;

    ram_escenario map_inst (
        .clk(pclk),
        .screen_tile_x(tile_x),
        .screen_tile_y(tile_y),
        .scroll_offset(scroll_offset),
        .chunk_id(chunk_id),
        .is_solid(is_solid)
    );

    wire [3:0] pixel_color_index;

    rom_chunks_mario rom_sprites (
        .clk(pclk),
        .chunk_id(chunk_id),
        .pixel_x(chunk_pixel_x_delay), // Se inyectan las coordenadas sincronizadas
        .pixel_y(chunk_pixel_y_delay),
        .pixel_data(pixel_color_index)
    );

    wire [23:0] rgb_24;

    paleta_rgb palette (
        .color_index(pixel_color_index),
        .rgb_24(rgb_24)
    );

    reg [1:0] hsync_delay;
    reg [1:0] vsync_delay;
    reg [1:0] video_on_delay;

    always @(posedge pclk) begin
        hsync_delay    <= {hsync_delay[0], hsync};
        vsync_delay    <= {vsync_delay[0], vsync};
        video_on_delay <= {video_on_delay[0], video_on};
    end

    // =========================================================================
    // FIX 4: ORDEN DE COLORES RGB CORREGIDO PARA EL PUERTO HDMI
    // =========================================================================
    rgb2dvi_0 hdmi_tx (
        .TMDS_Clk_p(tmds_clk_p),
        .TMDS_Clk_n(tmds_clk_n),
        .TMDS_Data_p(tmds_data_p),
        .TMDS_Data_n(tmds_data_n),
        .aRst(sys_reset),
        // Corrección de posiciones: {Rojo, Verde, Azul}
        .vid_pData(video_on_delay[1] ? {rgb_24[23:16], rgb_24[7:0], rgb_24[15:8]} : 24'h000000),
        .vid_pVDE(video_on_delay[1]),
        .vid_pHSync(hsync_delay[1]),
        .vid_pVSync(vsync_delay[1]),
        .PixelClk(pclk),
        .SerialClk(pclk_x5)
    );
endmodule

