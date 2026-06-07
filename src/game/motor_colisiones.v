`timescale 1ns / 1ps
// =============================================================================
// MOTOR_COLISIONES.V
// Detecta colisiones de Mario usando una Hitbox ajustada (más delgada que 32x32)
// para permitir caídas fluidas por los fosos.
// =============================================================================

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
    output reg         hit_right
);
    // Hitbox interna (Mario no ocupa los 32 píxeles completos)
    wire [12:0] left_edge   = mario_x + 13'd6;
    wire [12:0] right_edge  = mario_x + 13'd25;
    wire [8:0]  top_edge    = mario_y + 9'd2;
    wire [8:0]  bottom_edge = mario_y + 9'd31;

    wire [7:0]  tile_abs_left   = left_edge[12:5];
    wire [7:0]  tile_abs_right  = right_edge[12:5];
    wire [3:0]  tile_row_top    = top_edge[8:5];
    wire [3:0]  tile_row_bottom = bottom_edge[8:5];

    wire [4:0] rel_x_left  = tile_abs_left[4:0]  - scroll_offset[4:0];
    wire [4:0] rel_x_right = tile_abs_right[4:0] - scroll_offset[4:0];

    reg [2:0] phase = 0;
    reg ground_tmp, ceiling_tmp, left_tmp, right_tmp;

    always @(posedge clk) begin
        case (phase)
            // --- SUELO ---
            3'd0: begin
                col_tile_x <= rel_x_left;
                col_tile_y <= (bottom_edge + 1) >> 5;
                ground_tmp <= 1'b0;
                phase <= 3'd1;
            end
            3'd1: begin
                ground_tmp <= tile_solid;
                col_tile_x <= rel_x_right;
                col_tile_y <= (bottom_edge + 1) >> 5;
                phase <= 3'd2;
            end
            // --- TECHO ---
            3'd2: begin
                ground_tmp <= ground_tmp | tile_solid;
                col_tile_x <= rel_x_left;
                col_tile_y <= (top_edge - 1) >> 5;
                ceiling_tmp <= 1'b0;
                phase <= 3'd3;
            end
            3'd3: begin
                ceiling_tmp <= tile_solid;
                col_tile_x <= rel_x_right;
                col_tile_y <= (top_edge - 1) >> 5;
                phase <= 3'd4;
            end
            // --- IZQUIERDA ---
            3'd4: begin
                ceiling_tmp <= ceiling_tmp | tile_solid;
                col_tile_x <= ((left_edge - 1) >> 5) - scroll_offset[4:0];
                col_tile_y <= tile_row_top;
                left_tmp <= 1'b0;
                phase <= 3'd5;
            end
            3'd5: begin
                left_tmp <= tile_solid;
                col_tile_x <= ((left_edge - 1) >> 5) - scroll_offset[4:0];
                col_tile_y <= tile_row_bottom;
                phase <= 3'd6;
            end
            // --- DERECHA ---
            3'd6: begin
                left_tmp <= left_tmp | tile_solid;
                col_tile_x <= ((right_edge + 1) >> 5) - scroll_offset[4:0];
                col_tile_y <= tile_row_top;
                right_tmp <= 1'b0;
                phase <= 3'd7;
            end
            3'd7: begin
                right_tmp <= tile_solid;
                col_tile_x <= ((right_edge + 1) >> 5) - scroll_offset[4:0];
                col_tile_y <= tile_row_bottom;
                phase <= 3'd0;
            end
        endcase

        // Actualización síncrona
        if (phase == 3'd7) begin
            on_ground   <= ground_tmp;
            hit_ceiling <= ceiling_tmp;
            hit_left    <= left_tmp;
            hit_right   <= right_tmp | tile_solid;
        end
    end
endmodule

