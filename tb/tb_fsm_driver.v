// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// Testbench: FSM de control del driver (se manejan las entradas a mano)
`timescale 1ns/1ps
module tb_fsm_driver;

    reg  clk = 0, rst = 1;
    reg  start = 0, fin_periodo = 0, bit_done = 0, led_done = 0, latch_done = 0;
    wire listo, load_piso, tx_activo, inc_led, en_latch;

    integer errores = 0;

    always #5 clk = ~clk;

    fsm_driver dut (.clk(clk), .rst(rst), .start(start), .fin_periodo(fin_periodo),
        .bit_done(bit_done), .led_done(led_done), .latch_done(latch_done),
        .listo(listo), .load_piso(load_piso), .tx_activo(tx_activo),
        .inc_led(inc_led), .en_latch(en_latch));

    // Revisa las 5 salidas: {listo, load_piso, tx_activo, inc_led, en_latch}
    task revisar(input [4:0] esperado, input [8*12:1] nombre);
        begin
            if ({listo, load_piso, tx_activo, inc_led, en_latch} !== esperado) begin
                $display("ERROR  esperaba %0s, salidas = %b", nombre,
                         {listo, load_piso, tx_activo, inc_led, en_latch});
                errores = errores + 1;
            end else
                $display("OK     estado %0s", nombre);
        end
    endtask

    initial begin
        $dumpfile("tb_fsm_driver.vcd");
        $dumpvars(0, tb_fsm_driver);
        $display("=== Prueba: FSM del driver ===");
        repeat (2) @(negedge clk); rst = 0;

        revisar(5'b10000, "IDLE");
        repeat (3) @(negedge clk);
        revisar(5'b10000, "IDLE (espera)");

        start = 1; @(negedge clk); start = 0;
        revisar(5'b01000, "LOAD_COLOR");
        @(negedge clk);
        revisar(5'b00100, "SEND_BIT");

        // fin de un bit que no es el ultimo: sigue en SEND_BIT
        fin_periodo = 1; @(negedge clk); fin_periodo = 0;
        revisar(5'b00100, "SEND_BIT");

        // ultimo bit: pasa a NEXT_LED
        bit_done = 1; fin_periodo = 1; @(negedge clk); fin_periodo = 0; bit_done = 0;
        revisar(5'b00010, "NEXT_LED");

        // no es el ultimo LED: vuelve a LOAD_COLOR
        @(negedge clk);
        revisar(5'b01000, "LOAD_COLOR");
        @(negedge clk);
        bit_done = 1; fin_periodo = 1; @(negedge clk); fin_periodo = 0; bit_done = 0;
        revisar(5'b00010, "NEXT_LED");

        // ultimo LED: pasa a RESET_LATCH
        led_done = 1; @(negedge clk); led_done = 0;
        revisar(5'b00001, "RESET_LATCH");
        repeat (5) @(negedge clk);
        revisar(5'b00001, "RESET_LATCH");

        latch_done = 1; @(negedge clk); latch_done = 0;
        revisar(5'b10000, "IDLE");

        if (errores == 0) $display(">>> FSM DEL DRIVER: TODAS LAS PRUEBAS PASARON");
        else              $display(">>> FSM DEL DRIVER: %0d ERRORES", errores);
        $finish;
    end
endmodule
