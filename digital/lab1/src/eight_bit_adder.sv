
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
    full_adder fa0(
        .a(a[0]),
        .b(b[0]),
        .cin(1'b0),
        .s(c[0]),
        .cout(carries[0])
    );

    genvar i;
    generate
        for(i = 1; i < 7; i++) begin : fa_array
            full_adder fa_instance(
                .a(a[i]),
                .b(b[i]),
                .cin(carries[i-1]),
                .s(c[i]),
                .cout(carries[i])
            );
        end
    endgenerate

    full_adder fa7(
        .a(a[7]),
        .b(b[7]),
        .cin(carries[6]),
        .s(c[7]),
        .cout(c[8])
    );

endmodule