
# 退出之前仿真
quit -sim

# =========================< 建立工程并仿真 >===============================

# 建立新的工程库
vlib work

# 映射逻辑库到物理目录
# vmap work work

# 编译仿真文件
vlog -f ./file.f

# 无优化simulation          *** 请修改文件名 ***
vsim -c -novopt top_tb -l sim.log

# 跑完
run -all