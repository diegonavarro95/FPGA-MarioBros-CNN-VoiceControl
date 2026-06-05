`timescale 1ns / 1ps

module generador_random (
    input  wire       CLK,
    input  wire       RST,
    input  wire       EN,        // Añadido para arreglar el bug: Habilita el cambio de ID
    output reg  [7:0] CHUNK_ID
);

    reg [7:0] r_reg;
    wire feedback;
    wire [3:0] seleccion;

    // 1. GENERADOR LFSR (Ecuación del polinomio)
    assign feedback = r_reg[7] ^ r_reg[5] ^ r_reg[4] ^ r_reg[3];

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            r_reg <= 8'b10010110; // Semilla inicial (no usar ceros)
        end else if (EN) begin 
            // El LFSR SOLO avanza cuando recibe el pulso "next_chunk"
            r_reg <= {r_reg[6:0], feedback};
        end
    end

    // 2. EL TRADUCTOR (Mapeo a Chunks Válidos)
    assign seleccion = r_reg[3:0];

    always @(*) begin
        case (seleccion)
            // TERRENO Y BLOQUES 
            4'b0000: CHUNK_ID = 8'h01; // 1: Ladrillo
            4'b0001: CHUNK_ID = 8'h02; // 2: Pregunta
            4'b0010: CHUNK_ID = 8'h03; // 3: Suelo
            4'b0011: CHUNK_ID = 8'h03; // 3: Suelo
            // DECORACIÓN Y CIELO 
            4'b0100: CHUNK_ID = 8'h00; // 0: Vacío
            4'b0101: CHUNK_ID = 8'h00; // 0: Vacío
            4'b0110: CHUNK_ID = 8'h60; // 96: Nube pequeña
            4'b0111: CHUNK_ID = 8'h61; // 97: Arbusto
            // ESTRUCTURAS
            4'b1000: CHUNK_ID = 8'h04; // 4: Escalera
            4'b1001: CHUNK_ID = 8'h0A; // 10: Tubería tope izq
            4'b1010: CHUNK_ID = 8'h07; // 7: Metal
            // ENEMIGOS E ITEMS
            4'b1011: CHUNK_ID = 8'h20; // 32: Goomba
            4'b1100: CHUNK_ID = 8'h21; // 33: Koopa
            4'b1101: CHUNK_ID = 8'h40; // 64: Moneda
            4'b1110: CHUNK_ID = 8'h42; // 66: Flor de fuego
            // DEFAULT 
            default: CHUNK_ID = 8'h03; // 3: Suelo
        endcase
    end

endmodule

