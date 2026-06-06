module top_mario (
    input wire clk_100mhz,
    input wire reset_n,
    input wire btn_left,
    input wire btn_right,
    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n,
    output wire hdmi_txen
);
    wire pclk, pclk_x5, locked;
    wire hsync, vsync, video_on;
    wire [9:0] pixel_x, pixel_y;

    wire sys_reset = (~reset_n) | (~locked);
    assign hdmi_txen = 1'b1;

    clk_wiz_0 clk_inst (
        .clk_in1(clk_100mhz),
        .clk_out1(pclk),
        .clk_out2(pclk_x5),
        .locked(locked)
    );

    vga_sync vga_inst (
        .clk(pclk),
        .reset(sys_reset),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .p_tick(),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    reg [7:0] scroll_offset = 8'd0;
    reg vsync_prev;
    reg [2:0] frame_counter;

    always @(posedge pclk) begin
        if (sys_reset) begin
            scroll_offset <= 8'd0;
            frame_counter <= 0;
            vsync_prev <= 0;
        end else begin
            vsync_prev <= vsync;
            if (vsync_prev && !vsync) begin
                frame_counter <= frame_counter + 1;
                if (frame_counter == 0) begin
                    if (btn_right && scroll_offset < 192)
                        scroll_offset <= scroll_offset + 1;
                    else if (btn_left && scroll_offset > 0)
                        scroll_offset <= scroll_offset - 1;
                end
            end
        end
    end

    wire [4:0] tile_x = pixel_x[9:5];
    wire [3:0] tile_y = pixel_y[8:5];
    wire [3:0] chunk_pixel_x = pixel_x[4:1];
    wire [3:0] chunk_pixel_y = pixel_y[4:1];

    wire [7:0] chunk_id;
    wire is_solid;

    ram_escenario map_inst (
        .clk(pclk),
        .screen_tile_x(tile_x),
        .screen_tile_y(tile_y),
        .scroll_offset(scroll_offset),
        .chunk_id(chunk_id),
        .is_solid(is_solid)
    );

    wire [3:0] pixel_color_index;

    rom_chunks_mario rom_sprites (
        .clk(pclk),
        .chunk_id(chunk_id),
        .pixel_x(chunk_pixel_x),
        .pixel_y(chunk_pixel_y),
        .pixel_data(pixel_color_index)
    );

    wire [23:0] rgb_24;

    paleta_rgb palette (
        .color_index(pixel_color_index),
        .rgb_24(rgb_24)
    );

    reg [1:0] hsync_delay;
    reg [1:0] vsync_delay;
    reg [1:0] video_on_delay;

    always @(posedge pclk) begin
        hsync_delay    <= {hsync_delay[0], hsync};
        vsync_delay    <= {vsync_delay[0], vsync};
        video_on_delay <= {video_on_delay[0], video_on};
    end

    rgb2dvi_0 hdmi_tx (
        .TMDS_Clk_p(tmds_clk_p),
        .TMDS_Clk_n(tmds_clk_n),
        .TMDS_Data_p(tmds_data_p),
        .TMDS_Data_n(tmds_data_n),
        .aRst(sys_reset),
        .vid_pData(video_on_delay[1] ? {rgb_24[23:16], rgb_24[7:0], rgb_24[15:8]} : 24'h000000),
        .vid_pVDE(video_on_delay[1]),
        .vid_pHSync(hsync_delay[1]),
        .vid_pVSync(vsync_delay[1]),
        .PixelClk(pclk),
        .SerialClk(pclk_x5)
    );
endmodule

