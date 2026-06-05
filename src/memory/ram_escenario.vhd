-- =============================================================================
-- RAM_ESCENARIO.VHD
-- Módulo de mapa del nivel para Super Mario Bros - Nivel 1-1
--
-- DESCRIPCIÓN:
--   Almacena el tile map completo del Nivel 1-1 y devuelve el chunk_id
--   correspondiente a cualquier posición del escenario, considerando el
--   scroll horizontal.
--
-- ARQUITECTURA DEL NIVEL:
--   - El nivel completo mide 212 tiles de ancho x 15 tiles de alto
--     (el tile de fila 0 es el cielo, filas 13-14 son el suelo)
--   - La pantalla muestra 20 tiles de ancho x 15 tiles de alto
--     (a 32x32 px por tile en 640x480, o 16x16 si se escala 1:1)
--   - El scroll_offset indica cuántos tiles se han desplazado desde el inicio
--
-- COORDENADAS:
--   tile_x  : posición absoluta en el nivel (0 a MAP_WIDTH-1)
--   tile_y  : fila del nivel (0 = cielo, 14 = suelo)
--   chunk_id: ID del sprite de 16x16 a renderizar (ver rom_chunks_mario.vhd)
--
-- CHUNK IDs USADOS (referencia de rom_chunks_mario.vhd):
--   0  = vacío/cielo (transparente)
--   1  = bloque ladrillo
--   2  = bloque pregunta (?)
--   3  = suelo/piso
--   4  = escalera (stair block)
--   5  = castillo
--   6  = bloque ladrillo usado
--   8  = asta de bandera
--   9  = bandera
--   10 = tubería tope izquierdo
--   11 = tubería tope derecho
--   12 = tubería cuerpo izquierdo
--   13 = tubería cuerpo derecho
--   32 = goomba
--   64 = moneda
--   96 = nube pequeña
--   97 = arbusto
--   98 = nube izquierda
--   99 = nube centro
--  100 = nube derecha
--  101 = arbusto izquierdo
--  102 = arbusto centro
--  103 = arbusto derecho
--  104 = colina pequeña
--  128 = Mario pequeño (sprite del jugador - NO va en el mapa estático)
--
-- NOTA SOBRE EL JUGADOR:
--   Mario NO se almacena en esta RAM. Su posición y sprite se gestionan
--   desde sprite_manager.vhd y se componen encima en render_pipeline.vhd.
--
-- INTERFAZ:
--   Entrada: clk, scroll_offset (tile offset horizontal), screen_tile_x (0-19),
--            screen_tile_y (0-14)
--   Salida:  chunk_id (8 bits), is_solid (para colisiones)
--
-- LATENCIA: 1 ciclo de reloj (ROM síncrona)
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram_escenario is
    Port (
        clk           : in  STD_LOGIC;

        -- Posición de pantalla (en tiles, relativa a la pantalla visible)
        -- screen_tile_x: 0 a 19  (pantalla de 20 tiles de ancho)
        -- screen_tile_y: 0 a 14  (pantalla de 15 tiles de alto)
        screen_tile_x : in  STD_LOGIC_VECTOR(4 downto 0);   -- 5 bits: 0-19
        screen_tile_y : in  STD_LOGIC_VECTOR(3 downto 0);   -- 4 bits: 0-14

        -- Desplazamiento horizontal actual del nivel (en tiles)
        -- El render_pipeline o scroll_controller actualiza este valor
        scroll_offset : in  STD_LOGIC_VECTOR(7 downto 0);   -- 0 a 211

        -- Salidas
        chunk_id      : out STD_LOGIC_VECTOR(7 downto 0);   -- ID del sprite
        is_solid      : out STD_LOGIC                        -- 1 = colisión sólida
    );
end ram_escenario;

architecture Behavioral of ram_escenario is

    -- -------------------------------------------------------------------------
    -- CONSTANTES DEL NIVEL
    -- -------------------------------------------------------------------------
    constant MAP_WIDTH  : integer := 212;  -- Ancho del nivel en tiles
    constant MAP_HEIGHT : integer := 15;   -- Alto del nivel en tiles
    constant SCREEN_W   : integer := 20;   -- Tiles visibles horizontalmente

    -- -------------------------------------------------------------------------
    -- TIPO DEL MAPA
    -- Cada celda guarda un chunk_id de 8 bits
    -- Total: 212 x 15 = 3180 celdas = ~3.1 KB de ROM
    -- -------------------------------------------------------------------------
    type row_type is array (0 to MAP_WIDTH - 1) of STD_LOGIC_VECTOR(7 downto 0);
    type map_type is array (0 to MAP_HEIGHT - 1) of row_type;

    -- =========================================================================
    -- MAPA DEL NIVEL 1-1
    -- Basado en el nivel original de Super Mario Bros (NES, 1985)
    --
    -- Filas (Y):
    --   0-1  : cielo (vacío)
    --   2-3  : zona de nubes y decoraciones de fondo
    --   4-11 : zona de juego principal (bloques, tuberías, escaleras)
    --   12   : zona de suelo superior
    --   13-14: suelo sólido
    --
    -- Se usa notación compacta: cada número es un chunk_id
    -- =========================================================================

    -- Shorthand para chunk IDs frecuentes (mejora legibilidad)
    -- Se definen como constantes locales de 8 bits
    constant E  : STD_LOGIC_VECTOR(7 downto 0) := x"00"; -- vacío
    constant BR : STD_LOGIC_VECTOR(7 downto 0) := x"01"; -- brick (ladrillo)
    constant QQ : STD_LOGIC_VECTOR(7 downto 0) := x"02"; -- question block
    constant GR : STD_LOGIC_VECTOR(7 downto 0) := x"03"; -- ground (suelo)
    constant ST : STD_LOGIC_VECTOR(7 downto 0) := x"04"; -- stair block
    constant CA : STD_LOGIC_VECTOR(7 downto 0) := x"05"; -- castle block
    constant BU : STD_LOGIC_VECTOR(7 downto 0) := x"06"; -- brick used
    constant FP : STD_LOGIC_VECTOR(7 downto 0) := x"08"; -- flag pole
    constant FL : STD_LOGIC_VECTOR(7 downto 0) := x"09"; -- flag
    constant TL : STD_LOGIC_VECTOR(7 downto 0) := x"0A"; -- pipe top left
    constant TR : STD_LOGIC_VECTOR(7 downto 0) := x"0B"; -- pipe top right
    constant PL : STD_LOGIC_VECTOR(7 downto 0) := x"0C"; -- pipe body left
    constant PR : STD_LOGIC_VECTOR(7 downto 0) := x"0D"; -- pipe body right
    constant GO : STD_LOGIC_VECTOR(7 downto 0) := x"20"; -- goomba
    constant CO : STD_LOGIC_VECTOR(7 downto 0) := x"40"; -- coin
    constant CL : STD_LOGIC_VECTOR(7 downto 0) := x"60"; -- cloud small
    constant BH : STD_LOGIC_VECTOR(7 downto 0) := x"61"; -- bush
    constant NL : STD_LOGIC_VECTOR(7 downto 0) := x"62"; -- cloud left
    constant NC : STD_LOGIC_VECTOR(7 downto 0) := x"63"; -- cloud center
    constant NR : STD_LOGIC_VECTOR(7 downto 0) := x"64"; -- cloud right
    constant BL : STD_LOGIC_VECTOR(7 downto 0) := x"65"; -- bush left
    constant BC : STD_LOGIC_VECTOR(7 downto 0) := x"66"; -- bush center
    constant BR2: STD_LOGIC_VECTOR(7 downto 0) := x"67"; -- bush right
    constant HL : STD_LOGIC_VECTOR(7 downto 0) := x"68"; -- hill small

    -- =========================================================================
    -- DEFINICIÓN DEL MAPA COMPLETO - NIVEL 1-1
    --
    -- Columnas 0-211 (de izquierda a derecha del nivel)
    -- Filas 0-14    (de arriba a abajo)
    --
    -- Referencia visual del nivel original:
    --   Pantalla 1 (cols 0-19):   inicio, tubería 1 (col 0 de tuberías), bloques BR/QQ
    --   Pantalla 2 (cols 20-39):  tuberías 2 y 3, bloque QQ con estrella
    --   Pantalla 3 (cols 40-59):  tuberías 4, escaleras de castillo
    --   etc.
    -- =========================================================================
    constant LEVEL_MAP : map_type := (

        -- =====================================================================
        -- FILA 0: Cielo superior (todo vacío)
        -- =====================================================================
        0 => (others => E),

        -- =====================================================================
        -- FILA 1: Nubes (decoración, no sólidas)
        -- Nube grande cols 1-3, nube pequeña col 9, otra nube cols 16-18
        -- =====================================================================
        1 => (
             0 => E,
             1 => NL,  2 => NC,  3 => NR,   -- nube grande izquierda
             4 => E,  5 => E,  6 => E,  7 => E,  8 => E,
             9 => CL,                          -- nube pequeña
            10 => E, 11 => E, 12 => E, 13 => E, 14 => E, 15 => E,
            16 => NL, 17 => NC, 18 => NR,    -- nube grande derecha
            19 => E, 20 => E, 21 => E, 22 => E, 23 => E,
            24 => NL, 25 => NC, 26 => NR,    -- nube
            27 => E, 28 => E, 29 => E, 30 => E, 31 => E, 32 => E,
            33 => CL, 34 => E,               -- nube pequeña
            35 => E, 36 => E, 37 => E, 38 => E, 39 => E,
            40 => NL, 41 => NC, 42 => NR,    -- nube
            43 => E, 44 => E, 45 => E, 46 => E, 47 => E, 48 => E,
            49 => CL, 50 => E,
            51 => E, 52 => E, 53 => E, 54 => E, 55 => E,
            56 => NL, 57 => NC, 58 => NR,
            59 => E, 60 => E, 61 => E, 62 => E, 63 => E, 64 => E,
            65 => CL,
            66 => E, 67 => E, 68 => E, 69 => E, 70 => E,
            71 => NL, 72 => NC, 73 => NR,
            74 => E, 75 => E, 76 => E, 77 => E, 78 => E, 79 => E,
            80 => CL,
            81 => E, 82 => E, 83 => E, 84 => E, 85 => E,
            86 => NL, 87 => NC, 88 => NR,
            89 => E, 90 => E, 91 => E, 92 => E, 93 => E, 94 => E,
            95 => CL,
            96 => E, 97 => E, 98 => E, 99 => E, 100 => E,
           101 => NL, 102 => NC, 103 => NR,
           104 => E, 105 => E, 106 => E, 107 => E, 108 => E, 109 => E,
           110 => CL,
           111 => E, 112 => E, 113 => E, 114 => E, 115 => E,
           116 => NL, 117 => NC, 118 => NR,
           119 => E, 120 => E, 121 => E, 122 => E, 123 => E, 124 => E,
           125 => CL,
           126 => E, 127 => E, 128 => E, 129 => E, 130 => E,
           131 => NL, 132 => NC, 133 => NR,
           134 => E, 135 => E, 136 => E, 137 => E, 138 => E, 139 => E,
           140 => CL,
           141 => E, 142 => E, 143 => E, 144 => E, 145 => E,
           146 => NL, 147 => NC, 148 => NR,
           149 => E, 150 => E, 151 => E, 152 => E, 153 => E, 154 => E,
           155 => CL,
           156 => E, 157 => E, 158 => E, 159 => E, 160 => E,
           161 => NL, 162 => NC, 163 => NR,
           164 => E, 165 => E, 166 => E, 167 => E, 168 => E, 169 => E,
           170 => CL,
           171 => E, 172 => E, 173 => E, 174 => E, 175 => E,
           176 => NL, 177 => NC, 178 => NR,
           179 => E, 180 => E, 181 => E, 182 => E, 183 => E, 184 => E,
           185 => CL,
           186 => E, 187 => E, 188 => E, 189 => E, 190 => E,
           191 => NL, 192 => NC, 193 => NR,
           194 => E, 195 => E, 196 => E, 197 => E, 198 => E, 199 => E,
           200 => E, 201 => E, 202 => E, 203 => E, 204 => E, 205 => E,
           206 => E, 207 => E, 208 => E, 209 => E, 210 => E, 211 => E
        ),

        -- =====================================================================
        -- FILA 2: Parte inferior de nubes (vacío aquí, se comparte con fila 1)
        -- + decoraciones de colina y arbusto a nivel de suelo
        -- En el NES original las nubes tienen 2 tiles de alto
        -- =====================================================================
        2 => (others => E),

        -- =====================================================================
        -- FILA 3: Vacío (zona aérea de juego)
        -- =====================================================================
        3 => (others => E),

        -- =====================================================================
        -- FILA 4: Bloques elevados y parte superior de tuberías altas
        -- tubería 1: col 0 (2 tiles alto = filas 11-12 → solo tope en fila 11)
        -- tubería 2: col 4 (3 tiles = filas 10-12)
        -- tubería 3: col 7 (3 tiles = filas 10-12)
        -- tubería 4: col 16 (4 tiles = filas 9-12)
        -- =====================================================================
        4 => (others => E),

        -- =====================================================================
        -- FILA 5: Bloques con monedas o power-ups (fila de bloques elevada)
        -- Col 16: brick, col 19: QQ (hongo), col 20: brick,
        -- col 22: QQ (estrella), col 23: brick, col 24: QQ (moneda), col 27: brick
        -- =====================================================================
        5 => (
             0 =>  E,  1 =>  E,  2 =>  E,  3 =>  E,  4 =>  E,
             5 =>  E,  6 =>  E,  7 =>  E,  8 =>  E,  9 =>  E,
            10 =>  E, 11 =>  E, 12 =>  E, 13 =>  E, 14 =>  E,
            15 =>  E, 16 => BR, 17 =>  E, 18 =>  E, 19 => QQ,
            20 => BR, 21 =>  E, 22 => QQ, 23 => BR, 24 => QQ,
            25 =>  E, 26 =>  E, 27 => BR, 28 =>  E, 29 =>  E,
            30 =>  E, 31 =>  E, 32 =>  E, 33 =>  E, 34 =>  E,
            35 =>  E, 36 =>  E, 37 =>  E, 38 =>  E, 39 =>  E,
            40 =>  E, 41 =>  E, 42 =>  E, 43 =>  E, 44 =>  E,
            45 =>  E, 46 =>  E, 47 =>  E, 48 =>  E, 49 =>  E,
            50 =>  E, 51 =>  E, 52 =>  E, 53 =>  E, 54 =>  E,
            55 =>  E, 56 =>  E, 57 =>  E, 58 =>  E, 59 =>  E,
            60 =>  E, 61 =>  E, 62 =>  E, 63 =>  E, 64 =>  E,
            65 =>  E, 66 =>  E, 67 =>  E, 68 =>  E, 69 =>  E,
            70 =>  E, 71 =>  E, 72 =>  E, 73 =>  E, 74 =>  E,
            75 =>  E, 76 =>  E, 77 =>  E, 78 =>  E, 79 =>  E,
            -- Bloque QQ con power-up sobre tubería 4 (cols 78-79)
            78 => QQ, 79 =>  E,
            -- Bloques en zona media del nivel
            80 => BR, 81 => BR, 82 => QQ, 83 => BR, 84 =>  E,
            85 =>  E, 86 =>  E, 87 =>  E, 88 =>  E, 89 =>  E,
            90 =>  E, 91 =>  E, 92 =>  E, 93 =>  E, 94 =>  E,
            95 =>  E, 96 =>  E, 97 =>  E, 98 =>  E, 99 =>  E,
           100 =>  E, 101 => QQ, 102 =>  E, 103 =>  E, 104 =>  E,
           105 =>  E, 106 =>  E, 107 =>  E, 108 =>  E, 109 =>  E,
           110 => BR, 111 => BR, 112 =>  E, 113 =>  E, 114 =>  E,
           115 =>  E, 116 =>  E, 117 =>  E, 118 =>  E, 119 =>  E,
           120 =>  E, 121 =>  E, 122 =>  E, 123 =>  E, 124 =>  E,
           125 =>  E, 126 =>  E, 127 =>  E, 128 =>  E, 129 =>  E,
           130 =>  E, 131 =>  E, 132 =>  E, 133 =>  E, 134 =>  E,
           135 =>  E, 136 =>  E, 137 =>  E, 138 =>  E, 139 =>  E,
           140 => BR, 141 => BR, 142 => BR, 143 =>  E, 144 =>  E,
           145 =>  E, 146 =>  E, 147 =>  E, 148 =>  E, 149 =>  E,
           150 =>  E, 151 =>  E, 152 =>  E, 153 =>  E, 154 =>  E,
           155 =>  E, 156 =>  E, 157 =>  E, 158 =>  E, 159 =>  E,
           160 =>  E, 161 =>  E, 162 =>  E, 163 =>  E, 164 =>  E,
           165 =>  E, 166 =>  E, 167 =>  E, 168 =>  E, 169 =>  E,
           170 =>  E, 171 =>  E, 172 =>  E, 173 =>  E, 174 =>  E,
           175 =>  E, 176 =>  E, 177 =>  E, 178 =>  E, 179 =>  E,
           180 =>  E, 181 =>  E, 182 =>  E, 183 =>  E, 184 =>  E,
           185 =>  E, 186 =>  E, 187 =>  E, 188 =>  E, 189 =>  E,
           190 =>  E, 191 =>  E, 192 =>  E, 193 =>  E, 194 =>  E,
           195 =>  E, 196 =>  E, 197 =>  E, 198 =>  E, 199 =>  E,
           200 =>  E, 201 =>  E, 202 =>  E, 203 =>  E, 204 =>  E,
           205 =>  E, 206 =>  E, 207 =>  E, 208 =>  E, 209 =>  E,
           210 =>  E, 211 =>  E
        ),

        -- =====================================================================
        -- FILA 6: Segunda fila de bloques elevados
        -- =====================================================================
        6 => (others => E),

        -- =====================================================================
        -- FILA 7: Zona de bloques bajos (cerca del suelo)
        -- Bloques QQ típicamente en fila 8 del mapa NES (1 tile sobre el suelo)
        -- =====================================================================
        7 => (others => E),

        -- =====================================================================
        -- FILA 8: Bloques al nivel bajo (3 tiles sobre el suelo)
        -- Col 3-4: QQ (moneda), col 5: QQ (power-up), colores del nivel original
        -- =====================================================================
        8 => (
             0 =>  E,  1 =>  E,  2 =>  E,  3 => QQ,  4 => QQ,
             5 => QQ,  6 =>  E,  7 =>  E,  8 =>  E,   9 =>  E,
            10 =>  E, 11 =>  E, 12 =>  E, 13 =>  E,  14 =>  E,
            15 =>  E, 16 =>  E, 17 =>  E, 18 =>  E,  19 =>  E,
            20 =>  E, 21 =>  E, 22 =>  E, 23 =>  E,  24 =>  E,
            25 =>  E, 26 =>  E, 27 =>  E, 28 =>  E,  29 =>  E,
            30 =>  E, 31 =>  E, 32 =>  E, 33 =>  E,  34 =>  E,
            35 =>  E, 36 =>  E, 37 =>  E, 38 =>  E,  39 =>  E,
            40 =>  E, 41 =>  E, 42 =>  E, 43 =>  E,  44 =>  E,
            -- Grupos de bloques más adelante en el nivel
            55 => BR, 56 => BR,
            65 => BR, 66 => BR, 67 => BR, 68 => BR,
            78 =>  E, 79 =>  E,
            90 => BR, 91 => BR, 92 => BR,
           100 =>  E, 101 =>  E, 102 =>  E, 103 =>  E, 104 =>  E,
           105 =>  E, 106 =>  E, 107 =>  E, 108 =>  E, 109 =>  E,
           110 =>  E, 111 =>  E, 112 =>  E, 113 =>  E, 114 =>  E,
           115 =>  E, 116 =>  E, 117 =>  E, 118 =>  E, 119 =>  E,
           120 =>  E, 121 =>  E, 122 =>  E, 123 =>  E, 124 =>  E,
           125 =>  E, 126 =>  E, 127 =>  E, 128 =>  E, 129 =>  E,
           130 =>  E, 131 =>  E, 132 =>  E, 133 =>  E, 134 =>  E,
           135 =>  E, 136 =>  E, 137 =>  E, 138 =>  E, 139 =>  E,
           140 =>  E, 141 =>  E, 142 =>  E, 143 =>  E, 144 =>  E,
           145 =>  E, 146 =>  E, 147 =>  E, 148 =>  E, 149 =>  E,
           150 =>  E, 151 =>  E, 152 =>  E, 153 =>  E, 154 =>  E,
           155 =>  E, 156 =>  E, 157 =>  E, 158 =>  E, 159 =>  E,
           160 =>  E, 161 =>  E, 162 =>  E, 163 =>  E, 164 =>  E,
           165 =>  E, 166 =>  E, 167 =>  E, 168 =>  E, 169 =>  E,
           170 =>  E, 171 =>  E, 172 =>  E, 173 =>  E, 174 =>  E,
           175 =>  E, 176 =>  E, 177 =>  E, 178 =>  E, 179 =>  E,
           180 =>  E, 181 =>  E, 182 =>  E, 183 =>  E, 184 =>  E,
           185 =>  E, 186 =>  E, 187 =>  E, 188 =>  E, 189 =>  E,
           190 =>  E, 191 =>  E, 192 =>  E, 193 =>  E, 194 =>  E,
           195 =>  E, 196 =>  E, 197 =>  E, 198 =>  E, 199 =>  E,
           200 =>  E, 201 =>  E, 202 =>  E, 203 =>  E, 204 =>  E,
           205 =>  E, 206 =>  E, 207 =>  E, 208 =>  E, 209 =>  E,
           210 =>  E, 211 =>  E
        ),

        -- =====================================================================
        -- FILA 9: Tuberías más altas (4 tiles de alto: filas 9, 10, 11, 12_tope)
        -- Col 16-17: cuerpo tubería alta
        -- =====================================================================
        9 => (
             0 =>  E,  1 =>  E,  2 =>  E,  3 =>  E,  4 =>  E,
             5 =>  E,  6 =>  E,  7 =>  E,  8 =>  E,  9 =>  E,
            10 =>  E, 11 =>  E, 12 =>  E, 13 =>  E, 14 =>  E,
            15 =>  E, 16 => PL, 17 => PR, 18 =>  E, 19 =>  E,
            20 =>  E, 21 =>  E, 22 =>  E, 23 =>  E, 24 =>  E,
            25 =>  E, 26 =>  E, 27 =>  E, 28 =>  E, 29 =>  E,
            -- Segunda tubería alta (cols 32-33)
            30 =>  E, 31 =>  E, 32 => PL, 33 => PR, 34 =>  E,
            35 =>  E, 36 =>  E, 37 =>  E, 38 =>  E, 39 =>  E,
            40 =>  E, 41 =>  E, 42 =>  E, 43 =>  E, 44 =>  E,
            45 =>  E, 46 =>  E, 47 =>  E, 48 =>  E, 49 =>  E,
            50 =>  E, 51 =>  E, 52 =>  E, 53 =>  E, 54 =>  E,
            55 =>  E, 56 =>  E, 57 =>  E, 58 =>  E, 59 =>  E,
            60 =>  E, 61 =>  E, 62 =>  E, 63 =>  E, 64 =>  E,
            65 =>  E, 66 =>  E, 67 =>  E, 68 =>  E, 69 =>  E,
            70 =>  E, 71 =>  E, 72 =>  E, 73 =>  E, 74 =>  E,
            75 =>  E, 76 =>  E, 77 =>  E, 78 =>  E, 79 =>  E,
            80 =>  E, 81 =>  E, 82 =>  E, 83 =>  E, 84 =>  E,
            85 =>  E, 86 =>  E, 87 =>  E, 88 =>  E, 89 =>  E,
            90 =>  E, 91 =>  E, 92 =>  E, 93 =>  E, 94 =>  E,
            95 =>  E, 96 =>  E, 97 =>  E, 98 =>  E, 99 =>  E,
           100 =>  E, 101 =>  E, 102 =>  E, 103 =>  E, 104 =>  E,
           105 =>  E, 106 =>  E, 107 =>  E, 108 =>  E, 109 =>  E,
           110 =>  E, 111 =>  E, 112 =>  E, 113 =>  E, 114 =>  E,
           115 =>  E, 116 =>  E, 117 =>  E, 118 =>  E, 119 =>  E,
           120 =>  E, 121 =>  E, 122 =>  E, 123 =>  E, 124 =>  E,
           125 =>  E, 126 =>  E, 127 =>  E, 128 =>  E, 129 =>  E,
           130 =>  E, 131 =>  E, 132 =>  E, 133 =>  E, 134 =>  E,
           135 =>  E, 136 =>  E, 137 =>  E, 138 =>  E, 139 =>  E,
           140 =>  E, 141 =>  E, 142 =>  E, 143 =>  E, 144 =>  E,
           145 =>  E, 146 =>  E, 147 =>  E, 148 =>  E, 149 =>  E,
           150 =>  E, 151 =>  E, 152 =>  E, 153 =>  E, 154 =>  E,
           155 =>  E, 156 =>  E, 157 =>  E, 158 =>  E, 159 =>  E,
           160 =>  E, 161 =>  E, 162 =>  E, 163 =>  E, 164 =>  E,
           165 =>  E, 166 =>  E, 167 =>  E, 168 =>  E, 169 =>  E,
           170 =>  E, 171 =>  E, 172 =>  E, 173 =>  E, 174 =>  E,
           175 =>  E, 176 =>  E, 177 =>  E, 178 =>  E, 179 =>  E,
           180 =>  E, 181 =>  E, 182 =>  E, 183 =>  E, 184 =>  E,
           185 =>  E, 186 =>  E, 187 =>  E, 188 =>  E, 189 =>  E,
           190 =>  E, 191 =>  E, 192 =>  E, 193 =>  E, 194 =>  E,
           195 =>  E, 196 =>  E, 197 =>  E, 198 =>  E, 199 =>  E,
           200 =>  E, 201 =>  E, 202 =>  E, 203 =>  E, 204 =>  E,
           205 =>  E, 206 =>  E, 207 =>  E, 208 =>  E, 209 =>  E,
           210 =>  E, 211 =>  E
        ),

        -- =====================================================================
        -- FILA 10: Cuerpos de tuberías (2 tiles de alto: filas 10-11 para las
        -- tuberías de 2 tiles, filas 10-12 para las de 3 tiles)
        -- Tubería 1 (2 tiles): solo tope en fila 11
        -- Tubería 2 (3 tiles): cuerpo en filas 10-11, tope en 12... 
        -- NOTA: en el NES el suelo está en fila 14, así que usamos:
        --   Tubería 1 (col 0-1): tope fila 11, cuerpo fila 12
        --   Tubería 2 (col 4-5): cuerpo fila 10, tope fila 11, cuerpo fila 12
        --   Tubería 3 (col 7-8): igual que tubería 2
        --   Tubería 4 (col 16-17): cuerpo filas 9-10, tope fila 11, cuerpo fila 12
        -- =====================================================================
        10 => (
             0 =>  E,  1 =>  E,  2 =>  E,  3 =>  E,
             4 => PL,  5 => PR,  6 =>  E,
             7 => PL,  8 => PR,  9 =>  E,
            10 =>  E, 11 =>  E, 12 =>  E, 13 =>  E, 14 =>  E,
            15 =>  E, 16 => PL, 17 => PR, 18 =>  E, 19 =>  E,
            20 =>  E, 21 =>  E, 22 =>  E, 23 =>  E, 24 =>  E,
            25 =>  E, 26 =>  E, 27 =>  E, 28 =>  E, 29 =>  E,
            30 =>  E, 31 =>  E, 32 => PL, 33 => PR,
            others => E
        ),

        -- =====================================================================
        -- FILA 11: Topes de tuberías (todas las tuberías tienen tope aquí)
        -- =====================================================================
        11 => (
             0 => TL,  1 => TR,  2 =>  E,  3 =>  E,
             4 => TL,  5 => TR,  6 =>  E,
             7 => TL,  8 => TR,  9 =>  E,
            10 =>  E, 11 =>  E, 12 =>  E, 13 =>  E, 14 =>  E,
            15 =>  E, 16 => TL, 17 => TR, 18 =>  E, 19 =>  E,
            20 =>  E, 21 =>  E, 22 =>  E, 23 =>  E, 24 =>  E,
            25 =>  E, 26 =>  E, 27 =>  E, 28 =>  E, 29 =>  E,
            30 =>  E, 31 =>  E, 32 => TL, 33 => TR,
            others => E
        ),

        -- =====================================================================
        -- FILA 12: Fila entre tuberías y suelo
        -- Cuerpos de tuberías que llegan hasta el suelo, arbustos de decoración
        -- =====================================================================
        12 => (
             0 => PL,  1 => PR,  2 =>  E,  3 => BL,  -- pipe body + bush
             4 => PL,  5 => PR,  6 => BC,             -- pipe body + bush center
             7 => PL,  8 => PR,  9 => BR2,            -- pipe body + bush right
            10 =>  E, 11 =>  E, 12 =>  E, 13 =>  E, 14 =>  E,
            15 =>  E, 16 => PL, 17 => PR, 18 =>  E, 19 =>  E,
            20 =>  E, 21 =>  E, 22 =>  E, 23 =>  E, 24 =>  E,
            25 =>  E, 26 =>  E, 27 =>  E, 28 =>  E, 29 =>  E,
            30 =>  E, 31 =>  E, 32 => PL, 33 => PR, 34 =>  E,
            35 =>  E, 36 =>  E, 37 => BL, 38 => BC, 39 => BR2,
            40 =>  E, 41 =>  E, 42 =>  E, 43 =>  E, 44 =>  E,
            45 =>  E, 46 =>  E, 47 =>  E, 48 =>  E, 49 =>  E,
            50 =>  E, 51 =>  E, 52 => BL, 53 => BC, 54 => BR2,
            -- Escaleras finales del nivel (cols 187-205)
           187 => ST,
           188 => ST, 189 => ST,
           190 => ST, 191 => ST, 192 => ST,
           193 => ST, 194 => ST, 195 => ST, 196 => ST,
           -- Asta de bandera (col 198)
           198 => FP,
           -- Bloques del castillo
           200 => CA, 201 => CA, 202 => CA, 203 => CA, 204 => CA,
           others => E
        ),

        -- =====================================================================
        -- FILA 13: Primera fila de suelo sólido (toda sólida excepto hoyos)
        -- El nivel 1-1 tiene un hoyo entre cols 63-65 y otro entre 108-112
        -- =====================================================================
        13 => (
            -- Hoyo 1: cols 63-65 (vacío = hoyo)
             0 => GR,  1 => GR,  2 => GR,  3 => GR,  4 => GR,
             5 => GR,  6 => GR,  7 => GR,  8 => GR,  9 => GR,
            10 => GR, 11 => GR, 12 => GR, 13 => GR, 14 => GR,
            15 => GR, 16 => GR, 17 => GR, 18 => GR, 19 => GR,
            20 => GR, 21 => GR, 22 => GR, 23 => GR, 24 => GR,
            25 => GR, 26 => GR, 27 => GR, 28 => GR, 29 => GR,
            30 => GR, 31 => GR, 32 => GR, 33 => GR, 34 => GR,
            35 => GR, 36 => GR, 37 => GR, 38 => GR, 39 => GR,
            40 => GR, 41 => GR, 42 => GR, 43 => GR, 44 => GR,
            45 => GR, 46 => GR, 47 => GR, 48 => GR, 49 => GR,
            50 => GR, 51 => GR, 52 => GR, 53 => GR, 54 => GR,
            55 => GR, 56 => GR, 57 => GR, 58 => GR, 59 => GR,
            60 => GR, 61 => GR, 62 => GR,
            63 =>  E, 64 =>  E, 65 =>  E,             -- HOYO 1
            66 => GR, 67 => GR, 68 => GR, 69 => GR,
            70 => GR, 71 => GR, 72 => GR, 73 => GR,
            74 => GR, 75 => GR, 76 => GR, 77 => GR,
            78 => GR, 79 => GR, 80 => GR, 81 => GR,
            82 => GR, 83 => GR, 84 => GR, 85 => GR,
            86 => GR, 87 => GR, 88 => GR, 89 => GR,
            90 => GR, 91 => GR, 92 => GR, 93 => GR,
            94 => GR, 95 => GR, 96 => GR, 97 => GR,
            98 => GR, 99 => GR, 100 => GR, 101 => GR,
           102 => GR, 103 => GR, 104 => GR, 105 => GR,
           106 => GR, 107 => GR,
           108 =>  E, 109 =>  E, 110 =>  E, 111 =>  E, 112 =>  E, -- HOYO 2
           113 => GR, 114 => GR, 115 => GR, 116 => GR,
           117 => GR, 118 => GR, 119 => GR, 120 => GR,
           121 => GR, 122 => GR, 123 => GR, 124 => GR,
           125 => GR, 126 => GR, 127 => GR, 128 => GR,
           129 => GR, 130 => GR, 131 => GR, 132 => GR,
           133 => GR, 134 => GR, 135 => GR, 136 => GR,
           137 => GR, 138 => GR, 139 => GR, 140 => GR,
           141 => GR, 142 => GR, 143 => GR, 144 => GR,
           145 => GR, 146 => GR, 147 => GR, 148 => GR,
           149 => GR, 150 => GR, 151 => GR, 152 => GR,
           153 => GR, 154 => GR, 155 => GR, 156 => GR,
           157 => GR, 158 => GR, 159 => GR, 160 => GR,
           161 => GR, 162 => GR, 163 => GR, 164 => GR,
           165 => GR, 166 => GR, 167 => GR, 168 => GR,
           169 => GR, 170 => GR, 171 => GR, 172 => GR,
           173 => GR, 174 => GR, 175 => GR, 176 => GR,
           177 => GR, 178 => GR, 179 => GR, 180 => GR,
           181 => GR, 182 => GR, 183 => GR, 184 => GR,
           185 => GR, 186 => GR, 187 => GR, 188 => GR,
           189 => GR, 190 => GR, 191 => GR, 192 => GR,
           193 => GR, 194 => GR, 195 => GR, 196 => GR,
           197 => GR, 198 => GR, 199 => GR, 200 => GR,
           201 => GR, 202 => GR, 203 => GR, 204 => GR,
           205 => GR, 206 => GR, 207 => GR, 208 => GR,
           209 => GR, 210 => GR, 211 => GR
        ),

        -- =====================================================================
        -- FILA 14: Segunda fila de suelo (todo sólido, sin hoyos)
        -- Los hoyos solo afectan la fila superior del suelo; fila 14 siempre GR
        -- para evitar que el jugador caiga "a través" visualmente
        -- =====================================================================
        14 => (
             0 => GR,  1 => GR,  2 => GR,  3 => GR,  4 => GR,
             5 => GR,  6 => GR,  7 => GR,  8 => GR,  9 => GR,
            10 => GR, 11 => GR, 12 => GR, 13 => GR, 14 => GR,
            15 => GR, 16 => GR, 17 => GR, 18 => GR, 19 => GR,
            20 => GR, 21 => GR, 22 => GR, 23 => GR, 24 => GR,
            25 => GR, 26 => GR, 27 => GR, 28 => GR, 29 => GR,
            30 => GR, 31 => GR, 32 => GR, 33 => GR, 34 => GR,
            35 => GR, 36 => GR, 37 => GR, 38 => GR, 39 => GR,
            40 => GR, 41 => GR, 42 => GR, 43 => GR, 44 => GR,
            45 => GR, 46 => GR, 47 => GR, 48 => GR, 49 => GR,
            50 => GR, 51 => GR, 52 => GR, 53 => GR, 54 => GR,
            55 => GR, 56 => GR, 57 => GR, 58 => GR, 59 => GR,
            60 => GR, 61 => GR, 62 => GR, 63 => GR, 64 => GR,
            65 => GR, 66 => GR, 67 => GR, 68 => GR, 69 => GR,
            70 => GR, 71 => GR, 72 => GR, 73 => GR, 74 => GR,
            75 => GR, 76 => GR, 77 => GR, 78 => GR, 79 => GR,
            80 => GR, 81 => GR, 82 => GR, 83 => GR, 84 => GR,
            85 => GR, 86 => GR, 87 => GR, 88 => GR, 89 => GR,
            90 => GR, 91 => GR, 92 => GR, 93 => GR, 94 => GR,
            95 => GR, 96 => GR, 97 => GR, 98 => GR, 99 => GR,
           100 => GR, 101 => GR, 102 => GR, 103 => GR, 104 => GR,
           105 => GR, 106 => GR, 107 => GR, 108 => GR, 109 => GR,
           110 => GR, 111 => GR, 112 => GR, 113 => GR, 114 => GR,
           115 => GR, 116 => GR, 117 => GR, 118 => GR, 119 => GR,
           120 => GR, 121 => GR, 122 => GR, 123 => GR, 124 => GR,
           125 => GR, 126 => GR, 127 => GR, 128 => GR, 129 => GR,
           130 => GR, 131 => GR, 132 => GR, 133 => GR, 134 => GR,
           135 => GR, 136 => GR, 137 => GR, 138 => GR, 139 => GR,
           140 => GR, 141 => GR, 142 => GR, 143 => GR, 144 => GR,
           145 => GR, 146 => GR, 147 => GR, 148 => GR, 149 => GR,
           150 => GR, 151 => GR, 152 => GR, 153 => GR, 154 => GR,
           155 => GR, 156 => GR, 157 => GR, 158 => GR, 159 => GR,
           160 => GR, 161 => GR, 162 => GR, 163 => GR, 164 => GR,
           165 => GR, 166 => GR, 167 => GR, 168 => GR, 169 => GR,
           170 => GR, 171 => GR, 172 => GR, 173 => GR, 174 => GR,
           175 => GR, 176 => GR, 177 => GR, 178 => GR, 179 => GR,
           180 => GR, 181 => GR, 182 => GR, 183 => GR, 184 => GR,
           185 => GR, 186 => GR, 187 => GR, 188 => GR, 189 => GR,
           190 => GR, 191 => GR, 192 => GR, 193 => GR, 194 => GR,
           195 => GR, 196 => GR, 197 => GR, 198 => GR, 199 => GR,
           200 => GR, 201 => GR, 202 => GR, 203 => GR, 204 => GR,
           205 => GR, 206 => GR, 207 => GR, 208 => GR, 209 => GR,
           210 => GR, 211 => GR
        )
    );

    -- =========================================================================
    -- TABLA DE SOLIDEZ (is_solid)
    -- Determina si un chunk_id es sólido para colisiones
    -- Evita decodificar esto en el motor de colisiones
    -- =========================================================================
    -- Sólidos: suelo (3), ladrillo (1), ladrillo-usado (6), pregunta (2),
    --          escalera (4), castillo (5), tubería top/body (10-13), metal (7)
    -- No sólidos: vacío (0), decoraciones (96-104), monedas (64), sprites

    function is_solid_chunk(id : STD_LOGIC_VECTOR(7 downto 0)) return STD_LOGIC is
    begin
        case to_integer(unsigned(id)) is
            when 1 | 2 | 3 | 4 | 5 | 6 | 7 |
                 10 | 11 | 12 | 13 | 14 | 15 => return '1'; -- bloques y tuberías
            when others                        => return '0'; -- vacío, decoraciones, sprites
        end case;
    end function;

begin

    -- =========================================================================
    -- PROCESO DE LECTURA SÍNCRONO
    --
    -- Calcula la columna absoluta del nivel:
    --   col_absoluta = scroll_offset + screen_tile_x
    --
    -- Si la columna está fuera del rango del nivel (> 211), devuelve vacío.
    -- =========================================================================
    read_proc: process(clk)
        variable col_abs  : integer range 0 to 511;
        variable col_safe : integer range 0 to MAP_WIDTH - 1;
        variable row      : integer range 0 to MAP_HEIGHT - 1;
        variable tid      : STD_LOGIC_VECTOR(7 downto 0);
    begin
        if rising_edge(clk) then

            -- Calcular posición absoluta en el nivel
            col_abs := to_integer(unsigned(scroll_offset)) +
                       to_integer(unsigned(screen_tile_x));

            row := to_integer(unsigned(screen_tile_y));

            -- Limitar al rango válido del mapa
            if col_abs >= MAP_WIDTH or row >= MAP_HEIGHT then
                -- Fuera del nivel: mostrar vacío (cielo)
                chunk_id <= (others => '0');
                is_solid <= '0';
            else
                col_safe := col_abs;
                tid := LEVEL_MAP(row)(col_safe);
                chunk_id <= tid;
                is_solid <= is_solid_chunk(tid);
            end if;

        end if;
    end process;

end Behavioral;


-- =============================================================================
-- NOTAS DE INTEGRACIÓN
-- =============================================================================
--
-- 1. CONEXIÓN CON ROM_CHUNKS_MARIO:
--    El chunk_id de salida de este módulo va DIRECTO al puerto chunk_id
--    de rom_chunks_mario.vhd. No se necesita lógica intermedia.
--
--    ram_escenario_inst: entity work.ram_escenario
--        port map(
--            clk           => clk,
--            screen_tile_x => tile_col,      -- del render pipeline
--            screen_tile_y => tile_row,      -- del render pipeline
--            scroll_offset => scroll_reg,    -- del scroll_controller
--            chunk_id      => bg_chunk_id,   -- → rom_chunks_mario.chunk_id
--            is_solid      => tile_solid     -- → motor_colisiones
--        );
--
-- 2. LATENCIA TOTAL BG PIPELINE:
--    Ciclo 0: presentar screen_tile_x/y + scroll_offset
--    Ciclo 1: chunk_id disponible (este módulo)
--    Ciclo 2: pixel_data disponible (rom_chunks_mario)
--    → render_pipeline debe compensar 2 ciclos de latencia
--
-- 3. CÓMO MODIFICAR EL NIVEL:
--    Solo editar las constantes de LEVEL_MAP arriba. Cada fila es un
--    aggregate de VHDL indexado. Para añadir un bloque en (col=50, fila=8):
--    en la fila 8, cambiar "50 => E" por "50 => QQ" (o el chunk deseado).
--
-- 4. EXPANDIR A MÚLTIPLES NIVELES:
--    Añadir un puerto "level_sel : in STD_LOGIC_VECTOR(1 downto 0)" y
--    reemplazar LEVEL_MAP por un array de mapas:
--    type all_levels_type is array (0 to 3) of map_type;
--    constant ALL_LEVELS : all_levels_type := (LEVEL_1_1, LEVEL_1_2, ...);
--    Luego indexar: ALL_LEVELS(to_integer(unsigned(level_sel)))(row)(col_safe)
--
-- 5. SCROLL EN PÍXELES VS TILES:
--    Este módulo recibe scroll en TILES. Si scroll_controller trabaja en
--    píxeles, dividir entre 16 antes de conectar aquí:
--    scroll_offset <= scroll_px(11 downto 4);  -- bits [11:4] = píxel / 16
-- =============================================================================