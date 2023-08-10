module full_adder(
    input logic a,
    input logic b,
    input logic cin,
    output logic s,
    output logic cout
);
    // Note: an alternative way of expressing this would be:
    // assign {cout, s} = a + b + cin;
    // TODO: There's a bug in here!
    assign s = a ^ b;
    assign cout = (a & b) | ((a ^ b) & cin);

endmodule