`timescale 1ns / 1ps
// RAM_ESCENARIO.V
// Módulo de mapa del nivel para Super Mario Bros - Nivel 1-1
module ram_escenario (
    input  wire        clk,
    input  wire [4:0]  screen_tile_x, // 0 a 19
    input  wire [3:0]  screen_tile_y, // 0 a 14
    input  wire [7:0]  scroll_offset, // 0 a 211
    output reg  [7:0]  chunk_id,      // ID del sprite
    output reg         is_solid       // 1 = colisión sólida
);

    // -------------------------------------------------------------------------
    // CONSTANTES DEL NIVEL
    // -------------------------------------------------------------------------
    localparam MAP_WIDTH  = 212;
    localparam MAP_HEIGHT = 15;

    // Shorthand para chunk IDs frecuentes
    localparam [7:0] E   = 8'h00, // vacío
                     BR  = 8'h01, // brick (ladrillo)
                     QQ  = 8'h02, // question block
                     GR  = 8'h03, // ground (suelo)
                     ST  = 8'h04, // stair block
                     CA  = 8'h05, // castle block
                     BU  = 8'h06, // brick used
                     FP  = 8'h08, // flag pole
                     FL  = 8'h09, // flag
                     TL  = 8'h0A, // pipe top left
                     TR  = 8'h0B, // pipe top right
                     PL  = 8'h0C, // pipe body left
                     PR  = 8'h0D, // pipe body right
                     GO  = 8'h20, // goomba
                     CO  = 8'h40, // coin
                     CL  = 8'h60, // cloud small
                     BH  = 8'h61, // bush
                     NL  = 8'h62, // cloud left
                     NC  = 8'h63, // cloud center
                     NR  = 8'h64, // cloud right
                     BL  = 8'h65, // bush left
                     BC  = 8'h66, // bush center
                     BR2 = 8'h67, // bush right
                     HL  = 8'h68; // hill small

    // -------------------------------------------------------------------------
    // MEMORIA DEL MAPA (212 x 15)
    // -------------------------------------------------------------------------
    reg [7:0] LEVEL_MAP [0:MAP_HEIGHT-1][0:MAP_WIDTH-1];

    integer r, c;
    initial begin
        // 1. Llenar todo el nivel con Cielo (E) por defecto
        for (r = 0; r < MAP_HEIGHT; r = r + 1) begin
            for (c = 0; c < MAP_WIDTH; c = c + 1) begin
                LEVEL_MAP[r][c] = E;
            end
        end

        // 2. Filas 13 y 14: Llenar completamente de Suelo (GR)
        for (c = 0; c < MAP_WIDTH; c = c + 1) begin
            LEVEL_MAP[13][c] = GR;
            LEVEL_MAP[14][c] = GR;
        end

        // 3. Modificar la Fila 13 para agregar los hoyos
        LEVEL_MAP[13][63] = E; LEVEL_MAP[13][64] = E; LEVEL_MAP[13][65] = E;
        LEVEL_MAP[13][108] = E; LEVEL_MAP[13][109] = E; LEVEL_MAP[13][110] = E; LEVEL_MAP[13][111] = E; LEVEL_MAP[13][112] = E;

        // 4. Fila 1: Nubes
        // Nubes pequeñas
        LEVEL_MAP[1][9]=CL; LEVEL_MAP[1][33]=CL; LEVEL_MAP[1][49]=CL; LEVEL_MAP[1][65]=CL; LEVEL_MAP[1][80]=CL; LEVEL_MAP[1][95]=CL;
        LEVEL_MAP[1][110]=CL; LEVEL_MAP[1][125]=CL; LEVEL_MAP[1][140]=CL; LEVEL_MAP[1][155]=CL; LEVEL_MAP[1][170]=CL; LEVEL_MAP[1][185]=CL;
        // Nubes grandes
        LEVEL_MAP[1][1]=NL; LEVEL_MAP[1][2]=NC; LEVEL_MAP[1][3]=NR;
        LEVEL_MAP[1][16]=NL; LEVEL_MAP[1][17]=NC; LEVEL_MAP[1][18]=NR;
        LEVEL_MAP[1][24]=NL; LEVEL_MAP[1][25]=NC; LEVEL_MAP[1][26]=NR;
        LEVEL_MAP[1][40]=NL; LEVEL_MAP[1][41]=NC; LEVEL_MAP[1][42]=NR;
        LEVEL_MAP[1][56]=NL; LEVEL_MAP[1][57]=NC; LEVEL_MAP[1][58]=NR;
        LEVEL_MAP[1][71]=NL; LEVEL_MAP[1][72]=NC; LEVEL_MAP[1][73]=NR;
        LEVEL_MAP[1][86]=NL; LEVEL_MAP[1][87]=NC; LEVEL_MAP[1][88]=NR;
        LEVEL_MAP[1][101]=NL; LEVEL_MAP[1][102]=NC; LEVEL_MAP[1][103]=NR;
        LEVEL_MAP[1][116]=NL; LEVEL_MAP[1][117]=NC; LEVEL_MAP[1][118]=NR;
        LEVEL_MAP[1][131]=NL; LEVEL_MAP[1][132]=NC; LEVEL_MAP[1][133]=NR;
        LEVEL_MAP[1][146]=NL; LEVEL_MAP[1][147]=NC; LEVEL_MAP[1][148]=NR;
        LEVEL_MAP[1][161]=NL; LEVEL_MAP[1][162]=NC; LEVEL_MAP[1][163]=NR;
        LEVEL_MAP[1][176]=NL; LEVEL_MAP[1][177]=NC; LEVEL_MAP[1][178]=NR;
        LEVEL_MAP[1][191]=NL; LEVEL_MAP[1][192]=NC; LEVEL_MAP[1][193]=NR;

        // 5. Fila 5: Bloques elevados (Ladrillos y ? )
        LEVEL_MAP[5][16]=BR; LEVEL_MAP[5][20]=BR; LEVEL_MAP[5][23]=BR; LEVEL_MAP[5][27]=BR; LEVEL_MAP[5][80]=BR; LEVEL_MAP[5][81]=BR; LEVEL_MAP[5][83]=BR; LEVEL_MAP[5][110]=BR; LEVEL_MAP[5][111]=BR; LEVEL_MAP[5][140]=BR; LEVEL_MAP[5][141]=BR; LEVEL_MAP[5][142]=BR;
        LEVEL_MAP[5][19]=QQ; LEVEL_MAP[5][22]=QQ; LEVEL_MAP[5][24]=QQ; LEVEL_MAP[5][78]=QQ; LEVEL_MAP[5][82]=QQ; LEVEL_MAP[5][101]=QQ;

        // 6. Fila 8: Bloques bajos
        LEVEL_MAP[8][3]=QQ; LEVEL_MAP[8][4]=QQ; LEVEL_MAP[8][5]=QQ;
        LEVEL_MAP[8][55]=BR; LEVEL_MAP[8][56]=BR; LEVEL_MAP[8][65]=BR; LEVEL_MAP[8][66]=BR; LEVEL_MAP[8][67]=BR; LEVEL_MAP[8][68]=BR; LEVEL_MAP[8][90]=BR; LEVEL_MAP[8][91]=BR; LEVEL_MAP[8][92]=BR;

        // 7. Fila 9: Cuerpos altos de Tuberías
        LEVEL_MAP[9][16]=PL; LEVEL_MAP[9][17]=PR;
        LEVEL_MAP[9][32]=PL; LEVEL_MAP[9][33]=PR;

        // 8. Fila 10: Cuerpos medios de Tuberías
        LEVEL_MAP[10][4]=PL; LEVEL_MAP[10][5]=PR;
        LEVEL_MAP[10][7]=PL; LEVEL_MAP[10][8]=PR;
        LEVEL_MAP[10][16]=PL; LEVEL_MAP[10][17]=PR;
        LEVEL_MAP[10][32]=PL; LEVEL_MAP[10][33]=PR;

        // 9. Fila 11: Topes de Tuberías
        LEVEL_MAP[11][0]=TL; LEVEL_MAP[11][1]=TR;
        LEVEL_MAP[11][4]=TL; LEVEL_MAP[11][5]=TR;
        LEVEL_MAP[11][7]=TL; LEVEL_MAP[11][8]=TR;
        LEVEL_MAP[11][16]=TL; LEVEL_MAP[11][17]=TR;
        LEVEL_MAP[11][32]=TL; LEVEL_MAP[11][33]=TR;

        // 10. Fila 12: Base de tuberías, Arbustos, Escaleras y Castillo
        LEVEL_MAP[12][0]=PL; LEVEL_MAP[12][1]=PR; LEVEL_MAP[12][4]=PL; LEVEL_MAP[12][5]=PR; LEVEL_MAP[12][7]=PL; LEVEL_MAP[12][8]=PR; LEVEL_MAP[12][16]=PL; LEVEL_MAP[12][17]=PR; LEVEL_MAP[12][32]=PL; LEVEL_MAP[12][33]=PR;
        
        LEVEL_MAP[12][3]=BL; LEVEL_MAP[12][6]=BC; LEVEL_MAP[12][9]=BR2;
        LEVEL_MAP[12][37]=BL; LEVEL_MAP[12][38]=BC; LEVEL_MAP[12][39]=BR2;
        LEVEL_MAP[12][52]=BL; LEVEL_MAP[12][53]=BC; LEVEL_MAP[12][54]=BR2;
        
        LEVEL_MAP[12][187]=ST; LEVEL_MAP[12][188]=ST; LEVEL_MAP[12][189]=ST; LEVEL_MAP[12][190]=ST; LEVEL_MAP[12][191]=ST; LEVEL_MAP[12][192]=ST; LEVEL_MAP[12][193]=ST; LEVEL_MAP[12][194]=ST; LEVEL_MAP[12][195]=ST; LEVEL_MAP[12][196]=ST;
        LEVEL_MAP[12][198]=FP;
        LEVEL_MAP[12][200]=CA; LEVEL_MAP[12][201]=CA; LEVEL_MAP[12][202]=CA; LEVEL_MAP[12][203]=CA; LEVEL_MAP[12][204]=CA;
    end

    // -------------------------------------------------------------------------
    // LÓGICA SÍNCRONA DE LECTURA DE MEMORIA
    // -------------------------------------------------------------------------
    // ELIMINE esta línea (era combinacional y glitchy):
    // wire [8:0] col_abs = scroll_offset + screen_tile_x;
    reg  [7:0] tid;

    // REEMPLAZAR el bloque always por esto:
    reg [8:0] col_abs_reg;

    always @(posedge clk) begin
        col_abs_reg = scroll_offset + screen_tile_x;   // se calcula y usa en el MISMO flanco

        if (col_abs_reg >= MAP_WIDTH || screen_tile_y >= MAP_HEIGHT) begin
            tid <= E;
        end else begin
            tid <= LEVEL_MAP[screen_tile_y][col_abs_reg];
        end
    end

    // GENERACIÓN DE BANDERA DE COLISIÓN (Equivalente a tu función en VHDL)
    always @(*) begin
        chunk_id = tid;
        case(tid)
            // Sólidos: Ladrillos, Suelo, Cajas de ?, Escaleras, Castillo y Tuberías
            BR, QQ, GR, ST, CA, BU, 8'h07, TL, TR, PL, PR, 8'h0E, 8'h0F: 
                is_solid = 1'b1;
            default: 
                is_solid = 1'b0; // Vacío, nubes, monedas o decoraciones
        endcase
    end

endmodule

