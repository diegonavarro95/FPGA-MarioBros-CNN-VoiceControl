`timescale 1ns / 1ps

module mario_vga_top (
    input  wire       clk,   // Reloj maestro simulado de 25 MHz
    input  wire       rst,
    input  wire [7:0] scroll_offset,
    
    // Pines físicos que irían al Pmod VGA
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       hsync,
    output wire       vsync,
    
    // Salidas extra SOLO para que Verilator (nuestro monitor de C++) sepa dónde dibujar
    output wire [9:0] sim_x,
    output wire [9:0] sim_y,
    output wire       sim_video_on
);

    // 1. GENERADOR DE TIEMPOS VGA
    wire [9:0] vga_x, vga_y;
    wire video_on;
    
    video_generator_vga vga_inst (
        .clk_25MHz(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .pixel_x(vga_x),
        .pixel_y(vga_y)
    );

    // 2. EXTRACCIÓN DEL ESCENARIO (Usa las coordenadas del VGA divididas entre 2)
    wire [3:0] pixel_color_idx;
    
    escenario_top escenario_inst (
        .clk(clk),
        .screen_x(vga_x[9:1]), // FIX: Shift a la derecha = Dividir entre 2 (Mapea 640 a 320)
        .screen_y(vga_y[9:1]), // FIX: Shift a la derecha = Dividir entre 2 (Mapea 480 a 240)
        .scroll_offset(scroll_offset),
        .pixel_color(pixel_color_idx)
    );

    // 3. PIPELINE DE SINCRONIZACIÓN (El arreglo de latencia de 2 ciclos)
    reg [1:0] video_on_delay;
    reg [9:0] x_delay_1, x_delay_2;
    reg [9:0] y_delay_1, y_delay_2;
    
    always @(posedge clk) begin
        // Retrasamos video_on
        video_on_delay <= {video_on_delay[0], video_on};
        
        // Retrasamos las coordenadas para el simulador C++
        x_delay_1 <= vga_x; x_delay_2 <= x_delay_1;
        y_delay_1 <= vga_y; y_delay_2 <= y_delay_1;
    end

    // 4. PALETA DE COLORES (DAC lógico)
    wire [3:0] raw_r, raw_g, raw_b;
    
    paleta_rgb paleta_inst (
        .color_index(pixel_color_idx),
        .vga_r(raw_r),
        .vga_g(raw_g),
        .vga_b(raw_b)
    );

    // 5. ASIGNACIÓN FINAL (Con Blanking)
    // Si no estamos en la zona visible (video_on_delay[1] == 0), mandamos 0V (Negro)
    assign vga_r = (video_on_delay[1]) ? raw_r : 4'h0;
    assign vga_g = (video_on_delay[1]) ? raw_g : 4'h0;
    assign vga_b = (video_on_delay[1]) ? raw_b : 4'h0;

    // Pasamos las señales sincronizadas a Verilator
    assign sim_x = x_delay_2;
    assign sim_y = y_delay_2;
    assign sim_video_on = video_on_delay[1];

endmodule

