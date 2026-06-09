`timescale 1ns / 1ps

module motor_colisiones (
    input  wire        clk,
    input  wire [12:0] mario_x,
    input  wire [8:0]  mario_y,
    input  wire [7:0]  scroll_offset,
    output reg  [4:0]  col_tile_x,
    output reg  [3:0]  col_tile_y,
    input  wire        tile_solid,
    output reg         on_ground,
    output reg         hit_ceiling,
    output reg         hit_left,
    output reg         hit_right,
    input  wire [7:0]  tile_chunk_id,
    output reg  [7:0]  hit_ceil_id,
    output reg  [7:0]  hit_ceil_x,
    output reg  [3:0]  hit_ceil_y,
    input  wire        is_super
);
    // BORDES EXTERNOS GENERALES
    wire [12:0] left_edge   = mario_x + 13'd6;
    wire [12:0] right_edge  = mario_x + 13'd25;
    wire [8:0]  top_edge    = mario_y + 9'd2;
    // El sensor inferior cambia según el estado de Mario
    wire [8:0]  bottom_edge = (is_super) ? (mario_y + 9'd63) : (mario_y + 9'd31);

    // BORDES INTERNOS (El Secreto anti-atascos)
    wire [12:0] inner_left  = mario_x + 13'd10; 
    wire [12:0] inner_right = mario_x + 13'd21;
    // Sensores laterales
    wire [8:0]  inner_top   = mario_y + 9'd10;
    wire [8:0]  inner_bot   = (is_super) ? (mario_y + 9'd56) : (mario_y + 9'd24);

    wire [4:0] rel_inner_L = (inner_left[12:5])  - scroll_offset[4:0];
    wire [4:0] rel_inner_R = (inner_right[12:5]) - scroll_offset[4:0];
    wire [4:0] rel_outer_L = ((left_edge - 1) >> 5)  - scroll_offset[4:0];
    wire [4:0] rel_outer_R = ((right_edge + 1) >> 5) - scroll_offset[4:0];

    wire [3:0] row_above = (top_edge - 1) >> 5;
    wire [3:0] row_below = (bottom_edge + 1) >> 5;
    wire [3:0] row_in_T  = inner_top[8:5];
    wire [3:0] row_in_B  = inner_bot[8:5];

    reg [2:0] phase = 0;
    reg ground_tmp, ceil_tmp, left_tmp, right_tmp;

    always @(posedge clk) begin
        phase <= phase + 1;

        case (phase)
            3'd0: begin col_tile_x <= rel_inner_L; col_tile_y <= row_below; end 
            3'd1: begin col_tile_x <= rel_inner_R; col_tile_y <= row_below; end 
            3'd2: begin col_tile_x <= rel_inner_L; col_tile_y <= row_above; end 
            3'd3: begin col_tile_x <= rel_inner_R; col_tile_y <= row_above; end 
            3'd4: begin col_tile_x <= rel_outer_L; col_tile_y <= row_in_T;  end 
            3'd5: begin col_tile_x <= rel_outer_L; col_tile_y <= row_in_B;  end 
            3'd6: begin col_tile_x <= rel_outer_R; col_tile_y <= row_in_T;  end 
            3'd7: begin col_tile_x <= rel_outer_R; col_tile_y <= row_in_B;  end 
        endcase

        case (phase)
            3'd2: ground_tmp <= tile_solid;
            3'd3: ground_tmp <= ground_tmp | tile_solid;
            3'd4: begin 
                ceil_tmp <= tile_solid;
                if (tile_solid) begin
                    hit_ceil_id <= tile_chunk_id;
                    hit_ceil_x  <= rel_inner_L + scroll_offset[4:0];
                    hit_ceil_y  <= row_above;
                end
            end
            3'd5: begin 
                ceil_tmp <= ceil_tmp | tile_solid;
                if (tile_solid && !ceil_tmp) begin
                    hit_ceil_id <= tile_chunk_id;
                    hit_ceil_x  <= rel_inner_R + scroll_offset[4:0];
                    hit_ceil_y  <= row_above;
                end
            end
            3'd6: left_tmp   <= tile_solid;
            3'd7: left_tmp   <= left_tmp | tile_solid;
            3'd0: right_tmp  <= tile_solid;
            3'd1: begin 
                right_tmp   <= right_tmp | tile_solid; 
                on_ground   <= ground_tmp;
                hit_ceiling <= ceil_tmp;
                hit_left    <= left_tmp;
                hit_right   <= right_tmp | tile_solid;
            end
        endcase
    end
endmodule

