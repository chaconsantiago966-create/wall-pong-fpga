// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: registros sombra
`timescale 1ns/1ps
module tb_registros_sombra;

    reg        clk = 0, rst = 1, cargar = 0;
    reg  [3:0] pelota_x = 0, pelota_y = 0, pala_y = 0;
    wire [3:0] s_pelota_x, s_pelota_y, s_pala_y;

    integer errores = 0;

    always #5 clk = ~clk;

    registros_sombra dut (.clk(clk), .rst(rst), .cargar(cargar),
        .pelota_x(pelota_x), .pelota_y(pelota_y), .pala_y(pala_y),
        .s_pelota_x(s_pelota_x), .s_pelota_y(s_pelota_y), .s_pala_y(s_pala_y));

    task revisar(input [3:0] a, input [3:0] b, input [3:0] c, input [8*30:1] texto);
        begin
            if (s_pelota_x !== a || s_pelota_y !== b || s_pala_y !== c) begin
                $display("ERROR  %0s: (%0d,%0d) pala=%0d", texto, s_pelota_x, s_pelota_y, s_pala_y);
                errores = errores + 1;
            end else
                $display("OK     %0s: (%0d,%0d) pala=%0d", texto, s_pelota_x, s_pelota_y, s_pala_y);
        end
    endtask

    initial begin
        $dumpfile("tb_registros_sombra.vcd");
        $dumpvars(0, tb_registros_sombra);
        $display("=== Prueba: registros sombra ===");
        repeat (2) @(negedge clk); rst = 0;
        revisar(7, 7, 6, "despues de reset");

        pelota_x = 3; pelota_y = 12; pala_y = 9;
        repeat (4) @(negedge clk);
        revisar(7, 7, 6, "sin cargar no cambia");

        cargar = 1; @(negedge clk); cargar = 0;
        revisar(3, 12, 9, "con cargar copia");

        pelota_x = 4;
        repeat (4) @(negedge clk);
        revisar(3, 12, 9, "frame en curso: congelado");

        if (errores == 0) $display(">>> REGISTROS SOMBRA: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> REGISTROS SOMBRA: %0d ERRORES", errores);
        $finish;
    end
endmodule
