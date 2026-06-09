`timescale 1ns / 1ps

module mushroom_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire        vsync,
    
    input  wire        spawn_trigger,
    input  wire [7:0]  spawn_tile_x,
    input  wire [3:0]  spawn_tile_y,
    
    input  wire        on_ground,
    input  wire        hit_left,
    input  wire        hit_right,
    
    // Nuevas señales de interacción
    input  wire        consumed,
    output wire [1:0]  mush_state_out,
    
    output reg  [12:0] mush_x,
    output reg  [8:0]  mush_y,
    output reg         mush_active,
    output wire [7:0]  mush_chunk
);

    assign mush_chunk = 8'd16; 
    
    localparam S_HIDDEN = 2'd0, S_SPAWNING = 2'd1, S_MOVING = 2'd2;
    reg [1:0] state;
    assign mush_state_out = state; // Exportamos el estado
    
    reg signed [5:0] vel_y;
    reg signed [5:0] vel_x;
    reg [5:0] spawn_counter; 
    
    wire signed [13:0] calc_y = $signed({1'b0, mush_y}) + $signed(vel_y); 
    wire signed [14:0] calc_x = $signed({2'b0, mush_x}) + $signed(vel_x);

    reg vsync_prev;
    wire frame_tick = vsync_prev & ~vsync;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_HIDDEN;
            mush_active <= 1'b0;
            mush_x <= 13'd0; mush_y <= 9'd0;
            vel_x <= 6'sd0; vel_y <= 6'sd0;
            spawn_counter <= 6'd0;
        end else begin
            vsync_prev <= vsync;
            
            if (frame_tick) begin
                if (consumed) begin
                    state <= S_HIDDEN;
                    mush_active <= 1'b0;
                end else begin
                    case (state)
                        S_HIDDEN: begin
                            mush_active <= 1'b0;
                            if (spawn_trigger) begin
                                state <= S_SPAWNING;
                                mush_active <= 1'b1;
                                mush_x <= spawn_tile_x * 13'd32;
                                mush_y <= spawn_tile_y * 9'd32;
                                spawn_counter <= 6'd0;
                                vel_x <= 6'sd0; vel_y <= 6'sd0;
                            end
                        end
                        
                        S_SPAWNING: begin
                            if (spawn_counter < 6'd32) begin
                                mush_y <= mush_y - 9'd1;
                                spawn_counter <= spawn_counter + 6'd1;
                            end else begin
                                state <= S_MOVING;
                                vel_x <= 6'sd2; 
                                vel_y <= 6'sd0;
                            end
                        end
                        
                        S_MOVING: begin
                            if (!on_ground) begin
                                if (vel_y < 6'sd6) vel_y <= vel_y + 6'sd1;
                            end else vel_y <= 6'sd0;
                            
                            if (on_ground && vel_y >= 0) mush_y <= (mush_y[8:5]) * 32; 
                            else mush_y <= calc_y[8:0];
                            
                            if (hit_right && vel_x > 0) vel_x <= -6'sd2;      
                            else if (hit_left && vel_x < 0) vel_x <= 6'sd2;   
                            
                            mush_x <= calc_x[12:0];
                            if (mush_y > 9'd460) state <= S_HIDDEN;
                        end
                        default: state <= S_HIDDEN;
                    endcase
                end
            end
        end
    end
endmodule

