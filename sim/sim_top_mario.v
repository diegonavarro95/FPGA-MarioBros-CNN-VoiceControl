`timescale 1ns / 1ps

module sim_top_mario (
    input  wire        clk_25mhz,
    input  wire        reset,
    input  wire        btn_left,
    input  wire        btn_right,
    input  wire        btn_jump,
    input  wire        btn_run,
    output wire [23:0] rgb_24_out,
    output wire        hsync,
    output wire        vsync,
    output wire        video_on_out,
    output wire [9:0]  sim_x,
    output wire [9:0]  sim_y
);

    wire video_on;
    wire [9:0] pixel_x, pixel_y;

    video_generator_vga vga_inst(
        .clk_25MHz(clk_25mhz), .rst(reset), .hsync(hsync), .vsync(vsync),
        .video_on(video_on), .pixel_x(pixel_x), .pixel_y(pixel_y)
    );

    wire [12:0] mario_x;
    wire [8:0]  mario_y;
    wire [7:0]  mario_chunk;
    wire [7:0]  scroll_offset;
    wire on_ground, hit_ceiling, hit_left, hit_right;
    wire mario_dead, sfx_jump, is_super;

    wire [7:0] hit_ceil_id, col_chunk_id;
    wire [7:0] hit_ceil_x;
    wire [3:0] hit_ceil_y;
    wire       map_we;
    wire [7:0] map_write_x;
    wire [3:0] map_write_y;
    wire [7:0] map_write_id;
    wire       spawn_mushroom;
    
    wire [4:0] col_tile_x;
    wire [3:0] col_tile_y;
    wire       tile_solid_col;

    wire [12:0] mush_x;
    wire [8:0]  mush_y;
    wire        mush_active;
    wire [7:0]  mush_chunk;
    wire        mush_on_ground, mush_hit_L, mush_hit_R;
    wire [1:0]  mush_state;
    wire        mush_consumed;
    wire [4:0]  col2_tile_x;
    wire [3:0]  col2_tile_y;
    wire        tile2_solid_col;

    wire [7:0] bg_chunk_id;
    wire       bg_is_solid;
    
    wire [7:0] dummy_mush_ceil_id;
    wire [7:0] dummy_mush_ceil_x;
    wire [3:0] dummy_mush_ceil_y;
    wire       dummy_mush_hit_ceiling;

    mario_fsm fsm_inst(
        .clk(clk_25mhz), .reset(reset), .vsync(vsync),
        .btn_right(btn_right), .btn_left(btn_left), .btn_jump(btn_jump), .btn_run(btn_run),
        .on_ground(on_ground), .hit_ceiling(hit_ceiling), .hit_left(hit_left), .hit_right_col(hit_right),
        .hit_ceil_id(hit_ceil_id), .hit_ceil_x(hit_ceil_x), .hit_ceil_y(hit_ceil_y), 
        .is_super(is_super),
        .map_we(map_we), .map_write_x(map_write_x), .map_write_y(map_write_y), .map_write_id(map_write_id),
        .spawn_mushroom(spawn_mushroom),
        .mush_active(mush_active), .mush_x(mush_x), .mush_y(mush_y), .mush_state(mush_state), .mush_consumed(mush_consumed),
        .mario_x(mario_x), .mario_y(mario_y), .mario_chunk(mario_chunk), .scroll_offset(scroll_offset),
        .mario_dead(mario_dead), .sfx_jump(sfx_jump)
    );

    mushroom_fsm mush_inst(
        .clk(clk_25mhz), .reset(reset), .vsync(vsync),
        .spawn_trigger(spawn_mushroom), .spawn_tile_x(map_write_x), .spawn_tile_y(map_write_y),
        .on_ground(mush_on_ground), .hit_left(mush_hit_L), .hit_right(mush_hit_R),
        .consumed(mush_consumed), .mush_state_out(mush_state),
        .mush_x(mush_x), .mush_y(mush_y), .mush_active(mush_active), .mush_chunk(mush_chunk)
    );

    motor_colisiones mush_cols(
        .clk(clk_25mhz), .mario_x(mush_x), .mario_y(mush_y), .scroll_offset(scroll_offset),
        .col_tile_x(col2_tile_x), .col_tile_y(col2_tile_y), 
        .tile_solid(tile2_solid_col), .tile_chunk_id(8'd0),
        .hit_ceil_id(dummy_mush_ceil_id), .hit_ceil_x(dummy_mush_ceil_x), .hit_ceil_y(dummy_mush_ceil_y),
        .is_super(1'b0),
        .on_ground(mush_on_ground), .hit_ceiling(dummy_mush_hit_ceiling), .hit_left(mush_hit_L), .hit_right(mush_hit_R)
    );

    ram_escenario map_inst(
        .clk(clk_25mhz), 
        .screen_tile_x(pixel_x[9:5]), .screen_tile_y(pixel_y[8:5]), .scroll_offset(scroll_offset), 
        .chunk_id(bg_chunk_id), .is_solid(bg_is_solid), 
        .col_tile_x(col_tile_x), .col_tile_y(col_tile_y), .col_is_solid(tile_solid_col), .col_chunk_id(col_chunk_id),
        .col2_tile_x(col2_tile_x), .col2_tile_y(col2_tile_y), .col2_is_solid(tile2_solid_col),
        .write_en(map_we), .write_abs_x(map_write_x), .write_y(map_write_y), .write_id(map_write_id)
    );

    motor_colisiones cols_inst(
        .clk(clk_25mhz), .mario_x(mario_x), .mario_y(mario_y), .scroll_offset(scroll_offset),
        .col_tile_x(col_tile_x), .col_tile_y(col_tile_y), 
        .tile_solid(tile_solid_col), .tile_chunk_id(col_chunk_id),
        .hit_ceil_id(hit_ceil_id), .hit_ceil_x(hit_ceil_x), .hit_ceil_y(hit_ceil_y),
        .is_super(is_super),
        .on_ground(on_ground), .hit_ceiling(hit_ceiling), .hit_left(hit_left), .hit_right(hit_right)
    );
    
    reg [1:0] video_on_delay;
    reg [9:0] x_d1, x_d2, y_d1, y_d2;
    reg [4:0] bg_px, bg_py, m_px, m_py, mu_px, mu_py;
    reg       is_m1, is_m2, is_mu1, is_mu2;

    wire [12:0] p_abs = {scroll_offset, 5'b0} + pixel_x;
    wire [6:0]  m_h = is_super ? 7'd64 : 7'd32;
    
    wire is_m0 = (p_abs >= mario_x && p_abs < mario_x + 32 && pixel_y >= mario_y && pixel_y < mario_y + m_h);
    wire is_mu0 = mush_active && (p_abs >= mush_x && p_abs < mush_x + 32 && pixel_y >= mush_y && pixel_y < mush_y + 32);

    always @(posedge clk_25mhz) begin
        video_on_delay <= {video_on_delay[0], video_on};
        x_d1 <= pixel_x; x_d2 <= x_d1;
        y_d1 <= pixel_y; y_d2 <= y_d1;
        bg_px <= pixel_x[4:0]; bg_py <= pixel_y[4:0];
        
        // Al aplicar modulo [4:0], Mario se repite naturalmente si el hitbox (m_h) se estira a 64
        m_px <= p_abs[4:0] - mario_x[4:0]; 
        m_py <= pixel_y[4:0] - mario_y[4:0]; 
        
        mu_px <= p_abs[4:0] - mush_x[4:0]; 
        mu_py <= pixel_y[4:0] - mush_y[4:0];
        
        is_m1 <= is_m0; is_m2 <= is_m1;
        is_mu1 <= is_mu0; is_mu2 <= is_mu1;
    end

    wire [3:0] bg_c, m_c, mu_c;

    rom_chunks_mario rbg(.clk(clk_25mhz), .chunk_id(bg_chunk_id), .pixel_x(bg_px), .pixel_y(bg_py), .pixel_data(bg_c));
    rom_chunks_mario rm (.clk(clk_25mhz), .chunk_id(mario_chunk), .pixel_x(m_px),  .pixel_y(m_py),  .pixel_data(m_c));
    rom_chunks_mario rmu(.clk(clk_25mhz), .chunk_id(mush_chunk),  .pixel_x(mu_px), .pixel_y(mu_py), .pixel_data(mu_c));

    wire [3:0] final_idx = (is_mu2 && mu_c != 0) ? mu_c : (is_m2 && m_c != 0) ? m_c : bg_c;
    
    paleta_rgb palette(.color_index(final_idx), .rgb_24(rgb_24_out));

    assign video_on_out = video_on_delay[1];
    assign sim_x = x_d2;
    assign sim_y = y_d2;

endmodule

