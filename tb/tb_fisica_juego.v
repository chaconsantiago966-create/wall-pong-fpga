// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Testbench FINAL: fisica del juego completa
//  Fase 1: el potenciometro queda quieto -> debe haber goles.
//  Fase 2: un "jugador automatico" gira el potenciometro para seguir
//          la pelota -> no debe haber goles.
//  En las dos fases se revisa que la pelota nunca entre a X = 0
//  ni a la pared (X = 15), y que la paleta quede entre 0 y 13.
// =============================================================
`timescale 1ns/1ps
module tb_fisica_juego;

    reg        clk = 0;
    reg        rst = 1;
    reg [11:0] pot = 12'd1902;     // centro de la fila 6
    reg        jugar = 0;          // 1 = el jugador automatico gira el potenciometro
    wire       tick, tick_pala;
    wire [3:0] pelota_x, pelota_y, pala_y;
    wire       gol;
    wire [2:0] nivel;
    integer    golpes_desde_gol = 0;

    integer errores = 0;
    integer goles = 0;
    integer rebotes_paleta = 0;
    integer n_tick = 0;

    always #5 clk = ~clk;   // 100 MHz

    // En simulacion los ticks son cortos para que sea rapida:
    // pelota cada 20 ciclos, lectura del potenciometro cada 8 ciclos.
    generador_tick #(.N(20)) u_tick_pelota (.clk(clk), .rst(rst), .tick(tick));
    generador_tick #(.N(8))  u_tick_muest (.clk(clk), .rst(rst), .tick(tick_pala));

    fisica_juego dut (
        .clk(clk), .rst(rst),
        .tick(tick), .tick_pala(tick_pala),
.pot(pot),
        .pelota_x(pelota_x), .pelota_y(pelota_y),
        .pala_y(pala_y), .gol(gol), .nivel(nivel)
    );

    // Jugador automatico: gira el potenciometro para que el centro de la
    // paleta (fila pala_y + 1) quede a la altura de la pelota.
    integer objetivo;
    always @(*) begin
        if (jugar) begin
            objetivo = pelota_y - 1;
            if (objetivo < 0)  objetivo = 0;
            if (objetivo > 13) objetivo = 13;
            pot = ((16 * objetivo + 8) * 256) / 14;   // centro de esa fila
        end
    end

    // En cada tick: contar eventos, mostrar y revisar limites
    always @(posedge clk) begin
        if (!rst && tick) begin
            n_tick = n_tick + 1;
            // el nivel debe ser (golpes desde el ultimo gol) / 10, maximo 7
            // (se revisa antes de contar el evento de este tick)
            if (nivel != ((golpes_desde_gol / 10 > 7) ? 7 : golpes_desde_gol / 10)) begin
                $display("ERROR  tick %0d: nivel=%0d con %0d golpes", n_tick, nivel, golpes_desde_gol);
                errores = errores + 1;
            end

            if (gol) begin
                goles = goles + 1;
                $display("  tick %0d: pelota=(%0d,%0d) pala=%0d  --> GOL, saque en (7,7)",
                         n_tick, pelota_x, pelota_y, pala_y);
            end
            if (gol) golpes_desde_gol = 0;
            if (dut.u_colisiones.reb_x && pelota_x == 4'd1) begin
                rebotes_paleta = rebotes_paleta + 1;
                golpes_desde_gol = golpes_desde_gol + 1;
                if (n_tick <= 120 || golpes_desde_gol % 10 == 0)
                    $display("  tick %0d: pelota=(%0d,%0d) pala=%0d  --> rebote en paleta (golpe %0d; nivel antes del golpe = %0d)",
                             n_tick, pelota_x, pelota_y, pala_y, golpes_desde_gol, nivel);
            end
            if (dut.u_colisiones.reb_x && pelota_x == 4'd14 && n_tick <= 120)
                $display("  tick %0d: pelota=(%0d,%0d)          --> rebote en pared",
                         n_tick, pelota_x, pelota_y);

            if (pelota_x == 4'd0 || pelota_x == 4'd15) begin
                $display("ERROR  tick %0d: la pelota se salio a X=%0d", n_tick, pelota_x);
                errores = errores + 1;
            end
            if (pala_y > 4'd13) begin
                $display("ERROR  tick %0d: pala_y=%0d fuera de rango", n_tick, pala_y);
                errores = errores + 1;
            end
        end
    end

    // Dibuja el tablero 16x16 en texto (O = pelota, | = paleta, # = pared)
    task dibujar;
        integer fx, fy;
        reg [8*16:1] fila;
        begin
            $display("  pelota=(%0d,%0d)  pala_y=%0d", pelota_x, pelota_y, pala_y);
            for (fy = 0; fy < 16; fy = fy + 1) begin
                fila = "";
                for (fx = 0; fx < 16; fx = fx + 1) begin
                    if (fx == pelota_x && fy == pelota_y)          fila = {fila[8*15:1], "O"};
                    else if (fx == 0 && fy >= pala_y && fy <= pala_y + 2) fila = {fila[8*15:1], "|"};
                    else if (fx == 15)                              fila = {fila[8*15:1], "#"};
                    else                                            fila = {fila[8*15:1], "."};
                end
                $display("  %s", fila);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_fisica_juego.vcd");
        $dumpvars(0, tb_fisica_juego);
        $display("=== Prueba final: fisica del juego completa ===");

        repeat (3) @(negedge clk);
        rst = 0;

        // ---------- Fase 1: sin jugador ----------
        $display("--- Fase 1: potenciometro quieto (60 ticks) ---");
        dibujar;
        repeat (60) @(posedge tick);
        @(negedge clk);
        $display("Fase 1: goles = %0d, rebotes en paleta = %0d", goles, rebotes_paleta);
        if (goles == 0) begin
            $display("ERROR  sin jugador deberia haber al menos un gol");
            errores = errores + 1;
        end

        // ---------- Fase 2: con jugador automatico ----------
        $display("--- Fase 2: jugador automatico (2200 ticks, se muestran los primeros eventos) ---");
        rst = 1; goles = 0; rebotes_paleta = 0; n_tick = 0; golpes_desde_gol = 0;
        repeat (3) @(negedge clk);
        rst = 0; jugar = 1;
        repeat (2200) @(posedge tick);
        @(negedge clk);
        dibujar;
        $display("Fase 2: goles = %0d, rebotes en paleta = %0d", goles, rebotes_paleta);
        if (goles != 0) begin
            $display("ERROR  con el jugador automatico no deberia haber goles");
            errores = errores + 1;
        end
        $display("Fase 2: nivel de velocidad = %0d (esperado %0d)", nivel, (rebotes_paleta/10 > 7) ? 7 : rebotes_paleta/10);
        if (nivel != ((rebotes_paleta/10 > 7) ? 7 : rebotes_paleta/10)) errores = errores + 1;
        else $display("OK     el nivel sube 1 cada 10 golpes de la paleta");
        if (rebotes_paleta == 0) begin
            $display("ERROR  deberia haber rebotes en la paleta");
            errores = errores + 1;
        end

        if (errores == 0) $display(">>> FISICA DEL JUEGO: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> FISICA DEL JUEGO: %0d ERRORES", errores);
        $finish;
    end
endmodule
