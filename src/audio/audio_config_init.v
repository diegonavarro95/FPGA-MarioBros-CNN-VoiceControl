module audio_config_init (
    input wire clk,
    input wire reset,
    output wire scl,
    inout wire sda,
    output reg done
);
    reg [31:0] rom [0:9];
    initial begin
        rom[0] = 32'h76_4000_01;
        rom[1] = 32'h76_4015_00;
        rom[2] = 32'h76_402A_03;
        rom[3] = 32'h76_4029_03;
        rom[4] = 32'h76_401C_21;
        rom[5] = 32'h76_401E_41;
        rom[6] = 32'h76_4023_E7;
        rom[7] = 32'h76_4024_E7;
        rom[8] = 32'h76_40F9_7F;
        rom[9] = 32'h76_40FA_01;
    end
    reg [3:0] state = 0;
    reg [5:0] bit_cnt = 0;
    reg [3:0] word_cnt = 0;
    reg [31:0] shift_reg = 0;
    reg scl_r = 1, sda_r = 1;
    reg [9:0] timer = 0;
    
    assign scl = scl_r;
    assign sda = sda_r ? 1'bz : 1'b0;
    
    always @(posedge clk) begin
        if (reset) begin
            state <= 0; done <= 0; scl_r <= 1; sda_r <= 1; word_cnt <= 0;
        end else begin
            timer <= timer + 1;
            if (timer == 0) begin
                case (state)
                    0: if (word_cnt < 10) begin shift_reg <= rom[word_cnt]; state <= 1; end else done <= 1;
                    1: begin sda_r <= 0; state <= 2; bit_cnt <= 31; end
                    2: begin scl_r <= 0; state <= 3; end
                    3: begin sda_r <= shift_reg[bit_cnt]; state <= 4; end
                    4: begin scl_r <= 1; state <= 5; end
                    5: begin
                           scl_r <= 0;
                           if (bit_cnt % 8 == 0) state <= 6;
                           else begin bit_cnt <= bit_cnt - 1; state <= 3; end
                       end
                    6: begin sda_r <= 1; state <= 7; end
                    7: begin scl_r <= 1; state <= 8; end
                    8: begin
                           scl_r <= 0;
                           if (bit_cnt == 0) state <= 9;
                           else begin bit_cnt <= bit_cnt - 1; state <= 3; end
                       end
                    9: begin sda_r <= 0; state <= 10; end
                   10: begin scl_r <= 1; state <= 11; end
                   11: begin sda_r <= 1; word_cnt <= word_cnt + 1; state <= 0; end
                endcase
            end
        end
    end
endmodule