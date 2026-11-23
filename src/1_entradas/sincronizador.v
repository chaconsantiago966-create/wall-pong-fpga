// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Entradas - Sincronizador de 2 flip-flops
// El boton cambia en cualquier momento (no respeta el reloj).
// Dos registros en serie evitan la metaestabilidad: el segundo
// siempre entrega un valor estable de 0 o 1.
// =============================================================
module sincronizador (
    input      clk,
    input      boton,       // pin fisico del boton
    output reg sinc         // boton ya sincronizado con clk
);

    reg ff1;

    always @(posedge clk) begin
        ff1  <= boton;      // primer flip-flop (puede quedar inestable)
        sinc <= ff1;        // segundo flip-flop (valor estable)
    end

endmodule
