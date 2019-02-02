# make          <- runs simv (after compiling simv if needed)
# make all      <- runs simv (after compiling simv if needed)
# make simv     <- compile simv if needed (but do not run)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
#
#t

VCS = vcs -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

# For visual debugger
VISFLAGS = -lncurses

all:    simv
	./simv | tee program.out

##### 
# Modify starting here
#####

TESTBENCH = 	sys_defs.vh	\
		testbench/testbench.v	\
		testbench/mem.v		\
		testbench/pipe_print.c	 
SIMFILES =	verilog/pipeline.v	\
		verilog/regfile.v	\
		verilog/if_stage.v	\
		verilog/id_stage.v	\
		verilog/ex_stage.v	\
		verilog/mem_stage.v	\
		verilog/wb_stage.v	
SYNFILES = synth/pipeline.vg

# For visual debugger
VISTESTBENCH = $(TESTBENCH:testbench.v=visual_testbench.v) \
		testbench/visual_c_hooks.c

synth/pipeline.vg:        $(SIMFILES) synth/pipeline.tcl
	cd synth && dc_shell-t -f ./pipeline.tcl | tee synth.out 

#####
# Should be no need to modify after here
#####
simv:	$(SIMFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SIMFILES)	-o simv
	
dve:	$(SIMFILES) $(TESTBENCH)
	$(VCS) +memcbk $(TESTBENCH) $(SIMFILES) -o dve -R -gui
.PHONY:	dve

# For visual debugger
vis_simv:	$(SIMFILES) $(VISTESTBENCH)
	$(VCS) $(VISFLAGS) $(VISTESTBENCH) $(SIMFILES) -o vis_simv 
	./vis_simv

syn_simv:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) -o syn_simv 

syn:	syn_simv
	./syn_simv | tee syn_program.out

clean:
	rm -rf simv simv.daidir csrc vcs.key program.out
	rm -rf vis_simv vis_simv.daidir
	rm -rf dve* DVEfiles ucli.key
	rm -rf syn_simv syn_simv.daidir syn_program.out
	rm -rf synsimv synsimv.daidir csrc *.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h

nuke:	clean
	rm -f synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/command.log
	rm -f synth/*.out command.log synth/*.db synth/*.svf
