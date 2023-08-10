# Digital Design Lab 1

## Before you start
1. Make sure your environment setup is complete! At a minimum, you should have set up your bashrc according to the instructions on the Wiki!

## Important terminology
- HDL: Hardware Description Language, a language designed to describe and design circuits. This includes SystemVerilog, VHDL, and Verilog, as well as modern languages like Chisel and ClaSH.
- Testbench: HDL code that describes sequences of inputs, output checks, and other procedural code that will *not* be turned into a circuit. A testbench is used to test your design -- think plugging signal generators into your breadboard.
- Synthesis: Process of compiling HDL into a circuit netlist.

## Using Verilator
Verilator is an open-source (System)Verilog simulator. Verilator "synthesizes" your circuit and testbench into a C++ model, that is then compiled in to an executable binary.