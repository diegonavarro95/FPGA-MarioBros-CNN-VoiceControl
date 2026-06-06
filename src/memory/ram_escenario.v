`timescale 1ns / 1ps
// =============================================================================
// RAM_ESCENARIO.V  —  Nivel 1-1 Super Mario Bros (NES) - RECREACIÓN EXACTA
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

    // Diccionario Completo
    localparam [7:0]
        E   = 8'h00,  BR  = 8'h01,  QQ  = 8'h02,  GR  = 8'h03,
        ST  = 8'h04,  CA  = 8'h05,  BU  = 8'h06,  FP  = 8'h08,
        FL  = 8'h09,  TL  = 8'h0A,  TR  = 8'h0B,  PL  = 8'h0C,
        PR  = 8'h0D,  NL  = 8'h62,  NC  = 8'h63,  NR  = 8'h64,
        CS  = 8'h60,  BsL = 8'h65,  BsC = 8'h66,  BsR = 8'h67,
        C_DT= 8'h69,  C_DB= 8'h6A,  C_WN= 8'h6B,  
        H_SL= 8'h6C,  H_SC= 8'h6D,  H_SR= 8'h6E,  H_FL= 8'h6F,
        DBL = 8'h70,  DBC = 8'h71,  DBR = 8'h72;

    reg [7:0] MAP [0:MAP_H-1][0:MAP_W-1];
    integer r, c, i;

    initial begin
        // 1. CIELO Y SUELO BASE
        for (r = 0; r < MAP_H; r = r + 1)
            for (c = 0; c < MAP_W; c = c + 1)
                MAP[r][c] = (r >= 13) ? GR : E;

        // 2. FOSOS
        for (r = 13; r <= 14; r = r + 1) begin
            MAP[r][69]=E;  MAP[r][70]=E;
            MAP[r][86]=E;  MAP[r][87]=E;  MAP[r][88]=E;
            MAP[r][153]=E; MAP[r][154]=E;
        end

        // 3. DECORACIÓN DE FONDO (Sin colinas)
        for (i = 0; i < MAP_W; i = i + 48) begin
            if (i+40 < MAP_W) begin
                // Nubes Pequeñas y Grandes
                MAP[3][i+8]=CS;   MAP[2][i+36]=CS;
                MAP[2][i+19]=NL;  MAP[2][i+20]=NC; MAP[2][i+21]=NR;
                MAP[3][i+27]=NL;  MAP[3][i+28]=NR;
                // Arbustos
                MAP[12][i+11]=BsL; MAP[12][i+12]=BsC; MAP[12][i+13]=BsR;
                MAP[12][i+23]=BsC; MAP[12][i+41]=BsL; MAP[12][i+42]=BsR;
            end
        end

        //Primeros Arbustos Osuros (Que simulan COlina)
        MAP[12][0] = DBL; MAP[12][1] = DBC; MAP[12][2] = DBR;
        //Otra colina
        MAP[12][16] = DBL; MAP[12][17] = DBR;
        MAP[12][48] = DBL; MAP[12][49] = DBC; MAP[12][50] = DBR;
        MAP[12][63] = DBL; MAP[12][64] = DBC; MAP[12][65] = DBR;

        // 4. TUBERÍAS
        MAP[11][28]=TL; MAP[11][29]=TR; MAP[12][28]=PL; MAP[12][29]=PR;
        MAP[10][38]=TL; MAP[10][39]=TR; MAP[11][38]=PL; MAP[11][39]=PR; MAP[12][38]=PL; MAP[12][39]=PR;
        MAP[9][46]=TL; MAP[9][47]=TR; MAP[10][46]=PL; MAP[10][47]=PR; MAP[11][46]=PL; MAP[11][47]=PR; MAP[12][46]=PL; MAP[12][47]=PR;
        MAP[9][57]=TL; MAP[9][58]=TR; MAP[10][57]=PL; MAP[10][58]=PR; MAP[11][57]=PL; MAP[11][58]=PR; MAP[12][57]=PL; MAP[12][58]=PR;
        MAP[11][163]=TL; MAP[11][164]=TR; MAP[12][163]=PL; MAP[12][164]=PR;
        MAP[11][179]=TL; MAP[11][180]=TR; MAP[12][179]=PL; MAP[12][180]=PR;

        // 5. BLOQUES DE INTERROGACIÓN Y LADRILLOS (Corregidos)
        MAP[9][16]=QQ;
        MAP[9][20]=BR; MAP[9][21]=QQ; MAP[9][22]=BR; MAP[9][23]=QQ; MAP[9][24]=BR;
        MAP[5][22]=QQ;
        MAP[9][77]=BR; MAP[9][78]=QQ; MAP[9][79]=BR;
        for(c=80; c<=87; c=c+1) MAP[5][c]=BR; // 8 ladrillos altos
        MAP[5][91]=BR; MAP[5][92]=BR; MAP[5][93]=BR; MAP[5][94]=QQ;

        MAP[9][94]=BR;
        MAP[9][100]=BR; 
        MAP[9][101]=BR; //Aqui debe de haber una estrella oculta
        //Colina Grande
        MAP[12][96]=DBL; MAP[12][97]=DBC; MAP[12][98]=DBC; MAP[12][99]=DBC; MAP[12][100]=DBR; 

        MAP[9][106]=QQ; 
        MAP[9][109]=QQ; MAP[5][109]=QQ; // Moneda baja y alta
        MAP[9][112]=QQ;
        MAP[9][118]=BR;
        //Colina
        MAP[12][110]=DBL;
        MAP[12][111]=DBC;
        MAP[12][112]=DBR;
        
        MAP[5][121]=BR; MAP[5][122]=BR; MAP[5][123]=BR; 
        
        MAP[5][128]=BR; MAP[5][129]=QQ; MAP[5][130]=QQ; MAP[5][131]=BR;
        MAP[9][129]=BR; MAP[9][130]=BR; 
        MAP[9][168]=BR; MAP[9][169]=BR; MAP[9][170]=QQ; MAP[9][171]=BR;

        MAP[12][168]=BsR;

        // 6. ESCALERAS (Asignadas estáticamente para evitar alturas incorrectas)
        MAP[12][134]=ST; 
        MAP[12][135]=ST; MAP[11][135]=ST;
        MAP[12][136]=ST; MAP[11][136]=ST; MAP[10][136]=ST;
        MAP[12][137]=ST; MAP[11][137]=ST; MAP[10][137]=ST; MAP[9][137]=ST;
        //Arbusto de enmedio:
        MAP[12][139]=BsR;
        //Continua escaleras
        MAP[12][140]=ST; MAP[11][140]=ST; MAP[10][140]=ST; MAP[9][140]=ST;
        MAP[12][141]=ST; MAP[11][141]=ST; MAP[10][141]=ST;
        MAP[12][142]=ST; MAP[11][142]=ST;
        MAP[12][143]=ST;

        //Arbustos oscuros(simular colinas)
        MAP[12][144]=DBL; MAP[12][145]=DBC; MAP[12][146]=DBC; MAP[12][147]=DBR;

        //Continuan Escaleras
        MAP[12][148]=ST;
        MAP[12][149]=ST; MAP[11][149]=ST;
        MAP[12][150]=ST; MAP[11][150]=ST; MAP[10][150]=ST;
        MAP[12][151]=ST; MAP[11][151]=ST; MAP[10][151]=ST; MAP[9][151]=ST;
        MAP[12][152]=ST; MAP[11][152]=ST; MAP[10][152]=ST; MAP[9][152]=ST; // Tope plano altura 4

        MAP[12][155]=ST; MAP[11][155]=ST; MAP[10][155]=ST; MAP[9][155]=ST;
        MAP[12][156]=ST; MAP[11][156]=ST; MAP[10][156]=ST;
        MAP[12][157]=ST; MAP[11][157]=ST;
        MAP[12][158]=ST;

        //Arbusto pequeno en termino de escaleras
        MAP[12][159]=BsR;

        //Arbustos oscuros(simular colina)
        MAP[12][160]=DBL; MAP[12][161]=DBC; MAP[12][162]=DBR;

        MAP[12][181]=ST;
        MAP[12][182]=ST; MAP[11][182]=ST;
        MAP[12][183]=ST; MAP[11][183]=ST; MAP[10][183]=ST;
        MAP[12][184]=ST; MAP[11][184]=ST; MAP[10][184]=ST; MAP[9][184]=ST;
        MAP[12][185]=ST; MAP[11][185]=ST; MAP[10][185]=ST; MAP[9][185]=ST; MAP[8][185]=ST;
        MAP[12][186]=ST; MAP[11][186]=ST; MAP[10][186]=ST; MAP[9][186]=ST; MAP[8][186]=ST; MAP[7][186]=ST;
        MAP[12][187]=ST; MAP[11][187]=ST; MAP[10][187]=ST; MAP[9][187]=ST; MAP[8][187]=ST; MAP[7][187]=ST; MAP[6][187]=ST;
        MAP[12][188]=ST; MAP[11][188]=ST; MAP[10][188]=ST; MAP[9][188]=ST; MAP[8][188]=ST; MAP[7][188]=ST; MAP[6][188]=ST; MAP[5][188]=ST;
        MAP[12][189]=ST; MAP[11][189]=ST; MAP[10][189]=ST; MAP[9][189]=ST; MAP[8][189]=ST; MAP[7][189]=ST; MAP[6][189]=ST; MAP[5][189]=ST;

        //Arbusto oscuro grandote(colina)
        MAP[12][192]=DBL; MAP[12][193]=DBC; MAP[12][194]=DBC; MAP[12][195]=DBC; MAP[12][196]=DBR; 

        // 7. BANDERA Y CASTILLO
        for(r=3; r<=12; r=r+1) MAP[r][198]=FP;
        MAP[4][197]=FL;
        
        MAP[8][202]=CA; MAP[8][204]=CA; MAP[8][206]=CA;
        for(c=202; c<=206; c=c+1) MAP[9][c]=CA;
        MAP[10][202]=CA; MAP[10][203]=C_WN; MAP[10][204]=CA; MAP[10][205]=C_WN; MAP[10][206]=CA;
        MAP[11][202]=CA; MAP[11][203]=CA; MAP[11][204]=C_DT; MAP[11][205]=CA; MAP[11][206]=CA;
        MAP[12][202]=CA; MAP[12][203]=CA; MAP[12][204]=C_DB; MAP[12][205]=CA; MAP[12][206]=CA;

        //Arbustos finales despues del Castillo
        MAP[12][207]=BsR; 
        //Colina final
        MAP[12][208]=DBL; MAP[12][209]=DBC; MAP[12][210]=DBR; 
    end

    reg [7:0] tid;
    reg [8:0] col_abs_r;

    always @(posedge clk) begin
        col_abs_r = {1'b0, scroll_offset} + {4'b0, screen_tile_x};
        if (col_abs_r >= MAP_W || screen_tile_y >= MAP_H) tid <= E;
        else tid <= MAP[screen_tile_y][col_abs_r[7:0]];
    end

    always @(*) begin
        chunk_id = tid;
        case (tid)
            BR, QQ, GR, ST, CA, BU, TL, TR, PL, PR, C_DT, C_DB, C_WN, H_SL, H_SC, H_SR, H_FL : is_solid = 1'b1;
            default : is_solid = 1'b0;
        endcase
    end
endmodule

