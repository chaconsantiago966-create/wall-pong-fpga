// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: logica de color (prioridad pelota > paleta > pared > fondo)
`timescale 1ns/1ps
module tb_logica_color;

    reg  [3:0]  x, y, pelota_x, pelota_y, pala_y;
    wire [23:0] color;

    integer errores = 0;

    logica_color dut (.x(x), .y(y), .pelota_x(pelota_x), .pelota_y(pelota_y),
                      .pala_y(pala_y), .color(color));

    task probar(input [3:0] px, input [3:0] py, input [3:0] bx, input [3:0] by,
                input [3:0] p, input [23:0] esperado, input [8*24:1] texto);
        begin
            x = px; y = py; pelota_x = bx; pelota_y = by; pala_y = p;
            #10;
            if (color !== esperado) begin
                $display("ERROR  %0s: (%0d,%0d) color=%h (esperado %h)", texto, px, py, color, esperado);
                errores = errores + 1;
            end else
                $display("OK     %0s: (%0d,%0d) color=%h", texto, px, py, color);
        end
    endtask

    initial begin
        $dumpfile("tb_logica_color.vcd");
        $dumpvars(0, tb_logica_color);
        $display("=== Prueba: logica de color ===");

        //     x   y  pel_x pel_y pala   color         descripcion
        probar( 7,  7,  7,   7,   6,   24'h202020, "pelota");
        probar( 5,  5,  7,   7,   6,   24'h000000, "fondo");
        probar(15,  3,  7,   7,   6,   24'h002000, "pared");
        probar( 0,  6,  7,   7,   6,   24'h000020, "paleta arriba");
        probar( 0,  8,  7,   7,   6,   24'h000020, "paleta abajo");
        probar( 0,  9,  7,   7,   6,   24'h000000, "debajo de paleta");
        probar( 0,  5,  7,   7,   6,   24'h000000, "encima de paleta");
        probar( 0, 15,  7,   7,  13,   24'h000020, "paleta en tope");
        probar( 0,  7,  0,   7,   6,   24'h202020, "pelota sobre paleta");
        probar(15,  4, 15,   4,   6,   24'h202020, "pelota sobre pared");

        if (errores == 0) $display(">>> LOGICA DE COLOR: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> LOGICA DE COLOR: %0d ERRORES", errores);
        $finish;
    end
endmodule
