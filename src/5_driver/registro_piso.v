// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Driver - Registro PISO de 24 bits (entrada paralela, salida serie)
//   load_piso = 1 : carga los 24 bits del color (GRB)
//   shift_en  = 1 : desplaza a la izquierda (sale el siguiente bit)
// El WS2812B recibe primero el bit mas significativo (G7),
// por eso la salida serie es piso[23].
// =============================================================
module registro_piso (
    input             clk,
    input             rst,
    input             load_piso,
    input             shift_en,
    input      [23:0] color,
    output            bit_actual
);

    reg [23:0] piso;

    assign bit_actual = piso[23];

    always @(posedge clk) begin
        if (rst)
            piso <= 24'd0;
        else if (load_piso)
            piso <= color;
        else if (shift_en)
            piso <= {piso[22:0], 1'b0};
    end

endmodule
