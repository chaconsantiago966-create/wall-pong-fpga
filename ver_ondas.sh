#!/bin/bash
# Simula una prueba y la abre en GTKWave con las senales ya organizadas.
#   ./ver_ondas.sh generador_bit
#   ./ver_ondas.sh fsm_driver
#   ./ver_ondas.sh driver_ws2812b
#   ./ver_ondas.sh control_paleta
#   ./ver_ondas.sh fisica_juego
#   ./ver_ondas.sh colisiones
#   ./ver_ondas.sh control_velocidad
#   ./ver_ondas.sh generador_tick_var
cd "$(dirname "$0")"
if [ -z "$1" ]; then
    echo "Uso: ./ver_ondas.sh <prueba>   (generador_bit, fsm_driver, driver_ws2812b,"
    echo "                                control_paleta, fisica_juego, colisiones,"
    echo "                                control_velocidad, generador_tick_var)"
    exit 1
fi
./simular.sh "$1" || exit 1
if [ -f "ondas/tb_$1.gtkw" ]; then
    gtkwave "sim/tb_$1.vcd" "ondas/tb_$1.gtkw" &
else
    gtkwave "sim/tb_$1.vcd" &
fi
