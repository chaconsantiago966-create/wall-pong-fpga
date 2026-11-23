# =============================================================
# Crea el proyecto de Vivado desde cero para la Basys 3 (reproducible).
#
#   cd wall-pong-fpga
#   vivado -mode batch -source vivado/crear_proyecto.tcl                 (solo crea el proyecto)
#   vivado -mode batch -source vivado/crear_proyecto.tcl -tclargs bitstream
#
# Tambien desde la consola Tcl de Vivado (cd a la carpeta del repo):
#   set argv {bitstream}; source vivado/crear_proyecto.tcl
# =============================================================
set raiz [file normalize [file dirname [info script]]/..]

create_project wall_pong_basys3 $raiz/vivado/proyecto_basys3 -part xc7a35tcpg236-1 -force
# Solo el diseno: NO se agregan los testbench ni tb/modelos/XADC.v (Vivado usa el XADC real)
add_files [glob $raiz/src/*/*.v]
add_files -fileset constrs_1 $raiz/xdc/basys3.xdc
set_property top wall_pong_top [current_fileset]
update_compile_order -fileset sources_1

if {[lindex $argv 0] eq "bitstream"} {
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    open_run impl_1
    report_utilization -file $raiz/vivado/utilizacion_basys3.txt
    report_timing_summary -file $raiz/vivado/timing_basys3.txt
    puts "Bitstream: [get_property DIRECTORY [get_runs impl_1]]/wall_pong_top.bit"
}
