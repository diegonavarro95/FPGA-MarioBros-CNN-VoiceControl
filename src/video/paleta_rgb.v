`timescale 1ns / 1ps
// =============================================================================
// PALETA_RGB.V — Convierte índice de color de 4 bits a RGB 24 bits
// COMPATIBLE CON top-mario.v (.rgb_24 [23:0])
// Colores basados en la paleta NES original de Super Mario Bros.
// LATENCIA: combinacional puro (0 ciclos)
// =============================================================================

module paleta_rgb (
    input  wire [3:0]  color_index,
    output reg  [23:0] rgb_24        // Formato: {R[23:16], G[15:8], B[7:0]}
);

    always @(*) begin
        case (color_index)
            4'h0: rgb_24 = 24'h5C94FC; // Azul cielo   — transparente -> fondo
            4'h1: rgb_24 = 24'h000000; // Negro
            4'h2: rgb_24 = 24'hBCBCBC; // Gris claro
            4'h3: rgb_24 = 24'h008800; // Verde oscuro  — borde de tuberia
            4'h4: rgb_24 = 24'h00D800; // Verde claro   — interior tuberia
            4'h5: rgb_24 = 24'h7C4C00; // Cafe oscuro
            4'h6: rgb_24 = 24'hC49C00; // Cafe claro    — patron de suelo
            4'h7: rgb_24 = 24'hFCBCB0; // Piel NES
            4'h8: rgb_24 = 24'h444444; // Gris oscuro   — bordes bloques
            4'h9: rgb_24 = 24'h7C5800; // Cafe/Marron   — goomba, ladrillos
            4'hA: rgb_24 = 24'h00A8E4; // Azul claro
            4'hB: rgb_24 = 24'hE87000; // Naranja       — bloque ? borde
            4'hC: rgb_24 = 24'hD82800; // Rojo NES Mario          — Mario cuerpo
            4'hD: rgb_24 = 24'hF878F8; // Rosa
            4'hE: rgb_24 = 24'hFCE840; // Amarillo      — monedas, bloque ?
            4'hF: rgb_24 = 24'hFCFCFC; // Blanco        — nubes, signo ?
            default: rgb_24 = 24'hFF00FF;
        endcase
    end
endmodule

