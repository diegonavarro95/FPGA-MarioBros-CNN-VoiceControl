module audio_controller (
    input wire clk_12m,
    input wire reset,
    input wire btn_jump,
    input wire btn_coin,
    input wire next_sample,
    
    output reg [15:0] addr_jump,
    output reg [15:0] addr_coin,
    input wire [15:0] data_jump,
    input wire [15:0] data_coin,
    
    output wire [15:0] audio_out
);
    // REEMPLAZA ESTOS NÚMEROS CON LAS LÍNEAS TOTALES DE TUS ARCHIVOS .COE
    parameter MAX_JUMP = 14438; 
    parameter MAX_COIN = 12496;

    reg playing_jump = 0;
    reg playing_coin = 0;
    
    reg btn_jump_prev = 0, btn_coin_prev = 0;

    always @(posedge clk_12m) begin
        if (reset) begin
            playing_jump <= 0; playing_coin <= 0;
            addr_jump <= 0; addr_coin <= 0;
            btn_jump_prev <= 0; btn_coin_prev <= 0;
        end else begin
            btn_jump_prev <= btn_jump;
            btn_coin_prev <= btn_coin;

            // Detección de flanco de subida (Trigger)
            if (btn_jump && !btn_jump_prev) begin
                playing_jump <= 1;
                addr_jump <= 0;
            end
            if (btn_coin && !btn_coin_prev) begin
                playing_coin <= 1;
                addr_coin <= 0;
            end

            // Avance de memoria dictado por el I2S (16,000 veces por segundo)
            if (next_sample) begin
                if (playing_jump) begin
                    if (addr_jump >= MAX_JUMP - 1) playing_jump <= 0;
                    else addr_jump <= addr_jump + 1;
                end
                
                if (playing_coin) begin
                    if (addr_coin >= MAX_COIN - 1) playing_coin <= 0;
                    else addr_coin <= addr_coin + 1;
                end
            end
        end
    end

    // DSP Básico: Mezcla dividiendo la amplitud a la mitad para evitar overflow
    wire [15:0] out_jump = playing_jump ? {data_jump[15], data_jump[15:1]} : 16'd0;
    wire [15:0] out_coin = playing_coin ? {data_coin[15], data_coin[15:1]} : 16'd0;
    
    assign audio_out = out_jump + out_coin;
endmodule