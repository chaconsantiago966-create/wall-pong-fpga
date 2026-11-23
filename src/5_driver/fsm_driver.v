// [USO DE IA] Codigo redactado con asistencia de IA (Claude, de Anthropic) a partir de las
// especificaciones, diagramas y decisiones de diseno del autor. Ver USO_DE_IA.md.
// =============================================================
// Driver - FSM de control (Moore: las salidas dependen solo del estado)
//
//   IDLE --start--> LOAD_COLOR --> SEND_BIT --(fin_periodo & bit_done)--> NEXT_LED
//   NEXT_LED --led_done--> RESET_LATCH --latch_done--> IDLE
//   NEXT_LED --no led_done--> LOAD_COLOR
//
// Salidas:
//   IDLE        : listo = 1      (esperando frame)
//   LOAD_COLOR  : load_piso = 1  (carga el color del LED en el PISO)
//   SEND_BIT    : tx_activo = 1  (envia los 24 bits)
//   NEXT_LED    : inc_led = 1    (pasa al siguiente LED)
//   RESET_LATCH : en_latch = 1   (linea en 0 durante 300 us)
// =============================================================
module fsm_driver (
    input      clk,
    input      rst,
    input      start,
    input      fin_periodo,
    input      bit_done,
    input      led_done,
    input      latch_done,
    output     listo,
    output     load_piso,
    output     tx_activo,
    output     inc_led,
    output     en_latch
);

    localparam IDLE        = 3'd0;
    localparam LOAD_COLOR  = 3'd1;
    localparam SEND_BIT    = 3'd2;
    localparam NEXT_LED    = 3'd3;
    localparam RESET_LATCH = 3'd4;

    reg [2:0] estado, siguiente;

    // Registro de estado
    always @(posedge clk) begin
        if (rst)
            estado <= IDLE;
        else
            estado <= siguiente;
    end

    // Logica de siguiente estado
    always @(*) begin
        case (estado)
            IDLE:        siguiente = start                    ? LOAD_COLOR  : IDLE;
            LOAD_COLOR:  siguiente = SEND_BIT;
            SEND_BIT:    siguiente = (fin_periodo & bit_done) ? NEXT_LED    : SEND_BIT;
            NEXT_LED:    siguiente = led_done                 ? RESET_LATCH : LOAD_COLOR;
            RESET_LATCH: siguiente = latch_done               ? IDLE        : RESET_LATCH;
            default:     siguiente = IDLE;
        endcase
    end

    // Decodificador de salidas (comparadores del estado)
    assign listo     = (estado == IDLE);
    assign load_piso = (estado == LOAD_COLOR);
    assign tx_activo = (estado == SEND_BIT);
    assign inc_led   = (estado == NEXT_LED);
    assign en_latch  = (estado == RESET_LATCH);

endmodule
