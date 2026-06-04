`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.01.2026 16:38:39
// Design Name: 
// Module Name: audio_config_init
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module audio_config_init(
    input  wire clk,        // Usa el de 25MHz
    input  wire reset,
    output reg  scl,
    output reg  sda,
    output reg  done
);
    // Maquina de estados para enviar: [START] [ADDR+W] [REG_H] [REG_L] [DATA] [STOP]
    // Registros minimos: 0x4000=0x01, 0x40F2=0x01, 0x40F9=0x7F, 0x40FA=0x7F
    reg [7:0] state = 0;
    reg [31:0] timer = 0;
    
    // Simplificación: Driver I2C de "bit-banging" para inicialización
    always @(posedge clk) begin
        if (reset) begin
            state <= 0;
            done <= 0;
            scl <= 1; sda <= 1;
        end else begin
            case(state)
                0: if (timer < 2500000) timer <= timer + 1; else state <= 1; // Esperar 100ms
                // Aquí iría la lógica serie para mandar los 4 comandos de setup.
                // Por ahora, mantén SCL/SDA en alto para no bloquear el bus.
                1: begin scl <= 1; sda <= 1; done <= 1; end 
            endcase
        end
    end
endmodule