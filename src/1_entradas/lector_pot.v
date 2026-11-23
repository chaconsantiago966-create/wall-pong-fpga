// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Entradas - Lector del potenciometro (XADC del Artix-7)
// El XADC convierte el voltaje del cursor del potenciometro
// (0 a 1 V, entrada unipolar) en un numero de 12 bits (0..4095).
//
// Configuracion (registros iniciales del XADC):
//   INIT_40: promedio de 256 muestras (lectura estable) + canal VAUX
//   INIT_41: modo un solo canal, conversion continua
//   INIT_42: reloj del ADC = 100 MHz / 4 = 25 MHz
// Cada vez que termina una conversion (eoc) se lee el resultado
// por el puerto DRP; cuando llega drdy se guarda en el registro pot.
//
// CANAL_AUX: Basys 3 -> 6 (JXADC pin 1/7 = VAUX6)
// En simulacion se usa el modelo tb/modelos/XADC.v
// =============================================================
module lector_pot #(
    parameter CANAL_AUX = 6
) (
    input             clk,
    input             rst,
    input             vauxp,      // cursor del potenciometro (XA1_P)
    input             vauxn,      // referencia a GND (XA1_N)
    output reg [11:0] pot         // posicion del potenciometro: 0..4095
);

    wire [15:0] dato;
    wire        drdy, eoc;
    wire [4:0]  canal;

    // La entrada analogica va en el bit CANAL_AUX del bus de 16 entradas
    wire [15:0] bus_p = {15'd0, vauxp} << CANAL_AUX;
    wire [15:0] bus_n = {15'd0, vauxn} << CANAL_AUX;

    XADC #(
        .INIT_40(16'h3010 + CANAL_AUX),  // promedio 256, canal VAUX
        .INIT_41(16'h31AF),              // un solo canal, continuo, alarmas apagadas
        .INIT_42(16'h0400)               // divisor de reloj = 4
    ) u_xadc (
        .DCLK      (clk),
        .RESET     (rst),
        .DEN       (eoc),                // leer cuando termina la conversion
        .DADDR     ({2'b00, canal}),     // direccion del resultado = numero de canal
        .DWE       (1'b0),
        .DI        (16'd0),
        .DO        (dato),
        .DRDY      (drdy),
        .EOC       (eoc),
        .CHANNEL   (canal),
        .VAUXP     (bus_p),
        .VAUXN     (bus_n),
        .VP        (1'b0),
        .VN        (1'b0),
        .CONVST    (1'b0),
        .CONVSTCLK (1'b0)
    );

    // Registro del resultado: los 12 bits utiles son DO[15:4]
    always @(posedge clk) begin
        if (rst)
            pot <= 12'd0;
        else if (drdy)
            pot <= dato[15:4];
    end

endmodule
