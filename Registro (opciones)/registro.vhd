library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Necesario para conversiones numéricas

entity generador_random is
    Port ( 
        CLK        : in  STD_LOGIC;
        RST        : in  STD_LOGIC;
        CHUNK_ID   : out STD_LOGIC_VECTOR (7 downto 0) -- Salida siempre válida
    );
end generador_random;

architecture Behavioral of generador_random is

    -- Registro interno de 8 bits para la aleatoriedad
    signal r_reg : STD_LOGIC_VECTOR(7 downto 0);
    signal feedback : STD_LOGIC;
    
    -- Señal auxiliar para seleccionar el chunk
    signal seleccion : STD_LOGIC_VECTOR(3 downto 0);

begin

    -- 1. GENERADOR LFSR 
    feedback <= r_reg(7) XOR r_reg(5) XOR r_reg(4) XOR r_reg(3);

    process(CLK, RST)
    begin
        if RST = '1' then
            r_reg <= "10010110"; -- Semilla inicial (no usar ceros)
        elsif rising_edge(CLK) then
            r_reg <= r_reg(6 downto 0) & feedback;
        end if;
    end process;

    -- 2. EL TRADUCTOR (Mapeo a Chunks Válidos)
    seleccion <= r_reg(3 downto 0);

    process(seleccion)
    begin
        case seleccion is
            -- TERRENO Y BLOQUES 
            when "0000" => CHUNK_ID <= "00000001"; 
            when "0001" => CHUNK_ID <= "00000010"; 
            when "0010" => CHUNK_ID <= "00000011"; 
            when "0011" => CHUNK_ID <= "00000011"; 
            
            -- DECORACIÓN Y CIELO 
            when "0100" => CHUNK_ID <= "00000000"; 
            when "0101" => CHUNK_ID <= "00000000"; 
            when "0110" => CHUNK_ID <= "01100000"; 
            when "0111" => CHUNK_ID <= "01100001"; 
            
            -- ESTRUCTURAS
            when "1000" => CHUNK_ID <= "00000100"; 
            when "1001" => CHUNK_ID <= "00001010"; 
            when "1010" => CHUNK_ID <= "00000111"; 

            -- ENEMIGOS E ITEMS
            when "1011" => CHUNK_ID <= "00100000"; 
            when "1100" => CHUNK_ID <= "00100001"; 
            when "1101" => CHUNK_ID <= "01000000"; 
            when "1110" => CHUNK_ID <= "01000010"; 
            
            -- DEFAULT 
            when others => CHUNK_ID <= "00000011"; --Suelo
        end case;
    end process;

end Behavioral;