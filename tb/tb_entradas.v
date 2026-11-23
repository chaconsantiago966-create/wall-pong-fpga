// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: entradas (reset sincronizado + lectura del potenciometro por XADC)
// Usa el modelo de simulacion tb/modelos/XADC.v
`timescale 1ns/1ps
module tb_entradas;

    reg  clk = 0, btn_rst = 1, btn_ext = 0;
    wire rst;
    wire [11:0] pot;

    integer errores = 0;

    always #5 clk = ~clk;

    entradas #(.CANAL_AUX(6)) dut (
        .clk(clk), .btn_rst(btn_rst), .btn_ext(btn_ext), .vauxp(1'b0), .vauxn(1'b0),
        .rst(rst), .pot(pot)
    );

    // Pone un voltaje en el "potenciometro" y revisa la lectura
    task probar(input [11:0] valor);
        begin
            dut.u_pot.u_xadc.valor_sim = valor;
            repeat (120) @(negedge clk);     // esperar al menos una conversion
            if (pot !== valor) begin
                $display("ERROR  potenciometro en %0d, pot leido = %0d", valor, pot);
                errores = errores + 1;
            end else
                $display("OK     potenciometro en %4d (%0.2f V) -> pot = %0d", valor, valor / 4096.0, pot);
        end
    endtask

    initial begin
        $dumpfile("tb_entradas.vcd");
        $dumpvars(0, tb_entradas);
        $display("=== Prueba: entradas (reset + potenciometro) ===");

        #100;
        if (rst !== 1'b1) begin $display("ERROR  rst no sigue a btn_rst"); errores = errores + 1; end
        else $display("OK     rst = 1 mientras btn_rst = 1");
        btn_rst = 0;
        #30;
        if (rst !== 1'b0) begin $display("ERROR  rst no baja"); errores = errores + 1; end
        else $display("OK     rst baja 2 ciclos despues de soltar btn_rst");

        btn_ext = 1; #30;
        if (rst !== 1'b1) begin $display("ERROR  el boton externo no da reset"); errores = errores + 1; end
        else $display("OK     el boton externo (btn_ext) tambien da reset");
        btn_ext = 0; #30;


        probar(12'd0);
        probar(12'd1000);
        probar(12'd2048);
        probar(12'd4095);

        if (errores == 0) $display(">>> ENTRADAS: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> ENTRADAS: %0d ERRORES", errores);
        $finish;
    end
endmodule
