// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Bloque de RENDERIZADO (nivel 1)
// Calcula al vuelo el color del LED que el driver va a enviar,
// sin framebuffer (no se usa memoria BRAM).
//   led_idx -> mapeador_zigzag -> (x, y) -> logica_color -> color
// =============================================================
module renderizado (
    input         clk,
    input         rst,
    input         cargar_sombra,
    input  [7:0]  led_idx,
    input  [3:0]  pelota_x,
    input  [3:0]  pelota_y,
    input  [3:0]  pala_y,
    output [23:0] color
);

    wire [3:0] x, y;
    wire [3:0] s_pelota_x, s_pelota_y, s_pala_y;

    registros_sombra u_sombra (
        .clk(clk), .rst(rst), .cargar(cargar_sombra),
        .pelota_x(pelota_x), .pelota_y(pelota_y), .pala_y(pala_y),
        .s_pelota_x(s_pelota_x), .s_pelota_y(s_pelota_y), .s_pala_y(s_pala_y)
    );

    mapeador_zigzag u_zigzag (.led_idx(led_idx), .x(x), .y(y));

    logica_color u_color (
        .x(x), .y(y),
        .pelota_x(s_pelota_x), .pelota_y(s_pelota_y), .pala_y(s_pala_y),
        .color(color)
    );

endmodule
