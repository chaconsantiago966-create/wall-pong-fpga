// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Parte 6: FSM de fisica del juego (todo junto)
// Une los bloques igual que en el diagrama:
//   control_paleta -> colisiones -> direccion
//   -> siguiente_posicion -> registros_pelota
//   control_velocidad sube el nivel cada 10 golpes de la paleta
// =============================================================
module fisica_juego (
    input        clk,
    input        rst,
    input        tick,        // mueve la pelota (100 ms en la placa)
    input        tick_pala,   // lee el potenciometro (10 ms en la placa)
    input [11:0] pot,         // lectura del potenciometro (0..4095)
    output [3:0] pelota_x,
    output [3:0] pelota_y,
    output [3:0] pala_y,
    output       gol,
    output [2:0] nivel        // 0..7: velocidad de la pelota
);

    // Cables internos
    wire       dir_x, dir_y;
    wire       reb_x, reb_y;
    wire       next_dir_x, next_dir_y;
    wire [3:0] next_x, next_y;
    wire       golpe;

    // Solo cuenta en el tick en que la pelota de verdad se mueve
    // (si no, un golpe se contaria millones de veces: dura todo el tick).
    control_velocidad u_velocidad (
        .clk   (clk),
        .rst   (rst),
        .golpe (golpe & tick),
        .gol   (gol & tick),
        .nivel (nivel)
    );

    control_paleta u_paleta (
        .clk      (clk),
        .rst      (rst),
        .en_pala  (tick_pala),
        .pot      (pot),
        .pala_y   (pala_y)
    );

    colisiones u_colisiones (
        .pelota_x (pelota_x),
        .pelota_y (pelota_y),
        .dir_x    (dir_x),
        .dir_y    (dir_y),
        .pala_y   (pala_y),
        .reb_x    (reb_x),
        .reb_y    (reb_y),
        .gol      (gol),
        .golpe    (golpe)
    );

    direccion u_direccion (
        .dir_x      (dir_x),
        .dir_y      (dir_y),
        .reb_x      (reb_x),
        .reb_y      (reb_y),
        .gol        (gol),
        .next_dir_x (next_dir_x),
        .next_dir_y (next_dir_y)
    );

    siguiente_posicion u_siguiente (
        .pelota_x   (pelota_x),
        .pelota_y   (pelota_y),
        .next_dir_x (next_dir_x),
        .next_dir_y (next_dir_y),
        .gol        (gol),
        .next_x     (next_x),
        .next_y     (next_y)
    );

    registros_pelota u_registros (
        .clk        (clk),
        .rst        (rst),
        .tick       (tick),
        .next_x     (next_x),
        .next_y     (next_y),
        .next_dir_x (next_dir_x),
        .next_dir_y (next_dir_y),
        .pelota_x   (pelota_x),
        .pelota_y   (pelota_y),
        .dir_x      (dir_x),
        .dir_y      (dir_y)
    );

endmodule
