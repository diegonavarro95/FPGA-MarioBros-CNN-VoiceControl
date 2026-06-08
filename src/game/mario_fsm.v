`timescale 1ns / 1ps

module mario_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire        vsync,

    // Controles
    input  wire        btn_right,
    input  wire        btn_left,
    input  wire        btn_jump,
    input  wire        btn_run,

    // Del motor de colisiones
    input  wire        on_ground,
    input  wire        hit_ceiling,
    input  wire        hit_left,
    input  wire        hit_right_col,

    // Salidas
    output reg  [12:0] mario_x,
    output reg  [8:0]  mario_y,
    output reg  [7:0]  mario_chunk,
    output reg  [7:0]  scroll_offset,
    output reg         mario_dead,

    // Triggers de audio
    output reg         sfx_jump
);

    // Estados
    localparam S_IDLE = 3'd0, S_WALK = 3'd1, S_RUN = 3'd2, S_JUMP = 3'd3, S_FALL = 3'd4, S_DEAD = 3'd5;
    reg [2:0] state;

    // Física matemática FIRMADA (Complemento a 2)
    reg signed [5:0] vel_y;       // -16 a +15
    wire signed [13:0] calc_y = $signed({1'b0, mario_y}) + $signed(vel_y); 
    
    wire [12:0] hspeed = btn_run ? 13'd4 : 13'd2;

    reg [3:0] anim_cnt;
    reg [1:0] walk_frame;
    reg vsync_prev;
    wire frame_tick = vsync_prev & ~vsync;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= S_IDLE; // Iniciar de pie, no cayendo
            mario_x       <= 13'd64; 
            mario_y       <= 9'd384; // 384 = Nivel exacto del suelo (Fila 13)
            vel_y         <= 6'sd0;
            scroll_offset <= 8'd0;
            mario_chunk   <= 8'd128; 
            mario_dead    <= 1'b0;
            sfx_jump      <= 1'b0;
        end else begin
            vsync_prev <= vsync;
            sfx_jump   <= 1'b0;

            if (frame_tick && !mario_dead) begin
                
                // 1. MOVIMIENTO HORIZONTAL
                if (btn_right && !hit_right_col) begin
                    if (mario_x <= 13'd6751 - hspeed) mario_x <= mario_x + hspeed;
                end else if (btn_left && !hit_left) begin
                    // Evitar que Mario retroceda más allá del límite de la cámara izquierda
                    if (mario_x >= {scroll_offset, 5'b0} + hspeed) mario_x <= mario_x - hspeed;
                end

                // 2. MÁQUINA DE ESTADOS Y GRAVEDAD
                case (state)
                    S_IDLE, S_WALK, S_RUN: begin
                        vel_y <= 6'sd0;
                        if (!on_ground) begin
                            state <= S_FALL;
                        end else if (btn_jump) begin
                            vel_y <= -6'sd32; // Impulso hacia arriba (negativo)
                            state <= S_JUMP;
                            sfx_jump <= 1'b1;
                        end else if (btn_right || btn_left) begin
                            state <= btn_run ? S_RUN : S_WALK;
                        end else begin
                            state <= S_IDLE;
                            mario_chunk <= 8'd128; // Quieto
                        end

                        // Animación de Caminar
                        if (state == S_WALK || state == S_RUN) begin
                            anim_cnt <= anim_cnt + (state == S_RUN ? 4'd2 : 4'd1);
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
                        mario_chunk <= 8'd131; // Sprite de Salto
                        
                        // Aplicar gravedad
                        if (vel_y < 6'sd10) vel_y <= vel_y + 6'sd1;
                        
                        // Aplicar cinemática con protección de límites
                        if (calc_y < 0) mario_y <= 0; // Techo del mundo
                        else mario_y <= calc_y[8:0];

                        // Cambio de estado
                        if (vel_y >= 0) state <= S_FALL;

                        if (on_ground && vel_y >= 0) begin
                            // Snap a la cuadrícula del suelo para no hundirse
                            mario_y <= (mario_y[8:5]) * 32; 
                            state <= S_IDLE;
                        end
                        
                        if (hit_ceiling && vel_y < 0) vel_y <= 6'sd0; // Golpear bloque por debajo
                    end

                    // --- CASOS AGREGADOS PARA CUBRIR TODAS LAS POSIBILIDADES ---
                    S_DEAD: begin
                        vel_y <= 6'sd0;
                    end
                    
                    default: state <= S_IDLE;

                endcase

                // 3. FOSOS DE LA MUERTE
                if (mario_y >= 9'd460) begin
                    mario_dead <= 1'b1;
                end

                // 4. SCROLL DE CÁMARA
                // Si Mario pasa la mitad de la pantalla (320px)
                if (mario_x > {scroll_offset, 5'b0} + 13'd320) begin
                    if (scroll_offset < 8'd192) scroll_offset <= scroll_offset + 1;
                end
            end
        end
    end
endmodule

