`timescale 1ns / 1ps

module mario_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire        vsync,
    input  wire        btn_right,
    input  wire        btn_left,
    input  wire        btn_jump,
    input  wire        btn_run,
    input  wire        on_ground,
    input  wire        hit_ceiling,
    input  wire        hit_left,
    input  wire        hit_right_col,
    
    // Nuevos puertos del radar de techo y escritura de RAM
    input  wire [7:0]  hit_ceil_id,
    input  wire [7:0]  hit_ceil_x,
    input  wire [3:0]  hit_ceil_y,
    input  wire        is_super,
    output reg         map_we,
    output reg  [7:0]  map_write_x,
    output reg  [3:0]  map_write_y,
    output reg  [7:0]  map_write_id,
    output reg         spawn_mushroom,
    
    output reg  [12:0] mario_x,
    output reg  [8:0]  mario_y,
    output reg  [7:0]  mario_chunk,
    output reg  [7:0]  scroll_offset,
    output reg         mario_dead,
    output reg         sfx_jump
);

    localparam S_IDLE = 3'd0, S_WALK = 3'd1, S_RUN = 3'd2, S_JUMP = 3'd3, S_FALL = 3'd4, S_DEAD = 3'd5, S_WIN = 3'd6;
    reg [2:0] state;

    reg signed [5:0] vel_y; 
    reg signed [5:0] vel_x; 
    reg signed [5:0] jump_max_speed;
    
    reg [7:0] delay_timer; 
    
    wire signed [13:0] calc_y = $signed({1'b0, mario_y}) + $signed(vel_y); 
    wire signed [14:0] calc_x = $signed({2'b0, mario_x}) + $signed(vel_x);
    
    reg [3:0] anim_cnt;
    reg [1:0] walk_frame;
    reg vsync_prev;
    wire frame_tick = vsync_prev & ~vsync;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= S_IDLE;
            mario_x        <= 13'd64; 
            mario_y        <= 9'd384; 
            vel_y          <= 6'sd0;
            vel_x          <= 6'sd0;
            jump_max_speed <= 6'sd3;
            scroll_offset  <= 8'd0;
            mario_chunk    <= 8'd128; 
            mario_dead     <= 1'b0;
            sfx_jump       <= 1'b0;
            delay_timer    <= 8'd0;
            map_we         <= 1'b0;
            spawn_mushroom <= 1'b0;
        end else begin
            vsync_prev <= vsync;
            sfx_jump   <= 1'b0;

            if (frame_tick) begin
            
                // Resetear pulsos de interacción por defecto
                map_we <= 1'b0;
                spawn_mushroom <= 1'b0;

                // =========================================================
                // TRIGGERS GLOBALES (Bloquean el resto de la lógica si se activan)
                // =========================================================
                if (mario_y >= 9'd460 && state != S_DEAD) begin
                    state       <= S_DEAD;
                    delay_timer <= 8'd0;
                    mario_dead  <= 1'b1;
                    vel_x       <= 6'sd0;
                    vel_y       <= 6'sd0; 
                end 
                else if (mario_x >= 13'd6336 && state != S_WIN && state != S_DEAD) begin
                    state       <= S_WIN;
                    delay_timer <= 8'd0;
                    vel_x       <= 6'sd0;
                    mario_x     <= 13'd6336;
                end 
                else begin
                    // =========================================================
                    // FÍSICAS E INERCIA NORMAL
                    // =========================================================
                    if (state != S_DEAD && state != S_WIN) begin
                        if (on_ground) begin
                            jump_max_speed <= btn_run ? 6'sd8 : 6'sd6; 
                        end

                        if (btn_right && !hit_right_col) begin
                            if (vel_x < jump_max_speed) vel_x <= vel_x + 6'sd1;
                        end else if (btn_left && !hit_left) begin
                            if (vel_x > -jump_max_speed) vel_x <= vel_x - 6'sd1;
                        end else begin
                            if (on_ground) begin
                                if (vel_x > 0) vel_x <= vel_x - 6'sd1;
                                else if (vel_x < 0) vel_x <= vel_x + 6'sd1;
                            end
                        end

                        if ((vel_x > 0 && hit_right_col) || (vel_x < 0 && hit_left)) begin
                            vel_x <= 6'sd0;
                        end else begin
                            if (calc_x < $signed({2'b0, scroll_offset, 5'b0})) begin
                                mario_x <= {scroll_offset, 5'b0};
                                vel_x <= 6'sd0;
                            end else begin
                                mario_x <= calc_x[12:0]; 
                            end
                        end
                    end

                    // =========================================================
                    // MÁQUINA DE ESTADOS
                    // =========================================================
                    case (state)
                        S_IDLE, S_WALK, S_RUN: begin
                            vel_y <= 6'sd0;
                            if (!on_ground) begin
                                state <= S_FALL;
                            end else if (btn_jump) begin
                                vel_y <= -6'sd16; 
                                state <= S_JUMP;
                                sfx_jump <= 1'b1;
                            end else if (vel_x != 0) begin
                                state <= (vel_x > 3 || vel_x < -3) ? S_RUN : S_WALK;
                            end else begin
                                state <= S_IDLE;
                                mario_chunk <= 8'd128; 
                            end

                            if (state == S_WALK || state == S_RUN) begin
                                anim_cnt <= anim_cnt + ((state == S_RUN) ? 4'd2 : 4'd1);
                                if (anim_cnt >= 4'd7) begin
                                    anim_cnt <= 0;
                                    walk_frame <= walk_frame + 1;
                                end
                                case (walk_frame)
                                    2'd0: mario_chunk <= 8'd128;
                                    2'd1: mario_chunk <= 8'd129;
                                    2'd2: mario_chunk <= 8'd128;
                                    2'd3: mario_chunk <= 8'd130;
                                endcase
                            end
                        end

                        S_JUMP, S_FALL: begin
                            mario_chunk <= 8'd131; 
                            
                            if (vel_y < 6'sd10) vel_y <= vel_y + 6'sd1; 
                            if (calc_y < 0) mario_y <= 0; 
                            else mario_y <= calc_y[8:0];

                            if (vel_y >= 0) state <= S_FALL;

                            if (on_ground && vel_y >= 0) begin
                                mario_y <= (mario_y[8:5]) * 32; 
                                state <= S_IDLE;
                            end
                            
                            // Lógica de colisión con el techo
                            if (hit_ceiling && vel_y < 0) begin
                                vel_y <= 6'sd0; // Corta el salto instantáneamente
                                
                                if (hit_ceil_id == 8'h02) begin // Golpeó Caja Pregunta
                                    map_we <= 1'b1;
                                    map_write_x <= hit_ceil_x;
                                    map_write_y <= hit_ceil_y;
                                    map_write_id <= 8'h0E; // UB (Bloque Usado)
                                    
                                    if (hit_ceil_x == 8'd21) spawn_mushroom <= 1'b1;
                                end 
                                else if (hit_ceil_id == 8'h01 && is_super) begin // Golpeó Ladrillo siendo Grande
                                    map_we <= 1'b1;
                                    map_write_x <= hit_ceil_x;
                                    map_write_y <= hit_ceil_y;
                                    map_write_id <= 8'h00; // E (Aire)
                                end
                            end
                        end

                        S_DEAD: begin
                            mario_chunk <= 8'd128; 
                            vel_x <= 6'sd0;
                            vel_y <= 6'sd0;
                            
                            if (delay_timer < 8'd180) delay_timer <= delay_timer + 8'd1;
                            else begin
                                state         <= S_IDLE;
                                mario_x       <= 13'd64; 
                                mario_y       <= 9'd384; 
                                scroll_offset <= 8'd0;
                                mario_dead    <= 1'b0;
                            end
                        end

                        S_WIN: begin
                            mario_chunk <= 8'd128; 
                            
                            if (!on_ground) begin
                                mario_y <= mario_y + 9'd2; 
                            end 
                            else begin
                                mario_y <= (mario_y[8:5]) * 32; 
                                if (delay_timer < 8'd180) delay_timer <= delay_timer + 8'd1;
                                else begin
                                    state         <= S_IDLE;
                                    mario_x       <= 13'd64; 
                                    mario_y       <= 9'd384; 
                                    scroll_offset <= 8'd0;
                                end
                            end
                        end

                        default: state <= S_IDLE;
                    endcase
                end // Fin del if-else maestro

                // 3. CÁMARA
                if (state != S_DEAD && state != S_WIN) begin
                    if (mario_x > {scroll_offset, 5'b0} + 13'd320) begin
                        if (scroll_offset < 8'd192) scroll_offset <= scroll_offset + 1;
                    end
                end

            end
        end
    end
endmodule

