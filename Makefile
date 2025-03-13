default: vsim_cli

bender:
	bender script -t cv32a6_imac_sv0 vsim > runs/sim/compile.tcl

vsim_gui: bender
	cd runs/sim ; vsim -do "vlib work; source compile.tcl"

vsim_cli: bender
	cd runs/sim ; vsim -c -do "vlib work; source compile.tcl"
