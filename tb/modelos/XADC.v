// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// MODELO DE SIMULACION del XADC (solo para Icarus Verilog).
// En Vivado NO se agrega este archivo: se usa el XADC real.
// El testbench pone el valor del potenciometro en "valor_sim"
// (0..4095). Cada 50 ciclos el modelo termina una "conversion":
// pulsa EOC y, si le piden el dato (DEN), responde con DRDY y DO.
// =============================================================
`timescale 1ns/1ps
module XADC #(
    parameter [15:0] INIT_40 = 16'h0000,
    parameter [15:0] INIT_41 = 16'h0000,
    parameter [15:0] INIT_42 = 16'h0000
) (
    input         DCLK,
    input         RESET,
    input         DEN,
    input  [6:0]  DADDR,
    input         DWE,
    input  [15:0] DI,
    output reg [15:0] DO,
    output reg    DRDY,
    output reg    EOC,
    output [4:0]  CHANNEL,
    input  [15:0] VAUXP,
    input  [15:0] VAUXN,
    input         VP,
    input         VN,
    input         CONVST,
    input         CONVSTCLK
);

    reg [11:0] valor_sim = 12'd2048;   // lo cambia el testbench
    reg [5:0]  cuenta = 0;

    assign CHANNEL = INIT_40[4:0];

    always @(posedge DCLK) begin
        EOC  <= 1'b0;
        DRDY <= 1'b0;
        if (RESET) begin
            cuenta <= 0;
            DO     <= 16'd0;
        end else begin
            cuenta <= (cuenta == 49) ? 0 : cuenta + 1;
            if (cuenta == 49) EOC <= 1'b1;
            if (DEN) begin
                DO   <= {valor_sim, 4'b0000};
                DRDY <= 1'b1;
            end
        end
    end

endmodule
