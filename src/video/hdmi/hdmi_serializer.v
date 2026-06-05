`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// HDMI Serializer - Corrected for Artix-7 OSERDESE2
// 10:1 DDR Serialization using Master/Slave configuration
//////////////////////////////////////////////////////////////////////////////////

module hdmi_serializer(
    input wire pixel_clk,       // Pixel clock (1x)
    input wire pixel_clk_5x,    // Serial clock (5x)
    input wire reset,
    input wire [9:0] tmds_red,
    input wire [9:0] tmds_green,
    input wire [9:0] tmds_blue,
    output wire hdmi_clk_p,
    output wire hdmi_clk_n,
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n
);
    // HDMI clock pattern (10 bits: 5 high, 5 low)
    wire [9:0] tmds_clk = 10'b0000011111; // Patrón invertido (Desfase de 180 grados)

    // Instantiate 4 serializers: Blue, Green, Red, Clock
    serializer_10_to_1 ser_b (
        .clk_x1(pixel_clk), 
        .clk_x5(pixel_clk_5x), 
        .reset(reset), 
        .data_in(tmds_blue),  
        .data_p(hdmi_data_p[0]), 
        .data_n(hdmi_data_n[0])
    );
    
    serializer_10_to_1 ser_g (
        .clk_x1(pixel_clk), 
        .clk_x5(pixel_clk_5x), 
        .reset(reset), 
        .data_in(tmds_green), 
        .data_p(hdmi_data_p[1]), 
        .data_n(hdmi_data_n[1])
    );
    
    serializer_10_to_1 ser_r (
        .clk_x1(pixel_clk), 
        .clk_x5(pixel_clk_5x), 
        .reset(reset), 
        .data_in(tmds_red),   
        .data_p(hdmi_data_p[2]), 
        .data_n(hdmi_data_n[2])
    );
    
    serializer_10_to_1 ser_c (
        .clk_x1(pixel_clk), 
        .clk_x5(pixel_clk_5x), 
        .reset(reset), 
        .data_in(tmds_clk),   
        .data_p(hdmi_clk_p),     
        .data_n(hdmi_clk_n)
    );

endmodule

//////////////////////////////////////////////////////////////////////////////////
// 10:1 Serializer using OSERDESE2 Master/Slave cascade
// For Artix-7 / 7-Series FPGAs
//////////////////////////////////////////////////////////////////////////////////
module serializer_10_to_1 (
    input wire clk_x1,          // Parallel clock (CLKDIV)
    input wire clk_x5,          // Serial clock (CLK) - 5x for DDR
    input wire reset,
    input wire [9:0] data_in,
    output wire data_p,
    output wire data_n
);
    // Cascade wires from Slave to Master
    wire shift1;  // SHIFTOUT1 from slave -> SHIFTIN1 on master
    wire shift2;  // SHIFTOUT2 from slave -> SHIFTIN2 on master
    wire serial_out;

    // -------------------------------------------------------------------------
    // OSERDESE2 MASTER: Handles bits [0:3] and receives cascade from Slave
    // -------------------------------------------------------------------------
    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),       // DDR mode for 10:1
        .DATA_RATE_TQ("SDR"),       // Tristate data rate
        .DATA_WIDTH(10),            // 10-bit parallel width
        .SERDES_MODE("MASTER"),     // Master in cascade
        .TRISTATE_WIDTH(1)          // Tristate width
    ) serdes_master (
        // Outputs
        .OQ(serial_out),            // Serial data output
        .OFB(),                     // Feedback output (unused)
        .TQ(),                      // Tristate output (unused)
        .TFB(),                     // Tristate feedback (unused)
        .SHIFTOUT1(),               // Not used in master
        .SHIFTOUT2(),               // Not used in master
        // Inputs
        .CLK(clk_x5),               // High-speed clock
        .CLKDIV(clk_x1),            // Divided clock for parallel data
        .RST(reset),                // Reset
        .OCE(1'b1),                 // Output clock enable
        .TCE(1'b0),                 // Tristate clock enable
        // Parallel data inputs (bits 0-3 on Master)
        .D1(data_in[0]),
        .D2(data_in[1]),
        .D3(data_in[2]),
        .D4(data_in[3]),
        .D5(1'b0),                  // Unused in master for 10-bit
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),
        // Cascade inputs from Slave
        .SHIFTIN1(shift1),          // From slave SHIFTOUT1
        .SHIFTIN2(shift2),          // From slave SHIFTOUT2
        // Tristate inputs
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        // Other
        .TBYTEIN(1'b0),
        .TBYTEOUT()
    );

    // -------------------------------------------------------------------------
    // OSERDESE2 SLAVE: Handles bits [4:9] and cascades to Master
    // -------------------------------------------------------------------------
    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),       // DDR mode for 10:1
        .DATA_RATE_TQ("SDR"),       // Tristate data rate
        .DATA_WIDTH(10),            // 10-bit parallel width
        .SERDES_MODE("SLAVE"),      // Slave in cascade
        .TRISTATE_WIDTH(1)          // Tristate width
    ) serdes_slave (
        // Outputs
        .OQ(),                      // Not used in slave
        .OFB(),                     // Feedback output (unused)
        .TQ(),                      // Tristate output (unused)
        .TFB(),                     // Tristate feedback (unused)
        .SHIFTOUT1(shift1),         // Cascade to master SHIFTIN1
        .SHIFTOUT2(shift2),         // Cascade to master SHIFTIN2
        // Inputs
        .CLK(clk_x5),               // High-speed clock
        .CLKDIV(clk_x1),            // Divided clock for parallel data
        .RST(reset),                // Reset
        .OCE(1'b1),                 // Output clock enable
        .TCE(1'b0),                 // Tristate clock enable
        // Parallel data inputs
        // For 10-bit slave mode: D1, D2 are unused; D3-D8 carry bits 4-9
        .D1(1'b0),
        .D2(1'b0),
        .D3(data_in[4]),
        .D4(data_in[5]),
        .D5(data_in[6]),
        .D6(data_in[7]),
        .D7(data_in[8]),
        .D8(data_in[9]),
        // Cascade inputs (not used in slave)
        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0),
        // Tristate inputs
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        // Other
        .TBYTEIN(1'b0),
        .TBYTEOUT()
    );

    // -------------------------------------------------------------------------
    // Differential Output Buffer for TMDS
    // -------------------------------------------------------------------------
    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) obuf_inst (
        .I(serial_out),
        .O(data_p),
        .OB(data_n)
    );

endmodule