// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: generador de bit (mide los tiempos en alto y el periodo)
`timescale 1ns/1ps
module tb_generador_bit;

    reg  clk = 0, rst = 1, tx_activo = 0, bit_actual = 0;
    wire fin_periodo, dout;

    integer errores = 0;
    reg      alto = 0;
    realtime t_sube, t_fin_ant;
    real     ancho, periodo;
    integer  n_pulsos = 0, n_fin = 0;

    always #5 clk = ~clk;

    generador_bit dut (.clk(clk), .rst(rst), .tx_activo(tx_activo),
                       .bit_actual(bit_actual), .fin_periodo(fin_periodo), .dout(dout));

    // Medir cada pulso en alto de dout
    always @(posedge dout) begin t_sube = $realtime; alto = 1; end
    always @(negedge dout) if (alto) begin
        alto  = 0;
        ancho = $realtime - t_sube;
        n_pulsos = n_pulsos + 1;
        if (n_pulsos <= 3) begin
            if (ancho != 350.0) begin $display("ERROR  bit 0: alto %0.0f ns (esperado 350)", ancho); errores = errores + 1; end
            else $display("OK     bit 0: alto %0.0f ns", ancho);
        end else begin
            if (ancho != 700.0) begin $display("ERROR  bit 1: alto %0.0f ns (esperado 700)", ancho); errores = errores + 1; end
            else $display("OK     bit 1: alto %0.0f ns", ancho);
        end
    end

    // Medir el periodo con fin_periodo
    always @(posedge clk) if (fin_periodo) begin
        n_fin = n_fin + 1;
        if (n_fin > 1) begin
            periodo = $realtime - t_fin_ant;
            if (periodo != 1250.0) begin $display("ERROR  periodo %0.0f ns (esperado 1250)", periodo); errores = errores + 1; end
        end
        t_fin_ant = $realtime;
        if (n_fin == 3) bit_actual <= 1;   // los 3 primeros bits son 0, luego 1
    end

    initial begin
        $dumpfile("tb_generador_bit.vcd");
        $dumpvars(0, tb_generador_bit);
        $display("=== Prueba: generador de bit ===");
        repeat (3) @(negedge clk); rst = 0;
        repeat (5) @(negedge clk);
        if (dout !== 1'b0) begin $display("ERROR  dout debe ser 0 sin tx_activo"); errores = errores + 1; end
        else $display("OK     dout = 0 mientras tx_activo = 0");

        tx_activo = 1;
        wait (n_fin == 6);
        @(negedge clk) tx_activo = 0;
        repeat (200) @(negedge clk);
        if (dout !== 1'b0) begin $display("ERROR  dout no queda en 0"); errores = errores + 1; end
        $display("Periodo de bit medido: %0.0f ns", periodo);

        if (errores == 0) $display(">>> GENERADOR DE BIT: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> GENERADOR DE BIT: %0d ERRORES", errores);
        $finish;
    end
endmodule
