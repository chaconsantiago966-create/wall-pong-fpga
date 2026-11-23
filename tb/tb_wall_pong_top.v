// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Testbench FINAL: sistema completo Wall-Pong
// Hace de "matriz WS2812B": decodifica la senal dout, arma la
// imagen de 16x16 de cada frame, la dibuja en texto y la compara
// pixel por pixel con lo que deberia mostrarse segun la fisica.
//  - Frames 1 a 3: potenciometro en la mitad (paleta en la fila 6).
//  - Desde el frame 4: potenciometro al maximo (paleta abajo, fila 13).
// Revisa: los 256 LEDs de cada frame, que la paleta siga al
// potenciometro y que el LED de gol se encienda.
// =============================================================
`timescale 1ns/1ps
module tb_wall_pong_top;

    reg  clk = 0;
    reg  btn_rst = 1, btn_ext = 0;
    wire dout, led_gol;
    wire [2:0] led_nivel;

    integer errores = 0;
    integer frames = 0, n_bits = 0, goles_led = 0;
    integer i, fx, fy;
    reg  [23:0] rx;
    reg  [23:0] imagen [0:255];      // lo que "ve" la matriz
    reg      alto = 0;           // 1 = se vio la subida del pulso
    realtime t_sube;
    reg  [3:0] f_px, f_py, f_pala;   // fisica capturada al empezar el frame
    reg  [3:0] pala_frame [1:20];
    reg  led_gol_ant = 0;
    reg  [8*16:1] fila;
    reg  [23:0] esp;

    always #5 clk = ~clk;

    // En simulacion: pelota cada 5 ms, potenciometro cada 10 us, frame cada 10 ms.
    // Asi en pocos frames pasa de todo.
    wall_pong_top #(
        .CANAL_AUX(6),
        .N_PELOTA(500_000), .N_MUESTRA(1_000), .N_FRAME(1_000_000)
    ) dut (
        .clk(clk), .btn_rst(btn_rst), .btn_ext(btn_ext), .vauxp(1'b0), .vauxn(1'b0),
        .dout(dout), .led_gol(led_gol), .led_nivel(led_nivel)
    );

    // Contar goles (flanco de subida del LED de gol)
    always @(posedge clk) begin
        if (led_gol && !led_gol_ant) begin
            goles_led = goles_led + 1;
            $display("  [%0.1f ms] LED de gol encendido", $realtime / 1e6);
        end
        led_gol_ant <= led_gol;
    end

    // Capturar el estado de la fisica justo cuando empieza cada frame
    always @(posedge clk) if (dut.start) begin
        f_px   <= dut.pelota_x;
        f_py   <= dut.pelota_y;
        f_pala <= dut.pala_y;
    end

    // Color que deberia tener el LED numero i (modelo independiente)
    function [23:0] color_esperado(input integer idx);
        integer x, y;
        begin
            y = idx / 16;
            x = (y % 2 == 0) ? (idx % 16) : (15 - idx % 16);
            if (x == f_px && y == f_py)                       color_esperado = 24'h202020;
            else if (x == 0 && y >= f_pala && y <= f_pala + 2) color_esperado = 24'h000020;
            else if (x == 15)                                 color_esperado = 24'h002000;
            else                                              color_esperado = 24'h000000;
        end
    endfunction

    // ---------- Decodificador WS2812B ----------
    always @(posedge dout) begin t_sube = $realtime; alto = 1; end
    always @(negedge dout) if (alto) begin
        alto = 0;
        rx = {rx[22:0], ($realtime - t_sube > 500.0)};
        n_bits = n_bits + 1;
        if (n_bits % 24 == 0) imagen[n_bits / 24 - 1] = rx;
        if (n_bits == 256 * 24) begin
            n_bits = 0;
            frames = frames + 1;
            revisar_frame;
        end
    end

    task revisar_frame;
        integer malos;
        begin
            malos = 0;
            for (i = 0; i < 256; i = i + 1) begin
                esp = color_esperado(i);
                if (imagen[i] !== esp) malos = malos + 1;
            end
            pala_frame[frames] = f_pala;
            $display("Frame %0d [%0.1f ms]: pelota=(%0d,%0d) pala_y=%0d  -> %0s",
                     frames, $realtime / 1e6, f_px, f_py, f_pala,
                     (malos == 0) ? "256 LEDs correctos" : "HAY LEDS MALOS");
            if (malos != 0) begin
                $display("ERROR  %0d LEDs con color equivocado", malos);
                errores = errores + 1;
            end
            if (frames == 1 || frames == 6) dibujar;
        end
    endtask

    // Dibuja la imagen recibida (no la esperada): O pelota, | paleta, # pared
    task dibujar;
        integer idx;
        begin
            for (fy = 0; fy < 16; fy = fy + 1) begin
                fila = "";
                for (fx = 0; fx < 16; fx = fx + 1) begin
                    idx = fy * 16 + ((fy % 2 == 0) ? fx : 15 - fx);
                    case (imagen[idx])
                        24'h202020: fila = {fila[8*15:1], "O"};
                        24'h000020: fila = {fila[8*15:1], "|"};
                        24'h002000: fila = {fila[8*15:1], "#"};
                        24'h000000: fila = {fila[8*15:1], "."};
                        default:    fila = {fila[8*15:1], "?"};
                    endcase
                end
                $display("    %s", fila);
            end
        end
    endtask

    initial begin
        $display("=== Prueba final: sistema completo Wall-Pong ===");
        dut.u_entradas.u_pot.u_xadc.valor_sim = 12'd1902;   // mitad: fila 6
        #2000 btn_rst = 0;

        wait (frames == 3);
        $display("--- Se gira el potenciometro al maximo ---");
        dut.u_entradas.u_pot.u_xadc.valor_sim = 12'd4095;

        wait (frames == 6);

        if (pala_frame[3] == 6 && pala_frame[6] == 13)
            $display("OK     la paleta siguio al potenciometro: fila %0d -> fila %0d", pala_frame[3], pala_frame[6]);
        else begin
            $display("ERROR  paleta en el frame 3 = %0d (esperado 6), en el frame 6 = %0d (esperado 13)",
                     pala_frame[3], pala_frame[6]);
            errores = errores + 1;
        end

        // Con la paleta en la fila 13 la pelota rebota. Se baja el potenciometro
        // a 0 (paleta abajo) para que la pelota se le escape y haya gol.
        $display("--- Se gira el potenciometro a 0 para dejar pasar la pelota ---");
        dut.u_entradas.u_pot.u_xadc.valor_sim = 12'd0;
        wait (frames == 18 || goles_led > 0);
        if (goles_led > 0) $display("OK     el LED de gol se encendio %0d vez/veces", goles_led);
        else begin $display("ERROR  nunca hubo gol"); errores = errores + 1; end

        if (errores == 0) $display(">>> SISTEMA COMPLETO: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> SISTEMA COMPLETO: %0d ERRORES", errores);
        $finish;
    end
endmodule
