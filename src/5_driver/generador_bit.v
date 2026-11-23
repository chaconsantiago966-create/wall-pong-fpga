// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Driver - Generador de bit (forma de onda de cada bit)
// Un bit del WS2812B dura 1,25 us = 125 ciclos de 100 MHz.
//   bit 0: alto 350 ns (35 ciclos), luego bajo
//   bit 1: alto 700 ns (70 ciclos), luego bajo
// Contador de periodo de 7 bits: cuenta 0..124 mientras tx_activo = 1.
// fin_periodo = (cnt == 124): avisa que termino el bit.
// El MSB del registro PISO elige con un mux cual comparador sale.
// La AND con tx_activo deja la linea en 0 fuera de la transmision.
// La salida pasa por un flip-flop para que no tenga glitches.
// =============================================================
module generador_bit (
    input      clk,
    input      rst,
    input      tx_activo,
    input      bit_actual,    // MSB del registro PISO
    output     fin_periodo,
    output reg dout
);

    reg [6:0] cnt;

    // Contador de periodo
    assign fin_periodo = (cnt == 7'd124);

    always @(posedge clk) begin
        if (rst | ~tx_activo | fin_periodo)
            cnt <= 7'd0;
        else
            cnt <= cnt + 7'd1;
    end

    // Comparadores de tiempo en alto
    wire t0h = (cnt < 7'd35);     // 350 ns
    wire t1h = (cnt < 7'd70);     // 700 ns

    // Mux 2:1 y compuerta AND
    wire nivel = bit_actual ? t1h : t0h;
    wire salida = nivel & tx_activo;

    // Flip-flop de salida
    always @(posedge clk) begin
        if (rst)
            dout <= 1'b0;
        else
            dout <= salida;
    end

endmodule
