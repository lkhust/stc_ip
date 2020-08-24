vlib work

vlog -f ./file_103.f
#vlog -f ./file_merge.f

vsim -c -novopt -hazards tb_top \
	 -l sim.log \
	 +notimingchecks +nospecify

run -all