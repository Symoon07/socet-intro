yosys -import

if {[info exists env(INTRO_PDK_LIBERTY)]} {
    set pdk_path $::env(INTRO_PDK_LIBERTY)
} else {
    puts "Error: Please set environment variable INTRO_PDK_LIBERTY"
    exit 1
}

if {$pdk_path eq ""} {
    puts "Error: Please set environment variable INTRO_PDK_LIBERTY"
    exit 1
}


read_verilog -sv src/fsm.sv
show -format svg -prefix ./syn/pre_syn

synth -top fsm
dfflibmap -liberty $pdk_path
abc -dff -liberty $pdk_path
clean

tee -o syn/area.rpt stat -liberty $pdk_path
write_verilog syn/fsm_syn.v
show -format svg -prefix ./syn/post_syn
