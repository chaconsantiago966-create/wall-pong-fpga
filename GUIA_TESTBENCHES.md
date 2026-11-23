# Guía de testbenches

Hay un testbench por módulo (23 en total). Cada uno escribe en la consola una línea `OK` por cada caso
que pasa, `ERROR` si algo falla, y al final una línea `>>>` con el resultado. `./simular.sh` los corre
todos y junta esas líneas en el RESUMEN.

**Cómo mostrar que funcionó:** el RESUMEN con las 23 líneas `TODAS LAS PRUEBAS PASARON` (o `CORRECTOS`)
y, para los testbench clave, la forma de onda en GTKWave (`./ver_ondas.sh <nombre>`).

Escala en GTKWave: los bits de 1 señal se ven solos. Para buses, clic derecho → *Data Format*:
**Decimal** para contadores y posiciones, **Hexadecimal** para colores, **Binario** para patrones de bits.

---

## 1. Entradas

### `tb_sincronizador`
- **Qué prueba:** el sincronizador de 2 flip-flops.
- **Casos límite:**
  - la salida llega exactamente 2 flancos después (no 1);
  - un pulso de 1 ciclo no se pierde;
  - un cambio asíncrono a mitad de ciclo (a 2,7 ns) también llega en el 2.º flanco.
- **Debe mostrar:** `1 flanco despues ... sinc=0` y `2 flancos despues ... sinc=1`.
- **En ondas:** `boton` → `dut.ff1` un ciclo después → `sinc` un ciclo después.

### `tb_lector_pot`
- **Qué prueba:** el XADC se configura en el canal correcto y `pot` toma `DO[15:4]` en cada conversión.
- **Casos límite:**
  - extremos 0 y 4095;
  - valor 1;
  - `pot` = 0 en reset;
  - `pot` **solo cambia el ciclo después de DRDY** (lo vigila todo el tiempo).
- **Debe mostrar:** `Canal del XADC = 22 (VAUX6)` y `voltaje -> 4095 pot = 4095`.

### `tb_entradas`
- **Qué prueba:** el bloque completo de entradas: reset por BTNC o por el botón externo, y lectura del potenciómetro.
- **Casos límite:**
  - `rst` baja 2 ciclos después de soltar el botón;
  - cada uno de los dos botones de reset funciona por separado;
  - potenciómetro en 0, 1000, 2048 y 4095.
- **Debe mostrar:** `el boton externo (btn_ext) tambien da reset`.

## 2. Ticks

### `tb_generador_tick`
- **Qué prueba:** contador módulo N (N = 10): un tick cada 10 ciclos que dura 1 ciclo.
- **Debe mostrar:** `Ticks en 100 ciclos: 10`.

### `tb_generador_tick_var` (nuevo)
- **Qué prueba:** el contador con período de entrada que acelera la pelota.
- **Casos límite:**
  - períodos 10, 7 y el mínimo, 2;
  - **el período baja cuando la cuenta ya pasó el nuevo valor**: el tick debe salir enseguida, no después de 2^24 ciclos;
  - un vigilante corta la simulación si un tick nunca llega.
- **Debe mostrar:** `el tick sale enseguida (0 ciclos), no da la vuelta de 2^24`.
- **En ondas** (`./ver_ondas.sh generador_tick_var`): `cuenta` en decimal sube y vuelve a 0 en cada `tick`. Cuando `periodo` pasa de 10 a 4 con la cuenta en 6, `tick` sale en el siguiente ciclo.
- **Para demostrarlo en la sustentación:** cambien `>=` por `==` en `generador_tick_var.v` y corran de nuevo. El testbench falla con `tiempo agotado`.

### `tb_ticks` (nuevo)
- **Qué prueba:** el bloque de ticks completo, con N pequeños (pelota 100, muestra 10, frame 25).
- **Casos límite:** los **8 niveles** de velocidad, uno por uno.
- **Debe mostrar:** `nivel 0: tick_pelota cada 100 ciclos` … `nivel 7: tick_pelota cada 30 ciclos`. En la placa son 100 … 30 ms.

## 3. Física

### `tb_colisiones`
- **Qué prueba:** la lógica combinacional de choques, con una tabla de 14 casos.
- **Casos límite:**
  - techo y piso según la dirección;
  - pared;
  - paleta en el borde de arriba, el centro y el borde de abajo;
  - pasar justo por encima o por debajo de la paleta (gol);
  - esquinas con dos choques a la vez (paleta + techo, paleta + piso);
  - estar en X = 1 pero alejándose.
- **Nuevo:** revisa que `golpe` sea 1 solo en los rebotes contra la **paleta** (no contra la pared).

### `tb_direccion`
- **Qué prueba:** la XOR que invierte la dirección y el gol que fuerza la dirección del saque.
- **Casos límite:** rebote en un eje, en los dos ejes y gol (que gana sobre el rebote).

### `tb_siguiente_posicion`
- **Qué prueba:** ±1 en cada eje según la dirección y el saque en (7,7) cuando hay gol.
- **Casos límite:** bordes (1,0), (14,5) y (5,15).

### `tb_registros_pelota`
- **Qué prueba:**
  - en reset la pelota está en (7,7);
  - sin tick no carga;
  - con tick carga el siguiente estado.

### `tb_control_paleta`
- **Qué prueba:** la escala pot × 14 / 256 → fila 0..13 y la histéresis.
- **Casos límite:**
  - potenciómetro en 0 y en 4095;
  - las 14 filas, con el centro de su rango;
  - el borde entre dos filas, viniendo de arriba y de abajo (la paleta no tiembla);
  - sin `en_pala` no se mueve.
- **En ondas:** `pot` (decimal), `por14`, `fino`, `objetivo`, `resto`, `zona_segura` y `pala_y`.

### `tb_control_velocidad` (nuevo, requisito "acelerar cada 10 tiros")
- **Qué prueba:** el contador de golpes 0..9 y el registro de nivel 0..7.
- **Casos límite:**
  - **9 golpes no suben**; el 10.º sí;
  - **saturación en 7**: los golpes 80, 90 y 100 no lo regresan a 0;
  - un gol borra el nivel y **también la cuenta de golpes**: después de un gol hacen falta otra vez 10;
  - **golpe y gol en el mismo ciclo**: gana el gol;
  - 10 golpes en 10 ciclos seguidos;
  - reset a mitad de la cuenta.
- **Debe mostrar:** `9 golpes (aun no sube): nivel=0`, `golpe 10: nivel=1` y `golpe 100 (saturado, no vuelve a 0): nivel=7`.
- **En ondas** (`./ver_ondas.sh control_velocidad`): `cont_golpes` (decimal) va 0…9 y vuelve a 0. En ese mismo flanco `nivel` sube 1 y `decimo` está en 1. `nivel_max` se pone en 1 cuando `nivel` = 7.
- **Para demostrarlo en la sustentación:** cambien `4'd9` por `4'd8` en `control_velocidad.v`. El testbench da 3 errores.

### `tb_fisica_juego` (prueba de integración de la física)
- **Fase 1:** con el potenciómetro quieto debe haber goles. En cada gol el saque vuelve a (7,7).
- **Fase 2:** un "jugador automático" gira el potenciómetro para seguir la pelota durante 2200 ticks.
  - No debe haber goles.
  - El nivel debe subir de 1 en 1 cada 10 golpes, hasta 7.
- **En todos los ticks:** la pelota nunca sale a X = 0 ni a X = 15, la paleta queda entre 0 y 13, y
  `nivel` = golpes desde el último gol / 10 (máximo 7).
- **Debe mostrar:** el tablero dibujado en texto, la lista de rebotes con `golpe 10, 20 … 80` y
  `Fase 2: nivel de velocidad = 7 (esperado 7)`.

## 4. Renderizado

### `tb_mapeador_zigzag`
- **Qué prueba:** los 256 índices de LED → (x, y). Las filas impares van al revés.
- **Debe mostrar:** `led 16 -> (x=15, y=1) <- fila impar` y `LOS 256 LEDS CORRECTOS`.

### `tb_logica_color`
- **Qué prueba:** los colores de pelota, paleta, pared y fondo.
- **Casos límite:**
  - justo encima y debajo de la paleta;
  - paleta en el tope de abajo;
  - prioridad cuando dos objetos coinciden.

### `tb_registros_sombra`
- **Qué prueba:** copian la posición solo con `cargar` y la mantienen congelada durante el frame.

### `tb_renderizado` (nuevo)
- **Qué prueba:** el bloque completo. Recorre los 256 LEDs como lo hace el driver y cuenta los colores.
- **Casos límite:**
  - **la pelota cambia a mitad del frame** y la imagen no se rompe (registros sombra);
  - pelota en la esquina (0,0) encima de la paleta;
  - pelota en (15,15) encima de la pared (prioridades).
- **Debe mostrar:** `blancos=1 azules=3 rojos=16` y `la pelota cambio a mitad del frame y la imagen no se rompio`.

## 5. Driver WS2812B

### `tb_generador_bit`
- **Qué prueba:** cada bit dura 1,25 µs. Un 0 está alto 350 ns y un 1 está alto 700 ns.
- **Debe mostrar:** `bit 0: alto 350 ns`, `bit 1: alto 700 ns` y `Periodo de bit medido: 1250 ns`.
- **En ondas:** `dout`, con 125 ciclos por bit. El cursor sobre el flanco de bajada mide 350 o 700 ns.

### `tb_registro_piso`
- **Qué prueba:** carga 24 bits (`A5C30F`) y los saca en serie con el MSB primero.

### `tb_contadores_driver`
- **Qué prueba:**
  - `bit_done` en el bit 23;
  - `led_done` en el LED 255, y luego vuelve a 0;
  - `latch_done` a los 30 000 ciclos (300 µs);
  - los `clr`.

### `tb_fsm_driver`
- **Qué prueba:** la secuencia de estados IDLE → LOAD_COLOR → SEND_BIT → NEXT_LED → … → RESET_LATCH → IDLE, y que las salidas sean de Moore.
- **En ondas:** `estado` en decimal y las salidas `listo`, `load_piso`, `tx_activo`, `inc_led` y `en_latch`.

### `tb_driver_ws2812b`
- **Qué prueba:** un frame completo de 256 LEDs. Decodifica `dout` como lo haría la matriz.
- **Debe mostrar:**
  - `Bits recibidos: 6144` (256 × 24);
  - todos los bits con T0H = 350 ns y T1H = 700 ns;
  - el latch de 300 µs;
  - `LOS 256 LEDS LLEGARON CORRECTOS`.

## 6. Sistema completo

### `tb_wall_pong_top`
- **Qué prueba:** el diseño completo. El testbench hace de matriz: decodifica `dout`, arma cada imagen de 16 × 16, la dibuja en texto y compara los 256 LEDs con lo que debería verse.
- **Secuencia:**
  1. potenciómetro en la mitad: la paleta en la fila 6;
  2. se gira el potenciómetro al máximo y la paleta llega a la fila 13;
  3. se gira a 0 para dejar pasar la pelota;
  4. hay gol y LD0 se enciende.
- **Debe mostrar:** `Frame N [... ms]: ... -> 256 LEDs correctos` en cada frame, los dibujos del tablero y `el LED de gol se encendio`.
- No guarda ondas, porque serían muy grandes.
