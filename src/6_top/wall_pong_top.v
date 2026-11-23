// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// WALL-PONG - Sistema completo (nivel 0)
//
//   potenciometro -> ENTRADAS -> FISICA -> RENDERIZADO -> DRIVER -> dout
//                                  ^                         ^
//                       TICKS (pelota 100 ms -> 30 ms segun el nivel, 10 ms paleta, 10 ms frame)
//                         ^ nivel (sube cada 10 golpes de la paleta)
//
// dout sale por el pin JA1 y, con una resistencia de 330 ohm en serie,
// llega a la entrada DIN de la matriz WS2812B 16x16.
// =============================================================
module wall_pong_top #(
    parameter CANAL_AUX = 6,            // Basys 3: JXADC pin 1/7 = VAUX6
    parameter N_PELOTA  = 10_000_000,   // 100 ms
    parameter N_MUESTRA =  1_000_000,   //  10 ms
    parameter N_FRAME   =  1_000_000    //  10 ms (100 frames por segundo)
) (
    input  clk,        // 100 MHz
    input  btn_rst,    // boton central = reset
    input  btn_ext,    // boton externo de reset (Pmod JB pin 1, con pull-down)
    input  vauxp,      // cursor del potenciometro (JXADC pin 1)
    input  vauxn,      // GND del potenciometro    (JXADC pin 7)
    output dout,       // senal de datos hacia la matriz
    output led_gol,    // LED de la placa: se prende un momento con cada gol
    output [2:0] led_nivel  // LD1..LD3: nivel de velocidad en binario
);

    wire        rst;
    wire [11:0] pot;
    wire        tick_pelota, tick_muestra, tick_frame;
    wire [3:0]  pelota_x, pelota_y, pala_y;
    wire        gol;
    wire [2:0]  nivel;
    wire [7:0]  led_idx;
    wire [23:0] color;
    wire        listo;

    // Un frame nuevo solo empieza si el driver esta libre
    // start del driver: empieza un frame nuevo
    wire start = tick_frame & listo;

    entradas #(.CANAL_AUX(CANAL_AUX)) u_entradas (
        .clk(clk), .btn_rst(btn_rst), .btn_ext(btn_ext),
        .vauxp(vauxp), .vauxn(vauxn),
        .rst(rst), .pot(pot)
    );

    ticks #(.N_PELOTA(N_PELOTA), .N_MUESTRA(N_MUESTRA), .N_FRAME(N_FRAME)) u_ticks (
        .clk(clk), .rst(rst), .nivel(nivel),
        .tick_pelota(tick_pelota), .tick_muestra(tick_muestra), .tick_frame(tick_frame)
    );

    fisica_juego u_fisica (
        .clk(clk), .rst(rst), .tick(tick_pelota), .tick_pala(tick_muestra),
        .pot(pot),
        .pelota_x(pelota_x), .pelota_y(pelota_y), .pala_y(pala_y), .gol(gol), .nivel(nivel)
    );

    renderizado u_render (
        .clk(clk), .rst(rst), .cargar_sombra(start), .led_idx(led_idx),
        .pelota_x(pelota_x), .pelota_y(pelota_y), .pala_y(pala_y),
        .color(color)
    );

    driver_ws2812b u_driver (
        .clk(clk), .rst(rst), .start(start), .color(color),
        .led_idx(led_idx), .listo(listo), .dout(dout)
    );

    // LED de gol: se mantiene prendido hasta el siguiente tick de pelota
    reg gol_reg;
    always @(posedge clk) begin
        if (rst)              gol_reg <= 1'b0;
        else if (tick_pelota) gol_reg <= gol;
    end
    assign led_gol = gol_reg;
    assign led_nivel = nivel;

endmodule
