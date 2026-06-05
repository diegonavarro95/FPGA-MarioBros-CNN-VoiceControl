`timescale 1ns / 1ps
module controlador_escritura (
    input  wire       clk,
    input  wire       rst,
    output wire [3:0] pixel_x,
    output wire [3:0] pixel_y,
    output wire       ram_we,
    output reg        next_chunk  // Pulso para cambiar el ID aleatorio
);

    // Registros internos para los contadores
    reg [3:0] count_x = 4'd0;
    reg [3:0] count_y = 4'd0;

    // Asignación continua a las salidas
    assign pixel_x = count_x;
    assign pixel_y = count_y;
    assign ram_we  = 1'b1; // Siempre escribiendo mientras recorremos

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_x    <= 4'd0;
            count_y    <= 4'd0;
            next_chunk <= 1'b0;
        end else begin
            next_chunk <= 1'b0; // Por defecto es 0, solo da un pulso de 1 ciclo
            
            if (count_x == 4'd15) begin
                count_x <= 4'd0;
                
                if (count_y == 4'd15) begin
                    count_y <= 4'd0;
                    next_chunk <= 1'b1; // Ya llenamos la RAM, pedir nuevo chunk
                end else begin
                    count_y <= count_y + 4'd1;
                end
                
            end else begin
                count_x <= count_x + 4'd1;
            end
        end
    end

endmodule

