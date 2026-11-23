# Declaración de uso de inteligencia artificial

Este documento cumple el requisito 8 de la guía de proyectos de ELDI 2026: indica qué herramienta de IA
se usó, para qué y qué código generó.

## Herramienta

| | |
|---|---|
| Herramienta | **Claude** (modelo de lenguaje de Anthropic), en la aplicación de Claude |
| Periodo de uso | Noviembre de 2026 |
| Quién la usó | Santiago Chacón, autor del proyecto |

## Para qué se usó

La IA se usó para tres cosas: **consultas**, **diseño** y **redacción de código**.

### 1. Consultas (preguntas técnicas)

Se le preguntó a la IA para entender temas y resolver dudas, entre ellos:

- El protocolo WS2812B: tiempos T0H y T1H, orden GRB y señal de *reset/latch*.
- El XADC del Artix-7: registros INIT_40/41/42, puerto DRP, señales EOC/DEN/DRDY, entrada unipolar de 0 a 1 V.
- La metaestabilidad y el sincronizador de 2 flip-flops.
- Niveles lógicos de 3,3 V y 5 V, buffers 74AHCT125 / 74HCT245, condensador de entrada y tierra común.
- El divisor del potenciómetro, el diagnóstico de la entrada XA1_N al aire y la alimentación de la Basys 3 por J6.

### 2. Diseño

- Propuesta de la **arquitectura por bloques**, del nivel 0 (sistema) hasta el nivel 2 (operadores sencillos).
- **Diagramas de bloques** de `diagramas/`, dibujados con un generador en Python escrito con la IA.
- Alternativas evaluadas con la IA. Las decisiones las tomó el autor:
  - paleta por potenciómetro en vez de botones;
  - aceleración cada 10 golpes con un período lineal de 100 a 30 ms;
  - render sin framebuffer con registros sombra;
  - FSM de Moore en el driver.

### 3. Redacción de código

**Todo el código del repositorio fue redactado con asistencia de la IA** a partir de las
especificaciones, los diagramas y las decisiones del autor. Cada archivo `.v` lo indica en sus dos
primeras líneas con la etiqueta `[USO DE IA]`.

| Archivos | Qué son | Generado con IA |
|---|---|---|
| `src/**/*.v` (26 módulos) | Diseño en Verilog | Sí |
| `tb/*.v`, `tb/modelos/XADC.v` | Testbenches y modelo del XADC para simular | Sí |
| `xdc/*.xdc` | Restricciones de pines | Sí; pines verificados por el autor con el manual de la placa |
| `simular.sh`, `ver_ondas.sh`, `vivado/crear_proyecto.tcl`, `ondas/*.gtkw` | Scripts de simulación, de Vivado y de GTKWave | Sí |
| `diagramas/*.png` | Diagramas de bloques (imágenes generadas por un script) | Sí |
| `README.md`, `GUIA_TESTBENCHES.md`, `reporte/` | Documentación y borrador del reporte | Redactados con asistencia de la IA y revisados por el autor |

## Qué hizo el autor

- Escogió el proyecto y definió el juego y sus requisitos: Pong de un jugador contra la pared, matriz
  WS2812B 16 × 16, paleta con potenciómetro y aceleración cada 10 tiros.
- Hizo el diagrama inicial de la FSM de física, del que se partió.
- Hizo todo el hardware: armó y cableó el circuito (matriz, fuente de 5 V, condensador, resistencia de
  330 Ω en DIN, divisor del potenciómetro y botón de reset), y midió los voltajes del potenciómetro
  (0 a 1,001 V).
- Depuró en hardware: encontró que la paleta no llegaba a las filas de arriba y lo corrigió conectando
  XA1_N a GND. Comprobó que la matriz funciona sin buffer, directo desde la FPGA.
- Corrió y revisó las simulaciones y los diagramas.

## Cómo se verificó el código generado

- Cada módulo tiene su testbench, con casos límite (ver `GUIA_TESTBENCHES.md`). Los 23 pasan con
  `./simular.sh`.
- Algunos testbench se comprobaron metiendo errores a propósito en el diseño, y el testbench los detectó.
  Por ejemplo: subir de nivel en el golpe 9 en lugar del 10, o comparar con `==` en lugar de `>=` en el
  generador de tick variable.
- Síntesis, implementación y bitstream en Vivado 2026.1 para la Basys 3: sin errores y cumpliendo el reloj de
  100 MHz (WNS = +2,613 ns). La primera versión no cumplía (WNS = −0,367 ns) y se corrigió con el registro
  `limite` en `generador_tick_var.v`.
- Prueba en la placa de la versión con aceleración: pendiente.
