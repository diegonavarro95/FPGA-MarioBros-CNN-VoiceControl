`timescale 1ns / 1ps

module ram_ventana (
    input  wire       clk,
    input  wire       we,
    input  wire [7:0] addr,
    input  wire [2:0] data_in,
    output reg  [2:0] data_out
);

    // Inferencia de memoria (256 localidades de 3 bits)
    // Vivado lo mapeará a Distributed RAM o BRAM automáticamente
    reg [2:0] RAM [0:255];

    // Inicialización a cero (Buena práctica en FPGAs de Xilinx)
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            RAM[i] = 3'b000;
        end
    end

    // Proceso de lectura y escritura síncrona
    always @(posedge clk) begin
        if (we) begin
            RAM[addr] <= data_in;
        end
        // La lectura tiene 1 ciclo de latencia, exactamente igual que en tu VHDL
        data_out <= RAM[addr]; 
    end

endmodule

