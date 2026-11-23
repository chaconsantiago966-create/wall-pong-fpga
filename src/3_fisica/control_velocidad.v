// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Parte 3g: control de velocidad
// Cada 10 golpes de la paleta sube un nivel (la pelota va mas rapido).
//   nivel 0 -> 100 ms por paso ... nivel 7 -> 30 ms por paso
//
//   cont_golpes : cuenta golpes 0..9 (4 bits)
//   nivel       : 0..7 (3 bits), se satura en 7
//   gol o rst   : todo vuelve a 0 (cada punto nuevo empieza lento)
//
// "golpe" debe durar 1 ciclo y llegar solo cuando la pelota se mueve
// (en fisica_juego: golpe = choca_paleta AND tick).
// =============================================================
module control_velocidad (
    input            clk,
    input            rst,
    input            golpe,       // la paleta devolvio la pelota (1 ciclo)
    input            gol,         // la pelota se escapo (1 ciclo)
    output reg [2:0] nivel
);

    reg [3:0] cont_golpes;

    wire decimo    = (cont_golpes == 4'd9);   // este golpe es el numero 10
    wire nivel_max = (nivel == 3'd7);

    always @(posedge clk) begin
        if (rst | gol) begin
            cont_golpes <= 4'd0;
            nivel       <= 3'd0;
        end else if (golpe) begin
            if (decimo) begin
                cont_golpes <= 4'd0;
                if (!nivel_max) nivel <= nivel + 3'd1;
            end else begin
                cont_golpes <= cont_golpes + 4'd1;
            end
        end
    end

endmodule
