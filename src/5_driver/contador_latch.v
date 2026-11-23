// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Driver - Contador de latch (15 bits)
// Despues del ultimo LED la linea debe quedar en 0 al menos
// 280 us para que la matriz muestre la imagen (latch/reset).
// Se usan 300 us = 30 000 ciclos (cuenta 0..29 999).
// Mientras en_latch = 0 el contador se queda en 0.
// =============================================================
module contador_latch (
    input   clk,
    input   rst,
    input   en_latch,
    output  latch_done
);

    reg [14:0] cnt;

    assign latch_done = (cnt == 15'd29_999);

    always @(posedge clk) begin
        if (rst | ~en_latch)
            cnt <= 15'd0;
        else
            cnt <= cnt + 15'd1;
    end

endmodule
