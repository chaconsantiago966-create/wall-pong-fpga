// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench Parte 4: registros de la pelota
`timescale 1ns/1ps
module tb_registros_pelota;

    reg        clk = 0, rst = 1, tick = 0;
    reg  [3:0] next_x = 0, next_y = 0;
    reg        next_dir_x = 0, next_dir_y = 0;
    wire [3:0] pelota_x, pelota_y;
    wire       dir_x, dir_y;

    integer errores = 0;

    always #5 clk = ~clk;

    registros_pelota dut (
        .clk(clk), .rst(rst), .tick(tick),
        .next_x(next_x), .next_y(next_y),
        .next_dir_x(next_dir_x), .next_dir_y(next_dir_y),
        .pelota_x(pelota_x), .pelota_y(pelota_y),
        .dir_x(dir_x), .dir_y(dir_y)
    );

    task revisar(input [3:0] ex, input [3:0] ey, input edx, input edy, input [8*40:1] texto);
        begin
            if (pelota_x !== ex || pelota_y !== ey || dir_x !== edx || dir_y !== edy) begin
                $display("ERROR  %0s: (%0d,%0d) dir=(%b,%b) (esperado (%0d,%0d) dir=(%b,%b))",
                         texto, pelota_x, pelota_y, dir_x, dir_y, ex, ey, edx, edy);
                errores = errores + 1;
            end else
                $display("OK     %0s: (%0d,%0d) dir=(%b,%b)", texto, pelota_x, pelota_y, dir_x, dir_y);
        end
    endtask

    initial begin
        $dumpfile("tb_registros_pelota.vcd");
        $dumpvars(0, tb_registros_pelota);
        $display("=== Prueba: registros de la pelota ===");

        repeat (2) @(negedge clk);
        rst = 0;
        revisar(7, 7, 0, 1, "despues de reset");

        // Cambian las entradas pero sin tick: no debe cargar
        next_x = 3; next_y = 9; next_dir_x = 1; next_dir_y = 0;
        repeat (5) @(negedge clk);
        revisar(7, 7, 0, 1, "sin tick no carga");

        // Pulso de tick de un ciclo: ahora si carga
        tick = 1; @(negedge clk); tick = 0;
        revisar(3, 9, 1, 0, "con tick carga");

        if (errores == 0) $display(">>> REGISTROS: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> REGISTROS: %0d ERRORES", errores);
        $finish;
    end
endmodule
