## Wall-Pong - Basys 3 (Artix-7 XC7A35T)

## Reloj de 100 MHz
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk -period 10.00 -waveform {0 5} [get_ports clk]

## Reset: boton central
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports btn_rst]   ;# BTNC

## Boton externo de reset: Pmod JB pin 1 (y el otro terminal al pin 6 = 3,3 V)
## PULLDOWN: con el boton suelto la entrada lee 0
set_property -dict { PACKAGE_PIN A14  IOSTANDARD LVCMOS33  PULLDOWN true } [get_ports btn_ext]   ;# JB1

## Potenciometro: Pmod JXADC (entrada analogica VAUX6, 0 a 1 V)
## En wall_pong_top dejar CANAL_AUX = 6
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports vauxp]     ;# JXADC pin 1 (XA1_P)
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports vauxn]     ;# JXADC pin 7 (XA1_N)

## Salida de datos a la matriz: Pmod JA, pin 1 -> resistencia de 330 ohm -> DIN de la matriz
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports dout]      ;# JA1

## LED de gol
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports led_gol]   ;# LD0

## Nivel de velocidad en binario (LD1 = bit 0, LD2 = bit 1, LD3 = bit 2)
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {led_nivel[0]}] ;# LD1
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {led_nivel[1]}] ;# LD2
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {led_nivel[2]}] ;# LD3

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
