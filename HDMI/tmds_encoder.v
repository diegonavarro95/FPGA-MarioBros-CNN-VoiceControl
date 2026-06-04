`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// TMDS Encoder - Codifica los datos de 8 bits en TMDS de 10 bits para HDMI
//////////////////////////////////////////////////////////////////////////////////

module tmds_encoder(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,    // Datos de pixel (R, G o B)
    input wire c0,                // Control bit 0 (para el canal azul: hsync)
    input wire c1,                // Control bit 1 (para el canal azul: vsync)
    input wire de,                // Data Enable - indica si estamos en área activa
    output reg [9:0] tmds_out    // Salida TMDS codificada
);

    // Variables internas para el algoritmo TMDS
    reg [8:0] q_m;
    reg signed [4:0] cnt = 0;
    
    // Cuenta el número de '1's en los datos de entrada
    function [3:0] count_ones;
        input [7:0] data;
        integer i;
        begin
            count_ones = 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (data[i]) count_ones = count_ones + 1;
            end
        end
    endfunction
    
    // Cuenta el número de '1's en q_m[7:0]
    function [3:0] count_ones_q_m;
        input [7:0] q_m_data;
        integer i;
        begin
            count_ones_q_m = 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (q_m_data[i]) count_ones_q_m = count_ones_q_m + 1;
            end
        end
    endfunction
    
    wire [3:0] n1_data = count_ones(data_in);
    wire [3:0] n1_q_m;
    wire [3:0] n0_q_m;
    
    // Primera etapa: minimización de transiciones
    always @(*) begin
        if (n1_data > 4 || (n1_data == 4 && data_in[0] == 0)) begin
            // Usar XNOR
            q_m[0] = data_in[0];
            q_m[1] = q_m[0] ~^ data_in[1];
            q_m[2] = q_m[1] ~^ data_in[2];
            q_m[3] = q_m[2] ~^ data_in[3];
            q_m[4] = q_m[3] ~^ data_in[4];
            q_m[5] = q_m[4] ~^ data_in[5];
            q_m[6] = q_m[5] ~^ data_in[6];
            q_m[7] = q_m[6] ~^ data_in[7];
            q_m[8] = 0;
        end else begin
            // Usar XOR
            q_m[0] = data_in[0];
            q_m[1] = q_m[0] ^ data_in[1];
            q_m[2] = q_m[1] ^ data_in[2];
            q_m[3] = q_m[2] ^ data_in[3];
            q_m[4] = q_m[3] ^ data_in[4];
            q_m[5] = q_m[4] ^ data_in[5];
            q_m[6] = q_m[5] ^ data_in[6];
            q_m[7] = q_m[6] ^ data_in[7];
            q_m[8] = 1;
        end
    end
    
    assign n1_q_m = count_ones_q_m(q_m[7:0]);
    assign n0_q_m = 4'd8 - n1_q_m;
    
    // Segunda etapa: balance DC
    always @(posedge clk) begin
        if (reset) begin
            tmds_out <= 10'b0000000000;
            cnt <= 0;
        end else begin
            if (de) begin
                // Área activa de video - codificar datos
                if (cnt == 0 || n1_q_m == n0_q_m) begin
                    // Sin disparidad previa o igual número de 1s y 0s
                    tmds_out[9] <= ~q_m[8];
                    tmds_out[8] <= q_m[8];
                    if (q_m[8]) begin
                        tmds_out[7:0] <= q_m[7:0];
                        cnt <= cnt + n1_q_m - n0_q_m;
                    end else begin
                        tmds_out[7:0] <= ~q_m[7:0];
                        cnt <= cnt + n0_q_m - n1_q_m;
                    end
                end else begin
                    if ((cnt[4] == 0 && n1_q_m > n0_q_m) || 
                        (cnt[4] == 1 && n0_q_m > n1_q_m)) begin
                        tmds_out[9] <= 1;
                        tmds_out[8] <= q_m[8];
                        tmds_out[7:0] <= ~q_m[7:0];
                        if (q_m[8])
                            cnt <= cnt + 2'b10 + n0_q_m - n1_q_m;
                        else
                            cnt <= cnt + n0_q_m - n1_q_m;
                    end else begin
                        tmds_out[9] <= 0;
                        tmds_out[8] <= q_m[8];
                        tmds_out[7:0] <= q_m[7:0];
                        if (q_m[8])
                            cnt <= cnt + n1_q_m - n0_q_m;
                        else
                            cnt <= cnt - 2'b10 + n1_q_m - n0_q_m;
                    end
                end
            end else begin
                // Período de blanking - enviar caracteres de control
                cnt <= 0;
                case ({c1, c0})
                    2'b00: tmds_out <= 10'b1101010100;
                    2'b01: tmds_out <= 10'b0010101011;
                    2'b10: tmds_out <= 10'b0101010100;
                    2'b11: tmds_out <= 10'b1010101011;
                endcase
            end
        end
    end

endmodule
