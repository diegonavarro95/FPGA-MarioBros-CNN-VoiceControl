-- ROM de Chunks OPTIMIZADA - Super Mario Bros FPGA
-- Checar los readmes para explicación
--NOTA: Los loops en las funciones:
--for y in 0 to 15 loop
--    for x in 0 to 15 loop
-- Se desenrollan completamente en tiempo de compilación. 
--El sintetizador los ejecuta una vez y genera 256 asignaciones constantes.
--No deberian de ser tan complejos de procesar, pero si no estan de acuerdo con el uso de for los cambio.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rom_chunks_mario is
    Port ( 
        clk         : in  STD_LOGIC;
        chunk_id    : in  STD_LOGIC_VECTOR(7 downto 0);  -- ID del chunk (0-255)
        pixel_x     : in  STD_LOGIC_VECTOR(3 downto 0);  -- Posicion X dentro del chunk (0-15)
        pixel_y     : in  STD_LOGIC_VECTOR(3 downto 0);  -- Posicion Y dentro del chunk (0-15)
        pixel_data  : out STD_LOGIC_VECTOR(3 downto 0)   -- Color del pixel (4 bits)
    );
end rom_chunks_mario;

architecture Behavioral of rom_chunks_mario is
    
    -- Tipo para almacenar un chunk completo de 16x16 pixels
    type chunk_array is array (0 to 255) of STD_LOGIC_VECTOR(3 downto 0);
    type rom_type is array (0 to 255) of chunk_array;
    
    function init_empty_chunk return chunk_array is
        variable temp : chunk_array;
    begin
        for i in 0 to 255 loop
            temp(i) := "0000";  -- Color 0 = transparente
        end loop;
        return temp;
    end function;
    
    function init_brick_block return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y = 0 or y = 15 or x = 0 or x = 15) then
                    temp(y*16 + x) := "1000";
                elsif ((y mod 8) < 4 and (x mod 8) < 4) then
                    temp(y*16 + x) := "1100";
                else
                    temp(y*16 + x) := "1001";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_question_block return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y = 0 or y = 15 or x = 0 or x = 15) then
                    temp(y*16 + x) := "1011";
                elsif (x >= 6 and x <= 9 and y >= 3 and y <= 12) then
                    temp(y*16 + x) := "1111";
                else
                    temp(y*16 + x) := "1110";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_ground_block return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if ((x + y) mod 2 = 0) then
                    temp(y*16 + x) := "0110";
                else
                    temp(y*16 + x) := "0101";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_pipe_top_left return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (x < 2 or y < 2) then
                    temp(y*16 + x) := "0011";
                else
                    temp(y*16 + x) := "0100";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_pipe_top_right return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (x > 13 or y < 2) then
                    temp(y*16 + x) := "0011";
                else
                    temp(y*16 + x) := "0100";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_pipe_body_left return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (x < 2) then
                    temp(y*16 + x) := "0011";
                else
                    temp(y*16 + x) := "0100";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_pipe_body_right return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (x > 13) then
                    temp(y*16 + x) := "0011";
                else
                    temp(y*16 + x) := "0100";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_goomba return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y < 4) then
                    temp(y*16 + x) := "0000";
                elsif (y < 10 and x >= 2 and x <= 13) then
                    temp(y*16 + x) := "1001";
                elsif (y >= 10 and y < 14 and ((x >= 1 and x <= 6) or (x >= 9 and x <= 14))) then
                    temp(y*16 + x) := "1001";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_koopa return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y < 3 or y > 12) then
                    temp(y*16 + x) := "0000";
                elsif ((x >= 3 and x <= 12) and (y >= 3 and y <= 12)) then
                    if ((x + y) mod 3 = 0) then
                        temp(y*16 + x) := "0100";
                    else
                        temp(y*16 + x) := "0011";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_coin return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 4 and y <= 11 and x >= 4 and x <= 11) then
                    if (x = 4 or x = 11 or y = 4 or y = 11) then
                        temp(y*16 + x) := "1011";
                    else
                        temp(y*16 + x) := "1110";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_mushroom return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y < 5) then
                    temp(y*16 + x) := "0000";
                elsif (y >= 5 and y < 10 and x >= 2 and x <= 13) then
                    if ((x + y) mod 2 = 0) then
                        temp(y*16 + x) := "1100";
                    else
                        temp(y*16 + x) := "1111";
                    end if;
                elsif (y >= 10 and x >= 5 and x <= 10) then
                    temp(y*16 + x) := "0111";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_cloud_small return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 3 and y <= 8 and x >= 2 and x <= 13) then
                    temp(y*16 + x) := "1111";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_bush return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 8 and x >= 1 and x <= 14) then
                    temp(y*16 + x) := "0100";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_mario_small return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 2 and y <= 5 and x >= 5 and x <= 10) then
                    temp(y*16 + x) := "0111";
                elsif (y >= 6 and y <= 11 and x >= 4 and x <= 11) then
                    temp(y*16 + x) := "1100";
                elsif (y >= 12 and y <= 14 and ((x >= 4 and x <= 6) or (x >= 9 and x <= 11))) then
                    temp(y*16 + x) := "1001";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_stair_block return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                temp(y*16 + x) := "1011";
            end loop;
        end loop;
        return temp;
    end function;
    
    function init_castle_block return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if ((x + y) mod 3 = 0) then
                    temp(y*16 + x) := "1000";
                else
                    temp(y*16 + x) := "0010";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_pipe_red_top_left return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (x < 2 or y < 2) then
                    temp(y*16 + x) := "1001";
                else
                    temp(y*16 + x) := "1100";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_pipe_yellow_top_left return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (x < 2 or y < 2) then
                    temp(y*16 + x) := "1011";
                else
                    temp(y*16 + x) := "1110";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_cloud_left return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 4 and y <= 10) then
                    if (x >= 3 and x <= 15) then
                        temp(y*16 + x) := "1111";
                    elsif (x = 2 and y >= 5 and y <= 9) then
                        temp(y*16 + x) := "1111";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_cloud_center return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 4 and y <= 10) then
                    temp(y*16 + x) := "1111";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_cloud_right return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 4 and y <= 10) then
                    if (x >= 0 and x <= 12) then
                        temp(y*16 + x) := "1111";
                    elsif (x = 13 and y >= 5 and y <= 9) then
                        temp(y*16 + x) := "1111";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_bush_left return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 9 and y <= 15) then
                    if (x >= 1 and x <= 15) then
                        temp(y*16 + x) := "0100";
                    elsif (x = 0 and y >= 10 and y <= 14) then
                        temp(y*16 + x) := "0100";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                elsif (y >= 6 and y <= 8 and x >= 6 and x <= 15) then
                    temp(y*16 + x) := "0100";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_bush_center return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 9 and y <= 15) then
                    temp(y*16 + x) := "0100";
                elsif (y >= 6 and y <= 8) then
                    temp(y*16 + x) := "0100";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_bush_right return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 9 and y <= 15) then
                    if (x >= 0 and x <= 14) then
                        temp(y*16 + x) := "0100";
                    elsif (x = 15 and y >= 10 and y <= 14) then
                        temp(y*16 + x) := "0100";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                elsif (y >= 6 and y <= 8 and x >= 0 and x <= 9) then
                    temp(y*16 + x) := "0100";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_hill_small return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 12) then
                    if (x >= 2 and x <= 13) then
                        temp(y*16 + x) := "0100";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                elsif (y >= 10 and y < 12) then
                    if (x >= 4 and x <= 11) then
                        temp(y*16 + x) := "0100";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                elsif (y >= 8 and y < 10) then
                    if (x >= 6 and x <= 9) then
                        temp(y*16 + x) := "0100";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_mario_big_top return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 1 and y <= 7 and x >= 4 and x <= 11) then
                    if (y <= 4) then
                        temp(y*16 + x) := "0111";
                    else
                        temp(y*16 + x) := "1100";
                    end if;
                elsif (y >= 8 and y <= 15 and x >= 3 and x <= 12) then
                    temp(y*16 + x) := "1100";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_mario_big_bottom return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 0 and y <= 11 and x >= 3 and x <= 12) then
                    temp(y*16 + x) := "1100";
                elsif (y >= 12 and y <= 15) then
                    if ((x >= 3 and x <= 6) or (x >= 9 and x <= 12)) then
                        temp(y*16 + x) := "1001";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_mario_jump return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 2 and y <= 5 and x >= 5 and x <= 10) then
                    temp(y*16 + x) := "0111";
                elsif (y >= 5 and y <= 7 and ((x >= 2 and x <= 4) or (x >= 11 and x <= 13))) then
                    temp(y*16 + x) := "0111";
                elsif (y >= 6 and y <= 11 and x >= 4 and x <= 11) then
                    temp(y*16 + x) := "1100";
                elsif (y >= 12 and y <= 14 and x >= 5 and x <= 10) then
                    temp(y*16 + x) := "1001";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_koopa_walk return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 3 and y <= 9 and x >= 3 and x <= 12) then
                    if ((x + y) mod 3 = 0) then
                        temp(y*16 + x) := "0100";
                    else
                        temp(y*16 + x) := "0011";
                    end if;
                elsif (y >= 1 and y <= 3 and x >= 6 and x <= 9) then
                    temp(y*16 + x) := "1110";
                elsif (y >= 10 and y <= 13) then
                    if ((x >= 4 and x <= 5) or (x >= 10 and x <= 11)) then
                        temp(y*16 + x) := "1110";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_goomba_squashed return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 12 and y <= 15 and x >= 1 and x <= 14) then
                    temp(y*16 + x) := "1001";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_fire_flower return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (x >= 7 and x <= 8 and y >= 8 and y <= 15) then
                    temp(y*16 + x) := "0100";
                elsif (y >= 3 and y <= 9) then
                    if ((x >= 5 and x <= 6) or (x >= 9 and x <= 10)) then
                        temp(y*16 + x) := "1100";
                    elsif (y >= 3 and y <= 5 and x >= 7 and x <= 8) then
                        temp(y*16 + x) := "1100";
                    elsif (y >= 7 and y <= 9 and x >= 7 and x <= 8) then
                        temp(y*16 + x) := "1100";
                    elsif (y >= 5 and y <= 7 and x >= 7 and x <= 8) then
                        temp(y*16 + x) := "1111";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_star return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y = 8 and x >= 4 and x <= 11) then
                    temp(y*16 + x) := "1110";
                elsif (x = 8 and y >= 4 and y <= 11) then
                    temp(y*16 + x) := "1110";
                elsif ((y >= 5 and y <= 7) or (y >= 9 and y <= 11)) then
                    if ((x >= 5 and x <= 7) or (x >= 9 and x <= 10)) then
                        temp(y*16 + x) := "1110";
                    else
                        temp(y*16 + x) := "0000";
                    end if;
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_brick_used return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y = 0 or y = 15 or x = 0 or x = 15) then
                    temp(y*16 + x) := "1000";
                else
                    temp(y*16 + x) := "1001";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_metal_block return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y = 0 or y = 15 or x = 0 or x = 15) then
                    temp(y*16 + x) := "1000";
                elsif ((x + y) mod 2 = 0) then
                    temp(y*16 + x) := "0010";
                else
                    temp(y*16 + x) := "1000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_flag_pole return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (x >= 7 and x <= 8) then
                    temp(y*16 + x) := "0111";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;

    function init_flag return chunk_array is
        variable temp : chunk_array;
    begin
        for y in 0 to 15 loop
            for x in 0 to 15 loop
                if (y >= 2 and y <= 9 and x >= 0 and x <= 6) then
                    temp(y*16 + x) := "1111";
                else
                    temp(y*16 + x) := "0000";
                end if;
            end loop;
        end loop;
        return temp;
    end function;
    
    -- CONSTANTE ROM: Se inicializa en tiempo de compilación
    constant ROM_CHUNKS : rom_type := (
        0   => init_empty_chunk,
        1   => init_brick_block,
        2   => init_question_block,
        3   => init_ground_block,
        4   => init_stair_block,
        5   => init_castle_block,
        6   => init_brick_used,
        7   => init_metal_block,
        8   => init_flag_pole,
        9   => init_flag,
        10  => init_pipe_top_left,
        11  => init_pipe_top_right,
        12  => init_pipe_body_left,
        13  => init_pipe_body_right,
        14  => init_pipe_red_top_left,
        15  => init_pipe_yellow_top_left,
        32  => init_goomba,
        33  => init_koopa,
        34  => init_koopa_walk,
        35  => init_goomba_squashed,
        64  => init_coin,
        65  => init_mushroom,
        66  => init_fire_flower,
        67  => init_star,
        96  => init_cloud_small,
        97  => init_bush,
        98  => init_cloud_left,
        99  => init_cloud_center,
        100 => init_cloud_right,
        101 => init_bush_left,
        102 => init_bush_center,
        103 => init_bush_right,
        104 => init_hill_small,
        128 => init_mario_small,
        129 => init_mario_big_top,
        130 => init_mario_big_bottom,
        131 => init_mario_jump,
        others => init_empty_chunk
    );
    
begin

    -- Acceso directo en un solo ciclo - sin señales intermedias
    read_process: process(clk)
        variable addr_pixel : integer range 0 to 255;
    begin
        if rising_edge(clk) then
            -- Calcular dirección del pixel
            addr_pixel := to_integer(unsigned(pixel_y)) * 16 + to_integer(unsigned(pixel_x));
            
            -- ACCESO DIRECTO: Elimina multiplexor de 1024 bits
            pixel_data <= ROM_CHUNKS(to_integer(unsigned(chunk_id)))(addr_pixel);
        end if;
    end process;

end Behavioral;