// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Bloque de ENTRADAS (nivel 1)
//   btn_rst OR btn_ext -> sincronizador -> rst
//   (btn_ext = boton externo, en el Pmod JB)
//   potenciometro  -> lector_pot (XADC) -> pot [11:0]
// =============================================================
module entradas #(
    parameter CANAL_AUX = 6
) (
    input         clk,
    input         btn_rst,     // boton central de la placa
    input         btn_ext,     // boton externo de reset (Pmod JB1)
    input         vauxp,
    input         vauxn,
    output        rst,
    output [11:0] pot
);

    sincronizador u_sinc_rst   (.clk(clk), .boton(btn_rst | btn_ext), .sinc(rst));

    lector_pot #(.CANAL_AUX(CANAL_AUX)) u_pot (
        .clk(clk), .rst(rst), .vauxp(vauxp), .vauxn(vauxn), .pot(pot)
    );

endmodule
