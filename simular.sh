#!/bin/bash
# Compila y corre las pruebas con Icarus Verilog.
#   ./simular.sh                  todas las pruebas (la del sistema completo tarda ~40 s)
#   ./simular.sh driver_ws2812b   solo una (el nombre sin "tb_")
#   gtkwave sim/tb_colisiones.vcd ver ondas
# Nota: tb_wall_pong_top no guarda ondas (serian muy grandes).

cd "$(dirname "$0")"
mkdir -p sim

pruebas="sincronizador lector_pot entradas generador_tick generador_tick_var ticks
colisiones direccion siguiente_posicion registros_pelota control_paleta control_velocidad fisica_juego
mapeador_zigzag logica_color registros_sombra renderizado
generador_bit registro_piso contadores_driver fsm_driver driver_ws2812b
wall_pong_top"
if [ -n "$1" ]; then pruebas="$1"; fi

fuentes="$(find src -name '*.v' | sort) tb/modelos/XADC.v"
: > sim/resumen.txt

for p in $pruebas; do
    echo ""
    iverilog -g2005 -o sim/tb_$p.out $fuentes tb/tb_$p.v || exit 1
    (cd sim && vvp -n tb_$p.out | grep -v "VCD info" | grep -v '\$finish') | tee -a sim/resumen.txt
done

echo ""
echo "================ RESUMEN ================"
grep ">>>" sim/resumen.txt
