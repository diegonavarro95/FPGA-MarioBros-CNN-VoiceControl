// =============================================================================
// PALETA_RGB.V
// Convierte el índice de color de 4 bits de los chunks a RGB de 24 bits
//
// Los 16 colores están basados en la paleta NES aproximada para Mario Bros.
// El color 0 (transparente) se mapea al azul cielo del fondo.
//
// LATENCIA: combinacional puro (0 ciclos) - sin registros
// =============================================================================

module paleta_rgb (
    input  wire [3:0]  color_index,  // Color de 4 bits de rom_chunks_mario
    output reg  [23:0] rgb_out       // RGB 24 bits: [23:16]=R, [15:8]=G, [7:0]=B
);

    always @(*) begin
        case (color_index)
            4'h0: rgb_out = 24'h5C94FC; // Azul cielo  (transparente → fondo)
            4'h1: rgb_out = 24'h000000; // Negro
            4'h2: rgb_out = 24'hBCBCBC; // Gris claro
            4'h3: rgb_out = 24'h008800; // Verde oscuro  (tuberías borde)
            4'h4: rgb_out = 24'h00D800; // Verde claro   (tuberías interior)
            4'h5: rgb_out = 24'h7C4C00; // Café oscuro
            4'h6: rgb_out = 24'hC49C00; // Café claro    (suelo)
            4'h7: rgb_out = 24'hFCA044; // Beige/Piel    (Mario cara/manos)
            4'h8: rgb_out = 24'h444444; // Gris oscuro   (bordes bloques)
            4'h9: rgb_out = 24'h7C5800; // Café/Marrón   (Goomba, ladrillos)
            4'hA: rgb_out = 24'h00A8E4; // Azul claro
            4'hB: rgb_out = 24'hE87000; // Naranja/Dorado oscuro (bloque ?)
            4'hC: rgb_out = 24'hE40058; // Rojo          (Mario cuerpo)
            4'hD: rgb_out = 24'hF878F8; // Rosa
            4'hE: rgb_out = 24'hFCE840; // Amarillo/Dorado brillante (monedas)
            4'hF: rgb_out = 24'hFCFCFC; // Blanco        (nubes, signo ?)
            default: rgb_out = 24'hFF00FF; // Magenta (error, no debería ocurrir)
        endcase
    end

endmodule