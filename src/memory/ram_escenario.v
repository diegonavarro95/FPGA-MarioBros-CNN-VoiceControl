`timescale 1ns / 1ps
// =============================================================================
// RAM_ESCENARIO.V  —  Nivel 1-1 Super Mario Bros (NES) — Layout 1:1
// =============================================================================
//
// FUENTE DEL MAPA: datos del ROM real del NES (L_GroundArea6) + verificación
// con nesmaps.com, mariowiki.com y el ensamblador descompilado (smbdis.asm).
//
// SISTEMA DE COORDENADAS (idéntico al NES):
//   Fila  0-1  : cielo (vacío / nubes decorativas)
//   Fila  2    : nivel alto de bloques elevados
//   Fila  3    : nivel bajo de bloques elevados (¿? y ladrillos)
//   Fila  4    : espacio abierto
//   Fila  5    : hilera de bloques BR/QQ altos
//   Fila  8    : hilera de bloques BR/QQ bajos
//   Fila  9-10 : topes y cuerpos de tuberías altas
//   Fila 11    : topes de tuberías normales / cuerpos de tuberías altas
//   Fila 12    : bases de tuberías + arbustos decorativos
//   Fila 13    : suelo superior (con hoyos)
//   Fila 14    : suelo inferior (siempre sólido)
//
// INTERFAZ (compatible con top-mario.v del compañero):
//   screen_tile_x [4:0]  : tile visible en X (0-19)
//   screen_tile_y [3:0]  : tile visible en Y (0-14)
//   scroll_offset [7:0]  : desplazamiento en tiles (0-192)
//   chunk_id      [7:0]  : ID del sprite (→ rom_chunks_mario)
//   is_solid             : 1 si el tile es colisionable
//
// LATENCIA: 1 ciclo de reloj
// =============================================================================

module ram_escenario (
    input  wire        clk,
    input  wire [4:0]  screen_tile_x,
    input  wire [3:0]  screen_tile_y,
    input  wire [7:0]  scroll_offset,
    output reg  [7:0]  chunk_id,
    output reg         is_solid
);

    localparam MAP_W = 212;
    localparam MAP_H = 15;

    // IDs de chunks — deben coincidir con rom_chunks_mario.v
    localparam [7:0]
        E   = 8'h00,  // vacío / cielo
        BR  = 8'h01,  // ladrillo rompible
        QQ  = 8'h02,  // bloque pregunta (?)
        GR  = 8'h03,  // suelo
        ST  = 8'h04,  // escalera (stair)
        CA  = 8'h05,  // castillo
        BU  = 8'h06,  // ladrillo ya golpeado
        FP  = 8'h08,  // asta de bandera (pole)
        FL  = 8'h09,  // bandera
        TL  = 8'h0A,  // tubería tope izquierdo
        TR  = 8'h0B,  // tubería tope derecho
        PL  = 8'h0C,  // tubería cuerpo izquierdo
        PR  = 8'h0D,  // tubería cuerpo derecho
        NL  = 8'h62,  // nube izquierda
        NC  = 8'h63,  // nube centro
        NR  = 8'h64,  // nube derecha
        CS  = 8'h60,  // nube pequeña (cloud small)
        BsL = 8'h65,  // arbusto izquierdo
        BsC = 8'h66,  // arbusto centro
        BsR = 8'h67,  // arbusto derecho
        HL  = 8'h68;  // colina pequeña

    // =========================================================================
    // MAPA DEL NIVEL — 212 cols x 15 filas
    // =========================================================================
    reg [7:0] MAP [0:MAP_H-1][0:MAP_W-1];

    integer r, c;
    initial begin

        // --- 1. Rellenar todo con cielo vacío ---
        for (r = 0; r < MAP_H; r = r + 1)
            for (c = 0; c < MAP_W; c = c + 1)
                MAP[r][c] = E;

        // --- 2. Suelo: filas 13-14 completas ---
        for (c = 0; c < MAP_W; c = c + 1) begin
            MAP[13][c] = GR;
            MAP[14][c] = GR;
        end

        // --- 3. Hoyos en fila 13 (fila 14 siempre sólida) ---
        // Hoyo 1: columnas 63-65
        MAP[13][63]=E; MAP[13][64]=E; MAP[13][65]=E;
        // Hoyo 2: columnas 108-112
        MAP[13][108]=E; MAP[13][109]=E; MAP[13][110]=E;
        MAP[13][111]=E; MAP[13][112]=E;

        // =====================================================================
        // TUBERÍAS — layout exacto del ROM
        // Tubería 1: 2 tiles alto (cols 0-1)
        MAP[11][0]=TL; MAP[11][1]=TR;
        MAP[12][0]=PL; MAP[12][1]=PR;

        // Tubería 2: 3 tiles alto (cols 4-5)
        MAP[10][4]=TL; MAP[10][5]=TR;
        MAP[11][4]=PL; MAP[11][5]=PR;
        MAP[12][4]=PL; MAP[12][5]=PR;

        // Tubería 3: 3 tiles alto (cols 7-8)
        MAP[10][7]=TL; MAP[10][8]=TR;
        MAP[11][7]=PL; MAP[11][8]=PR;
        MAP[12][7]=PL; MAP[12][8]=PR;

        // Tubería 4: 4 tiles alto (cols 16-17)
        MAP[ 9][16]=TL; MAP[ 9][17]=TR;
        MAP[10][16]=PL; MAP[10][17]=PR;
        MAP[11][16]=PL; MAP[11][17]=PR;
        MAP[12][16]=PL; MAP[12][17]=PR;

        // Tubería 5: 3 tiles alto (cols 32-33)
        MAP[10][32]=TL; MAP[10][33]=TR;
        MAP[11][32]=PL; MAP[11][33]=PR;
        MAP[12][32]=PL; MAP[12][33]=PR;

        // Tubería 6: 3 tiles alto (cols 57-58)
        MAP[10][57]=TL; MAP[10][58]=TR;
        MAP[11][57]=PL; MAP[11][58]=PR;
        MAP[12][57]=PL; MAP[12][58]=PR;

        // Tubería 7: 2 tiles alto (cols 65-66, después del hoyo 2)
        MAP[11][65]=TL; MAP[11][66]=TR;
        MAP[12][65]=PL; MAP[12][66]=PR;

        // Tubería 8: 2 tiles alto (cols 86-87)
        MAP[11][86]=TL; MAP[11][87]=TR;
        MAP[12][86]=PL; MAP[12][87]=PR;

        // =====================================================================
        // HILERA DE BLOQUES ALTOS — fila 5
        // Secuencia exacta del ROM:
        //   BR en 16, QQ(hongo) en 19, BR en 20, QQ en 22, BR en 23, QQ en 24, BR en 27
        MAP[5][16]=BR;
        MAP[5][19]=QQ; // Hongo mágico
        MAP[5][20]=BR;
        MAP[5][22]=QQ; // Estrella oculta (hit desde abajo cuando pequeño) / moneda
        MAP[5][23]=BR;
        MAP[5][24]=QQ; // Moneda
        MAP[5][27]=BR;

        // Bloque QQ con power-up (col 78, fila 5) — sobre tubería 4 aprox
        MAP[5][78]=QQ;

        // Grupo de ladrillos y QQ (cols 80-84, fila 5)
        MAP[5][80]=BR; MAP[5][81]=BR;
        MAP[5][82]=QQ;
        MAP[5][83]=BR; MAP[5][84]=BR;

        // QQ solitario col 101
        MAP[5][101]=QQ;

        // Dos ladrillos cols 110-111
        MAP[5][110]=BR; MAP[5][111]=BR;

        // Tres ladrillos cols 140-142
        MAP[5][140]=BR; MAP[5][141]=BR; MAP[5][142]=BR;

        // =====================================================================
        // HILERA DE BLOQUES BAJOS — fila 8
        // 3 bloques QQ en cols 3-5 (monedas)
        MAP[8][3]=QQ; MAP[8][4]=QQ; MAP[8][5]=QQ;

        // Ladrillos en cols 55-56
        MAP[8][55]=BR; MAP[8][56]=BR;

        // 4 ladrillos en cols 65-68
        MAP[8][65]=BR; MAP[8][66]=BR; MAP[8][67]=BR; MAP[8][68]=BR;

        // 3 ladrillos en cols 90-92
        MAP[8][90]=BR; MAP[8][91]=BR; MAP[8][92]=BR;

        // =====================================================================
        // NUBES DECORATIVAS — fila 1 (no sólidas)
        // Nubes grandes (3 tiles: NL NC NR)
        MAP[1][1]=NL;  MAP[1][2]=NC;  MAP[1][3]=NR;
        MAP[1][16]=NL; MAP[1][17]=NC; MAP[1][18]=NR;
        MAP[1][24]=NL; MAP[1][25]=NC; MAP[1][26]=NR;
        MAP[1][40]=NL; MAP[1][41]=NC; MAP[1][42]=NR;
        MAP[1][56]=NL; MAP[1][57]=NC; MAP[1][58]=NR;
        MAP[1][71]=NL; MAP[1][72]=NC; MAP[1][73]=NR;
        MAP[1][86]=NL; MAP[1][87]=NC; MAP[1][88]=NR;
        MAP[1][101]=NL; MAP[1][102]=NC; MAP[1][103]=NR;
        MAP[1][116]=NL; MAP[1][117]=NC; MAP[1][118]=NR;
        MAP[1][131]=NL; MAP[1][132]=NC; MAP[1][133]=NR;
        MAP[1][146]=NL; MAP[1][147]=NC; MAP[1][148]=NR;
        MAP[1][161]=NL; MAP[1][162]=NC; MAP[1][163]=NR;
        MAP[1][176]=NL; MAP[1][177]=NC; MAP[1][178]=NR;
        MAP[1][191]=NL; MAP[1][192]=NC; MAP[1][193]=NR;

        // Nubes pequeñas (1 tile: CS)
        MAP[1][9]=CS;   MAP[1][33]=CS;  MAP[1][49]=CS;
        MAP[1][65]=CS;  MAP[1][80]=CS;  MAP[1][95]=CS;
        MAP[1][110]=CS; MAP[1][125]=CS; MAP[1][140]=CS;
        MAP[1][155]=CS; MAP[1][170]=CS; MAP[1][185]=CS;

        // =====================================================================
        // ARBUSTOS DECORATIVOS — fila 12 (sobre el suelo, no sólidos)
        // Arbustos de 3 tiles (BsL BsC BsR)
        MAP[12][3]=BsL;  MAP[12][4]=BsC;  MAP[12][5]=BsR;
        MAP[12][37]=BsL; MAP[12][38]=BsC; MAP[12][39]=BsR;
        MAP[12][52]=BsL; MAP[12][53]=BsC; MAP[12][54]=BsR;
        MAP[12][77]=BsL; MAP[12][78]=BsC; MAP[12][79]=BsR;
        MAP[12][93]=BsL; MAP[12][94]=BsC; MAP[12][95]=BsR;

        // =====================================================================
        // ESCALERAS FINALES — estructura piramidal antes del asta
        // Cuatro escaleras de 4 steps cada una
        // Escalera A (cols 168-171): step 1=1tile alto, step 2=2tiles, etc.
        MAP[13][168]=ST;
        MAP[12][169]=ST; MAP[13][169]=ST;
        MAP[11][170]=ST; MAP[12][170]=ST; MAP[13][170]=ST;
        MAP[10][171]=ST; MAP[11][171]=ST; MAP[12][171]=ST; MAP[13][171]=ST;

        // Escalera B (cols 175-178): escaleras descendentes
        MAP[10][175]=ST; MAP[11][175]=ST; MAP[12][175]=ST; MAP[13][175]=ST;
        MAP[11][176]=ST; MAP[12][176]=ST; MAP[13][176]=ST;
        MAP[12][177]=ST; MAP[13][177]=ST;
        MAP[13][178]=ST;

        // Escalera final hacia castillo (cols 184-191): sube 8 steps
        MAP[13][184]=ST;
        MAP[12][185]=ST; MAP[13][185]=ST;
        MAP[11][186]=ST; MAP[12][186]=ST; MAP[13][186]=ST;
        MAP[10][187]=ST; MAP[11][187]=ST; MAP[12][187]=ST; MAP[13][187]=ST;
        MAP[ 9][188]=ST; MAP[10][188]=ST; MAP[11][188]=ST; MAP[12][188]=ST; MAP[13][188]=ST;
        MAP[ 8][189]=ST; MAP[ 9][189]=ST; MAP[10][189]=ST; MAP[11][189]=ST; MAP[12][189]=ST; MAP[13][189]=ST;
        MAP[ 7][190]=ST; MAP[ 8][190]=ST; MAP[ 9][190]=ST; MAP[10][190]=ST; MAP[11][190]=ST; MAP[12][190]=ST; MAP[13][190]=ST;
        MAP[ 6][191]=ST; MAP[ 7][191]=ST; MAP[ 8][191]=ST; MAP[ 9][191]=ST; MAP[10][191]=ST; MAP[11][191]=ST; MAP[12][191]=ST; MAP[13][191]=ST;

        // =====================================================================
        // ASTA DE BANDERA (col 198, filas 4-12)
        MAP[ 4][198]=FP; MAP[ 5][198]=FP; MAP[ 6][198]=FP;
        MAP[ 7][198]=FP; MAP[ 8][198]=FP; MAP[ 9][198]=FP;
        MAP[10][198]=FP; MAP[11][198]=FP; MAP[12][198]=FP;
        // Bandera en la cima
        MAP[4][197]=FL;

        // =====================================================================
        // CASTILLO (cols 200-211, filas 8-14)
        // Estructura básica del castillo
        for (c = 200; c <= 211; c = c + 1) begin
            MAP[8][c]=CA; MAP[9][c]=CA; MAP[10][c]=CA;
            MAP[11][c]=CA; MAP[12][c]=CA; MAP[13][c]=CA;
        end
        // Almenas superiores del castillo (espacios en fila 8)
        MAP[8][200]=CA; MAP[8][201]=E;
        MAP[8][202]=CA; MAP[8][203]=E;
        MAP[8][204]=CA; MAP[8][205]=E;
        MAP[8][206]=CA; MAP[8][207]=E;
        MAP[8][208]=CA; MAP[8][209]=E;
        MAP[8][210]=CA; MAP[8][211]=CA;
        // Puerta del castillo (cols 203-205, filas 11-13)
        MAP[11][204]=E; MAP[11][205]=E;
        MAP[12][204]=E; MAP[12][205]=E;
        MAP[13][204]=E; MAP[13][205]=E;

    end // initial

    // =========================================================================
    // LÓGICA SÍNCRONA DE LECTURA — 1 ciclo de latencia
    // col_abs y la lectura de MAP en el MISMO flanco para evitar glitches
    // =========================================================================
    reg [7:0] tid;
    reg [8:0] col_abs_r;

    always @(posedge clk) begin
        col_abs_r = {1'b0, scroll_offset} + {4'b0, screen_tile_x};
        if (col_abs_r >= MAP_W || screen_tile_y >= MAP_H)
            tid <= E;
        else
            tid <= MAP[screen_tile_y][col_abs_r[7:0]];
    end

    // =========================================================================
    // SALIDAS COMBINACIONALES — chunk_id e is_solid siguen a tid sin latencia
    // =========================================================================
    always @(*) begin
        chunk_id = tid;
        case (tid)
            BR, QQ, GR, ST, CA, BU, 8'h07,
            TL, TR, PL, PR, 8'h0E, 8'h0F : is_solid = 1'b1;
            default                        : is_solid = 1'b0;
        endcase
    end

endmodule

