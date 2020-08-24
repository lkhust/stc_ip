
#-------------------------------------------------------------------------------------------------------
TC =
FSDB_DIR  = .
FSDB_NAME = test.fsdb
DUT_SRC_DIR = .
DUT_NAME = file.f
#DUT_INC += +incdir+../task/
#DUT_INC += +incdir+../sim/
#LOG_DIR = ../log
LOG_DIR = .
LOG_NAME = sim.log


DUT = -f ${DUT_SRC_DIR}/${DUT_NAME}
LOG = -l ${LOG_DIR}/${LOG_NAME}
FSDB = -ssf ${FSDB_DIR}/${FSDB_NAME}

#-------------------------------------------------------------------------------------------------------
#all: vcs
#verdi
#sim
case_cp:
	cp -rf ${TC} ./testcase.v

irun:
	irun -access +rwc -loadpli1 debpli:novas_pli_boot \
	  ${DUT} ${LOG}

vcs:
	vcs -R +vc +v2k +lint=TFIPC-L -sverilog -debug_all -fsdb -full64 \
		${DUT} ${LOG}

verdi:
	verdi +v2k -sverilog -nologo -sv \
		${DUT}  ${FSDB}

sim:
	./simv ${LOG}

clean:
	rm  -rf  *~  core  csrc  simv*  vc_hdrs.h  ucli.key  urg* \
		*.log  novas.* *.fsdb* verdiLog  64* DVEfiles *.vpd \
		INCA_libs spyglass* es.esdb++ *.dat
#-------------------------------------------------------------------------------------------------------



