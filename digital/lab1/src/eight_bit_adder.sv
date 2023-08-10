
module eight_bit_adder(
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [8:0] c
);
    logic [6:0] carries;
    // TODO: Implement logic for an eight-bit full adder
    // *by instantiating 'full_adder' modules!*
    // Note: One solution to this would be simply:
    // assign c = a + b;
    // HINT: For ease of implementation, you can use
    // a "generate" loop: https://www.systemverilog.io/verification/generate/

endmodule