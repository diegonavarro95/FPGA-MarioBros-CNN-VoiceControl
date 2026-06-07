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

    // 2. SEÑALES DE FÍSICA Y FSM
    wire [12:0] mario_x;
    wire [8:0]  mario_y;
    wire [7:0]  mario_chunk;
    wire [7:0]  scroll_offset;
    wire on_ground, hit_ceiling, hit_left, hit_right;

    wire mario_dead;
    wire sfx_jump;

    mario_fsm fsm_inst(
        .clk(clk_25mhz), .reset(reset), .vsync(vsync),
        .btn_right(btn_right), .btn_left(btn_left), .btn_jump(btn_jump), .btn_run(btn_run),
        .on_ground(on_ground), .hit_ceiling(hit_ceiling), .hit_left(hit_left), .hit_right_col(hit_right),
        .mario_x(mario_x), .mario_y(mario_y), .mario_chunk(mario_chunk), .scroll_offset(scroll_offset),
        .mario_dead(mario_dead), .sfx_jump(sfx_jump)
    );

    // 3. MEMORIA RAM DE DOBLE PUERTO
    wire [7:0] bg_chunk_id;
    wire tile_solid_col;
    wire bg_is_solid; // Cable dummy para evitar el warning PINCONNECTEMPTY

    wire [4:0] col_tile_x;
    wire [3:0] col_tile_y;

    ram_escenario map_inst(
        .clk(clk_25mhz), 
        
        // Puerto A (Cámara)
        .screen_tile_x(pixel_x[9:5]), 
        .screen_tile_y(pixel_y[8:5]),
        .scroll_offset(scroll_offset), 
        .chunk_id(bg_chunk_id), 
        .is_solid(bg_is_solid), // Conectado al cable dummy

        // Puerto B (Colisiones de Mario)
        .col_tile_x(col_tile_x),
        .col_tile_y(col_tile_y),
        .col_is_solid(tile_solid_col)
    );

    // 4. MOTOR DE COLISIONES
    motor_colisiones cols_inst(
        .clk(clk_25mhz), .mario_x(mario_x), .mario_y(mario_y), .scroll_offset(scroll_offset),
        .col_tile_x(col_tile_x), .col_tile_y(col_tile_y), 
        .tile_solid(tile_solid_col),
        .on_ground(on_ground), .hit_ceiling(hit_ceiling), .hit_left(hit_left), .hit_right(hit_right)
    );
    
    // 5. DOBLE ROM (Una para el fondo, una para Mario)
    wire [3:0] bg_color_idx, mario_color_idx;
    
    // ROM FONDO
    rom_chunks_mario rom_bg(
        .clk(clk_25mhz), .chunk_id(bg_chunk_id), 
        .pixel_x(pixel_x[4:0]), .pixel_y(pixel_y[4:0]), .pixel_data(bg_color_idx)
    );

    // ROM MARIO
    wire [12:0] pixel_abs_x = {scroll_offset, 5'b0} + pixel_x;
    wire is_mario_box = (pixel_abs_x >= mario_x && pixel_abs_x < mario_x + 32 && pixel_y >= mario_y && pixel_y < mario_y + 32);
    
    rom_chunks_mario rom_mario(
        .clk(clk_25mhz), .chunk_id(mario_chunk),
        .pixel_x(pixel_abs_x[4:0] - mario_x[4:0]), .pixel_y(pixel_y[4:0] - mario_y[4:0]), 
        .pixel_data(mario_color_idx)
    );

    // 6. PIPELINE DE SINCRONIZACIÓN Y MULTIPLEXOR
    reg [1:0] video_on_delay;
    reg [9:0] x_delay_1, x_delay_2;
    reg [9:0] y_delay_1, y_delay_2;
    reg       is_mario_delay_1, is_mario_delay_2;

    always @(posedge clk_25mhz) begin
        video_on_delay <= {video_on_delay[0], video_on};
        x_delay_1 <= pixel_x; x_delay_2 <= x_delay_1;
        y_delay_1 <= pixel_y; y_delay_2 <= y_delay_1;
        is_mario_delay_1 <= is_mario_box; is_mario_delay_2 <= is_mario_delay_1;
    end

    // Si estamos en la caja de Mario y su ROM no escupe "0" (transparente), dibujamos a Mario. Si no, Fondo.
    wire [3:0] final_color_idx = (is_mario_delay_1 && mario_color_idx != 4'h0) ? mario_color_idx : bg_color_idx;

    // 7. PALETA DE COLORES
    wire [23:0] raw_rgb_24;
    paleta_rgb palette(
        .color_index(final_color_idx), .rgb_24(raw_rgb_24)
    );

    assign rgb_24_out   = (video_on_delay[1]) ? raw_rgb_24 : 24'h000000;
    assign video_on_out = video_on_delay[1];
    assign sim_x        = x_delay_2;
    assign sim_y        = y_delay_2;

endmodule

