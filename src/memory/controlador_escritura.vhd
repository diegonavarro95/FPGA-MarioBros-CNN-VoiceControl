library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controlador_escritura is
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        pixel_x  : out STD_LOGIC_VECTOR(3 downto 0);
        pixel_y  : out STD_LOGIC_VECTOR(3 downto 0);
        ram_we   : out STD_LOGIC;
        next_chunk : out STD_LOGIC -- Pulso para cambiar el ID aleatorio
    );
end controlador_escritura;

architecture Behavioral of controlador_escritura is
    signal count_x : unsigned(3 downto 0) := (others => '0');
    signal count_y : unsigned(3 downto 0) := (others => '0');
    signal escribiendo : std_logic := '1';
begin

    process(clk, rst)
    begin
        if rst = '1' then
            count_x <= (others => '0');
            count_y <= (others => '0');
            next_chunk <= '0';
        elsif rising_edge(clk) then
            next_chunk <= '0';
            
            if count_x = 15 then
                count_x <= (others => '0');
                if count_y = 15 then
                    count_y <= (others => '0');
                    next_chunk <= '1'; -- Ya llenamos la RAM, pedir nuevo chunk
                else
                    count_y <= count_y + 1;
                end if;
            else
                count_x <= count_x + 1;
            end if;
        end if;
    end process;

    pixel_x <= std_logic_vector(count_x);
    pixel_y <= std_logic_vector(count_y);
    ram_we  <= '1'; -- Siempre escribiendo mientras recorremos

end Behavioral;