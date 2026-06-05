library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM_Ventana is
    Port (
        clk      : in  STD_LOGIC;
        we       : in  STD_LOGIC;
        addr     : in  STD_LOGIC_VECTOR(7 downto 0);
        data_in  : in  STD_LOGIC_VECTOR(2 downto 0);
        data_out : out STD_LOGIC_VECTOR(2 downto 0)
    );
end RAM_Ventana;

architecture Behavioral of RAM_Ventana is
    type ram_type is array (0 to 255) of STD_LOGIC_VECTOR(2 downto 0);
    signal RAM : ram_type := (others => "000");
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                RAM(to_integer(unsigned(addr))) <= data_in;
            end if;
            data_out <= RAM(to_integer(unsigned(addr)));
        end if;
    end process;
end Behavioral;
