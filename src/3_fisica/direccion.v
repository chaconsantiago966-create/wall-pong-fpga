// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Parte 2: Direccion (combinacional)
// Si hay rebote se invierte la direccion (XOR).
// Si hay gol, next_dir_x se fuerza a 0 (saque hacia el jugador).
// =============================================================
module direccion (
    input  dir_x,
    input  dir_y,
    input  reb_x,
    input  reb_y,
    input  gol,
    output next_dir_x,
    output next_dir_y
);

    assign next_dir_x = (dir_x ^ reb_x) & ~gol;
    assign next_dir_y =  dir_y ^ reb_y;

endmodule
