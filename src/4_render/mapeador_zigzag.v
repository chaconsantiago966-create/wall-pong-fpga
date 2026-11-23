// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Render - Mapeador zigzag inverso
// La matriz esta cableada en serpentina (zigzag):
//   fila 0 (par)  : LED 0..15   va de izquierda a derecha
//   fila 1 (impar): LED 16..31  va de derecha a izquierda
//   ...
// Del indice del LED (0..255) se sacan las coordenadas:
//   y = 4 bits altos del indice   (cada fila tiene 16 LEDs)
//   x = 4 bits bajos, invertidos si la fila es impar
// El XOR con y[0] es un "inversor controlado": en filas pares
// deja pasar los bits; en impares los invierte (15 - x = ~x).
// =============================================================
module mapeador_zigzag (
    input  [7:0] led_idx,
    output [3:0] x,
    output [3:0] y
);

    assign y = led_idx[7:4];
    assign x = led_idx[3:0] ^ {4{y[0]}};

endmodule
