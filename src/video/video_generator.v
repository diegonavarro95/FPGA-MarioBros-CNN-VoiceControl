`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Video Generator Module - (Versión de prueba simplificada)
// Genera un patrón de 8 barras de color verticales para depuración.
//////////////////////////////////////////////////////////////////////////////////

module video_generator(
    input wire clk,
    input wire reset,
    input wire [10:0] x_pos,        // Posición horizontal (0 a 1279)
    input wire [10:0] y_pos,        // Posición vertical (0 a 719)
    input wire video_active,
    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue
);

    // Parámetros de la pantalla para el patrón
    parameter H_ACTIVE = 1280;
    localparam BAR_WIDTH = H_ACTIVE / 8; // 1280 / 8 = 160 píxeles por barra

    // Colores predefinidos (24 bits)
    localparam COLOR_WHITE   = 24'hFFFFFF;
    localparam COLOR_YELLOW  = 24'hFFFF00;
    localparam COLOR_CYAN    = 24'h00FFFF;
    localparam COLOR_GREEN   = 24'h00FF00;
    localparam COLOR_MAGENTA = 24'hFF00FF;
    localparam COLOR_RED     = 24'hFF0000;
    localparam COLOR_BLUE    = 24'h0000FF;
    localparam COLOR_BLACK   = 24'h000000;

    // Variable temporal para el color del píxel
    reg [23:0] pixel_color;

    // Lógica de generación de patrón registrada
    always @(posedge clk) begin
        if (reset) begin
            // Resetea a negro
            red   <= 8'h00;
            green <= 8'h00;
            blue  <= 8'h00;
            pixel_color <= 24'h00;

        end else if (video_active) begin
            // Generar el patrón de barras basado en la posición horizontal (x_pos)
            // Esto es hardware combinacional muy rápido (solo comparadores)
            if (x_pos < BAR_WIDTH) begin          // Barra 1 (0-159)
                pixel_color <= COLOR_WHITE;
            end else if (x_pos < BAR_WIDTH * 2) begin // Barra 2 (160-319)
                pixel_color <= COLOR_YELLOW;
            end else if (x_pos < BAR_WIDTH * 3) begin // Barra 3 (320-479)
                pixel_color <= COLOR_CYAN;
            end else if (x_pos < BAR_WIDTH * 4) begin // Barra 4 (480-639)
                pixel_color <= COLOR_GREEN;
            end else if (x_pos < BAR_WIDTH * 5) begin // Barra 5 (640-799)
                pixel_color <= COLOR_MAGENTA;
            end else if (x_pos < BAR_WIDTH * 6) begin // Barra 6 (800-959)
                pixel_color <= COLOR_RED;
            end else if (x_pos < BAR_WIDTH * 7) begin // Barra 7 (960-1119)
                pixel_color <= COLOR_BLUE;
            end else begin                            // Barra 8 (1120-1279)
                pixel_color <= COLOR_BLACK;
            end

            // Asignar los valores RGB finales a los registros de salida
            red   <= pixel_color[23:16];
            green <= pixel_color[15:8];
            blue  <= pixel_color[7:0];

        end else begin
            // Fuera del área activa, mostrar rojo
            red   <= 8'hFF; 
            green <= 8'h00;
            blue  <= 8'h00;
        end
    end

endmodule