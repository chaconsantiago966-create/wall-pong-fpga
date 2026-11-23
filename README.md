# Wall-Pong en FPGA

Pong para un jugador contra una pared, mostrado en una matriz de LEDs WS2812B de 16 × 16 y
controlado por una FPGA Artix-7 (Digilent **Basys 3**) a 100 MHz.

- La paleta se mueve con un **potenciómetro** leído por el **XADC** interno del Artix-7.
- La pelota **acelera cada 10 tiros** (golpes de la paleta): 8 niveles, de 100 ms a 30 ms por paso.
- **RESET** (BTNC o un botón externo en JB1) reinicia el juego; después de cada gol la pelota sale de nuevo desde el centro.
- El nivel de velocidad se ve en los LEDs LD1–LD3 y cada gol enciende LD0.
- Driver WS2812B propio (protocolo de 800 kHz generado en la FPGA), sin framebuffer.

Proyecto del curso ELDI 2026 (propuesta basada en el proyecto 14, "Pong", del listado del curso).

**Autor:** Santiago Chacón — Ingeniería Electrónica, Escuela Colombiana de Ingeniería Julio Garavito ([chaconsantiago966@gmail.com](mailto:chaconsantiago966@gmail.com))

> **Uso de inteligencia artificial:** se usó Claude (Anthropic) para consultas, diseño y redacción de
> código. El detalle de qué se hizo con IA, para qué y en qué archivos está en
> [`USO_DE_IA.md`](USO_DE_IA.md). Todos los archivos `.v` lo indican en su encabezado.

---

## 1. Requisitos

| Para | Herramienta |
|---|---|
| Simular | [Icarus Verilog](https://steveicarus.github.io/iverilog/) 11 o más nuevo y GTKWave (Linux o WSL) |
| Sintetizar y programar | AMD Vivado (probado con 2026.1) |
| Hardware | Basys 3, matriz WS2812B 16×16, potenciómetro de 10 kΩ + resistencia de 24 kΩ, 1 botón externo (opcional), fuente de 5 V / 3 A |

```bash
sudo apt install iverilog gtkwave
```

## 2. Reproducir la simulación

```bash
git clone https://github.com/chaconsantiago966-create/wall-pong-fpga.git
cd wall-pong-fpga
./simular.sh                       # corre los 23 testbench y muestra un resumen
./simular.sh control_velocidad     # corre solo uno (nombre sin "tb_")
./ver_ondas.sh control_velocidad   # lo corre y lo abre en GTKWave con las señales ordenadas
```

Al final debe aparecer `TODAS LAS PRUEBAS PASARON` (o `... CORRECTOS`) en cada línea del resumen.
Qué hace cada testbench y qué debe mostrar: [`GUIA_TESTBENCHES.md`](GUIA_TESTBENCHES.md).

El XADC no existe en Icarus: la simulación usa el modelo `tb/modelos/XADC.v`, al que cada testbench le
pone el valor del potenciómetro (`valor_sim`, de 0 a 4095). **Ese modelo no se agrega a Vivado.**

## 3. Reproducir el bitstream

Desde la carpeta del repositorio:

```bash
vivado -mode batch -source vivado/crear_proyecto.tcl -tclargs bitstream
```

El script crea el proyecto, agrega solo los archivos de `src/` y el XDC de la Basys 3, ajusta el canal
del XADC (`CANAL_AUX` = 6, entrada VAUX6 del JXADC), genera el bitstream y guarda los reportes de
utilización y de tiempos en `vivado/`. Sin la palabra `bitstream` solo crea el proyecto, para abrirlo
en la interfaz gráfica.

Resultado en Vivado 2026.1 (Basys 3, después de la implementación): 160 LUT (0,77 %), 170 flip-flops
(0,41 %), 74 slices, 0 BRAM, 1 XADC. Tiempos: WNS = +2,613 ns, WHS = +0,158 ns (cumple los 100 MHz).

Después: *Open Hardware Manager → Open Target → Auto Connect → Program Device*.
Para que arranque solo al encender: grabar en la memoria QSPI y poner el jumper JP1 en QSPI.

## 4. Conexiones (Basys 3)

| Señal | Pin de la placa | A dónde va |
|---|---|---|
| `dout` | JA1 | DIN de la matriz, directo con una resistencia de 330 Ω en serie (la matriz lee bien los 3,3 V) |
| `vauxp` | JXADC 1 (XA1_P) | Cursor del potenciómetro |
| `vauxn` | JXADC 7 (XA1_N) | **GND** (JXADC 11). Si queda al aire, la lectura se corre ~0,35 V |
| — | JXADC 6 (3,3 V) | 24 kΩ → potenciómetro de 10 kΩ → GND (el cursor queda entre 0 y 0,97 V) |
| `btn_ext` (RESET) | JB1 | NO del botón externo; su COM a JB6 (3,3 V). Pull-down interno |
| `btn_rst` | BTNC | Reset desde la placa |
| `led_gol` | LD0 | Se enciende con cada gol |
| `led_nivel[2:0]` | LD1–LD3 | Nivel de velocidad en binario |

La matriz y la placa comparten la **tierra** de la fuente de 5 V (condensador de 1000 µF en la entrada
de la matriz). La Basys 3 puede alimentarse por J6 con el jumper JP2 en EXT. Diagrama completo:
`diagramas/06_conexion_fisica.png`.

## 5. Arquitectura

```
 potenciómetro ─► ENTRADAS ─► FÍSICA (FSM) ─► RENDERIZADO ─► DRIVER WS2812B ─► matriz
 botones      ─┘     ▲            │   ▲              ▲                │
                     │      nivel │   │ tick_pelota  └── led_idx ─────┘
                     │            ▼   │
                     └──────────  TICKS (pelota: 100→30 ms, paleta 10 ms, frame 10 ms)
```

| Bloque | Qué hace |
|---|---|
| Entradas | Sincroniza el reset (OR de los dos botones + 2 flip-flops) y lee el potenciómetro con el XADC (promedio de 256 muestras) |
| Ticks | Tres contadores: la pelota con período variable `N − nivel × N/10`, la paleta y los frames cada 10 ms |
| Física | Colisiones, dirección, siguiente posición, registros de la pelota, paleta con histéresis y **control de velocidad** |
| Renderizado | Calcula al vuelo el color de cada LED (mapeo en zigzag + prioridad pelota > paleta > pared), sin framebuffer; registros sombra para que la imagen no se rompa |
| Driver | FSM Moore de 5 estados + registro de desplazamiento de 24 bits + contadores; genera los bits de 1,25 µs y el *latch* de 300 µs |

### Aceleración cada 10 tiros (requisito del proyecto)

- `colisiones` saca la señal `golpe` (la paleta devolvió la pelota).
- `control_velocidad` cuenta los golpes de 0 a 9; en el décimo vuelve a 0 y sube `nivel` (de 0 a 7, se
  satura en 7). Un gol o el reset devuelven los dos a 0: cada punto nuevo empieza lento.
- Solo se cuenta `golpe AND tick_pelota`. Si no, el golpe se contaría millones de veces, porque dura todo
  el tick de 100 ms.
- `ticks` calcula el período de la pelota: `N_PELOTA − nivel × PASO`, con PASO = N_PELOTA/10.
  Queda en 100, 90, 80 … 30 ms.
- `generador_tick_var` compara con `>=` (no con `==`). Así, si el período baja cuando la cuenta ya va
  más allá, el tick sale en el siguiente ciclo y la pelota no se queda quieta 0,17 s.
- `limite = periodo − 1` se guarda en un registro: sin él, el camino nivel → periodo → comparador no
  cabía en los 10 ns del reloj (Vivado daba WNS = −0,37 ns). Con el registro queda WNS = +2,6 ns.
- `periodo` es el número de ciclos de reloj (10 ns) entre dos movimientos de la pelota. El mayor es
  10 000 000 (100 ms). Como 2^23 = 8 388 608 < 10 000 000 ≤ 2^24 = 16 777 216, se usan **24 bits**.

## 6. Organización del repositorio

```
src/            Verilog del diseño, por bloques (1_entradas … 6_top)
tb/             Un testbench por módulo + modelo del XADC para simular
diagramas/      Diagramas de bloques, del nivel 0 (sistema) al nivel 2 (operadores)
xdc/            Restricciones de pines de la Basys 3
vivado/         Script Tcl que crea el proyecto y genera el bitstream
ondas/          Configuraciones de GTKWave y capturas de referencia
reporte/        Reporte final (formato IEEE)
simular.sh      Corre todas las simulaciones
ver_ondas.sh    Corre una simulación y la abre en GTKWave
```

| Diagrama | Nivel | Verilog (`src/`) | Testbench (`tb/`) |
|---|---|---|---|
| 00_sistema_completo, 00b_diagrama_general | 0 | 6_top/wall_pong_top.v | tb_wall_pong_top.v |
| 01_entradas | 1 | 1_entradas/entradas.v | tb_entradas.v |
| 01a_lector_potenciometro | 2 | 1_entradas/lector_pot.v, sincronizador.v | tb_lector_pot.v, tb_sincronizador.v |
| 02_ticks | 1 | 2_ticks/ticks.v | tb_ticks.v |
| 02a_generador_tick | 2 | 2_ticks/generador_tick.v | tb_generador_tick.v |
| 02b_generador_tick_var | 2 | 2_ticks/generador_tick_var.v | tb_generador_tick_var.v |
| 03_fsm_fisica | 1 | 3_fisica/fisica_juego.v | tb_fisica_juego.v |
| 03a_colisiones | 2 | 3_fisica/colisiones.v | tb_colisiones.v |
| 03b_direccion | 2 | 3_fisica/direccion.v | tb_direccion.v |
| 03c_siguiente_posicion | 2 | 3_fisica/siguiente_posicion.v | tb_siguiente_posicion.v |
| 03d_registros_pelota | 2 | 3_fisica/registros_pelota.v | tb_registros_pelota.v |
| 03e_control_paleta | 2 | 3_fisica/control_paleta.v | tb_control_paleta.v |
| 03g_control_velocidad | 2 | 3_fisica/control_velocidad.v | tb_control_velocidad.v |
| 04_renderizado | 1 | 4_render/renderizado.v | tb_renderizado.v |
| 04a_mapeador_zigzag | 2 | 4_render/mapeador_zigzag.v | tb_mapeador_zigzag.v |
| 04b_logica_color | 2 | 4_render/logica_color.v | tb_logica_color.v |
| 04c_registros_sombra | 2 | 4_render/registros_sombra.v | tb_registros_sombra.v |
| 05_driver_ws2812b | 1 | 5_driver/driver_ws2812b.v | tb_driver_ws2812b.v |
| 05a, 05b (FSM del driver) | 2 | 5_driver/fsm_driver.v | tb_fsm_driver.v |
| 05c_generador_bit | 2 | 5_driver/generador_bit.v | tb_generador_bit.v |
| 05d_registro_piso | 2 | 5_driver/registro_piso.v | tb_registro_piso.v |
| 05e_contadores | 2 | 5_driver/contador_bits.v, contador_leds.v, contador_latch.v | tb_contadores_driver.v |
| 06_conexion_fisica | — | xdc/ | — |

## 7. Problemas conocidos y cómo resolverlos

- **La paleta no llega a las filas de arriba:** XA1_N (JXADC 7) está al aire; debe ir a GND.
- **La imagen sale en espejo o volteada:** el LED 0 del panel está en otra esquina; se corrige solo en
  `src/4_render/mapeador_zigzag.v`.
- **La paleta se mueve al revés:** intercambiar los dos extremos del potenciómetro.
- **Advertencias del XADC en la síntesis** (`port ALM ... unconnected`): son salidas que no se usan;
  no afectan.

## 8. Pendiente

- Cargar el bitstream final en la placa y comprobar la aceleración (LD1–LD3 cuentan el nivel) y el gol (LD0).

## 9. Licencia

Uso académico. Ver `USO_DE_IA.md` para la declaración de uso de inteligencia artificial.
