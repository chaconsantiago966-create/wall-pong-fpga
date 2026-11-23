// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: registro PISO (carga en paralelo, sale en serie MSB primero)
`timescale 1ns/1ps
module tb_registro_piso;

    reg         clk = 0, rst = 1, load_piso = 0, shift_en = 0;
    reg  [23:0] color = 24'hA5C30F;
    wire        bit_actual;
    reg  [23:0] recibido;

    integer errores = 0;
    integer i;

    always #5 clk = ~clk;

    registro_piso dut (.clk(clk), .rst(rst), .load_piso(load_piso), .shift_en(shift_en),
                       .color(color), .bit_actual(bit_actual));

    initial begin
        $dumpfile("tb_registro_piso.vcd");
        $dumpvars(0, tb_registro_piso);
        $display("=== Prueba: registro PISO ===");
        repeat (2) @(negedge clk); rst = 0;

        load_piso = 1; @(negedge clk); load_piso = 0;

        // Leer los 24 bits uno por uno, desplazando despues de cada lectura
        for (i = 0; i < 24; i = i + 1) begin
            recibido = {recibido[22:0], bit_actual};
            shift_en = 1; @(negedge clk); shift_en = 0;
            repeat (2) @(negedge clk);       // entre desplazamientos se mantiene
        end

        if (recibido !== color) begin
            $display("ERROR  recibido %h, cargado %h", recibido, color);
            errores = errores + 1;
        end else
            $display("OK     se cargo %h y salieron en serie los mismos 24 bits (MSB primero)", recibido);

        if (errores == 0) $display(">>> REGISTRO PISO: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> REGISTRO PISO: %0d ERRORES", errores);
        $finish;
    end
endmodule
