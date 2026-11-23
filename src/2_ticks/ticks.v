// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Bloque de TICKS (nivel 1): tres generadores de tick
//   tick_pelota  : 100 ms -> mueve la pelota (baja 10 ms por nivel: 100, 90 ... 30 ms)
//   tick_muestra :  10 ms -> lee el potenciometro y mueve la paleta
//   tick_frame   :  10 ms -> pide un frame nuevo al driver (100 fps)
// Los N son parametros para poder usar valores pequenos en simulacion.
// =============================================================
module ticks #(
    parameter N_PELOTA  = 10_000_000,
    parameter N_MUESTRA =  1_000_000,
    parameter N_FRAME   =  1_000_000
) (
    input  clk,
    input  rst,
    input  [2:0] nivel,     // nivel de velocidad (control_velocidad)
    output tick_pelota,
    output tick_muestra,
    output tick_frame
);

    // periodo de la pelota = N_PELOTA - nivel * PASO   (PASO = 10 % de N_PELOTA)
    //   nivel*PASO es una multiplicacion por constante: el sintetizador la hace
    //   con sumas de desplazamientos (nivel tiene solo 3 bits).
    // periodo en ciclos de 10 ns: el mayor es N_PELOTA = 10 000 000 -> cabe en 24 bits
    localparam [23:0] PASO = N_PELOTA / 10;
    wire [23:0] periodo_pelota = N_PELOTA - nivel * PASO;

    generador_tick_var u_pelota (.clk(clk), .rst(rst), .periodo(periodo_pelota), .tick(tick_pelota));
    generador_tick #(.N(N_MUESTRA)) u_muestra (.clk(clk), .rst(rst), .tick(tick_muestra));
    generador_tick #(.N(N_FRAME))   u_frame   (.clk(clk), .rst(rst), .tick(tick_frame));

endmodule
