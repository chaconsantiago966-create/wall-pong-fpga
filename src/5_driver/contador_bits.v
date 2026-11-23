// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Driver - Contador de bits (5 bits): cuenta los 24 bits de un LED
// Se borra al cargar un color nuevo (load_piso).
// bit_done = 1 cuando va en el ultimo bit (el 23).
// =============================================================
module contador_bits (
    input        clk,
    input        rst,
    input        clr,        // load_piso
    input        inc_bit,
    output       bit_done
);

    reg [4:0] cnt;

    assign bit_done = (cnt == 5'd23);

    always @(posedge clk) begin
        if (rst | clr)
            cnt <= 5'd0;
        else if (inc_bit)
            cnt <= cnt + 5'd1;
    end

endmodule
