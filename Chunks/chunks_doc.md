# Documentación del Módulo ROM_CHUNKS_MARIO

Aquí explico como funciona las chunks del proyecto como guía

Este módulo implementa la memoria ROM que contiene todos los chunks que en varios juegos son también llamados sprites reutilizables del juego Super Mario Bros. Cada chunk representa un elemento visual de 16x16 píxeles que puede ser usado múltiples veces en el escenario del juego.

## Arquitectura

### Puertos de Entrada/Salida

```vhdl
Port ( 
    clk         : in  STD_LOGIC;                      -- Reloj del sistema
    chunk_id    : in  STD_LOGIC_VECTOR(7 downto 0);   -- ID del chunk (0-255)
    pixel_x     : in  STD_LOGIC_VECTOR(3 downto 0);   -- Posición X (0-15)
    pixel_y     : in  STD_LOGIC_VECTOR(3 downto 0);   -- Posición Y (0-15)
    pixel_data  : out STD_LOGIC_VECTOR(3 downto 0)    -- Color del pixel, después discutiremos en equipo la implementación de colores
);
```

### Señales y Tipos

1. **chunk_array**: Array de 256 elementos (16x16) de 4 bits cada uno
   - Representa un chunk completo
   - Cada elemento es un pixel con valor de color de 4 bits (0-15)

2. **rom_type**: Array de 256 chunks
   - Permite almacenar hasta 256 sprites diferentes
   - Indexado por chunk_id

## Organización de IDs de Chunks

### Bloques del Escenario (IDs 0-31)
- **ID 0**: Vacío/Transparente - Para áreas sin gráficos
- **ID 1**: Bloque de Ladrillo - Los bloques rompibles
- **ID 2**: Bloque de Pregunta (?) - Contiene items
- **ID 3**: Suelo/Piso - El terreno del nivel
- **ID 4**: Bloque de Escalera - Para construir escaleras
- **ID 5**: Bloque de Castillo - Para la estructura del castillo

### Tuberías (IDs 10-17)
- **ID 10**: Tubería Tope Izquierda
- **ID 11**: Tubería Tope Derecha
- **ID 12**: Tubería Cuerpo Izquierdo
- **ID 13**: Tubería Cuerpo Derecho

**Nota**: Las tuberías se construyen usando 4 chunks:
```
[ID 10][ID 11]  <- Tope
[ID 12][ID 13]  <- Cuerpo (se repite según altura)
[ID 12][ID 13]
```

### Enemigos (IDs 32-63)
- **ID 32**: Goomba - El pequeño
- **ID 33**: Koopa Troopa - La Tortuga

### Items/Powerups (IDs 64-95)
- **ID 64**: Moneda 
- **ID 65**: Hongo Rojo - Powerup que agranda a Mario

### Decoraciones (IDs 96-127)
- **ID 96**: Nube Pequeña - Decoración de fondo
- **ID 97**: Arbusto - Decoración del suelo

### Mario (IDs 128-159)
- **ID 128**: Mario Pequeño - Sprite principal del jugador
- **ID 131**: Mario Saltando - Sprite principal del jugador

### Reservado (IDs 160-255)
- Espacio disponible por si hacen falta más chunks que no consideramos

## Sistema de Colores (4 bits = 16 colores)

Los colores están codificados en 4 bits, permitiendo 16 colores diferentes, se discutira a futuro el formato:

```
"0000" (0)  - Transparente/Vacío
"0001" (1)  - Negro
"0010" (2)  - Gris Claro
"0011" (3)  - Verde Oscuro
"0100" (4)  - Verde Claro
"0101" (5)  - Café Oscuro
"0110" (6)  - Café Claro
"0111" (7)  - Beige/Piel
"1000" (8)  - Gris Oscuro
"1001" (9)  - Café/Marrón
"1010" (10) - Azul Claro
"1011" (11) - Dorado Oscuro/Naranja
"1100" (12) - Rojo
"1101" (13) - Rosa
"1110" (14) - Amarillo/Dorado Brillante
"1111" (15) - Blanco
```

**Nota**: El color "0000" siempre se considera transparente. Cuando un pixel tiene este valor, permite que se vea el fondo detrás del sprite.

## Funcionamiento del Módulo

### 1. Inicialización

El proceso `init_rom` se ejecuta **una sola vez** al inicio:
- Inicializa todos los 256 slots como chunks vacíos
- Carga los chunks definidos en sus posiciones correspondientes
- Usa funciones especializadas para crear cada tipo de chunk

### 2. Lectura de Datos

El acceso a los datos es **síncrono** con el reloj:

```
1. Se recibe chunk_id (qué sprite queremos)
2. Se reciben pixel_x y pixel_y (qué pixel del sprite)
3. Se calcula: addr_pixel = pixel_y * 16 + pixel_x
4. En el flanco de reloj: pixel_data <= chunk_data(addr_pixel)
```

### 3. Pipeline de Lectura

```
Ciclo 0: Presentar chunk_id, pixel_x, pixel_y
Ciclo 1: Dato disponible en pixel_data
```

Latencia: **1 ciclo de reloj**

## Funciones de Inicialización

Cada función crea un patrón específico de 16x16 píxeles:

### init_empty_chunk()
Retorna un chunk completamente transparente (todos los píxeles en "0000")

### init_brick_block()
Crea un bloque de ladrillo con:
- Bordes oscuros para definición
- Patrón de ladrillos con colores alternados
- Efecto de profundidad con tonos claros/oscuros

### init_question_block()
Bloque de pregunta con:
- Fondo amarillo brillante
- Signo de interrogación blanco centrado
- Bordes definidos

### init_pipe_top_left/right()
Partes superiores de tubería con:
- Borde superior engrosado
- Verde claro en el interior
- Verde oscuro en bordes

### init_pipe_body_left/right()
Cuerpo de tubería:
- Solo bordes laterales
- Se puede apilar verticalmente

### init_goomba()
Enemigo básico:
- Cuerpo café redondeado
- Dos pies en la base
- Área transparente arriba y abajo

### init_coin()
Moneda coleccionable:
- Forma cuadrada con esquinas
- Color dorado brillante
- Borde oscuro para contraste

## Para Usar Este Módulo

### Se necesitaria una Instanciación

```vhdl
-- En módulo superior
signal chunk_sel    : std_logic_vector(7 downto 0);
signal pos_x        : std_logic_vector(3 downto 0);
signal pos_y        : std_logic_vector(3 downto 0);
signal pixel_color  : std_logic_vector(3 downto 0);

-- Instancia del módulo
rom_inst: entity work.rom_chunks_mario
    port map (
        clk        => clk,
        chunk_id   => chunk_sel,
        pixel_x    => pos_x,
        pixel_y    => pos_y,
        pixel_data => pixel_color
    );
```

### Lectura

```vhdl
-- Para leer el pixel (5,7) del bloque de ladrillo (ID=1)
process(clk)
begin
    if rising_edge(clk) then
        chunk_sel <= "00000001";  -- ID 1 = Ladrillo
        pos_x <= "0101";          -- X = 5
        pos_y <= "0111";          -- Y = 7
        -- En el siguiente ciclo, pixel_color tendrá el dato
    end if;
end process;
```

## Consideraciones

### Optimización

El diseño está optimizado para:
- **Lectura rápida**: 1 ciclo de latencia
- **Acceso aleatorio**: Cualquier chunk, cualquier pixel
- **Síntesis eficiente**: El sintetizador infiere Bloque RAM automáticamente

## Integración con el Sistema Completo

Este módulo se conectará con:

1. **RAM de Escenario**: Proporciona los chunk_ids basándose en la posición en el nivel
2. **Controlador VGA/HDMI**: Proporciona pixel_x y pixel_y basándose en la posición de pantalla
3. **Motor de Colisiones**: Usa los chunk_ids para determinar qué es sólido
4. **Sistema de Animación**: Cambia chunk_ids para animar sprites

## A realizar:

1. **Paleta de Colores**: Crear módulo que convierta los 4 bits a RGB real
2. **RAM de Escenario**: Módulo que use esta ROM para construir el nivel, eso lo hará Gamboa creo
3. **Animación**: Sistema para cambiar entre chunks para crear movimiento
