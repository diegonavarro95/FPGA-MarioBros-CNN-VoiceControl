module i2s_master (
    input  wire clk_12m,
    input  wire reset,
    input  wire [15:0] audio_in,
    output reg  bclk,
    output reg  lrclk,
    output reg  sdata,
    output wire next_sample
);
    reg [4:0] div_cnt = 0;
    reg [4:0] bit_cnt = 0;
    reg [31:0] shift_reg = 0;

    assign next_sample = (div_cnt == 11 && bclk == 1 && bit_cnt == 31);

    always @(posedge clk_12m) begin
        if (reset) begin
            div_cnt <= 0; bclk <= 0; lrclk <= 0; sdata <= 0; bit_cnt <= 0; shift_reg <= 0;
        end else begin
            if (div_cnt == 11) begin
                div_cnt <= 0;
                bclk <= ~bclk;
                if (bclk) begin 
                    if (bit_cnt == 0) begin
                        lrclk <= 1'b0; 
                        sdata <= shift_reg[31]; 
                        shift_reg <= {audio_in, audio_in}; 
                    end else if (bit_cnt == 16) begin
                        lrclk <= 1'b1; 
                        sdata <= shift_reg[31]; 
                        shift_reg <= {shift_reg[30:0], 1'b0};
                    end else begin
                        sdata <= shift_reg[31]; 
                        shift_reg <= {shift_reg[30:0], 1'b0};
                    end
                    bit_cnt <= bit_cnt + 1;
                end
            end else begin
                div_cnt <= div_cnt + 1;
            end
        end
    end
endmodule