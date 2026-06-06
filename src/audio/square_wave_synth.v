module square_wave_synth (
    input wire clk_12m,
    input wire reset,
    input wire [15:0] note_period,
    input wire note_enable,
    output reg [15:0] pcm_out
);
    reg [15:0] counter;
    reg wave_state;

    always @(posedge clk_12m) begin
        if (reset) begin
            counter <= 0;
            wave_state <= 0;
            pcm_out <= 0;
        end else if (note_enable && note_period > 0) begin
            if (counter >= note_period) begin
                counter <= 0;
                wave_state <= ~wave_state;
            end else begin
                counter <= counter + 1;
            end
            pcm_out <= wave_state ? 16'h1FFF : 16'hE000;
        end else begin
            pcm_out <= 0;
        end
    end
endmodule