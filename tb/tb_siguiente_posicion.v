// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench Parte 3: siguiente posicion
`timescale 1ns/1ps
module tb_siguiente_posicion;

    reg  [3:0] pelota_x, pelota_y;
    reg        next_dir_x, next_dir_y, gol;
    wire [3:0] next_x, next_y;

    integer errores = 0;

    siguiente_posicion dut (
        .pelota_x(pelota_x), .pelota_y(pelota_y),
        .next_dir_x(next_dir_x), .next_dir_y(next_dir_y), .gol(gol),
        .next_x(next_x), .next_y(next_y)
    );

    task probar(input [3:0] x, input [3:0] y, input ndx, input ndy, input g,
                input [3:0] e_x, input [3:0] e_y);
        begin
            pelota_x = x; pelota_y = y; next_dir_x = ndx; next_dir_y = ndy; gol = g;
            #10;
            if (next_x !== e_x || next_y !== e_y) begin
                $display("ERROR  (%0d,%0d) dir=(%b,%b) gol=%b -> (%0d,%0d) (esperado (%0d,%0d))",
                         x, y, ndx, ndy, g, next_x, next_y, e_x, e_y);
                errores = errores + 1;
            end else
                $display("OK     (%0d,%0d) dir=(%b,%b) gol=%b -> (%0d,%0d)",
                         x, y, ndx, ndy, g, next_x, next_y);
        end
    endtask

    initial begin
        $dumpfile("tb_siguiente_posicion.vcd");
        $dumpvars(0, tb_siguiente_posicion);
        $display("=== Prueba: siguiente posicion ===");

        //      x   y  ndx ndy gol   x'  y'
        probar( 7,  7, 1,  1,  0,    8,  8);  // derecha y abajo
        probar( 7,  7, 0,  0,  0,    6,  6);  // izquierda y arriba
        probar(14,  5, 0,  1,  0,   13,  6);  // ejemplo del resumen: rebote en pared
        probar( 1,  0, 1,  1,  0,    2,  1);  // rebote en esquina paleta/techo
        probar( 5, 15, 1,  0,  0,    6, 14);  // rebote en piso
        probar( 1,  3, 0,  1,  1,    7,  7);  // gol: saque en (7,7)

        if (errores == 0) $display(">>> SIGUIENTE POSICION: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> SIGUIENTE POSICION: %0d ERRORES", errores);
        $finish;
    end
endmodule
