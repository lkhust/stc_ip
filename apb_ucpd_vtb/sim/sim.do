vlib work

vlog -f ./file.f

vsim -c -novopt -hazards top_tb \
   -l sim.log \
   +notimingchecks +nospecify

run -all