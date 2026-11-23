// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: bloque de renderizado (nivel 1)
//  Recorre los 256 led_idx como lo hace el driver y arma la imagen.
//  - la imagen tiene la pelota (blanco), la paleta (3 azules), la pared (16 rojos)
//  - el zigzag se respeta (las filas impares van al reves)
//  - los registros sombra: si la pelota cambia a mitad del frame,
//    la imagen NO cambia hasta el siguiente cargar_sombra (sin "tearing")
//  - casos limite: pelota en la esquina (0,0) tapa la paleta (prioridad)
`timescale 1ns/1ps
module tb_renderizado;
    reg  clk = 0, rst = 1, cargar = 0;
    reg  [7:0] led_idx = 0;
    reg  [3:0] pelota_x = 7, pelota_y = 7, pala_y = 6;
    wire [23:0] color;
    integer errores = 0;
    integer blancos, azules, rojos, i, x, y;
    always #5 clk = ~clk;
    renderizado dut (.clk(clk), .rst(rst), .cargar_sombra(cargar), .led_idx(led_idx),
                     .pelota_x(pelota_x), .pelota_y(pelota_y), .pala_y(pala_y), .color(color));

    task frame(input [3:0] ex, input [3:0] ey, input [3:0] ep, input cambiar_a_mitad);
        begin
            @(negedge clk) cargar = 1; @(negedge clk) cargar = 0;
            blancos = 0; azules = 0; rojos = 0;
            for (i = 0; i < 256; i = i + 1) begin
                led_idx = i; #1;
                y = i / 16; x = (y % 2) ? 15 - (i % 16) : (i % 16);   // zigzag esperado
                if (i == 100 && cambiar_a_mitad) begin pelota_x = 3; pelota_y = 3; #1; end
                case (color)
                    24'h202020: begin blancos = blancos + 1;
                        if (x != ex || y != ey) begin $display("ERROR  pelota dibujada en (%0d,%0d)", x, y); errores = errores + 1; end end
                    24'h000020: begin azules = azules + 1;
                        if (x != 0 || y < ep || y > ep + 2) begin $display("ERROR  paleta en (%0d,%0d)", x, y); errores = errores + 1; end end
                    24'h002000: begin rojos = rojos + 1;
                        if (x != 15) begin $display("ERROR  pared en (%0d,%0d)", x, y); errores = errores + 1; end end
                endcase
                @(negedge clk);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_renderizado.vcd"); $dumpvars(0, tb_renderizado);
        $display("=== Prueba: renderizado ===");
        repeat (2) @(negedge clk); rst = 0;
        frame(7, 7, 6, 0);
        $display("Frame 1: blancos=%0d azules=%0d rojos=%0d (esperado 1, 3, 16)", blancos, azules, rojos);
        if (blancos != 1 || azules != 3 || rojos != 16) errores = errores + 1;
        else $display("OK     pelota, paleta y pared en su lugar (con zigzag)");

        frame(7, 7, 6, 1);   // la pelota cambia en el LED 100: no debe verse
        if (blancos != 1) errores = errores + 1;
        else $display("OK     la pelota cambio a mitad del frame y la imagen no se rompio");
        frame(3, 3, 6, 0);
        if (blancos != 1) errores = errores + 1;
        else $display("OK     el siguiente frame ya muestra la pelota en (3,3)");

        pelota_x = 0; pelota_y = 0; pala_y = 0;
        frame(0, 0, 0, 0);
        $display("Esquina: blancos=%0d azules=%0d (esperado 1 y 2: la pelota tapa un LED de la paleta)", blancos, azules);
        if (blancos != 1 || azules != 2) errores = errores + 1;
        else $display("OK     prioridad: pelota > paleta");

        pelota_x = 15; pelota_y = 15; pala_y = 13;
        frame(15, 15, 13, 0);
        if (blancos != 1 || rojos != 15) errores = errores + 1;
        else $display("OK     prioridad: pelota > pared (esquina 15,15)");

        if (errores == 0) $display(">>> RENDERIZADO: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> RENDERIZADO: %0d ERRORES", errores);
        $finish;
    end
endmodule
