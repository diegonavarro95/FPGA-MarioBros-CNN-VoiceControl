# Integración del Módulo ROM_CHUNKS_MARIO


## Conexión con el Módulo RAM de Escenario

El módulo RAM de Escenario el que va a armar el nivel usando los chunks de la ROM.

### Diagrama de Conexión

```
┌──────────────────────┐
│   RAM ESCENARIO      │
│  (Nivel 1-1)         │
│                      │
│  Entrada: pos_x, y   │
│  Salida: chunk_id    │──────┐
└──────────────────────┘      │
                               │
                               ▼
                        ┌──────────────────────┐
                        │   ROM CHUNKS         │
                        │                      │
                        │  Entrada: chunk_id   │
                        │           pixel_x    │◄─── Controlador VGA
                        │           pixel_y    │
                        │  Salida: pixel_data  │────► Paleta de Colores
                        └──────────────────────┘
```

### Más o menos quedaría así

```vhdl
-- En el top level:
architecture Behavioral of mario_top is
    
    -- Señales de interconexión
    signal escenario_chunk_id : std_logic_vector(7 downto 0);
    signal rom_pixel_x        : std_logic_vector(3 downto 0);
    signal rom_pixel_y        : std_logic_vector(3 downto 0);
    signal rom_pixel_data     : std_logic_vector(3 downto 0);
    signal tile_x             : std_logic_vector(9 downto 0);  -- Posición en el escenario
    signal tile_y             : std_logic_vector(9 downto 0);
    
begin

    -- Instancia de RAM de Escenario
    escenario_inst: entity work.ram_escenario
        port map (
            clk      => clk,
            tile_x   => tile_x,
            tile_y   => tile_y,
            chunk_id => escenario_chunk_id
        );
    
    -- Instancia de ROM de Chunks
    rom_chunks_inst: entity work.rom_chunks_mario
        port map (
            clk        => clk,
            chunk_id   => escenario_chunk_id,
            pixel_x    => rom_pixel_x,
            pixel_y    => rom_pixel_y,
            pixel_data => rom_pixel_data
        );

end Behavioral;
```

---

## Conexión con el Controlador VGA/HDMI

Aunque aún falta tiempo para desarrollar esta parte, el planteamiento de esta parte quedaría de la sigueinte manera: el controlador de video necesita saber qué pixel mostrar en cada posición de la pantalla.

### Proceso de Renderizado

```vhdl
-- Proceso que conecta las coordenadas de pantalla con el sistema de chunks
render_process: process(clk)
    variable screen_x : integer range 0 to 639;   -- Coordenada de pantalla
    variable screen_y : integer range 0 to 479;
    variable chunk_x  : integer range 0 to 15;    -- Pixel dentro del chunk
    variable chunk_y  : integer range 0 to 15;
begin
    if rising_edge(clk) then
        
        -- Obtener coordenadas actuales del VGA controller
        screen_x := to_integer(unsigned(vga_x));
        screen_y := to_integer(unsigned(vga_y));
        
        -- Calcular qué tile del escenario corresponde
        -- (asumiendo chunks de 16x16 y que queremos mostrar 40 tiles horizontales)
        tile_x <= std_logic_vector(to_unsigned(screen_x / 16, 10));
        tile_y <= std_logic_vector(to_unsigned(screen_y / 16, 10));
        
        -- Calcular posición dentro del chunk (0-15)
        chunk_x := screen_x mod 16;
        chunk_y := screen_y mod 16;
        
        rom_pixel_x <= std_logic_vector(to_unsigned(chunk_x, 4));
        rom_pixel_y <= std_logic_vector(to_unsigned(chunk_y, 4));
        
    end if;
end process;
```

---

## Sistema de Scroll Horizontal

Para que el nivel se desplace:

```vhdl
architecture Behavioral of scroll_controller is
    
    signal scroll_offset : unsigned(15 downto 0) := (others => '0');  -- Offset en pixels
    signal mario_x       : unsigned(9 downto 0);  -- Posición de Mario
    
begin

    scroll_process: process(clk)
        variable adjusted_x : integer;
    begin
        if rising_edge(clk) then
            
            -- Si Mario pasa la mitad de la pantalla, hacer scroll
            if mario_x > 320 then
                scroll_offset <= scroll_offset + 1;  -- Avanzar 1 pixel por frame
            end if;
            
            -- Calcular posición ajustada por scroll
            adjusted_x := to_integer(unsigned(vga_x)) + to_integer(scroll_offset);
            
            -- Calcular tile considerando el scroll
            tile_x <= std_logic_vector(to_unsigned(adjusted_x / 16, 10));
            
        end if;
    end process;

end Behavioral;
```

---

## Múltiples Capas

Para sprites sobre el fondo (Mario, enemigos, items):

```vhdl
architecture Behavioral of layer_compositor is
    
    signal bg_pixel    : std_logic_vector(3 downto 0);  -- Pixel del fondo
    signal sprite_pixel: std_logic_vector(3 downto 0);  -- Pixel del sprite
    signal final_pixel : std_logic_vector(3 downto 0);  -- Pixel final
    
begin

    -- Instancia para el fondo
    bg_rom: entity work.rom_chunks_mario
        port map (
            clk        => clk,
            chunk_id   => bg_chunk_id,
            pixel_x    => pixel_x,
            pixel_y    => pixel_y,
            pixel_data => bg_pixel
        );
    
    -- Instancia para sprites
    sprite_rom: entity work.rom_chunks_mario
        port map (
            clk        => clk,
            chunk_id   => sprite_chunk_id,
            pixel_x    => sprite_offset_x,
            pixel_y    => sprite_offset_y,
            pixel_data => sprite_pixel
        );
    
    -- Sprite tiene prioridad si no es transparente
    compositor_process: process(clk)
    begin
        if rising_edge(clk) then
            if sprite_pixel = "0000" then
                final_pixel <= bg_pixel;         -- Mostrar fondo
            else
                final_pixel <= sprite_pixel;     -- Mostrar sprite
            end if;
        end if;
    end process;

end Behavioral;
```

---

## Paleta de Colores

Convierte los 4 bits de color a RGB real, pero aún falta evaluar esa parte:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity palette_rgb is
    Port ( 
        color_index : in  STD_LOGIC_VECTOR(3 downto 0);
        rgb_out     : out STD_LOGIC_VECTOR(23 downto 0)  -- 8 bits por canal
    );
end palette_rgb;

architecture Behavioral of palette_rgb is
begin

    process(color_index)
    begin
        case color_index is
            when "0000" => rgb_out <= x"5C94FC";  -- Azul cielo (transparente->fondo)
            when "0001" => rgb_out <= x"000000";  -- Negro
            when "0010" => rgb_out <= x"BCBCBC";  -- Gris claro
            when "0011" => rgb_out <= x"008800";  -- Verde oscuro
            when "0100" => rgb_out <= x"00D800";  -- Verde claro
            when "0101" => rgb_out <= x"7C4C00";  -- Café oscuro
            when "0110" => rgb_out <= x"C49C00";  -- Café claro
            when "0111" => rgb_out <= x"FCA044";  -- Beige/Piel
            when "1000" => rgb_out <= x"444444";  -- Gris oscuro
            when "1001" => rgb_out <= x"7C5800";  -- Café/Marrón
            when "1010" => rgb_out <= x"00A8E4";  -- Azul claro
            when "1011" => rgb_out <= x"E87000";  -- Naranja/Dorado oscuro
            when "1100" => rgb_out <= x"E40058";  -- Rojo
            when "1101" => rgb_out <= x"F878F8";  -- Rosa
            when "1110" => rgb_out <= x"FCE840";  -- Amarillo/Dorado brillante
            when "1111" => rgb_out <= x"FCFCFC";  -- Blanco
            when others => rgb_out <= x"FF00FF";  -- Magenta (error)
        end case;
    end process;

end Behavioral;
```

---

## Animación

Para animar sprites cambiando entre chunks:

```vhdl
architecture Behavioral of animation_controller is
    
    signal frame_counter : unsigned(23 downto 0) := (others => '0');
    signal animation_frame : integer range 0 to 3 := 0;
    signal mario_chunk_id : std_logic_vector(7 downto 0);
    
    -- IDs de chunks para animación de Mario caminando, quizá aquí habría que crear aún más chunks
    type mario_walk_frames is array (0 to 3) of std_logic_vector(7 downto 0);
    constant MARIO_WALK : mario_walk_frames := (
        x"80",  -- Frame 0: Mario parado
        x"81",  -- Frame 1: Mario paso 1
        x"80",  -- Frame 2: Mario parado
        x"82"   -- Frame 3: Mario paso 2
    );
    
begin

    -- Contador de frames (cambiar cada ~0.1 segundos a 100MHz)
    animation_process: process(clk)
    begin
        if rising_edge(clk) then
            
            frame_counter <= frame_counter + 1;
            
            -- Cambiar frame cada 10,000,000 ciclos (0.1s @ 100MHz)
            if frame_counter = 10000000 then
                frame_counter <= (others => '0');
                
                -- Avanzar al siguiente frame de animación
                if animation_frame = 3 then
                    animation_frame <= 0;
                else
                    animation_frame <= animation_frame + 1;
                end if;
            end if;
            
            -- Seleccionar el chunk correspondiente al frame actual
            mario_chunk_id <= MARIO_WALK(animation_frame);
            
        end if;
    end process;

end Behavioral;
```

---

## Gestión de Sprites en Movimiento

Para manejar múltiples sprites (enemigos, items):

```vhdl
architecture Behavioral of sprite_manager is
    
    -- Tabla de sprites activos (hasta 16 sprites simultáneos)
    type sprite_table is array (0 to 15) of record
        active    : std_logic;
        chunk_id  : std_logic_vector(7 downto 0);
        pos_x     : unsigned(9 downto 0);
        pos_y     : unsigned(9 downto 0);
    end record;
    
    signal sprites : sprite_table;
    
begin

    -- Inicializar sprites
    init_process: process
    begin
        -- Goomba en posición (100, 200)
        sprites(0).active   <= '1';
        sprites(0).chunk_id <= x"20";  -- ID 32 = Goomba
        sprites(0).pos_x    <= to_unsigned(100, 10);
        sprites(0).pos_y    <= to_unsigned(200, 10);
        
        -- Koopa en posición (200, 200)
        sprites(1).active   <= '1';
        sprites(1).chunk_id <= x"21";  -- ID 33 = Koopa
        sprites(1).pos_x    <= to_unsigned(200, 10);
        sprites(1).pos_y    <= to_unsigned(200, 10);
        
        -- Resto inactivos
        for i in 2 to 15 loop
            sprites(i).active <= '0';
        end loop;
        
        wait;
    end process;
    
    -- Renderizar sprites sobre el fondo
    render_sprites: process(clk)
        variable in_sprite : boolean;
        variable sprite_pixel_x : integer;
        variable sprite_pixel_y : integer;
    begin
        if rising_edge(clk) then
            
            in_sprite := false;
            
            -- Buscar si la posición actual está dentro de algún sprite
            for i in 0 to 15 loop
                if sprites(i).active = '1' then
                    
                    -- Verificar si estamos dentro del sprite
                    if (screen_x >= sprites(i).pos_x and 
                        screen_x < sprites(i).pos_x + 16 and
                        screen_y >= sprites(i).pos_y and 
                        screen_y < sprites(i).pos_y + 16) then
                        
                        in_sprite := true;
                        
                        -- Calcular posición relativa dentro del sprite
                        sprite_pixel_x := to_integer(screen_x - sprites(i).pos_x);
                        sprite_pixel_y := to_integer(screen_y - sprites(i).pos_y);
                        
                        -- Usar este chunk
                        sprite_chunk_id <= sprites(i).chunk_id;
                        sprite_offset_x <= std_logic_vector(to_unsigned(sprite_pixel_x, 4));
                        sprite_offset_y <= std_logic_vector(to_unsigned(sprite_pixel_y, 4));
                        
                        exit;  -- Usar el primer sprite encontrado
                    end if;
                    
                end if;
            end loop;
            
            -- Si no estamos en ningún sprite, usar chunk transparente
            if not in_sprite then
                sprite_chunk_id <= x"00";
            end if;
            
        end if;
    end process;

end Behavioral;
```
