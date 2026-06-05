`timescale 1ns / 1ps
// =============================================================================
// VIDEO_GENERATOR_VGA.V
// Generador de tiempos para VGA a 640x480 @ 60Hz
// Requiere un reloj de entrada (clk_25MHz) de exactamente 25 MHz.
// =============================================================================

module video_generator_vga (
    input  wire       clk_25MHz, // Reloj de píxel
    input  wire       rst,
    output wire       hsync,     // Sincronización Horizontal
    output wire       vsync,     // Sincronización Vertical
    output wire       video_on,  // 1 = Área visible, 0 = Zona de borrado (Blanking)
    output wire [9:0] pixel_x,   // Coordenada X actual (0 a 639)
    output wire [9:0] pixel_y    // Coordenada Y actual (0 a 479)
);

    // -------------------------------------------------------------------------
    // PARÁMETROS ESTÁNDAR VESA PARA 640x480 @ 60Hz (Reloj = 25.175 MHz ~ 25 MHz)
    // -------------------------------------------------------------------------
    // Tiempos Horizontales (en píxeles)
    localparam H_ACTIVE = 640;  // Área visible
    localparam H_FP     = 16;   // Front Porch (Margen derecho)
    localparam H_SYNC   = 96;   // Pulso de sincronía
    localparam H_BP     = 48;   // Back Porch (Margen izquierdo)
    localparam H_TOTAL  = H_ACTIVE + H_FP + H_SYNC + H_BP; // 800

    // Tiempos Verticales (en líneas)
    localparam V_ACTIVE = 480;  // Área visible
    localparam V_FP     = 10;   // Front Porch (Margen inferior)
    localparam V_SYNC   = 2;    // Pulso de sincronía
    localparam V_BP     = 33;   // Back Porch (Margen superior)
    localparam V_TOTAL  = V_ACTIVE + V_FP + V_SYNC + V_BP; // 525

    // -------------------------------------------------------------------------
    // CONTADORES DE PÍXELES Y LÍNEAS
    // -------------------------------------------------------------------------
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == (H_TOTAL - 1)) begin
                h_count <= 0;
                
                // Al terminar una línea horizontal, incrementamos la vertical
                if (v_count == (V_TOTAL - 1)) begin
                    v_count <= 0;
                end else begin
                    v_count <= v_count + 1;
                end
                
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // GENERACIÓN DE SEÑALES DE CONTROL
    // NOTA: Para 640x480, el estándar VGA requiere sincronía negativa (Lógica 0)
    // -------------------------------------------------------------------------
    assign hsync = ~(h_count >= (H_ACTIVE + H_FP) && h_count < (H_ACTIVE + H_FP + H_SYNC));
    assign vsync = ~(v_count >= (V_ACTIVE + V_FP) && v_count < (V_ACTIVE + V_FP + V_SYNC));

    // 'video_on' avisa al resto del hardware si estamos en la zona de dibujo
    assign video_on = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

    // Salida de coordenadas (Solo son válidas dentro del área visible)
    assign pixel_x = (video_on) ? h_count : 10'd0;
    assign pixel_y = (video_on) ? v_count : 10'd0;

endmodule

