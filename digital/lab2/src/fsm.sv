
module fsm(
    input CLK, nRST,
    input data,
    output accept
);

    // Declaring an 'enum' to work with states
    // In this case since the state names are not as
    // meaningful, it is less helpful, but for FSMs that
    // have semantically meaningful names, this makes code
    // much easier to understand than 'magic numbers'
    typedef enum logic [2:0] {
        S0,
        S1,
        S2,
        S3,
        S4
    } state_t;

    state_t state, next;

    // You may find the SystemVerilog 'casez' statement helpful here
    always_ff @(posedge CLK, negedge nRST) begin
        if(!nRST) begin
            state <= S0;
        end else begin
            state <= next;
        end
    end

    always_comb begin
        casez({state, data})
            {S0, 1'b0}, {S2, 1'b1}: next = S0;
            {S0, 1'b1}, {S3, 1'b0}: next = S1;
            {S1, 1'b0}, {S3, 1'b1}: next = S2;
            {S4, 1'b0}, {S1, 1'b1}: next = S3;
            {S2, 1'b0}, {S4, 1'b1}: next = S4;
            default: next = S0;
        endcase
    end

    assign accept = (state == S0);

endmodule
