library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TOP is
    Port (
        CLK : in  STD_LOGIC;
        RST : in  STD_LOGIC;
        RAM_DATA_OUT : out STD_LOGIC_VECTOR(2 downto 0) -- Para ver la salida
    );
end TOP;

architecture Structural of TOP is
    signal chunk_id   : STD_LOGIC_VECTOR(7 downto 0);
    signal p_x, p_y   : STD_LOGIC_VECTOR(3 downto 0);
    signal p_data     : STD_LOGIC_VECTOR(3 downto 0);
    signal p_data_reg : STD_LOGIC_VECTOR(2 downto 0);
    signal ram_we     : STD_LOGIC;
    signal sig_next   : STD_LOGIC;
    signal ram_addr   : STD_LOGIC_VECTOR(7 downto 0);
begin

    -- 1. CONTROLADOR: Genera X, Y y controla el flujo
    CTRL: entity work.controlador_escritura
        port map(
            clk        => CLK,
            rst        => RST,
            pixel_x    => p_x,
            pixel_y    => p_y,
            ram_we     => ram_we,
            next_chunk => sig_next
        );

    -- 2. GENERADOR: Solo cambia cuando el controlador termina un bloque
    GEN: entity work.generador_random
        port map(
            CLK      => CLK,
            RST      => RST,
            EN       => sig_next,
            CHUNK_ID => chunk_id
        );

    -- 3. ROM: Lee el color del pixel actual (p_x, p_y)
    ROM_INST: entity work.rom_chunks_mario
        port map(
            clk        => CLK,
            chunk_id   => chunk_id,
            pixel_x    => p_x,
            pixel_y    => p_y,
            pixel_data => p_data
        );

    -- Registro para sincronizar: La ROM tarda 1 ciclo, 
    -- por lo que la RAM debe recibir el dato sincronizado.
    process(CLK)
    begin
        if rising_edge(CLK) then
            ram_addr <= p_y & p_x; -- La dirección sigue a p_x y p_y
            p_data_reg <= p_data(2 downto 0);
        end if;
    end process;

    -- 4. RAM: Almacena el resultado
    RAM_INST: entity work.RAM_Ventana
        port map(
            clk      => CLK,
            we       => ram_we,
            addr     => ram_addr,
            data_in  => p_data_reg,
            data_out => RAM_DATA_OUT
        );

end Structural;