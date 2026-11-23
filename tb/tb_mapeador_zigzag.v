// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: mapeador zigzag (revisa los 256 LEDs)
`timescale 1ns/1ps
module tb_mapeador_zigzag;

    reg  [7:0] led_idx;
    wire [3:0] x, y;

    integer errores = 0;
    integer i, ex, ey;

    mapeador_zigzag dut (.led_idx(led_idx), .x(x), .y(y));

    initial begin
        $dumpfile("tb_mapeador_zigzag.vcd");
        $dumpvars(0, tb_mapeador_zigzag);
        $display("=== Prueba: mapeador zigzag ===");

        for (i = 0; i < 256; i = i + 1) begin
            led_idx = i;
            #1;
            // Modelo de referencia: fila = i / 16; columna segun fila par/impar
            ey = i / 16;
            if (ey % 2 == 0) ex = i % 16;
            else             ex = 15 - (i % 16);
            if (x != ex || y != ey) begin
                $display("ERROR  led %0d -> (%0d,%0d), esperado (%0d,%0d)", i, x, y, ex, ey);
                errores = errores + 1;
            end
        end

        // Algunos ejemplos para ver
        led_idx = 0;   #1 $display("led   0 -> (x=%0d, y=%0d)", x, y);
        led_idx = 15;  #1 $display("led  15 -> (x=%0d, y=%0d)", x, y);
        led_idx = 16;  #1 $display("led  16 -> (x=%0d, y=%0d)  <- fila impar: empieza a la derecha", x, y);
        led_idx = 31;  #1 $display("led  31 -> (x=%0d, y=%0d)", x, y);
        led_idx = 255; #1 $display("led 255 -> (x=%0d, y=%0d)", x, y);

        if (errores == 0) $display(">>> MAPEADOR ZIGZAG: LOS 256 LEDS CORRECTOS");
        else              $display(">>> MAPEADOR ZIGZAG: %0d ERRORES", errores);
        $finish;
    end
endmodule
