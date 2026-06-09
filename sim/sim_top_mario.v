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

    // 1. GENERADOR VGA
    video_generator_vga vga_inst(
        .clk_25MHz(clk_25mhz), .rst(reset), .hsync(hsync), .vsync(vsync),
        .video_on(video_on), .pixel_x(pixel_x), .pixel_y(pixel_y)
    );

    // 2. CABLES DE COMUNICACIÓN (MARIO)
    wire [12:0] mario_x;
    wire [8:0]  mario_y;
    wire [7:0]  mario_chunk;
    wire [7:0]  scroll_offset;
    wire on_ground, hit_ceiling, hit_left, hit_right;
    wire mario_dead;
    wire sfx_jump;

    // Cables para Radar de Techo y Escritura RAM
    wire [7:0] hit_ceil_id;
    wire [7:0] hit_ceil_x;
    wire [3:0] hit_ceil_y;
    wire [7:0] col_chunk_id;
    
    wire       map_we;
    wire [7:0] map_write_x;
    wire [3:0] map_write_y;
    wire [7:0] map_write_id;
    wire       spawn_mushroom;
    wire       is_super = 1'b0; // Temporal hasta programar el Power-Up de Mario Grande

    // 3. MÁQUINA DE ESTADOS DE MARIO
    mario_fsm fsm_inst(
        .clk(clk_25mhz), .reset(reset), .vsync(vsync),
        .btn_right(btn_right), .btn_left(btn_left), .btn_jump(btn_jump), .btn_run(btn_run),
        .on_ground(on_ground), .hit_ceiling(hit_ceiling), .hit_left(hit_left), .hit_right_col(hit_right),
        .hit_ceil_id(hit_ceil_id), .hit_ceil_x(hit_ceil_x), .hit_ceil_y(hit_ceil_y), .is_super(is_super),
        .map_we(map_we), .map_write_x(map_write_x), .map_write_y(map_write_y), .map_write_id(map_write_id),
        .spawn_mushroom(spawn_mushroom),
        .mario_x(mario_x), .mario_y(mario_y), .mario_chunk(mario_chunk), .scroll_offset(scroll_offset),
        .mario_dead(mario_dead), .sfx_jump(sfx_jump)
    );

    // [CABLES DEL CHAMPIÑÓN]
    wire [12:0] mush_x;
    wire [8:0]  mush_y;
    wire        mush_active;
    wire [7:0]  mush_chunk;
    wire        mush_on_ground, mush_hit_L, mush_hit_R;
    
    wire [4:0]  col2_tile_x;
    wire [3:0]  col2_tile_y;
    wire        tile2_solid_col;

    // Cables fantasma (Dummy) para conectar las salidas que no usa el champiñón
    wire [7:0]  dummy_mush_chunk_id;
    wire [7:0]  dummy_mush_ceil_id;
    wire [7:0]  dummy_mush_ceil_x;
    wire [3:0]  dummy_mush_ceil_y;
    wire        dummy_mush_hit_ceiling;

    // FSM del Champiñón
    mushroom_fsm mush_inst(
        .clk(clk_25mhz), .reset(reset), .vsync(vsync),
        .spawn_trigger(spawn_mushroom), .spawn_tile_x(map_write_x), .spawn_tile_y(map_write_y),
        .on_ground(mush_on_ground), .hit_left(mush_hit_L), .hit_right(mush_hit_R),
        .mush_x(mush_x), .mush_y(mush_y), .mush_active(mush_active), .mush_chunk(mush_chunk)
    );

    // Motor de Colisiones del Champiñón
    motor_colisiones mush_cols(
        .clk(clk_25mhz), .mario_x(mush_x), .mario_y(mush_y), .scroll_offset(scroll_offset),
        .col_tile_x(col2_tile_x), .col_tile_y(col2_tile_y), 
        .tile_solid(tile2_solid_col), .tile_chunk_id(8'd0), // <--- FIJADO A CERO
        .hit_ceil_id(dummy_mush_ceil_id), .hit_ceil_x(dummy_mush_ceil_x), .hit_ceil_y(dummy_mush_ceil_y),
        .on_ground(mush_on_ground), .hit_ceiling(dummy_mush_hit_ceiling), .hit_left(mush_hit_L), .hit_right(mush_hit_R)
    );

    // 5. MEMORIA RAM INTERACTIVA (3 PUERTOS)
    wire [7:0] bg_chunk_id;
    wire tile_solid_col;
    wire bg_is_solid; 
    wire [4:0] col_tile_x;
    wire [3:0] col_tile_y;

    ram_escenario map_inst(
        .clk(clk_25mhz), 
        // Puerto A (Cámara)
        .screen_tile_x(pixel_x[9:5]), 
        .screen_tile_y(pixel_y[8:5]),
        .scroll_offset(scroll_offset), 
        .chunk_id(bg_chunk_id), 
        .is_solid(bg_is_solid), 
        
        // Puerto B (Colisiones de Mario)
        .col_tile_x(col_tile_x),
        .col_tile_y(col_tile_y),
        .col_is_solid(tile_solid_col),
        .col_chunk_id(col_chunk_id),
        
        // Puerto C (Colisiones del Champiñón)
        .col2_tile_x(col2_tile_x),
        .col2_tile_y(col2_tile_y),
        .col2_is_solid(tile2_solid_col),
        
        // Puerto Escritura (Mario alterando el mapa)
        .write_en(map_we),
        .write_abs_x(map_write_x),
        .write_y(map_write_y),
        .write_id(map_write_id)
    );

    // 6. MOTOR DE COLISIONES DE MARIO
    motor_colisiones cols_inst(
        .clk(clk_25mhz), .mario_x(mario_x), .mario_y(mario_y), .scroll_offset(scroll_offset),
        .col_tile_x(col_tile_x), .col_tile_y(col_tile_y), 
        .tile_solid(tile_solid_col), .tile_chunk_id(col_chunk_id),
        .hit_ceil_id(hit_ceil_id), .hit_ceil_x(hit_ceil_x), .hit_ceil_y(hit_ceil_y),
        .on_ground(on_ground), .hit_ceiling(hit_ceiling), .hit_left(hit_left), .hit_right(hit_right)
    );
    
    // =====================================================================
    // 7. PIPELINE DE SINCRONIZACIÓN PERFECTA
    // =====================================================================
    reg [1:0] video_on_delay;
    reg [9:0] x_delay_1, x_delay_2;
    reg [9:0] y_delay_1, y_delay_2;

    reg [4:0] bg_px_c1, bg_py_c1;
    reg [4:0] mario_px_c1, mario_py_c1;
    reg [4:0] mush_px_c1, mush_py_c1;
    
    reg       is_mario_c1, is_mario_c2;
    reg       is_mush_c1, is_mush_c2;

    wire [12:0] pixel_abs_x_c0 = {scroll_offset, 5'b0} + pixel_x;
    
    // Detectores de colisión visual (Saber si el barrido VGA pasa por un sprite)
    wire is_mario_c0 = (pixel_abs_x_c0 >= mario_x && pixel_abs_x_c0 < mario_x + 32 && pixel_y >= mario_y && pixel_y < mario_y + 32);
    wire is_mush_c0  = mush_active && (pixel_abs_x_c0 >= mush_x && pixel_abs_x_c0 < mush_x + 32 && pixel_y >= mush_y && pixel_y < mush_y + 32);

    always @(posedge clk_25mhz) begin
        video_on_delay <= {video_on_delay[0], video_on};
        x_delay_1 <= pixel_x; x_delay_2 <= x_delay_1;
        y_delay_1 <= pixel_y; y_delay_2 <= y_delay_1;

        bg_px_c1 <= pixel_x[4:0];
        bg_py_c1 <= pixel_y[4:0];
        
        mario_px_c1 <= pixel_abs_x_c0[4:0] - mario_x[4:0];
        mario_py_c1 <= pixel_y[4:0] - mario_y[4:0];
        
        mush_px_c1  <= pixel_abs_x_c0[4:0] - mush_x[4:0];
        mush_py_c1  <= pixel_y[4:0] - mush_y[4:0];
        
        is_mario_c1 <= is_mario_c0;
        is_mario_c2 <= is_mario_c1;
        
        is_mush_c1  <= is_mush_c0;
        is_mush_c2  <= is_mush_c1;
    end

    // 8. MEMORIAS ROM (Ahora alimentadas por cables sincronizados C1)
    wire [3:0] bg_color_idx, mario_color_idx, mush_color_idx;
    
    rom_chunks_mario rom_bg(
        .clk(clk_25mhz), .chunk_id(bg_chunk_id), 
        .pixel_x(bg_px_c1), .pixel_y(bg_py_c1), .pixel_data(bg_color_idx)
    );

    rom_chunks_mario rom_mario(
        .clk(clk_25mhz), .chunk_id(mario_chunk),
        .pixel_x(mario_px_c1), .pixel_y(mario_py_c1), 
        .pixel_data(mario_color_idx)
    );
    
    rom_chunks_mario rom_mush(
        .clk(clk_25mhz), .chunk_id(mush_chunk),
        .pixel_x(mush_px_c1), .pixel_y(mush_py_c1), 
        .pixel_data(mush_color_idx)
    );

    // 9. MULTIPLEXOR MAESTRO Y PALETA
    // Prioridad de dibujado (Z-Index): Champiñón > Mario > Fondo
    wire [3:0] final_color_idx = (is_mush_c2 && mush_color_idx != 4'h0) ? mush_color_idx :
                                 (is_mario_c2 && mario_color_idx != 4'h0) ? mario_color_idx : 
                                 bg_color_idx;

    wire [23:0] raw_rgb_24;
    paleta_rgb palette(
        .color_index(final_color_idx), .rgb_24(raw_rgb_24)
    );

    assign rgb_24_out   = (video_on_delay[1]) ? raw_rgb_24 : 24'h000000;
    assign video_on_out = video_on_delay[1];
    assign sim_x        = x_delay_2;
    assign sim_y        = y_delay_2;

endmodule

