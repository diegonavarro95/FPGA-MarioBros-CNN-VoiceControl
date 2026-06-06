module partitura_rom (
    input wire [7:0] addr,
    output reg [31:0] data
);
    always @(*) begin
        case(addr)
            0: data = {16'd1600, 16'd18639};
            1: data = {16'd1600, 16'd18639};
            2: data = {16'd3200, 16'd0}; 
            default: data = 32'd0;
        endcase
    end
endmodule