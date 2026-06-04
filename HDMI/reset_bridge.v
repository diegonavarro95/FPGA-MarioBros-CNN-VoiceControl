`timescale 1ns / 1ps
module reset_bridge (
    input wire clk,           // Reloj de destino (pixel_clk)
    input wire locked,        // Señal de 'Locked' del PLL
    output reg sync_reset     // Reset sincronizado y limpio
);
    reg [1:0] rst_chain;

    // La señal 'locked' es 1 cuando está estable.
    // El reset del sistema debe ser 1 cuando NO está locked (activo alto para OSERDES).
    // OJO: OSERDESE2 usa RST activo ALTO.
    
    always @(posedge clk or negedge locked) begin
        if (!locked) begin
            // Si el PLL se cae, reset inmediato asíncrono
            rst_chain <= 2'b11;
            sync_reset <= 1'b1;
        end else begin
            // Si el PLL está estable, bajamos el reset sincronizado con el reloj
            rst_chain <= {rst_chain[0], 1'b0};
            sync_reset <= rst_chain[1];
        end
    end
endmodule