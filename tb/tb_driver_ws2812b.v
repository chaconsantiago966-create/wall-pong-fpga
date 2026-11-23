// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Testbench: driver WS2812B completo
// Envia un frame de 256 LEDs con colores de prueba, decodifica la
// senal dout como lo haria la matriz y compara bit por bit.
// Ademas mide T0H, T1H y el tiempo de latch.
// =============================================================
`timescale 1ns/1ps
module tb_driver_ws2812b;

    reg         clk = 0, rst = 1, start = 0;
    wire [7:0]  led_idx;
    wire        listo, dout;
    // Color de prueba distinto para cada LED
    wire [23:0] color = {led_idx, ~led_idx, led_idx ^ 8'h5A};

    integer errores = 0;
    integer n_bits = 0, n_led, i;
    reg  [23:0] rx;              // bits del LED que se esta recibiendo
    reg  [23:0] esperado;
    reg      alto = 0;           // 1 = se vio la subida del pulso
    realtime t_sube, t_baja, t_inicio, t_fin;
    real     ancho, bajo_max;
    integer  n_t0h_mal = 0, n_t1h_mal = 0;

    always #5 clk = ~clk;

    driver_ws2812b dut (.clk(clk), .rst(rst), .start(start), .color(color),
                        .led_idx(led_idx), .listo(listo), .dout(dout));

    // ---------- Decodificador (hace lo mismo que el chip WS2812B) ----------
    always @(posedge dout) begin
        if (n_bits == 0) t_inicio = $realtime;
        t_sube = $realtime;
        alto   = 1;
    end

    always @(negedge dout) if (alto) begin
        alto   = 0;
        t_baja = $realtime;
        ancho  = t_baja - t_sube;
        // Pulso corto = 0, pulso largo = 1
        rx = {rx[22:0], (ancho > 500.0)};
        if (ancho < 500.0 && ancho != 350.0) n_t0h_mal = n_t0h_mal + 1;
        if (ancho > 500.0 && ancho != 700.0) n_t1h_mal = n_t1h_mal + 1;
        n_bits = n_bits + 1;
        // Cada 24 bits se completa un LED
        if (n_bits % 24 == 0) begin
            n_led = n_bits / 24 - 1;
            esperado = {n_led[7:0], ~n_led[7:0], n_led[7:0] ^ 8'h5A};
            if (rx !== esperado) begin
                if (errores < 10)
                    $display("ERROR  LED %0d: recibido %h, esperado %h", n_led, rx, esperado);
                errores = errores + 1;
            end
        end
    end

    initial begin
        $dumpfile("tb_driver_ws2812b.vcd");
        $dumpvars(0, tb_driver_ws2812b);
        $display("=== Prueba: driver WS2812B (un frame de 256 LEDs) ===");
        repeat (3) @(negedge clk); rst = 0;
        repeat (3) @(negedge clk);

        start = 1; @(negedge clk); start = 0;

        // Esperar a que la FSM entre a RESET_LATCH y luego vuelva a IDLE
        wait (dut.en_latch == 1'b1);
        t_fin = $realtime;
        wait (listo == 1'b1);
        bajo_max = $realtime - t_baja;

        $display("Bits recibidos: %0d (esperado %0d)", n_bits, 256 * 24);
        if (n_bits != 256 * 24) errores = errores + 1;

        if (n_t0h_mal == 0) $display("OK     todos los bits 0 con T0H = 350 ns");
        else begin $display("ERROR  %0d bits 0 con T0H distinto", n_t0h_mal); errores = errores + 1; end
        if (n_t1h_mal == 0) $display("OK     todos los bits 1 con T1H = 700 ns");
        else begin $display("ERROR  %0d bits 1 con T1H distinto", n_t1h_mal); errores = errores + 1; end

        $display("Linea en 0 despues del ultimo bit: %0.1f us (minimo 280 us)", bajo_max / 1000.0);
        if (bajo_max < 280_000.0) errores = errores + 1;
        $display("Duracion de los datos del frame: %0.2f ms", (t_fin - t_inicio) / 1_000_000.0);

        if (errores == 0) $display(">>> DRIVER WS2812B: LOS 256 LEDS LLEGARON CORRECTOS");
        else              $display(">>> DRIVER WS2812B: %0d ERRORES", errores);
        $finish;
    end
endmodule
