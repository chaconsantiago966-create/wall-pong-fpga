// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Driver - Contador de LEDs (8 bits): 0..255
// Su valor es led_idx, el LED que se esta enviando.
// led_done = 1 en el ultimo LED (255). Al sumar 1 desde 255
// vuelve solo a 0 (suma modulo 256), listo para el otro frame.
// =============================================================
module contador_leds (
    input        clk,
    input        rst,
    input        inc_led,
    output [7:0] led_idx,
    output       led_done
);

    reg [7:0] cnt;

    assign led_idx  = cnt;
    assign led_done = (cnt == 8'd255);

    always @(posedge clk) begin
        if (rst)
            cnt <= 8'd0;
        else if (inc_led)
            cnt <= cnt + 8'd1;
    end

endmodule
