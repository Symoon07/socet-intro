VERILATE := verilator
VERILATE_FLAGS := --binary --trace-fst

fsm: src/fsm.sv tb/tb_fsm.sv
	$(VERILATE) $(VERILATE_FLAGS) $^
	cp obj_dir/Vfsm .

clean:
	rm -rf obj_dir
	rm -f Vfsm
