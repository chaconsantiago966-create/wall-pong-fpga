// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench Parte 1: logica de colisiones
`timescale 1ns/1ps
module tb_colisiones;

    reg  [3:0] pelota_x, pelota_y, pala_y;
    reg        dir_x, dir_y;
    wire       reb_x, reb_y, gol, golpe;

    integer errores = 0;

    colisiones dut (
        .pelota_x(pelota_x), .pelota_y(pelota_y),
        .dir_x(dir_x), .dir_y(dir_y), .pala_y(pala_y),
        .reb_x(reb_x), .reb_y(reb_y), .gol(gol), .golpe(golpe)
    );

    // Pone las entradas, espera y compara con lo esperado
    task probar(input [3:0] x, input [3:0] y, input dx, input dy, input [3:0] p,
                input e_rx, input e_ry, input e_gol);
        begin
            pelota_x = x; pelota_y = y; dir_x = dx; dir_y = dy; pala_y = p;
            #10;
            // golpe = rebote en la PALETA (no en la pared): reb_x estando en X = 1
            if (reb_x !== e_rx || reb_y !== e_ry || gol !== e_gol || golpe !== (e_rx && x == 4'd1)) begin
                $display("ERROR  pelota=(%0d,%0d) dir=(%b,%b) pala=%0d -> reb_x=%b reb_y=%b gol=%b (esperado %b %b %b)",
                         x, y, dx, dy, p, reb_x, reb_y, gol, e_rx, e_ry, e_gol);
                errores = errores + 1;
            end else
                $display("OK     pelota=(%0d,%0d) dir=(%b,%b) pala=%0d -> reb_x=%b reb_y=%b gol=%b",
                         x, y, dx, dy, p, reb_x, reb_y, gol);

        end
    endtask

    initial begin
        $dumpfile("tb_colisiones.vcd");
        $dumpvars(0, tb_colisiones);
        $display("=== Prueba: logica de colisiones ===");

        //      x   y  dx dy pala   reb_x reb_y gol
        probar( 7,  7, 0, 1,  6,    0,    0,    0);  // en el centro: nada
        probar( 5,  0, 0, 0,  6,    0,    1,    0);  // techo subiendo: rebota
        probar( 5,  0, 0, 1,  6,    0,    0,    0);  // techo pero ya baja: nada
        probar( 5, 15, 1, 1,  6,    0,    1,    0);  // piso bajando: rebota
        probar(14,  5, 1, 1,  6,    1,    0,    0);  // pared yendo a la derecha
        probar(14,  5, 0, 1,  6,    0,    0,    0);  // en X=14 pero va a la izquierda
        probar( 1,  6, 0, 1,  6,    1,    0,    0);  // paleta, borde de arriba
        probar( 1,  7, 0, 1,  6,    1,    0,    0);  // paleta, centro
        probar( 1,  8, 0, 0,  6,    1,    0,    0);  // paleta, borde de abajo
        probar( 1,  5, 0, 0,  6,    0,    0,    1);  // pasa por arriba: gol
        probar( 1,  9, 0, 1,  6,    0,    0,    1);  // pasa por abajo: gol
        probar( 1,  0, 0, 0,  0,    1,    1,    0);  // esquina: paleta + techo
        probar( 1, 15, 0, 1, 13,    1,    1,    0);  // esquina: paleta + piso
        probar( 1,  7, 1, 1,  0,    0,    0,    0);  // en X=1 pero va a la derecha

        if (errores == 0) $display(">>> COLISIONES: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> COLISIONES: %0d ERRORES", errores);
        $finish;
    end
endmodule
