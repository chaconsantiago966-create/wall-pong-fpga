// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Render - Registros sombra
// Copian pelota_x, pelota_y y pala_y solo al empezar un frame.
// Asi, si la fisica mueve la pelota mientras se envian los 256
// LEDs, el frame no sale mezclado (mitad vieja, mitad nueva).
// Son registros con habilitacion (cargar = inicio de frame).
// =============================================================
module registros_sombra (
    input            clk,
    input            rst,
    input            cargar,
    input      [3:0] pelota_x,
    input      [3:0] pelota_y,
    input      [3:0] pala_y,
    output reg [3:0] s_pelota_x,
    output reg [3:0] s_pelota_y,
    output reg [3:0] s_pala_y
);

    always @(posedge clk) begin
        if (rst) begin
            s_pelota_x <= 4'd7;
            s_pelota_y <= 4'd7;
            s_pala_y   <= 4'd6;
        end
        else if (cargar) begin
            s_pelota_x <= pelota_x;
            s_pelota_y <= pelota_y;
            s_pala_y   <= pala_y;
        end
    end

endmodule
