`timescale 1ns / 1ps
// =============================================================================
// PALETA_RGB.V
// Convierte el índice de color de 4 bits de los chunks a RGB de 12 bits (Pmod VGA)
// Aun se discute si usar VGA o HDMI
// LATENCIA: combinacional puro (0 ciclos) - sin registros
// =============================================================================

module paleta_rgb (
    input  wire [3:0] color_index,  // Color de 4 bits de rom_chunks_mario
    output reg  [3:0] vga_r,        // 4 bits canal Rojo
    output reg  [3:0] vga_g,        // 4 bits canal Verde
    output reg  [3:0] vga_b         // 4 bits canal Azul
);

    always @(*) begin
        case (color_index)
            // FORMATO 12'hRGB extraído de tu paleta NES original de 24 bits
            4'h0: {vga_r, vga_g, vga_b} = 12'h59F; // Azul cielo (5C, 94, FC)
            4'h1: {vga_r, vga_g, vga_b} = 12'h000; // Negro      (00, 00, 00)
            4'h2: {vga_r, vga_g, vga_b} = 12'hBBB; // Gris claro (BC, BC, BC)
            4'h3: {vga_r, vga_g, vga_b} = 12'h080; // Verde osc. (00, 88, 00)
            4'h4: {vga_r, vga_g, vga_b} = 12'h0D0; // Verde cla. (00, D8, 00)
            4'h5: {vga_r, vga_g, vga_b} = 12'h740; // Café osc.  (7C, 4C, 00)
            4'h6: {vga_r, vga_g, vga_b} = 12'hC90; // Café cla.  (C4, 9C, 00)
            4'h7: {vga_r, vga_g, vga_b} = 12'hFA4; // Piel       (FC, A0, 44)
            4'h8: {vga_r, vga_g, vga_b} = 12'h444; // Gris osc.  (44, 44, 44)
            4'h9: {vga_r, vga_g, vga_b} = 12'h750; // Marrón     (7C, 58, 00)
            4'hA: {vga_r, vga_g, vga_b} = 12'h0AE; // Azul claro (00, A8, E4)
            4'hB: {vga_r, vga_g, vga_b} = 12'hE70; // Naranja    (E8, 70, 00)
            4'hC: {vga_r, vga_g, vga_b} = 12'hE05; // Rojo Mario (E4, 00, 58)
            4'hD: {vga_r, vga_g, vga_b} = 12'hF7F; // Rosa       (F8, 78, F8)
            4'hE: {vga_r, vga_g, vga_b} = 12'hFE4; // Amarillo   (FC, E8, 40)
            4'hF: {vga_r, vga_g, vga_b} = 12'hFFF; // Blanco     (FC, FC, FC)
            default: {vga_r, vga_g, vga_b} = 12'hF0F; // Magenta de error
        endcase
    end

endmodule

