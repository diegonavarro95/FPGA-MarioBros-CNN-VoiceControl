module bgm_sequencer (
    input wire clk_12m,
    input wire reset,
    input wire next_sample,
    output wire [15:0] note_period,
    output wire note_enable
);
    reg [7:0] rom_addr;
    reg [15:0] timer;
    wire [31:0] rom_data; 

    partitura_rom memory (.addr(rom_addr), .data(rom_data));

    assign note_period = rom_data[15:0];
    assign note_enable = (rom_data[31:16] > 0);

    always @(posedge clk_12m) begin
        if (reset) begin
            rom_addr <= 0;
            timer <= 0;
        end else if (next_sample) begin
            if (timer >= rom_data[31:16]) begin
                timer <= 0;
                rom_addr <= (rom_addr == 8'd2) ? 0 : rom_addr + 1;
            end else begin
                timer <= timer + 1;
            end
        end
    end
endmodule