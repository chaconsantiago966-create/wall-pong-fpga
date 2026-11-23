// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Bloque DRIVER WS2812B (nivel 1) = FSM de control + ruta de datos
// shift_en e inc_bit son la misma senal: tx_activo AND fin_periodo
// (cada vez que termina un bit se desplaza el PISO y se cuenta el bit).
// =============================================================
module driver_ws2812b (
    input         clk,
    input         rst,
    input         start,
    input  [23:0] color,
    output [7:0]  led_idx,
    output        listo,
    output        dout
);

    // Senales de control (FSM -> ruta de datos)
    wire load_piso, tx_activo, inc_led, en_latch;
    // Senales de estado (ruta de datos -> FSM)
    wire fin_periodo, bit_done, led_done, latch_done;
    // Internas
    wire bit_actual;
    wire shift_en = tx_activo & fin_periodo;
    wire inc_bit  = shift_en;

    fsm_driver u_fsm (
        .clk(clk), .rst(rst), .start(start),
        .fin_periodo(fin_periodo), .bit_done(bit_done),
        .led_done(led_done), .latch_done(latch_done),
        .listo(listo), .load_piso(load_piso), .tx_activo(tx_activo),
        .inc_led(inc_led), .en_latch(en_latch)
    );

    registro_piso u_piso (
        .clk(clk), .rst(rst), .load_piso(load_piso), .shift_en(shift_en),
        .color(color), .bit_actual(bit_actual)
    );

    generador_bit u_bit (
        .clk(clk), .rst(rst), .tx_activo(tx_activo), .bit_actual(bit_actual),
        .fin_periodo(fin_periodo), .dout(dout)
    );

    contador_bits  u_bits  (.clk(clk), .rst(rst), .clr(load_piso), .inc_bit(inc_bit),
                            .bit_done(bit_done));
    contador_leds  u_leds  (.clk(clk), .rst(rst), .inc_led(inc_led),
                            .led_idx(led_idx), .led_done(led_done));
    contador_latch u_latch (.clk(clk), .rst(rst), .en_latch(en_latch),
                            .latch_done(latch_done));

endmodule
