// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Parte 3: Siguiente posicion (combinacional)
// Mux elige +1 (0001) o -1 (1111) segun la nueva direccion.
// Sumador de 4 bits (el acarreo se descarta: suma modulo 16).
// Mux final: si hay gol, la pelota vuelve a (7, 7).
// =============================================================
module siguiente_posicion (
    input  [3:0] pelota_x,
    input  [3:0] pelota_y,
    input        next_dir_x,
    input        next_dir_y,
    input        gol,
    output [3:0] next_x,
    output [3:0] next_y
);

    // Mux de +1 / -1
    wire [3:0] dx = next_dir_x ? 4'b0001 : 4'b1111;
    wire [3:0] dy = next_dir_y ? 4'b0001 : 4'b1111;

    // Sumadores de 4 bits
    wire [3:0] suma_x = pelota_x + dx;
    wire [3:0] suma_y = pelota_y + dy;

    // Mux de saque
    assign next_x = gol ? 4'd7 : suma_x;
    assign next_y = gol ? 4'd7 : suma_y;

endmodule
