`timescale 1ns / 1ps

module clk_generator(
    input wire clk_in,        // 100 MHz (Pin R4)
    input wire reset,
    output wire pixel_clk,    // 25.0 MHz
    output wire pixel_clk_5x, // 125.0 MHz
    output wire clk_12MHz,    // REQUERIDO para el chip de Audio
    output wire locked
);
    wire clkfb, clk_p_unbuf, clk_5x_unbuf, clk_12_unbuf;

    // VCO = (100 * 12) / 1 = 1200 MHz
    MMCME2_BASE #(
    .CLKIN1_PERIOD(10.0),       // 100 MHz entrada
    .CLKFBOUT_MULT_F(9.0),      // VCO = 900 MHz [cite: 1144]
    .DIVCLK_DIVIDE(1),           
    .CLKOUT0_DIVIDE_F(36.0),    // 900 / 36 = 25 MHz (Pixel) [cite: 1145]
    .CLKOUT1_DIVIDE(75),        // 900 / 75 = 12 MHz (Audio MCLK) [cite: 1052]
    .CLKOUT2_DIVIDE(7.2)      // 900 / 7.2 = 125 MHz (5x Serial EXACTO) [cite: 1231]
    ) MMCME2_inst (
        .CLKIN1(clk_in), .CLKFBIN(clkfb), .CLKFBOUT(clkfb),
        .CLKOUT0(clk_p_unbuf), .CLKOUT1(clk_12_unbuf), .CLKOUT2(clk_5x_unbuf),
        .LOCKED(locked), .PWRDWN(1'b0), .RST(reset)
    );

    BUFG buf1 (.I(clk_p_unbuf),  .O(pixel_clk));
    BUFG buf2 (.I(clk_12_unbuf), .O(clk_12MHz));
    BUFG buf3 (.I(clk_5x_unbuf), .O(pixel_clk_5x));
endmodule

