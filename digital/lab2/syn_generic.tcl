yosys -import

read_verilog -sv src/fsm.sv
show -format svg -prefix ./syn_generic/pre_syn

synth -top fsm
abc -g all,-ANDNOT,-ORNOT,-NMUX

clean

write_verilog syn_generic/fsm_syn.v
show -format svg -prefix ./syn_generic/post_syn
