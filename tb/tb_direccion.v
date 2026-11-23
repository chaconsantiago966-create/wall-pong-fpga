// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench Parte 2: direccion
`timescale 1ns/1ps
module tb_direccion;

    reg  dir_x, dir_y, reb_x, reb_y, gol;
    wire next_dir_x, next_dir_y;

    integer errores = 0;

    direccion dut (
        .dir_x(dir_x), .dir_y(dir_y), .reb_x(reb_x), .reb_y(reb_y), .gol(gol),
        .next_dir_x(next_dir_x), .next_dir_y(next_dir_y)
    );

    task probar(input dx, input dy, input rx, input ry, input g,
                input e_ndx, input e_ndy);
        begin
            dir_x = dx; dir_y = dy; reb_x = rx; reb_y = ry; gol = g;
            #10;
            if (next_dir_x !== e_ndx || next_dir_y !== e_ndy) begin
                $display("ERROR  dir=(%b,%b) reb=(%b,%b) gol=%b -> next=(%b,%b) (esperado %b,%b)",
                         dx, dy, rx, ry, g, next_dir_x, next_dir_y, e_ndx, e_ndy);
                errores = errores + 1;
            end else
                $display("OK     dir=(%b,%b) reb=(%b,%b) gol=%b -> next=(%b,%b)",
                         dx, dy, rx, ry, g, next_dir_x, next_dir_y);
        end
    endtask

    initial begin
        $dumpfile("tb_direccion.vcd");
        $dumpvars(0, tb_direccion);
        $display("=== Prueba: direccion ===");

        //     dx dy rx ry gol   ndx ndy
        probar(1, 1, 0, 0, 0,    1,  1);  // sin rebote: sigue igual
        probar(0, 0, 0, 0, 0,    0,  0);  // sin rebote: sigue igual
        probar(1, 1, 1, 0, 0,    0,  1);  // rebote en X: invierte X
        probar(0, 1, 1, 0, 0,    1,  1);  // rebote en paleta: ahora a la derecha
        probar(1, 0, 0, 1, 0,    1,  1);  // rebote en techo: ahora baja
        probar(0, 1, 1, 1, 0,    1,  0);  // esquina: invierte las dos
        probar(0, 1, 0, 0, 1,    0,  1);  // gol: X forzado a izquierda
        probar(1, 0, 0, 1, 1,    0,  1);  // gol + techo: X izq, Y invierte

        if (errores == 0) $display(">>> DIRECCION: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> DIRECCION: %0d ERRORES", errores);
        $finish;
    end
endmodule
