`timescale 1ns / 1ps
// =============================================================================
// ROM_CHUNKS_MARIO.V — Sprites 32x32 para Super Mario Bros FPGA
// =============================================================================

module rom_chunks_mario (
    input  wire        clk,
    input  wire [7:0]  chunk_id,
    input  wire [4:0]  pixel_x,   // 5 bits para chunks 32x32 (0-31)
    input  wire [4:0]  pixel_y,
    output reg  [3:0]  pixel_data
);

    // 256 chunks de 32x32 = 256*1024 bits = 256KB de ROM
    reg [3:0] ROM [0:143][0:1023];

    integer id, x, y, addr;
    integer px, py; // Variables para cálculo de sub-bloques

    initial begin

        // =====================================================================
        // PASO 1: Inicializar todo a transparente
        // =====================================================================
        for (id = 0; id < 144; id = id + 1)
            for (addr = 0; addr < 1024; addr = addr + 1)
                ROM[id][addr] = 4'h0;

        // =====================================================================
        // PASO 2: Dibujar cada chunk
        // =====================================================================
        for (y = 0; y < 32; y = y + 1) begin
            for (x = 0; x < 32; x = x + 1) begin
                addr = y * 32 + x;

                // =============================================================
                // ID 1: LADRILLO (BRICK BLOCK)
                // =============================================================
                begin
                    if (x == 0 || x == 31 || y == 0 || y == 31)
                        ROM[1][addr] = 4'h8;
                    else if (y == 8 || y == 9 || y == 20 || y == 21)
                        ROM[1][addr] = 4'h8;
                    else if (y < 9) begin
                        if (x == 16 || x == 17) ROM[1][addr] = 4'h8;
                        else ROM[1][addr] = 4'h9;
                    end else if (y > 9 && y < 20) begin
                        if (x == 8 || x == 9 || x == 24 || x == 25) ROM[1][addr] = 4'h8;
                        else ROM[1][addr] = 4'h9;
                    end else begin
                        if (x == 16 || x == 17) ROM[1][addr] = 4'h8;
                        else ROM[1][addr] = 4'h9;
                    end
                end

                // =============================================================
                // ID 2: BLOQUE PREGUNTA (?)
                // =============================================================
                begin
                    if (x == 0 || x == 31 || y == 0 || y == 31)
                        ROM[2][addr] = 4'hB;
                    else if (x == 1 || x == 30 || y == 1 || y == 30)
                        ROM[2][addr] = 4'hF;
                    else if ((y >= 4 && y <= 8) && (x >= 12 && x <= 19))
                        ROM[2][addr] = 4'hF; 
                    else if ((y >= 4 && y <= 11) && (x >= 8 && x <= 11))
                        ROM[2][addr] = 4'hF; 
                    else if ((y >= 4 && y <= 11) && (x >= 20 && x <= 23))
                        ROM[2][addr] = 4'hF; 
                    else if ((y >= 12 && y <= 16) && (x >= 12 && x <= 19))
                        ROM[2][addr] = 4'hF; 
                    else if ((y >= 18 && y <= 22) && (x >= 12 && x <= 19))
                        ROM[2][addr] = 4'hF; 
                    else
                        ROM[2][addr] = 4'hE;
                end
                
                // ==========================================
                // FIX SUELO (ID 3): Tu diseño restaurado en 32x32
                // ==========================================
                if (y == 0 || y == 1) ROM[3][addr] = 4'h9;
                else if ((y < 16) && (x == 0 || x == 1 || x == 16 || x == 17)) ROM[3][addr] = 4'h9;
                else if ((y >= 16) && (x == 8 || x == 9 || x == 24 || x == 25)) ROM[3][addr] = 4'h9;
                else if (y == 14 || y == 15 || y == 30 || y == 31) ROM[3][addr] = 4'h9;
                else ROM[3][addr] = 4'h6;

                // =============================================================
                // ID 4: ESCALERA (STAIR BLOCK)
                // =============================================================
                begin
                    if (x == 0 || x == 31 || y == 0 || y == 31)
                        ROM[4][addr] = 4'h8;
                    else if (x == 1 || y == 1)
                        ROM[4][addr] = 4'hF;
                    else
                        ROM[4][addr] = 4'hB;
                end

                // ==========================================
                // CASTILLO Y COLINAS (Nuevos Chunks)
                // ==========================================
                // ID 5: CASTILLO BASE (CA) - Ladrillo Naranja
                if (y == 0 || y == 1) ROM[5][addr] = 4'h1;
                else if ((y < 16) && (x == 0 || x == 1 || x == 16 || x == 17)) ROM[5][addr] = 4'h1;
                else if ((y >= 16) && (x == 8 || x == 9 || x == 24 || x == 25)) ROM[5][addr] = 4'h1;
                else if (y == 14 || y == 15 || y == 30 || y == 31) ROM[5][addr] = 4'h1;
                else ROM[5][addr] = 4'hB;

                // =============================================================
                // ID 6: LADRILLO USADO (BRICK USED)
                // =============================================================
                begin
                    if (x == 0 || x == 31 || y == 0 || y == 31)
                        ROM[6][addr] = 4'h8;
                    else
                        ROM[6][addr] = 4'h9;
                end

                // =============================================================
                // ID 7: BLOQUE METÁLICO
                // =============================================================
                begin
                    if (x == 0 || x == 31 || y == 0 || y == 31)
                        ROM[7][addr] = 4'h8;
                    else if ((x + y) % 2 == 0)
                        ROM[7][addr] = 4'h2;
                    else
                        ROM[7][addr] = 4'h8;
                end

                // ==========================================
                // FIX BANDERA Y ASTA
                // ==========================================
                // ID 8: ASTA (FP)
                if (x >= 14 && x <= 17) ROM[8][addr] = 4'h4;
                else ROM[8][addr] = 4'h0;
                
                // ID 9: BANDERA (FL)
                if (y >= 4 && y <= 16 && x >= 12 && x <= 31) ROM[9][addr] = 4'h4; 
                else ROM[9][addr] = 4'h0;

                // ==========================================
                // FIX TUBERÍAS: Bordes limpios sin líneas salidas
                // ==========================================
                // ID 10: TOPE IZQ
                if (x < 2 || y < 2 || y > 29) ROM[10][addr] = 4'h1; 
                else if (x >= 6 && x <= 12) ROM[10][addr] = 4'h4;
                else ROM[10][addr] = 4'h3;
                
                // ID 11: TOPE DER
                if (x > 29 || y < 2 || y > 29) ROM[11][addr] = 4'h1; 
                else if (x >= 20 && x <= 24) ROM[11][addr] = 4'h4;
                else ROM[11][addr] = 4'h3;

                // ID 12: CUERPO IZQ
                if (x < 4) ROM[12][addr] = 4'h0;
                else if (x == 4 || x == 5) ROM[12][addr] = 4'h1; 
                else if (x >= 8 && x <= 14) ROM[12][addr] = 4'h4;
                else ROM[12][addr] = 4'h3;

                // ID 13: CUERPO DER
                if (x > 27) ROM[13][addr] = 4'h0;
                else if (x == 26 || x == 27) ROM[13][addr] = 4'h1; 
                else if (x >= 18 && x <= 22) ROM[13][addr] = 4'h4;
                else ROM[13][addr] = 4'h3;

                // =============================================================
                // ID 14: BLOQUE USADO / CAJA VACÍA (NUEVO)
                // Bloque marrón con 4 remaches en las esquinas
                // =============================================================
                begin
                    if (x == 0 || x == 31 || y == 0 || y == 31)
                        ROM[14][addr] = 4'h8; // Borde oscuro
                    else if ((x>=4 && x<=7 && y>=4 && y<=7) || (x>=24 && x<=27 && y>=4 && y<=7) ||
                             (x>=4 && x<=7 && y>=24 && y<=27) || (x>=24 && x<=27 && y>=24 && y<=27))
                        ROM[14][addr] = 4'h1; // Remaches negros en las 4 esquinas
                    else
                        ROM[14][addr] = 4'h9; // Fondo marrón
                end

                // =============================================================
                // ID 16: CHAMPIÑÓN ROJO (NUEVO)
                // Diseño de 32x32 escalando un grid visual de 16x16
                // =============================================================
                begin
                    px = x / 2; // Extraemos sub-coordenadas de 16x16
                    py = y / 2;

                    if (py == 0 || py >= 15) ROM[16][addr] = 4'h0;
                    else if (py == 1) ROM[16][addr] = (px>=5 && px<=10) ? 4'h1 : 4'h0;
                    else if (py == 2) ROM[16][addr] = (px>=4 && px<=11) ? ((px>=5&&px<=10)?4'hC:4'h1) : 4'h0;
                    else if (py == 3) ROM[16][addr] = (px>=3 && px<=12) ? ((px>=4&&px<=11)?4'hC:4'h1) : 4'h0;
                    else if (py == 4) ROM[16][addr] = (px>=2 && px<=13) ? ((px==2||px==13)?4'h1:((px>=4&&px<=5)||(px>=10&&px<=11)?4'hF:4'hC)) : 4'h0;
                    else if (py == 5) ROM[16][addr] = (px>=1 && px<=14) ? ((px==1||px==14)?4'h1:((px>=3&&px<=6)||(px>=9&&px<=12)?4'hF:4'hC)) : 4'h0;
                    else if (py == 6) ROM[16][addr] = (px>=1 && px<=14) ? ((px==1||px==14)?4'h1:((px>=3&&px<=6)||(px>=9&&px<=12)?4'hF:4'hC)) : 4'h0;
                    else if (py == 7) ROM[16][addr] = (px>=1 && px<=14) ? ((px==1||px==14)?4'h1:((px>=4&&px<=5)||(px>=10&&px<=11)?4'hF:4'hC)) : 4'h0;
                    else if (py == 8) ROM[16][addr] = (px>=1 && px<=14) ? ((px==1||px==14)?4'h1:4'hC) : 4'h0;
                    else if (py == 9) ROM[16][addr] = (px>=1 && px<=14) ? 4'h1 : 4'h0; // Borde interior de la cabeza
                    else if (py == 10) ROM[16][addr] = (px>=3 && px<=12) ? 4'h1 : 4'h0;
                    else if (py == 11) ROM[16][addr] = (px>=4 && px<=11) ? ((px==4||px==11)?4'h1:4'h7) : 4'h0; 
                    else if (py == 12) ROM[16][addr] = (px>=4 && px<=11) ? ((px==4||px==11)?4'h1:((px==5||px==10)?4'h1:4'h7)) : 4'h0; // Ojos
                    else if (py == 13) ROM[16][addr] = (px>=4 && px<=11) ? ((px==4||px==11)?4'h1:((px==5||px==10)?4'h1:4'h7)) : 4'h0; // Ojos
                    else if (py == 14) ROM[16][addr] = (px>=4 && px<=11) ? 4'h1 : 4'h0; // Base
                    else ROM[16][addr] = 4'h0;
                end


                // =============================================================
                // ID 32: GOOMBA
                // =============================================================
                begin
                    if (y >= 6 && y <= 22 && x >= 4 && x <= 27) begin
                        if (y == 6 || y == 22 || x == 4 || x == 27)
                            ROM[32][addr] = 4'h1;
                        else if (y >= 9 && y <= 12 && x >= 6 && x <= 12 && (y - 9) > (x - 6)/2)
                            ROM[32][addr] = 4'h1;
                        else if (y >= 9 && y <= 12 && x >= 19 && x <= 25 && (y - 9) > (25 - x)/2)
                            ROM[32][addr] = 4'h1;
                        else if (y >= 10 && y <= 14 && x >= 7 && x <= 11)
                            ROM[32][addr] = (y >= 11 && y <= 13 && x >= 8 && x <= 10) ? 4'hF : 4'h9;
                        else if (y >= 10 && y <= 14 && x >= 20 && x <= 24)
                            ROM[32][addr] = (y >= 11 && y <= 13 && x >= 21 && x <= 23) ? 4'hF : 4'h9;
                        else
                            ROM[32][addr] = 4'h9;
                    end
                    else if (y >= 23 && y <= 27 && ((x >= 4 && x <= 12) || (x >= 19 && x <= 27)))
                        ROM[32][addr] = (x == 4 || x == 12 || x == 19 || x == 27 || y == 27) ? 4'h1 : 4'h9;
                    else
                        ROM[32][addr] = 4'h0;
                end

                // =============================================================
                // ID 33: KOOPA TROOPA
                // =============================================================
                begin
                    if (y >= 4 && y <= 20 && x >= 5 && x <= 26) begin
                        if (y == 4 || y == 20 || x == 5 || x == 26)
                            ROM[33][addr] = 4'h1;
                        else if ((x + y) % 5 == 0)
                            ROM[33][addr] = 4'h3;
                        else
                            ROM[33][addr] = 4'h4;
                    end
                    else if (y >= 1 && y <= 4 && x >= 18 && x <= 25)
                        ROM[33][addr] = (y == 1 || x == 25) ? 4'h1 : 4'hE;
                    else if (y >= 21 && y <= 26 && ((x >= 6 && x <= 11) || (x >= 20 && x <= 25)))
                        ROM[33][addr] = 4'h4;
                    else
                        ROM[33][addr] = 4'h0;
                end

                // =============================================================
                // ID 34: GOOMBA APLASTADO
                // =============================================================
                begin
                    if (y >= 20 && y <= 28 && x >= 3 && x <= 28)
                        ROM[34][addr] = (y == 20 || y == 28 || x == 3 || x == 28) ? 4'h1 : 4'h9;
                    else
                        ROM[34][addr] = 4'h0;
                end

                // =============================================================
                // ID 64: MONEDA
                // =============================================================
                begin
                    if (y >= 6 && y <= 25 && x >= 9 && x <= 22) begin
                        if (y == 6 || y == 25 || x == 9 || x == 22)
                            ROM[64][addr] = 4'hB;
                        else if (x >= 11 && x <= 13 && y >= 8 && y <= 12)
                            ROM[64][addr] = 4'hF;
                        else
                            ROM[64][addr] = 4'hE;
                    end else
                        ROM[64][addr] = 4'h0;
                end

                // =============================================================
                // ID 65: HONGO ROJO (power-up viejo del array)
                // =============================================================
                begin
                    if (y >= 18 && y <= 28 && x >= 9 && x <= 22)
                        ROM[65][addr] = (y == 18 || y == 28 || x == 9 || x == 22) ? 4'h1 : 4'h7;
                    else if (y >= 4 && y <= 18 && x >= 2 && x <= 29) begin
                        if ((x >= 2 && x <= 5) || (x >= 26 && x <= 29))
                            ROM[65][addr] = (y > 12) ? 4'h0 : 4'hC;
                        else if (y == 4 && (x < 8 || x > 23))
                            ROM[65][addr] = 4'h0;
                        else if ((y >= 8 && y <= 12 && x >= 6 && x <= 10) ||
                                 (y >= 8 && y <= 12 && x >= 21 && x <= 25))
                            ROM[65][addr] = 4'hF;
                        else
                            ROM[65][addr] = 4'hC;
                    end else
                        ROM[65][addr] = 4'h0;
                end

                // =============================================================
                // ID 66: FLOR DE FUEGO
                // =============================================================
                begin
                    if (x >= 14 && x <= 17 && y >= 16 && y <= 31)
                        ROM[66][addr] = 4'h4;
                    else if (y >= 4 && y <= 18) begin
                        if ((y >= 4 && y <= 8 && x >= 12 && x <= 19) ||
                            (y >= 8 && y <= 12 && x >= 6 && x <= 25) ||
                            (y >= 12 && y <= 18 && x >= 10 && x <= 21))
                            ROM[66][addr] = (x >= 12 && x <= 19 && y >= 8 && y <= 14) ? 4'hF : 4'hC;
                        else
                            ROM[66][addr] = 4'h0;
                    end else
                        ROM[66][addr] = 4'h0;
                end

                // =============================================================
                // ID 67: ESTRELLA
                // =============================================================
                begin
                    if ((x >= 12 && x <= 19) || (y >= 12 && y <= 19))
                        ROM[67][addr] = 4'hE;
                    else if ((x >= 6 && x <= 10 && y >= 6 && y <= 10 && (x - 6) == (y - 6)) ||
                             (x >= 21 && x <= 25 && y >= 6 && y <= 10 && (x - 21) == (10 - y)) ||
                             (x >= 6 && x <= 10 && y >= 21 && y <= 25 && (x - 6) == (25 - y)) ||
                             (x >= 21 && x <= 25 && y >= 21 && y <= 25 && (x - 21) == (y - 21)))
                        ROM[67][addr] = 4'hE;
                    else
                        ROM[67][addr] = 4'h0;
                end

                // =============================================================
                // ID 96: NUBE PEQUEÑA (CS)
                // =============================================================
                begin
                    if (y >= 16 && y <= 28 && x >= 4 && x <= 27) begin
                        if ((x >= 8 && x <= 23 && y >= 12) || (y >= 20)) ROM[96][addr] = 4'hF; 
                        else ROM[96][addr] = 4'h0;
                    end else ROM[96][addr] = 4'h0;
                end

                // ==========================================
                // FIX NUBES (IDs 98, 99, 100)
                // ==========================================
                if (y >= 8 && y <= 24 && x >= 8) begin
                    if (y < 12 && x < 16) ROM[98][addr] = 4'h0; 
                    else ROM[98][addr] = 4'hF; 
                end else ROM[98][addr] = 4'h0;

                if (y >= 8 && y <= 24) ROM[99][addr] = 4'hF;
                else ROM[99][addr] = 4'h0;

                if (y >= 8 && y <= 24 && x <= 23) begin
                    if (y < 12 && x > 15) ROM[100][addr] = 4'h0; 
                    else ROM[100][addr] = 4'hF;
                end else ROM[100][addr] = 4'h0;

                // =============================================================
                // ID 101: ARBUSTO IZQUIERDO
                // =============================================================
                begin
                    if (y >= 16 && y <= 31 && x >= 2) begin
                        if (y >= 16 && y <= 22) begin
                            if (x >= 2 && x <= 12 && y >= 18)
                                ROM[101][addr] = 4'h4;
                            else if (x >= 13)
                                ROM[101][addr] = 4'h4;
                            else
                                ROM[101][addr] = 4'h0;
                        end else
                            ROM[101][addr] = 4'h4;
                    end else
                        ROM[101][addr] = 4'h0;
                end

                // ID 102: ARBUSTO CENTRO
                begin
                    if (y >= 16 && y <= 31) begin
                        if ((x >= 4 && x <= 27 && y >= 12) || (y >= 20)) ROM[102][addr] = 4'h4;
                        else ROM[102][addr] = 4'h0;
                    end else ROM[102][addr] = 4'h0;
                end

                // =============================================================
                // ID 103: ARBUSTO DERECHO
                // =============================================================
                begin
                    if (y >= 16 && y <= 31 && x <= 29) begin
                        if (y >= 16 && y <= 22) begin
                            if (x >= 19 && x <= 29 && y >= 18)
                                ROM[103][addr] = 4'h4;
                            else if (x < 19)
                                ROM[103][addr] = 4'h4;
                            else
                                ROM[103][addr] = 4'h0;
                        end else
                            ROM[103][addr] = 4'h4;
                    end else
                        ROM[103][addr] = 4'h0;
                end

                // ==========================================
                // NUEVOS CHUNKS: COLINAS Y CASTILLO
                // ==========================================
                if (y >= 31 - x && y >= x && y >= 16) ROM[104][addr] = 4'h4;
                else ROM[104][addr] = 4'h0;

                ROM[105][addr] = ROM[5][addr];
                if (x >= 8 && x <= 23 && y >= 8) begin
                    if (y < 16 && (x < 12 || x > 19)) ROM[105][addr] = 4'hB; 
                    else ROM[105][addr] = 4'h1;
                end

                ROM[106][addr] = ROM[5][addr];
                if (x >= 8 && x <= 23) ROM[106][addr] = 4'h1;

                ROM[107][addr] = ROM[5][addr];
                if (x >= 12 && x <= 19 && y >= 8 && y <= 23) ROM[107][addr] = 4'h1;

                // ==========================================
                // NUEVOS CHUNKS: ARBUSTOS OSCUROS / COLINAS
                // ==========================================
                if (y >= 8 && x >= 8) begin
                    if (y < 12 && x < 16) ROM[112][addr] = 4'h0; 
                    else ROM[112][addr] = 4'h3; 
                end else ROM[112][addr] = 4'h0;

                if (y >= 8) ROM[113][addr] = 4'h3;
                else ROM[113][addr] = 4'h0;

                if (y >= 8 && x <= 23) begin
                    if (y < 12 && x > 15) ROM[114][addr] = 4'h0; 
                    else ROM[114][addr] = 4'h3; 
                end else ROM[114][addr] = 4'h0;

                // =============================================================
                // ID 128: MARIO PEQUEÑO
                // =============================================================
                begin
                    if (y >= 2 && y <= 7 && x >= 8 && x <= 23)
                        ROM[128][addr] = (y == 2 && (x < 10 || x > 21)) ? 4'h0 : 4'hC;
                    else if (y >= 8 && y <= 13 && x >= 6 && x <= 25) begin
                        if (y >= 9 && y <= 11 && x >= 9 && x <= 11) ROM[128][addr] = 4'h1;
                        else if (y >= 9 && y <= 11 && x >= 19 && x <= 21) ROM[128][addr] = 4'h1;
                        else if (y == 13 && x >= 9 && x <= 22) ROM[128][addr] = 4'h1;
                        else ROM[128][addr] = 4'h7;
                    end
                    else if (y >= 14 && y <= 22 && x >= 5 && x <= 26) begin
                        if (y >= 18 && (x < 9 || x > 22)) ROM[128][addr] = 4'hC;
                        else ROM[128][addr] = 4'hC;
                    end
                    else if (y >= 23 && y <= 27) begin
                        if (x >= 5 && x <= 13) ROM[128][addr] = 4'hC;
                        else if (x >= 18 && x <= 26) ROM[128][addr] = 4'hC;
                        else ROM[128][addr] = 4'h0;
                    end
                    else if (y >= 28 && y <= 30) begin
                        if ((x >= 4 && x <= 14) || (x >= 17 && x <= 27))
                            ROM[128][addr] = 4'h9;
                        else
                            ROM[128][addr] = 4'h0;
                    end
                    else
                        ROM[128][addr] = 4'h0;
                end

                // =============================================================
                // ID 131: MARIO SALTANDO
                // =============================================================
                begin
                    if (y >= 2 && y <= 7 && x >= 8 && x <= 23)
                        ROM[131][addr] = (y == 2 && (x < 10 || x > 21)) ? 4'h0 : 4'hC;
                    else if (y >= 10 && y <= 14 && ((x >= 1 && x <= 5) || (x >= 26 && x <= 30)))
                        ROM[131][addr] = 4'h7;
                    else if (y >= 8 && y <= 13 && x >= 6 && x <= 25)
                        ROM[131][addr] = 4'h7;
                    else if (y >= 14 && y <= 22 && x >= 5 && x <= 26)
                        ROM[131][addr] = 4'hC;
                    else if (y >= 23 && y <= 30 && x >= 8 && x <= 23)
                        ROM[131][addr] = (y >= 28) ? 4'h9 : 4'hC;
                    else
                        ROM[131][addr] = 4'h0;
                end

                // =============================================================
                // ID 108-111: COLINAS Y RELLENO
                // =============================================================
                if (x == 31 - y) ROM[108][addr] = 4'h1; 
                else if (x > 31 - y) ROM[108][addr] = 4'h4; 
                else ROM[108][addr] = 4'h0;

                if (y == 16) ROM[109][addr] = 4'h1; 
                else if (y > 16) ROM[109][addr] = 4'h4; 
                else ROM[109][addr] = 4'h0;

                if (x == y) ROM[110][addr] = 4'h1; 
                else if (x < y) ROM[110][addr] = 4'h4; 
                else ROM[110][addr] = 4'h0;

                ROM[111][addr] = 4'h4;

            end // for x
        end // for y
    end // initial

    // =========================================================================
    // LECTURA SÍNCRONA — 1 ciclo de latencia
    // =========================================================================
    wire [9:0] addr_pixel = {pixel_y, pixel_x};

    always @(posedge clk) begin
        pixel_data <= ROM[chunk_id][addr_pixel];
    end

endmodule

