// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Render - Logica de color
// Decide de que color va el LED (x, y). Colores en orden GRB
// (Verde, Rojo, Azul), que es el orden que espera el WS2812B.
// Brillo bajo: 0x20 en vez de 0xFF.
// Prioridad: pelota > paleta > pared > fondo
// (una cadena de multiplexores: el primero que se cumple gana).
// =============================================================
module logica_color (
    input  [3:0]  x,
    input  [3:0]  y,
    input  [3:0]  pelota_x,
    input  [3:0]  pelota_y,
    input  [3:0]  pala_y,
    output [23:0] color
);

    //                       G      R      B
    localparam BLANCO = 24'h20_20_20;
    localparam AZUL   = 24'h00_00_20;
    localparam ROJO   = 24'h00_20_00;
    localparam NEGRO  = 24'h00_00_00;

    // Comparadores
    wire es_pelota = (x == pelota_x) & (y == pelota_y);
    wire es_paleta = (x == 4'd0) & (y >= pala_y) & (y <= pala_y + 4'd2);
    wire es_pared  = (x == 4'd15);

    // Cadena de multiplexores (prioridad)
    wire [23:0] c_pared  = es_pared  ? ROJO   : NEGRO;
    wire [23:0] c_paleta = es_paleta ? AZUL   : c_pared;
    assign      color    = es_pelota ? BLANCO : c_paleta;

endmodule
