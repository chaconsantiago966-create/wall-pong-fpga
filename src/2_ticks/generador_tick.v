// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Generador de tick: da un pulso de 1 ciclo cada N ciclos de clk.
//   N = 10_000_000 -> 100 ms con reloj de 100 MHz (pelota)
//   N =  1_000_000 ->  10 ms con reloj de 100 MHz (potenciometro y frames)
// En simulacion se usa un N pequeno para que sea rapida.
// =============================================================
module generador_tick #(
    parameter N = 10_000_000
) (
    input  clk,
    input  rst,
    output tick
);

    reg [26:0] cuenta;

    assign tick = (cuenta == N - 1);

    always @(posedge clk) begin
        if (rst | tick)
            cuenta <= 27'd0;
        else
            cuenta <= cuenta + 27'd1;
    end

endmodule
