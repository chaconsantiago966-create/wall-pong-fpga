// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench Parte 3g: control de velocidad
//  - 9 golpes: el nivel NO cambia; el golpe 10 sube a nivel 1
//  - cada 10 golpes sube 1 nivel
//  - CASO LIMITE: se satura en 7 (golpe 80, 90, 100... no lo pasan a 0)
//  - un gol vuelve todo a 0 (nivel y cuenta de golpes)
//  - CASO LIMITE: golpe y gol en el mismo ciclo -> gana el gol
//  - golpes que llegan en ciclos seguidos se cuentan todos
`timescale 1ns/1ps
module tb_control_velocidad;
    reg  clk = 0, rst = 1, golpe = 0, gol = 0;
    wire [2:0] nivel;
    integer errores = 0, i;
    always #5 clk = ~clk;
    control_velocidad dut (.clk(clk), .rst(rst), .golpe(golpe), .gol(gol), .nivel(nivel));

    task golpes(input integer n);   // n golpes separados
        integer j;
        for (j = 0; j < n; j = j + 1) begin
            @(negedge clk) golpe = 1; @(negedge clk) golpe = 0; @(negedge clk);
        end
    endtask

    task revisar(input [2:0] esperado, input [8*44:1] texto);
        if (nivel !== esperado) begin $display("ERROR  %0s: nivel=%0d (esperado %0d)", texto, nivel, esperado); errores = errores + 1; end
        else $display("OK     %0s: nivel=%0d", texto, nivel);
    endtask

    initial begin
        $dumpfile("tb_control_velocidad.vcd"); $dumpvars(0, tb_control_velocidad);
        $display("=== Prueba: control de velocidad ===");
        repeat (2) @(negedge clk); rst = 0;
        revisar(0, "despues de reset");
        golpes(9);  revisar(0, "9 golpes (aun no sube)");
        golpes(1);  revisar(1, "golpe 10");
        golpes(10); revisar(2, "golpe 20");
        for (i = 3; i <= 7; i = i + 1) golpes(10);
        revisar(7, "golpe 70 (nivel maximo)");
        golpes(30); revisar(7, "golpe 100 (saturado, no vuelve a 0)");
        // gol: todo a 0
        @(negedge clk) gol = 1; @(negedge clk) gol = 0;
        revisar(0, "gol");
        golpes(9); revisar(0, "9 golpes despues del gol (la cuenta tambien se borro)");
        // golpe y gol a la vez: gana el gol
        @(negedge clk) begin golpe = 1; gol = 1; end
        @(negedge clk) begin golpe = 0; gol = 0; end
        golpes(9); revisar(0, "golpe+gol juntos y 9 golpes mas");
        golpes(1); revisar(1, "un golpe mas (contaba desde 0)");
        // golpes en ciclos seguidos
        @(negedge clk) golpe = 1; repeat (10) @(negedge clk); golpe = 0;
        revisar(2, "10 golpes en 10 ciclos seguidos");
        // reset en medio
        golpes(5); @(negedge clk) rst = 1; @(negedge clk) rst = 0;
        revisar(0, "reset");
        if (errores == 0) $display(">>> CONTROL DE VELOCIDAD: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> CONTROL DE VELOCIDAD: %0d ERRORES", errores);
        $finish;
    end
endmodule
