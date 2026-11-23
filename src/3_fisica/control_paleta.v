// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Parte 3e: Control de paleta con potenciometro
// Convierte la lectura del potenciometro (0..4095) en la fila
// de la paleta (0..13).
//
// 1) Escala:  fino = (pot * 14) / 256      -> 0..223
//    pot * 14 = pot*16 - pot*2 = (pot << 4) - (pot << 1)
//    dividir entre 256 = quedarse con los bits [15:8]
// 2) objetivo = fino[7:4] (0..13)   resto = fino[3:0] (0..15)
//    Cada fila de la paleta ocupa 16 valores de "fino".
// 3) Histeresis: solo se acepta el objetivo si "resto" esta en la
//    zona central 3..12 (lejos del borde entre dos filas). Asi el
//    ruido del potenciometro no hace temblar la paleta.
//    En los extremos (fila 0 y fila 13) se acepta todo el lado de afuera.
// 4) Registro con habilitacion: carga cada tick (10 ms) si es zona segura.
// =============================================================
module control_paleta (
    input            clk,
    input            rst,
    input            en_pala,     // tick_muestra (10 ms)
    input     [11:0] pot,
    output reg [3:0] pala_y
);

    // 1) Escala: pot * 14 con dos desplazamientos y una resta
    wire [15:0] pot16 = {4'd0, pot};
    wire [15:0] por14 = (pot16 << 4) - (pot16 << 1);
    wire [7:0]  fino  = por14[15:8];

    // 2) Fila objetivo y resto
    wire [3:0] objetivo = fino[7:4];
    wire [3:0] resto    = fino[3:0];

    // 3) Zona segura (histeresis)
    wire lejos_arriba = (resto >= 4'd3)  | (objetivo == 4'd0);
    wire lejos_abajo  = (resto <= 4'd12) | (objetivo == 4'd13);
    wire zona_segura  = lejos_arriba & lejos_abajo;

    wire carga = en_pala & zona_segura;

    // 4) Registro de la paleta
    always @(posedge clk) begin
        if (rst)
            pala_y <= 4'd6;
        else if (carga)
            pala_y <= objetivo;
    end

endmodule
