// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Generador de tick con PERIODO VARIABLE
// Da un pulso de 1 ciclo cada "periodo" ciclos de clk.
// El periodo puede cambiar en cualquier momento (sube de nivel).
//
// periodo = cuantos ciclos de reloj (10 ns) hay entre dos ticks.
//   nivel 0: 10 000 000 ciclos = 100 ms   (el valor mas grande)
//   nivel 7:  3 000 000 ciclos =  30 ms
//   2^23 = 8 388 608 < 10 000 000 <= 2^24 = 16 777 216  ->  24 bits
//
// Por que ">=" y no "==":
//   si el periodo baja mientras la cuenta ya va mas alla del nuevo
//   valor, con "==" la cuenta nunca lo igualaria y daria la vuelta
//   completa (2^24 ciclos = 0,17 s con la pelota quieta). Con ">="
//   el tick sale en el siguiente ciclo.
// =============================================================
module generador_tick_var (
    input         clk,
    input         rst,
    input  [23:0] periodo,     // ciclos de 10 ns entre ticks (2 ... 16 777 215)
    output        tick
);

    reg [23:0] cuenta;
    reg [23:0] limite;     // periodo - 1, guardado en un registro

    // El registro corta el camino largo nivel -> periodo -> comparador -> cuenta,
    // que no cabia en los 10 ns del reloj (Vivado daba WNS = -0,37 ns).
    // Costo: un cambio de periodo se nota 1 ciclo (10 ns) despues.
    always @(posedge clk)
        limite <= periodo - 24'd1;

    assign tick = (cuenta >= limite);

    always @(posedge clk) begin
        if (rst | tick)
            cuenta <= 24'd0;
        else
            cuenta <= cuenta + 24'd1;
    end

endmodule
