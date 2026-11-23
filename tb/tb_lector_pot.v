// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: lector del potenciometro (con el modelo del XADC)
//  - despues de reset pot = 0
//  - pot toma DO[15:4] del XADC en cada conversion
//  - casos limite: 0, 4095 (extremos) y un valor intermedio
//  - pot solo cambia cuando llega DRDY (no en otros ciclos)
`timescale 1ns/1ps
module tb_lector_pot;
    reg  clk = 0, rst = 1;
    wire [11:0] pot;
    integer errores = 0, cambios = 0;
    reg  [11:0] pot_ant;
    always #5 clk = ~clk;
    lector_pot #(.CANAL_AUX(6)) dut (.clk(clk), .rst(rst), .vauxp(1'b0), .vauxn(1'b0), .pot(pot));

    // pot solo puede cambiar en el ciclo siguiente a DRDY
    always @(posedge clk) pot_ant <= pot;
    reg drdy_d = 0;
    always @(posedge clk) drdy_d <= dut.drdy;
    always @(negedge clk) if (!rst && pot !== pot_ant && !drdy_d) begin
        $display("ERROR  pot cambio sin DRDY"); errores = errores + 1;
    end

    task probar(input [11:0] v);
        begin
            dut.u_xadc.valor_sim = v;
            repeat (120) @(posedge clk);       // mas de 2 conversiones
            #1;
            if (pot !== v) begin $display("ERROR  valor_sim=%0d -> pot=%0d", v, pot); errores = errores + 1; end
            else $display("OK     voltaje -> %4d   pot = %4d", v, pot);
        end
    endtask

    initial begin
        $dumpfile("tb_lector_pot.vcd"); $dumpvars(0, tb_lector_pot);
        $display("=== Prueba: lector del potenciometro (XADC) ===");
        $display("Canal del XADC = %0d (VAUX6 = 0x16 = 22)", dut.u_xadc.CHANNEL);
        if (dut.u_xadc.CHANNEL !== 5'd22) errores = errores + 1;
        repeat (3) @(posedge clk); #1;
        if (pot !== 12'd0) begin $display("ERROR  pot no es 0 en reset"); errores = errores + 1; end
        else $display("OK     en reset pot = 0");
        rst = 0;
        probar(12'd0);      // potenciometro al minimo
        probar(12'd4095);   // al maximo
        probar(12'd1902);   // centro de la fila 6
        probar(12'd1);      // casi minimo
        if (errores == 0) $display(">>> LECTOR POT: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> LECTOR POT: %0d ERRORES", errores);
        $finish;
    end
endmodule
