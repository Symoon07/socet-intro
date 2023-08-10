VERILATE := verilator
VERILATE_FLAGS := --binary --trace-fst

full_adder: src/full_adder.sv tb/tb_full_adder.sv
	$(VERILATE) $(VERILATE_FLAGS) $^
	cp obj_dir/Vfull_adder .

eight_bit_adder: src/full_adder.sv src/eight_bit_adder.sv tb/tb_eight_bit_adder.sv
	$(VERILATE) $(VERILATE_FLAGS) $^
	cp obj_dir/Veight_bit_adder .

counter: src/counter.sv tb/tb_counter.sv
	$(VERILATE) $(VERILATE_FLAGS) $^
	cp obj_dir/Vcounter .

clean:
	rm -rf obj_dir
	rm -rf waveform.fst
	rm -f Vcounter
	rm -f Veight_bit_adder
	rm -f Vfull_adder
