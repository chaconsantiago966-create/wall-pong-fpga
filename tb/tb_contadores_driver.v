// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: contadores del driver (bits, LEDs y latch)
`timescale 1ns/1ps
module tb_contadores_driver;

    reg  clk = 0, rst = 1;
    reg  clr = 0, inc_bit = 0, inc_led = 0, en_latch = 0;
    wire bit_done, led_done, latch_done;
    wire [7:0] led_idx;

    integer errores = 0;
    integer i, ciclos;

    always #5 clk = ~clk;

    contador_bits  u_bits  (.clk(clk), .rst(rst), .clr(clr), .inc_bit(inc_bit), .bit_done(bit_done));
    contador_leds  u_leds  (.clk(clk), .rst(rst), .inc_led(inc_led), .led_idx(led_idx), .led_done(led_done));
    contador_latch u_latch (.clk(clk), .rst(rst), .en_latch(en_latch), .latch_done(latch_done));

    initial begin
        $dumpfile("tb_contadores_driver.vcd");
        $dumpvars(0, tb_contadores_driver);
        $display("=== Prueba: contadores del driver ===");
        repeat (2) @(negedge clk); rst = 0;

        // ---- contador de bits ----
        for (i = 0; i < 23; i = i + 1) begin
            if (bit_done) begin $display("ERROR  bit_done antes de tiempo (bit %0d)", i); errores = errores + 1; end
            inc_bit = 1; @(negedge clk); inc_bit = 0;
        end
        if (bit_done !== 1'b1) begin $display("ERROR  bit_done no se activo en el bit 23"); errores = errores + 1; end
        else $display("OK     bit_done = 1 en el bit 23");
        clr = 1; @(negedge clk); clr = 0;
        if (bit_done !== 1'b0) begin $display("ERROR  clr no borra"); errores = errores + 1; end
        else $display("OK     clr (load_piso) vuelve el contador a 0");

        // ---- contador de LEDs ----
        for (i = 0; i < 255; i = i + 1) begin
            inc_led = 1; @(negedge clk); inc_led = 0;
        end
        if (led_idx !== 8'd255 || led_done !== 1'b1) begin
            $display("ERROR  led_idx=%0d led_done=%b", led_idx, led_done); errores = errores + 1;
        end else $display("OK     led_idx = 255 y led_done = 1");
        inc_led = 1; @(negedge clk); inc_led = 0;
        if (led_idx !== 8'd0) begin $display("ERROR  no volvio a 0"); errores = errores + 1; end
        else $display("OK     despues de 255 vuelve solo a 0");

        // ---- contador de latch ----
        en_latch = 1; ciclos = 0;
        while (!latch_done) begin @(negedge clk); ciclos = ciclos + 1; end
        if (ciclos != 29999) begin $display("ERROR  latch_done tras %0d ciclos", ciclos); errores = errores + 1; end
        else $display("OK     latch_done a los 30 000 ciclos (300 us)");
        en_latch = 0; @(negedge clk);
        if (latch_done !== 1'b0) begin $display("ERROR  en_latch = 0 no borra"); errores = errores + 1; end
        else $display("OK     con en_latch = 0 el contador vuelve a 0");

        if (errores == 0) $display(">>> CONTADORES: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> CONTADORES: %0d ERRORES", errores);
        $finish;
    end
endmodule
