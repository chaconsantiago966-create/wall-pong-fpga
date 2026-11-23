// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: sincronizador de 2 flip-flops
//  - la salida sigue a la entrada con exactamente 2 ciclos de retraso
//  - un pulso de 1 ciclo tambien pasa (no se pierde)
//  - un cambio entre flancos de reloj (asincrono) se ve en el 2.o flanco siguiente
`timescale 1ns/1ps
module tb_sincronizador;
    reg  clk = 0, boton = 0;
    wire sinc;
    integer errores = 0;
    always #5 clk = ~clk;
    sincronizador dut (.clk(clk), .boton(boton), .sinc(sinc));

    task revisar(input esperado, input [8*48:1] texto);
        if (sinc !== esperado) begin $display("ERROR  %0s: sinc=%b", texto, sinc); errores = errores + 1; end
        else $display("OK     %0s: sinc=%b", texto, sinc);
    endtask

    initial begin
        $dumpfile("tb_sincronizador.vcd"); $dumpvars(0, tb_sincronizador);
        $display("=== Prueba: sincronizador ===");
        repeat (3) @(posedge clk); #1;
        revisar(0, "boton suelto");
        boton = 1;                      // cambia justo despues de un flanco
        @(posedge clk); #1; revisar(0, "1 flanco despues (todavia en ff1)");
        @(posedge clk); #1; revisar(1, "2 flancos despues (llega a sinc)");
        boton = 0;
        @(posedge clk); #1; @(posedge clk); #1; revisar(0, "suelta, 2 flancos despues");
        // pulso de un ciclo
        @(negedge clk) boton = 1; @(negedge clk) boton = 0;
        @(posedge clk); #1; revisar(1, "pulso de 1 ciclo tambien pasa");
        @(posedge clk); #1; revisar(0, "y dura solo 1 ciclo");
        // cambio asincrono (a mitad de ciclo, en un tiempo raro)
        #2.7 boton = 1;
        @(posedge clk); @(posedge clk); #1; revisar(1, "cambio asincrono: 2 flancos despues");
        if (errores == 0) $display(">>> SINCRONIZADOR: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> SINCRONIZADOR: %0d ERRORES", errores);
        $finish;
    end
endmodule
