`timescale 1ns / 1ps

module sim_top_mario (
    input  wire        clk_25mhz, // Reloj maestro simulado
    input  wire        reset,
    input  wire        btn_left,
    input  wire        btn_right,
    
    // Salidas directas para SDL2 en C++
    output wire [23:0] rgb_24_out,
    output wire        hsync,
    output wire        vsync,
    output wire        video_on_out,
    output wire [9:0]  sim_x,
    output wire [9:0]  sim_y
);

    wire video_on;
    wire [9:0] pixel_x, pixel_y;

    // 1. Generador de Video (Reemplaza al vga_sync de Xilinx)
    video_generator_vga vga_inst (
        .clk_25MHz(clk_25mhz),
        .rst(reset),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // 2. Lógica de Scroll y Control de Frames (Idéntica al Top físico)
    reg [7:0] scroll_offset = 8'd0;
    reg vsync_prev;
    reg [2:0] frame_counter;

    always @(posedge clk_25mhz) begin
        if (reset) begin
            scroll_offset <= 8'd0;
            frame_counter <= 0;
            vsync_prev <= 0;
        end else begin
            vsync_prev <= vsync;
            // Flanco de bajada del VSYNC = Inicia nuevo frame
            if (vsync_prev && !vsync) begin
                frame_counter <= frame_counter + 1;
                // Sensibilidad ajustada para simulación (cada 8 frames)
                if (frame_counter == 0) begin
                    if (btn_right && scroll_offset < 192)
                        scroll_offset <= scroll_offset + 1;
                    else if (btn_left && scroll_offset > 0)
                        scroll_offset <= scroll_offset - 1;
                end
            end
        end
    end

    // 3. Extracción de Coordenadas (Usando el FIX de 5 bits para 32x32)
    wire [4:0] tile_x = pixel_x[9:5];
    wire [3:0] tile_y = pixel_y[8:5];
    wire [4:0] chunk_pixel_x = pixel_x[4:0]; // <-- FIX APLICADO
    wire [4:0] chunk_pixel_y = pixel_y[4:0]; // <-- FIX APLICADO

    // 4. Memoria RAM y ROM
    wire [7:0] chunk_id;
    wire is_solid;
    
    ram_escenario map_inst (
        .clk(clk_25mhz),
        .screen_tile_x(tile_x),
        .screen_tile_y(tile_y),
        .scroll_offset(scroll_offset),
        .chunk_id(chunk_id),
        .is_solid(is_solid)
    );

    wire [3:0] pixel_color_index;
    
    rom_chunks_mario rom_sprites (
        .clk(clk_25mhz),
        .chunk_id(chunk_id),
        .pixel_x(chunk_pixel_x),
        .pixel_y(chunk_pixel_y),
        .pixel_data(pixel_color_index)
    );

    // 5. Paleta de Colores a 24 bits
    wire [23:0] raw_rgb_24;
    paleta_rgb palette (
        .color_index(pixel_color_index),
        .rgb_24(raw_rgb_24)
    );

    // 6. Pipeline de sincronización (2 ciclos de latencia de memoria)
    reg [1:0] video_on_delay;
    reg [9:0] x_delay_1, x_delay_2;
    reg [9:0] y_delay_1, y_delay_2;

    always @(posedge clk_25mhz) begin
        video_on_delay <= {video_on_delay[0], video_on};
        x_delay_1 <= pixel_x; x_delay_2 <= x_delay_1;
        y_delay_1 <= pixel_y; y_delay_2 <= y_delay_1;
    end

    // Asignaciones finales para el simulador
    assign rgb_24_out   = (video_on_delay[1]) ? raw_rgb_24 : 24'h000000;
    assign video_on_out = video_on_delay[1];
    assign sim_x        = x_delay_2;
    assign sim_y        = y_delay_2;

endmodule

