// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: bloque de ticks (nivel 1)
//  - tick_muestra y tick_frame llegan cada N_MUESTRA / N_FRAME ciclos
//  - tick_pelota llega cada N_PELOTA - nivel*PASO ciclos (PASO = N_PELOTA/10)
//    se prueban los 8 niveles: 100, 90, 80 ... 30 ciclos
`timescale 1ns/1ps
module tb_ticks;
    reg  clk = 0, rst = 1;
    reg  [2:0] nivel = 0;
    wire tick_pelota, tick_muestra, tick_frame;
    integer errores = 0, n, c0, c1, k;
    integer reloj = 0;
    always #5 clk = ~clk;
    always @(posedge clk) reloj = reloj + 1;
    ticks #(.N_PELOTA(100), .N_MUESTRA(10), .N_FRAME(25)) dut (
        .clk(clk), .rst(rst), .nivel(nivel),
        .tick_pelota(tick_pelota), .tick_muestra(tick_muestra), .tick_frame(tick_frame));

    initial begin
        $dumpfile("tb_ticks.vcd"); $dumpvars(0, tb_ticks);
        $display("=== Prueba: bloque de ticks ===");
        repeat (3) @(negedge clk); rst = 0;
        @(posedge tick_muestra); c0 = reloj; @(posedge tick_muestra); c1 = reloj;
        if (c1 - c0 != 10) begin $display("ERROR  tick_muestra cada %0d", c1-c0); errores = errores + 1; end
        else $display("OK     tick_muestra cada 10 ciclos");
        @(posedge tick_frame); c0 = reloj; @(posedge tick_frame); c1 = reloj;
        if (c1 - c0 != 25) begin $display("ERROR  tick_frame cada %0d", c1-c0); errores = errores + 1; end
        else $display("OK     tick_frame cada 25 ciclos");
        for (k = 0; k < 8; k = k + 1) begin
            nivel = k;
            @(posedge tick_pelota); @(posedge tick_pelota); c0 = reloj;
            @(posedge tick_pelota); c1 = reloj;
            if (c1 - c0 != 100 - 10*k) begin
                $display("ERROR  nivel %0d: tick_pelota cada %0d (esperado %0d)", k, c1-c0, 100-10*k);
                errores = errores + 1;
            end else
                $display("OK     nivel %0d: tick_pelota cada %0d ciclos (en la placa: %0d ms)", k, c1-c0, 100-10*k);
        end
        if (errores == 0) $display(">>> TICKS: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> TICKS: %0d ERRORES", errores);
        $finish;
    end
endmodule
