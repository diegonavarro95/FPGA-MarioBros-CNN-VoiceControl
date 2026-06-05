`timescale 1ns / 1ps

module Ctop (
    input  wire       CLK,
    input  wire       RST,
    output wire [2:0] RAM_DATA_OUT, 
    output wire [3:0] out_x,        // NUEVO: Para que C++ sepa la coordenada X
    output wire [3:0] out_y         // NUEVO: Para que C++ sepa la coordenada Y
);

    // Señales de interconexión
    wire [7:0] chunk_id;
    wire [3:0] p_x;
    wire [3:0] p_y;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [3:0] p_data;
    /* verilator lint_on UNUSEDSIGNAL */
    reg  [2:0] p_data_reg;
    wire       ram_we;
    wire       sig_next;
    reg  [7:0] ram_addr;

    // 1. CONTROLADOR: Genera X, Y y controla el flujo
    controlador_escritura CTRL (
        .clk(CLK),
        .rst(RST),
        .pixel_x(p_x),
        .pixel_y(p_y),
        .ram_we(ram_we),
        .next_chunk(sig_next)
    );

    // 2. GENERADOR: Cambia de chunk cuando el controlador termina un bloque
    generador_random GEN (
        .CLK(CLK),
        .RST(RST),
        .EN(sig_next),  
        .CHUNK_ID(chunk_id)
    );

    // 3. ROM: Lee el color del pixel actual (p_x, p_y)
    rom_chunks_mario ROM_INST (
        .clk(CLK),
        .chunk_id(chunk_id),
        .pixel_x(p_x),
        .pixel_y(p_y),
        .pixel_data(p_data)
    );

    // Registro para sincronizar: La ROM tarda 1 ciclo, 
    // por lo que la RAM debe recibir el dato sincronizado.
    always @(posedge CLK) begin
        // La dirección de RAM se forma concatenando Y y X (8 bits total)
        ram_addr   <= {p_y, p_x}; 
        p_data_reg <= p_data[2:0];
    end

    // 4. RAM: Almacena el resultado
    ram_ventana RAM_INST (
        .clk(CLK),
        .we(ram_we),
        .addr(ram_addr),
        .data_in(p_data_reg),
        .data_out(RAM_DATA_OUT)
    );

    // Asignamos las señales internas a las salidas para el simulador C++
    assign out_x = p_x;
    assign out_y = p_y;

endmodule

