// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: generador de tick con periodo variable
//  - con periodo fijo los ticks llegan exactamente cada "periodo" ciclos
//  - cambiar el periodo cambia la distancia entre ticks
//  - CASO LIMITE: el periodo baja cuando la cuenta ya va mas alla del
//    nuevo valor -> el tick sale en el ciclo siguiente (no da la vuelta)
//  - periodo minimo (2) y tick de 1 ciclo
`timescale 1ns/1ps
module tb_generador_tick_var;
    reg  clk = 0, rst = 1;
    reg  [23:0] periodo = 24'd10;
    wire tick;
    integer errores = 0, ciclos = 0, ultimo = 0, dist = 0;
    always #5 clk = ~clk;
    generador_tick_var dut (.clk(clk), .rst(rst), .periodo(periodo), .tick(tick));

    always @(posedge clk) if (!rst) begin
        ciclos = ciclos + 1;
        if (tick) begin dist = ciclos - ultimo; ultimo = ciclos; end
    end

    task medir(input integer esperado, input integer veces, input [8*40:1] texto);
        integer k;
        begin
            @(posedge tick); @(negedge clk);      // sincroniza con un tick
            for (k = 0; k < veces; k = k + 1) begin
                @(posedge tick); @(negedge clk);
                if (dist != esperado) begin
                    $display("ERROR  %0s: distancia %0d (esperado %0d)", texto, dist, esperado);
                    errores = errores + 1;
                end
            end
            $display("OK     %0s: un tick cada %0d ciclos", texto, esperado);
        end
    endtask

    // Vigilante: si algun tick nunca llega (la cuenta dio la vuelta), termina con error
    initial begin
        #200000;
        $display("ERROR  tiempo agotado: un tick nunca llego");
        $display(">>> GENERADOR DE TICK VARIABLE: FALLO (tiempo agotado)");
        $finish;
    end

    integer espera;
    initial begin
        $dumpfile("tb_generador_tick_var.vcd"); $dumpvars(0, tb_generador_tick_var);
        $display("=== Prueba: generador de tick variable ===");
        repeat (3) @(negedge clk); rst = 0;
        medir(10, 5, "periodo = 10");
        periodo = 24'd7;  medir(7, 5, "periodo = 7");
        periodo = 24'd2;  medir(2, 5, "periodo minimo = 2");

        // CASO LIMITE: la cuenta ya va mas alla de 4 y el periodo baja a 4
        periodo = 24'd10;
        @(posedge tick); repeat (8) @(negedge clk);
        $display("       cuenta = %0d, se cambia el periodo de 10 a 4", dut.cuenta);
        periodo = 24'd4;
        espera = 0;
        while (!tick && espera < 20) begin @(negedge clk); espera = espera + 1; end
        if (tick && espera <= 1) $display("OK     el tick sale enseguida (%0d ciclos), no da la vuelta de 2^24", espera);
        else begin $display("ERROR  el tick tardo %0d ciclos", espera); errores = errores + 1; end
        medir(4, 5, "despues del cambio, periodo = 4");

        // el tick dura 1 ciclo
        periodo = 24'd10;
        @(posedge tick); @(negedge clk); @(negedge clk);
        if (tick) begin $display("ERROR  tick dura mas de 1 ciclo"); errores = errores + 1; end
        else $display("OK     tick dura 1 ciclo");

        if (errores == 0) $display(">>> GENERADOR DE TICK VARIABLE: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> GENERADOR DE TICK VARIABLE: %0d ERRORES", errores);
        $finish;
    end
endmodule
