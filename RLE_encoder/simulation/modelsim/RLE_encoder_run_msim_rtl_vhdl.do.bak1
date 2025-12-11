transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {D:/college/Acads/sem3/EE214_Digital_Circuits_Lab/Project/task_1/RLE_encoder.vhd}

vcom -93 -work work {D:/college/Acads/sem3/EE214_Digital_Circuits_Lab/Project/task_1/Testbench.vhdl}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  Testbench

add wave *
view structure
view signals
run -all
