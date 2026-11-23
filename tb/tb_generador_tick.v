// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: generador de tick
`timescale 1ns/1ps
module tb_generador_tick;

    reg  clk = 0, rst = 1;
    wire tick;

    integer errores = 0;
    integer ciclos = 0, n_ticks = 0, ultimo = 0;

    always #5 clk = ~clk;

    generador_tick #(.N(10)) dut (.clk(clk), .rst(rst), .tick(tick));

    // Mide la distancia en ciclos entre ticks
    always @(posedge clk) begin
        if (!rst) begin
            ciclos = ciclos + 1;
            if (tick) begin
                n_ticks = n_ticks + 1;
                if (n_ticks > 1 && (ciclos - ultimo) != 10) begin
                    $display("ERROR  tick %0d llego %0d ciclos despues del anterior", n_ticks, ciclos - ultimo);
                    errores = errores + 1;
                end
                ultimo = ciclos;
            end
        end
    end

    initial begin
        $dumpfile("tb_generador_tick.vcd");
        $dumpvars(0, tb_generador_tick);
        $display("=== Prueba: generador de tick (N = 10) ===");
        repeat (3) @(negedge clk);
        rst = 0;
        repeat (100) @(negedge clk);
        $display("Ticks en 100 ciclos: %0d (esperado 10)", n_ticks);
        if (n_ticks != 10) errores = errores + 1;

        // tick debe durar un solo ciclo
        @(posedge tick); @(negedge clk); @(negedge clk);
        if (tick !== 1'b0) begin $display("ERROR  tick dura mas de 1 ciclo"); errores = errores + 1; end
        else $display("OK     tick dura 1 ciclo y llega cada 10 ciclos");

        if (errores == 0) $display(">>> GENERADOR DE TICK: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> GENERADOR DE TICK: %0d ERRORES", errores);
        $finish;
    end
endmodule
