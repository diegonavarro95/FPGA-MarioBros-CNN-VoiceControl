// ROM de Chunks OPTIMIZADA - Super Mario Bros FPGA
// Checar los readmes para explicación
// NOTA: Los loops en el bloque initial:
// for (y = 0; y < 16; y = y + 1)
//     for (x = 0; x < 16; x = x + 1)
// Se desenrollan completamente en tiempo de compilación.
// El sintetizador los ejecuta una vez y genera asignaciones constantes.
// Al usar una matriz plana para cada ID, simplificamos el mapeo a memoria.

module rom_chunks_mario (
    input  wire       clk,
    input  wire [7:0] chunk_id,   // ID del chunk (0-255)
    input  wire [3:0] pixel_x,    // Posicion X dentro del chunk (0-15)
    input  wire [3:0] pixel_y,    // Posicion Y dentro del chunk (0-15)
    output reg  [3:0] pixel_data  // Color del pixel (4 bits)
);

    // Tipo para almacenar un chunk completo:
    // 256 chunks, donde cada chunk tiene 256 pixeles (16x16) de 4 bits
    reg [3:0] ROM_CHUNKS [0:255][0:255];

    integer id, x, y, addr;

    initial begin
        // 1. Inicialización Base: 
        // Color 0 = transparente ("0000") para todos los slots (0-255)
        for (id = 0; id < 256; id = id + 1) begin
            for (addr = 0; addr < 256; addr = addr + 1) begin
                ROM_CHUNKS[id][addr] = 4'b0000;
            end
        end

        // 2. Construcción algorítmica de los chunks
        for (y = 0; y < 16; y = y + 1) begin
            for (x = 0; x < 16; x = x + 1) begin
                addr = y * 16 + x;

                // ID 1: init_brick_block
                if (y == 0 || y == 15 || x == 0 || x == 15)
                    ROM_CHUNKS[1][addr] = 4'b1000;
                else if ((y % 8) < 4 && (x % 8) < 4)
                    ROM_CHUNKS[1][addr] = 4'b1100;
                else
                    ROM_CHUNKS[1][addr] = 4'b1001;

                // ID 2: init_question_block
                if (y == 0 || y == 15 || x == 0 || x == 15)
                    ROM_CHUNKS[2][addr] = 4'b1011;
                else if (x >= 6 && x <= 9 && y >= 3 && y <= 12)
                    ROM_CHUNKS[2][addr] = 4'b1111;
                else
                    ROM_CHUNKS[2][addr] = 4'b1110;

                // ID 3: init_ground_block
                if ((x + y) % 2 == 0)
                    ROM_CHUNKS[3][addr] = 4'b0110;
                else
                    ROM_CHUNKS[3][addr] = 4'b0101;

                // ID 4: init_stair_block
                ROM_CHUNKS[4][addr] = 4'b1011;

                // ID 5: init_castle_block
                if ((x + y) % 3 == 0)
                    ROM_CHUNKS[5][addr] = 4'b1000;
                else
                    ROM_CHUNKS[5][addr] = 4'b0010;

                // ID 6: init_brick_used
                if (y == 0 || y == 15 || x == 0 || x == 15)
                    ROM_CHUNKS[6][addr] = 4'b1000;
                else
                    ROM_CHUNKS[6][addr] = 4'b1001;

                // ID 7: init_metal_block
                if (y == 0 || y == 15 || x == 0 || x == 15)
                    ROM_CHUNKS[7][addr] = 4'b1000;
                else if ((x + y) % 2 == 0)
                    ROM_CHUNKS[7][addr] = 4'b0010;
                else
                    ROM_CHUNKS[7][addr] = 4'b1000;

                // ID 8: init_flag_pole
                if (x >= 7 && x <= 8)
                    ROM_CHUNKS[8][addr] = 4'b0111;
                else
                    ROM_CHUNKS[8][addr] = 4'b0000;

                // ID 9: init_flag
                if (y >= 2 && y <= 9 && x >= 0 && x <= 6)
                    ROM_CHUNKS[9][addr] = 4'b1111;
                else
                    ROM_CHUNKS[9][addr] = 4'b0000;

                // ID 10: init_pipe_top_left
                if (x < 2 || y < 2) ROM_CHUNKS[10][addr] = 4'b0011;
                else ROM_CHUNKS[10][addr] = 4'b0100;

                // ID 11: init_pipe_top_right
                if (x > 13 || y < 2) ROM_CHUNKS[11][addr] = 4'b0011;
                else ROM_CHUNKS[11][addr] = 4'b0100;

                // ID 12: init_pipe_body_left
                if (x < 2) ROM_CHUNKS[12][addr] = 4'b0011;
                else ROM_CHUNKS[12][addr] = 4'b0100;

                // ID 13: init_pipe_body_right
                if (x > 13) ROM_CHUNKS[13][addr] = 4'b0011;
                else ROM_CHUNKS[13][addr] = 4'b0100;

                // ID 14: init_pipe_red_top_left
                if (x < 2 || y < 2) ROM_CHUNKS[14][addr] = 4'b1001;
                else ROM_CHUNKS[14][addr] = 4'b1100;

                // ID 15: init_pipe_yellow_top_left
                if (x < 2 || y < 2) ROM_CHUNKS[15][addr] = 4'b1011;
                else ROM_CHUNKS[15][addr] = 4'b1110;

                // ID 32: init_goomba
                if (y < 4) ROM_CHUNKS[32][addr] = 4'b0000;
                else if (y < 10 && x >= 2 && x <= 13) ROM_CHUNKS[32][addr] = 4'b1001;
                else if (y >= 10 && y < 14 && ((x >= 1 && x <= 6) || (x >= 9 && x <= 14))) ROM_CHUNKS[32][addr] = 4'b1001;
                else ROM_CHUNKS[32][addr] = 4'b0000;

                // ID 33: init_koopa
                if (y < 3 || y > 12) ROM_CHUNKS[33][addr] = 4'b0000;
                else if ((x >= 3 && x <= 12) && (y >= 3 && y <= 12)) begin
                    if ((x + y) % 3 == 0) ROM_CHUNKS[33][addr] = 4'b0100;
                    else ROM_CHUNKS[33][addr] = 4'b0011;
                end else ROM_CHUNKS[33][addr] = 4'b0000;

                // ID 34: init_koopa_walk
                if (y >= 3 && y <= 9 && x >= 3 && x <= 12) begin
                    if ((x + y) % 3 == 0) ROM_CHUNKS[34][addr] = 4'b0100;
                    else ROM_CHUNKS[34][addr] = 4'b0011;
                end else if (y >= 1 && y <= 3 && x >= 6 && x <= 9) ROM_CHUNKS[34][addr] = 4'b1110;
                else if (y >= 10 && y <= 13) begin
                    if ((x >= 4 && x <= 5) || (x >= 10 && x <= 11)) ROM_CHUNKS[34][addr] = 4'b1110;
                    else ROM_CHUNKS[34][addr] = 4'b0000;
                end else ROM_CHUNKS[34][addr] = 4'b0000;

                // ID 35: init_goomba_squashed
                if (y >= 12 && y <= 15 && x >= 1 && x <= 14) ROM_CHUNKS[35][addr] = 4'b1001;
                else ROM_CHUNKS[35][addr] = 4'b0000;

                // ID 64: init_coin
                if (y >= 4 && y <= 11 && x >= 4 && x <= 11) begin
                    if (x == 4 || x == 11 || y == 4 || y == 11) ROM_CHUNKS[64][addr] = 4'b1011;
                    else ROM_CHUNKS[64][addr] = 4'b1110;
                end else ROM_CHUNKS[64][addr] = 4'b0000;

                // ID 65: init_mushroom
                if (y < 5) ROM_CHUNKS[65][addr] = 4'b0000;
                else if (y >= 5 && y < 10 && x >= 2 && x <= 13) begin
                    if ((x + y) % 2 == 0) ROM_CHUNKS[65][addr] = 4'b1100;
                    else ROM_CHUNKS[65][addr] = 4'b1111;
                end else if (y >= 10 && x >= 5 && x <= 10) ROM_CHUNKS[65][addr] = 4'b0111;
                else ROM_CHUNKS[65][addr] = 4'b0000;

                // ID 66: init_fire_flower
                if (x >= 7 && x <= 8 && y >= 8 && y <= 15) ROM_CHUNKS[66][addr] = 4'b0100;
                else if (y >= 3 && y <= 9) begin
                    if ((x >= 5 && x <= 6) || (x >= 9 && x <= 10)) ROM_CHUNKS[66][addr] = 4'b1100;
                    else if (y >= 3 && y <= 5 && x >= 7 && x <= 8) ROM_CHUNKS[66][addr] = 4'b1100;
                    else if (y >= 7 && y <= 9 && x >= 7 && x <= 8) ROM_CHUNKS[66][addr] = 4'b1100;
                    else if (y >= 5 && y <= 7 && x >= 7 && x <= 8) ROM_CHUNKS[66][addr] = 4'b1111;
                    else ROM_CHUNKS[66][addr] = 4'b0000;
                end else ROM_CHUNKS[66][addr] = 4'b0000;

                // ID 67: init_star
                if (y == 8 && x >= 4 && x <= 11) ROM_CHUNKS[67][addr] = 4'b1110;
                else if (x == 8 && y >= 4 && y <= 11) ROM_CHUNKS[67][addr] = 4'b1110;
                else if ((y >= 5 && y <= 7) || (y >= 9 && y <= 11)) begin
                    if ((x >= 5 && x <= 7) || (x >= 9 && x <= 10)) ROM_CHUNKS[67][addr] = 4'b1110;
                    else ROM_CHUNKS[67][addr] = 4'b0000;
                end else ROM_CHUNKS[67][addr] = 4'b0000;

                // ID 96: init_cloud_small
                if (y >= 3 && y <= 8 && x >= 2 && x <= 13) ROM_CHUNKS[96][addr] = 4'b1111;
                else ROM_CHUNKS[96][addr] = 4'b0000;

                // ID 97: init_bush
                if (y >= 8 && x >= 1 && x <= 14) ROM_CHUNKS[97][addr] = 4'b0100;
                else ROM_CHUNKS[97][addr] = 4'b0000;

                // ID 98: init_cloud_left
                if (y >= 4 && y <= 10) begin
                    if (x >= 3 && x <= 15) ROM_CHUNKS[98][addr] = 4'b1111;
                    else if (x == 2 && y >= 5 && y <= 9) ROM_CHUNKS[98][addr] = 4'b1111;
                    else ROM_CHUNKS[98][addr] = 4'b0000;
                end else ROM_CHUNKS[98][addr] = 4'b0000;

                // ID 99: init_cloud_center
                if (y >= 4 && y <= 10) ROM_CHUNKS[99][addr] = 4'b1111;
                else ROM_CHUNKS[99][addr] = 4'b0000;

                // ID 100: init_cloud_right
                if (y >= 4 && y <= 10) begin
                    if (x >= 0 && x <= 12) ROM_CHUNKS[100][addr] = 4'b1111;
                    else if (x == 13 && y >= 5 && y <= 9) ROM_CHUNKS[100][addr] = 4'b1111;
                    else ROM_CHUNKS[100][addr] = 4'b0000;
                end else ROM_CHUNKS[100][addr] = 4'b0000;

                // ID 101: init_bush_left
                if (y >= 9 && y <= 15) begin
                    if (x >= 1 && x <= 15) ROM_CHUNKS[101][addr] = 4'b0100;
                    else if (x == 0 && y >= 10 && y <= 14) ROM_CHUNKS[101][addr] = 4'b0100;
                    else ROM_CHUNKS[101][addr] = 4'b0000;
                end else if (y >= 6 && y <= 8 && x >= 6 && x <= 15) ROM_CHUNKS[101][addr] = 4'b0100;
                else ROM_CHUNKS[101][addr] = 4'b0000;

                // ID 102: init_bush_center
                if (y >= 9 && y <= 15) ROM_CHUNKS[102][addr] = 4'b0100;
                else if (y >= 6 && y <= 8) ROM_CHUNKS[102][addr] = 4'b0100;
                else ROM_CHUNKS[102][addr] = 4'b0000;

                // ID 103: init_bush_right
                if (y >= 9 && y <= 15) begin
                    if (x >= 0 && x <= 14) ROM_CHUNKS[103][addr] = 4'b0100;
                    else if (x == 15 && y >= 10 && y <= 14) ROM_CHUNKS[103][addr] = 4'b0100;
                    else ROM_CHUNKS[103][addr] = 4'b0000;
                end else if (y >= 6 && y <= 8 && x >= 0 && x <= 9) ROM_CHUNKS[103][addr] = 4'b0100;
                else ROM_CHUNKS[103][addr] = 4'b0000;

                // ID 104: init_hill_small
                if (y >= 12) begin
                    if (x >= 2 && x <= 13) ROM_CHUNKS[104][addr] = 4'b0100;
                    else ROM_CHUNKS[104][addr] = 4'b0000;
                end else if (y >= 10 && y < 12) begin
                    if (x >= 4 && x <= 11) ROM_CHUNKS[104][addr] = 4'b0100;
                    else ROM_CHUNKS[104][addr] = 4'b0000;
                end else if (y >= 8 && y < 10) begin
                    if (x >= 6 && x <= 9) ROM_CHUNKS[104][addr] = 4'b0100;
                    else ROM_CHUNKS[104][addr] = 4'b0000;
                end else ROM_CHUNKS[104][addr] = 4'b0000;

                // ID 128: init_mario_small
                if (y >= 2 && y <= 5 && x >= 5 && x <= 10) ROM_CHUNKS[128][addr] = 4'b0111;
                else if (y >= 6 && y <= 11 && x >= 4 && x <= 11) ROM_CHUNKS[128][addr] = 4'b1100;
                else if (y >= 12 && y <= 14 && ((x >= 4 && x <= 6) || (x >= 9 && x <= 11))) ROM_CHUNKS[128][addr] = 4'b1001;
                else ROM_CHUNKS[128][addr] = 4'b0000;

                // ID 129: init_mario_big_top
                if (y >= 1 && y <= 7 && x >= 4 && x <= 11) begin
                    if (y <= 4) ROM_CHUNKS[129][addr] = 4'b0111;
                    else ROM_CHUNKS[129][addr] = 4'b1100;
                end else if (y >= 8 && y <= 15 && x >= 3 && x <= 12) ROM_CHUNKS[129][addr] = 4'b1100;
                else ROM_CHUNKS[129][addr] = 4'b0000;

                // ID 130: init_mario_big_bottom
                if (y >= 0 && y <= 11 && x >= 3 && x <= 12) ROM_CHUNKS[130][addr] = 4'b1100;
                else if (y >= 12 && y <= 15) begin
                    if ((x >= 3 && x <= 6) || (x >= 9 && x <= 12)) ROM_CHUNKS[130][addr] = 4'b1001;
                    else ROM_CHUNKS[130][addr] = 4'b0000;
                end else ROM_CHUNKS[130][addr] = 4'b0000;

                // ID 131: init_mario_jump
                if (y >= 2 && y <= 5 && x >= 5 && x <= 10) ROM_CHUNKS[131][addr] = 4'b0111;
                else if (y >= 5 && y <= 7 && ((x >= 2 && x <= 4) || (x >= 11 && x <= 13))) ROM_CHUNKS[131][addr] = 4'b0111;
                else if (y >= 6 && y <= 11 && x >= 4 && x <= 11) ROM_CHUNKS[131][addr] = 4'b1100;
                else if (y >= 12 && y <= 14 && x >= 5 && x <= 10) ROM_CHUNKS[131][addr] = 4'b1001;
                else ROM_CHUNKS[131][addr] = 4'b0000;
            end
        end
    end

    // Acceso directo en un solo ciclo - sin señales intermedias
    // ACCESO DIRECTO: Elimina multiplexor de 1024 bits de VHDL, 
    // concatena Y y X para inferir el addr_pixel automáticamente
    wire [7:0] addr_pixel = {pixel_y, pixel_x}; 

    always @(posedge clk) begin
        pixel_data <= ROM_CHUNKS[chunk_id][addr_pixel];
    end

endmodule