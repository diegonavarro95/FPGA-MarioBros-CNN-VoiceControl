`timescale 1ns / 1ps

module mushroom_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire        vsync,
    
    // Gatillo y Coordenadas desde mario_fsm
    input  wire        spawn_trigger,
    input  wire [7:0]  spawn_tile_x,
    input  wire [3:0]  spawn_tile_y,
    
    // Señales del Motor de Colisiones (Puerto C)
    input  wire        on_ground,
    input  wire        hit_left,
    input  wire        hit_right,
    
    // Salidas
    output reg  [12:0] mush_x,
    output reg  [8:0]  mush_y,
    output reg         mush_active,
    output wire [7:0]  mush_chunk
);

    assign mush_chunk = 8'd16; // ID del Champiñón
    
    localparam S_HIDDEN = 2'd0, S_SPAWNING = 2'd1, S_MOVING = 2'd2;
    reg [1:0] state;
    
    reg signed [5:0] vel_y;
    reg signed [5:0] vel_x;
    
    // LA SOLUCIÓN: 6 bits permiten contar hasta 63, evitando el desbordamiento
    reg [5:0] spawn_counter; 
    
    // Matemáticas idénticas a las de Mario
    wire signed [13:0] calc_y = $signed({1'b0, mush_y}) + $signed(vel_y); 
    wire signed [14:0] calc_x = $signed({2'b0, mush_x}) + $signed(vel_x);

    reg vsync_prev;
    wire frame_tick = vsync_prev & ~vsync;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_HIDDEN;
            mush_active <= 1'b0;
            mush_x <= 13'd0;
            mush_y <= 9'd0;
            vel_x <= 6'sd0;
            vel_y <= 6'sd0;
            spawn_counter <= 6'd0;
        end else begin
            vsync_prev <= vsync;
            
            if (frame_tick) begin
                case (state)
                    S_HIDDEN: begin
                        mush_active <= 1'b0;
                        if (spawn_trigger) begin
                            state <= S_SPAWNING;
                            mush_active <= 1'b1;
                            // Nace exactamente dentro de la caja golpeada
                            mush_x <= spawn_tile_x * 13'd32;
                            mush_y <= spawn_tile_y * 9'd32;
                            spawn_counter <= 6'd0;
                            vel_x <= 6'sd0;
                            vel_y <= 6'sd0;
                        end
                    end
                    
                    S_SPAWNING: begin
                        // Ahora sí puede llegar a 32 sin reiniciarse a 0
                        if (spawn_counter < 6'd32) begin
                            mush_y <= mush_y - 9'd1;
                            spawn_counter <= spawn_counter + 6'd1;
                        end else begin
                            state <= S_MOVING;
                            vel_x <= 6'sd1; // Comienza a caminar a la derecha (1 px/frame)
                            vel_y <= 6'sd0;
                        end
                    end
                    
                    S_MOVING: begin
                        // 1. Gravedad
                        if (!on_ground) begin
                            if (vel_y < 6'sd6) vel_y <= vel_y + 6'sd1;
                        end else begin
                            vel_y <= 6'sd0;
                        end
                        
                        // 2. Aplicar Cinemática Vertical
                        if (on_ground && vel_y >= 0) begin
                            mush_y <= (mush_y[8:5]) * 32; // Ajuste perfecto al piso
                        end else begin
                            mush_y <= calc_y[8:0];
                        end
                        
                        // 3. Rebote en paredes horizontales
                        if (hit_right && vel_x > 0) vel_x <= -6'sd1;
                        else if (hit_left && vel_x < 0) vel_x <= 6'sd1;
                        
                        // 4. Aplicar Cinemática Horizontal
                        mush_x <= calc_x[12:0];
                        
                        // 5. Destrucción si cae por un foso
                        if (mush_y > 9'd460) state <= S_HIDDEN;
                    end
                    
                    default: state <= S_HIDDEN;
                endcase
            end
        end
    end
endmodule

