// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Parte 1: Logica de colisiones (combinacional)
// Detecta choques usando la posicion ACTUAL y la direccion.
//   dir_x = 1 derecha, 0 izquierda
//   dir_y = 1 abajo,   0 arriba   (Y = 0 es la fila de arriba)
// =============================================================
module colisiones (
    input  [3:0] pelota_x,
    input  [3:0] pelota_y,
    input        dir_x,
    input        dir_y,
    input  [3:0] pala_y,
    output       reb_x,
    output       reb_y,
    output       gol,
    output       golpe     // la paleta devuelve la pelota (para contar tiros)
);

    // Choques con techo y piso
    wire choca_techo = (pelota_y == 4'd0)  & ~dir_y;
    wire choca_piso  = (pelota_y == 4'd15) &  dir_y;

    // Choque con la pared (la pelota rebota en X = 14)
    wire choca_pared = (pelota_x == 4'd14) &  dir_x;

    // La pelota llega a la columna de al lado de la paleta (X = 1)
    wire llega_izq   = (pelota_x == 4'd1)  & ~dir_x;

    // La pelota esta frente a la paleta (paleta ocupa pala_y, +1, +2)
    wire en_paleta   = (pelota_y >= pala_y) & (pelota_y <= pala_y + 4'd2);

    wire choca_paleta = llega_izq & en_paleta;

    // Salidas
    assign reb_y = choca_techo | choca_piso;
    assign reb_x = choca_pared | choca_paleta;
    assign gol   = llega_izq & ~en_paleta;
    assign golpe = choca_paleta;

endmodule
