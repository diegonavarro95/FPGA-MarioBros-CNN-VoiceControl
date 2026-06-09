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
    
    // Radar de techo y escritura de RAM
    input  wire [7:0]  hit_ceil_id,
    input  wire [7:0]  hit_ceil_x,
    input  wire [3:0]  hit_ceil_y,
    output reg         map_we,
    output reg  [7:0]  map_write_x,
    output reg  [3:0]  map_write_y,
    output reg  [7:0]  map_write_id,
    output reg         spawn_mushroom,
    
    // Entradas del Champiñón
    input  wire        mush_active,
    input  wire [12:0] mush_x,
    input  wire [8:0]  mush_y,
    input  wire [1:0]  mush_state,      
    output reg         mush_consumed,   
    
    // Salidas de Mario
    output reg         is_super,
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
            mario_x        <= 13'd64; mario_y <= 9'd384; 
            vel_y          <= 6'sd0; vel_x <= 6'sd0;
            jump_max_speed <= 6'sd3;
            scroll_offset  <= 8'd0;
            mario_chunk    <= 8'd128; 
            mario_dead     <= 1'b0; sfx_jump <= 1'b0;
            delay_timer    <= 8'd0;
            map_we         <= 1'b0; spawn_mushroom <= 1'b0;
            is_super       <= 1'b0; mush_consumed <= 1'b0;
        end else begin
            vsync_prev <= vsync;
            sfx_jump   <= 1'b0;

            if (frame_tick) begin
                map_we <= 1'b0;
                spawn_mushroom <= 1'b0;
                mush_consumed <= 1'b0;

                // =========================================================
                // TRIGGERS GLOBALES DE FIN DE JUEGO
                // =========================================================
                // Blindamos la muerte para que no ocurra si ya ganaste
                if (mario_y >= 9'd460 && state != S_DEAD && state != S_WIN) begin
                    state       <= S_DEAD;
                    delay_timer <= 8'd0;
                    mario_dead  <= 1'b1;
                    vel_x       <= 6'sd0;
                    vel_y       <= 6'sd0; 
                end 
                // Al tocar el pixel 6336 (El asta de la bandera exacta)
                else if (mario_x >= 13'd6336 && state != S_WIN && state != S_DEAD) begin
                    state       <= S_WIN;
                    delay_timer <= 8'd0;
                    vel_x       <= 6'sd0;
                    vel_y       <= 6'sd0;
                    mario_x     <= 13'd6336; // Pegar a Mario a la bandera
                end 
                else begin
                    // FÍSICAS E INERCIA NORMAL (Solo si tienes control)
                    if (state != S_DEAD && state != S_WIN) begin
                        if (on_ground) jump_max_speed <= btn_run ? 6'sd8 : 6'sd6; 

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

                        if ((vel_x > 0 && hit_right_col) || (vel_x < 0 && hit_left)) vel_x <= 6'sd0;
                        else begin
                            if (calc_x < $signed({2'b0, scroll_offset, 5'b0})) begin
                                mario_x <= {scroll_offset, 5'b0}; vel_x <= 6'sd0;
                            end else mario_x <= calc_x[12:0]; 
                        end
                    end

                    // MÁQUINA DE ESTADOS
                    case (state)
                        S_IDLE, S_WALK, S_RUN: begin
                            vel_y <= 6'sd0;
                            if (!on_ground) state <= S_FALL;
                            else if (btn_jump) begin
                                vel_y <= -6'sd16; state <= S_JUMP; sfx_jump <= 1'b1;
                            end else if (vel_x != 0) state <= (vel_x > 3 || vel_x < -3) ? S_RUN : S_WALK;
                            else begin state <= S_IDLE; mario_chunk <= 8'd128; end

                            if (state == S_WALK || state == S_RUN) begin
                                anim_cnt <= anim_cnt + ((state == S_RUN) ? 4'd2 : 4'd1);
                                if (anim_cnt >= 4'd7) begin
                                    anim_cnt <= 0; walk_frame <= walk_frame + 1;
                                end
                                case (walk_frame)
                                    2'd0, 2'd1, 2'd2, 2'd3: mario_chunk <= 8'd128; // fallback anti-parpadeo
                                endcase
                            end
                        end

                        S_JUMP, S_FALL: begin
                            mario_chunk <= 8'd131; 
                            if (vel_y < 6'sd10) vel_y <= vel_y + 6'sd1; 
                            if (calc_y < 0) mario_y <= 0; else mario_y <= calc_y[8:0];
                            if (vel_y >= 0) state <= S_FALL;
                            if (on_ground && vel_y >= 0) begin mario_y <= (mario_y[8:5]) * 32; state <= S_IDLE; end
                            
                            if (hit_ceiling && vel_y < 0) begin
                                vel_y <= 6'sd0; 
                                if (hit_ceil_id == 8'h02) begin 
                                    map_we <= 1'b1; map_write_x <= hit_ceil_x; map_write_y <= hit_ceil_y; map_write_id <= 8'h0E; 
                                    if (hit_ceil_x == 8'd21) spawn_mushroom <= 1'b1;
                                end 
                                else if (hit_ceil_id == 8'h01 && is_super) begin 
                                    map_we <= 1'b1; map_write_x <= hit_ceil_x; map_write_y <= hit_ceil_y; map_write_id <= 8'h00; 
                                end
                            end
                        end

                        S_DEAD: begin
                            mario_chunk <= 8'd128; vel_x <= 6'sd0; vel_y <= 6'sd0;
                            if (delay_timer < 8'd180) delay_timer <= delay_timer + 8'd1;
                            else begin
                                state <= S_IDLE; mario_x <= 13'd64; mario_y <= 9'd384; 
                                scroll_offset <= 8'd0; mario_dead <= 1'b0; is_super <= 1'b0;
                            end
                        end

                        S_WIN: begin
                            // ========================================================
                            // SECUENCIA CINEMÁTICA DE FINAL DE NIVEL
                            // ========================================================
                            // Fase 0: Mario se desliza por el tubo
                            if (delay_timer == 8'd0) begin
                                mario_chunk <= 8'd128; 
                                if (!on_ground) begin
                                    mario_y <= mario_y + 9'd2; // Velocidad de deslizamiento
                                end else begin
                                    mario_y <= (mario_y[8:5]) * 32; // Acomodo en el suelo
                                    delay_timer <= 8'd1; 
                                end
                            end
                            // Fase 1: Pequeña pausa en el suelo
                            else if (delay_timer < 8'd30) begin
                                delay_timer <= delay_timer + 8'd1;
                            end
                            // Fase 2: Caminar hacia el castillo (coordenada 6464)
                            else if (delay_timer == 8'd30) begin
                                if (mario_x < 13'd6464) begin
                                    mario_x <= mario_x + 13'd2; // Caminar sin inercia
                                    anim_cnt <= anim_cnt + 4'd1;
                                    if (anim_cnt >= 4'd7) begin
                                        anim_cnt <= 0; walk_frame <= walk_frame + 1;
                                    end
                                end else begin
                                    delay_timer <= 8'd31; // Llegó a la puerta
                                end
                            end
                            // Fase 3: Desaparecer dentro del castillo y reiniciar
                            else begin
                                mario_y <= 9'd480; // Lo escondemos debajo del mapa para que no se dibuje
                                if (delay_timer < 8'd210) begin
                                    delay_timer <= delay_timer + 8'd1;
                                end else begin
                                    // REINICIO TOTAL
                                    state         <= S_IDLE;
                                    mario_x       <= 13'd64; 
                                    mario_y       <= 9'd384; 
                                    scroll_offset <= 8'd0;
                                    is_super      <= 1'b0; // Se pierde el poder al reiniciar
                                    delay_timer   <= 8'd0;
                                end
                            end
                        end
                        
                        default: state <= S_IDLE;
                    endcase
                end

                // =========================================================
                // LÓGICA DE PODER (Al final para anular la gravedad al crecer)
                // =========================================================
                if (!is_super && mush_active && mush_state == 2'd2) begin 
                    if (mario_x + 24 > mush_x && mario_x + 8 < mush_x + 32 &&
                        mario_y + 32 > mush_y && mario_y < mush_y + 32) begin
                        is_super <= 1'b1;
                        mush_consumed <= 1'b1;
                        mario_y <= mario_y - 9'd32; // Evita el glitch de atorarse en el suelo
                    end
                end

                // CÁMARA
                if (state != S_DEAD && state != S_WIN) begin
                    if (mario_x > {scroll_offset, 5'b0} + 13'd320) begin
                        if (scroll_offset < 8'd192) scroll_offset <= scroll_offset + 1;
                    end
                end

            end
        end
    end
endmodule

