// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench Parte 3e: control de paleta con potenciometro
`timescale 1ns/1ps
module tb_control_paleta;

    reg         clk = 0, rst = 1, en_pala = 0;
    reg  [11:0] pot = 0;
    wire [3:0]  pala_y;

    integer errores = 0;
    integer k;

    always #5 clk = ~clk;

    control_paleta dut (.clk(clk), .rst(rst), .en_pala(en_pala), .pot(pot), .pala_y(pala_y));

    // Valor del potenciometro que cae en el centro de la fila k
    function [11:0] centro(input integer fila);
        centro = ((16 * fila + 8) * 256) / 14;
    endfunction

    task muestra;   // un pulso de en_pala (como tick_muestra)
        begin
            @(negedge clk) en_pala = 1;
            @(negedge clk) en_pala = 0;
        end
    endtask

    task probar(input [11:0] valor, input [3:0] esperado, input [8*36:1] texto);
        begin
            pot = valor;
            muestra;
            if (pala_y !== esperado) begin
                $display("ERROR  %0s: pot=%0d -> pala_y=%0d (esperado %0d)", texto, valor, pala_y, esperado);
                errores = errores + 1;
            end else
                $display("OK     %0s: pot=%4d -> pala_y=%0d", texto, valor, pala_y);
        end
    endtask

    initial begin
        $dumpfile("tb_control_paleta.vcd");
        $dumpvars(0, tb_control_paleta);
        $display("=== Prueba: control de paleta con potenciometro ===");
        repeat (2) @(negedge clk); rst = 0;
        if (pala_y !== 4'd6) begin $display("ERROR  reset"); errores = errores + 1; end
        else $display("OK     despues de reset: pala_y=6");

        // Sin pulso de en_pala no se mueve
        pot = 12'd4095;
        repeat (5) @(negedge clk);
        if (pala_y !== 4'd6) begin $display("ERROR  se movio sin en_pala"); errores = errores + 1; end
        else $display("OK     sin en_pala no se mueve");

        // Extremos
        probar(12'd0,    4'd0,  "potenciometro al minimo");
        probar(12'd4095, 4'd13, "potenciometro al maximo");

        // El centro de cada fila lleva la paleta a esa fila
        for (k = 0; k <= 13; k = k + 1) begin
            pot = centro(k);
            muestra;
            if (pala_y != k) begin
                $display("ERROR  centro de la fila %0d (pot=%0d) -> pala_y=%0d", k, pot, pala_y);
                errores = errores + 1;
            end
        end
        if (errores == 0) $display("OK     las 14 filas se alcanzan con el centro de su rango");

        // Histeresis: justo en el borde entre la fila 6 y la 7 no cambia
        probar(centro(6), 4'd6, "centro de la fila 6");
        probar(12'd2048,  4'd6, "borde 6/7 viniendo de 6 (se queda)");
        probar(centro(7), 4'd7, "centro de la fila 7");
        probar(12'd2048,  4'd7, "borde 6/7 viniendo de 7 (se queda)");
        probar(12'd2060,  4'd7, "ruido en el borde (se queda)");

        if (errores == 0) $display(">>> CONTROL DE PALETA: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> CONTROL DE PALETA: %0d ERRORES", errores);
        $finish;
    end
endmodule
