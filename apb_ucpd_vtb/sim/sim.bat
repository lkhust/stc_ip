@echo off
vsim -c -do sim.do
del transcript /q
del debussy.rc nLint.rc nlReport.rdb /q