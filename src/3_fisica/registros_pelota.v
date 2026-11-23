// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Parte 4: Registros de la pelota
// Solo se actualizan cuando tick = 1 (cada 100 ms en la placa).
// Reset: pelota en (7, 7), dir_x = 0 (izquierda), dir_y = 1 (abajo).
// =============================================================
module registros_pelota (
    input            clk,
    input            rst,
    input            tick,
    input      [3:0] next_x,
    input      [3:0] next_y,
    input            next_dir_x,
    input            next_dir_y,
    output reg [3:0] pelota_x,
    output reg [3:0] pelota_y,
    output reg       dir_x,
    output reg       dir_y
);

    always @(posedge clk) begin
        if (rst) begin
            pelota_x <= 4'd7;
            pelota_y <= 4'd7;
            dir_x    <= 1'b0;
            dir_y    <= 1'b1;
        end
        else if (tick) begin
            pelota_x <= next_x;
            pelota_y <= next_y;
            dir_x    <= next_dir_x;
            dir_y    <= next_dir_y;
        end
    end

endmodule
