`timescale 1ns / 1ps
module vga_sync (
    input wire clk,
    input wire reset,
    output wire hsync,
    output wire vsync,
    output wire video_on,
    output wire p_tick,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y
);
    localparam HD = 640;
    localparam HF = 16;
    localparam HB = 48;
    localparam HR = 96;
    localparam VD = 480;
    localparam VF = 10;
    localparam VB = 33;
    localparam VR = 2;

    reg [9:0] h_count_reg;
    reg [9:0] v_count_reg;
    reg [9:0] h_count_next;
    reg [9:0] v_count_next;
    reg v_sync_reg;
    reg h_sync_reg;

    wire h_end = (h_count_reg == (HD+HF+HB+HR-1));
    wire v_end = (v_count_reg == (VD+VF+VB+VR-1));

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            v_count_reg <= 0;
            h_count_reg <= 0;
            v_sync_reg <= 1'b1;
            h_sync_reg <= 1'b1;
        end else begin
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            v_sync_reg <= ~((v_count_reg >= (VD+VB)) && (v_count_reg <= (VD+VB+VR-1)));
            h_sync_reg <= ~((h_count_reg >= (HD+HB)) && (h_count_reg <= (HD+HB+HR-1)));
        end
    end

    always @* begin
        h_count_next = h_end ? 0 : h_count_reg + 1;
        if (h_end)
            v_count_next = v_end ? 0 : v_count_reg + 1;
        else
            v_count_next = v_count_reg;
    end

    assign video_on = (h_count_reg < HD) && (v_count_reg < VD);
    assign hsync = h_sync_reg;
    assign vsync = v_sync_reg;
    assign pixel_x = h_count_reg;
    assign pixel_y = v_count_reg;
    assign p_tick = clk;
endmodule

