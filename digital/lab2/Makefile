VERILATE := verilator
VERILATE_FLAGS := --binary --trace-fst
YOSYS   := yosys

.PHONY: clean syn syn_generic

fsm: src/fsm.sv tb/tb_fsm.sv
	$(VERILATE) $(VERILATE_FLAGS) $^
	cp obj_dir/Vfsm .

syn: src/fsm.sv syn.tcl
	mkdir -p syn
	yosys -c syn.tcl | tee syn/yosys_run.log

syn_generic:
	mkdir -p syn_generic
	yosys -c syn_generic.tcl | tee syn_generic/yosys_run.log

clean:
	rm -rf obj_dir
	rm -rf syn
	rm -f waveform.fst
	rm -f Vfsm
