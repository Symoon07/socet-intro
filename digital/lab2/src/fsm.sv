
module fsm(
    input logic CLK, nRST,
    input logic data,
    output logic accept
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

    always_ff @(posedge CLK, negedge nRST) begin
        if(!nRST) begin
            state <= S0;
        end else begin
            state <= next;
        end
    end

    // Next state logic
    always_comb begin
        next = state;
        casez(state)
            S0: next = data ? S1 : S0;
            S1: next = data ? S3 : S2;
            S2: next = data ? S0 : S4;
            S3: next = data ? S2 : S1;
            S4: next = data ? S4 : S3;
            default: ;
        endcase
    end

    // Output logic
    assign accept = state == S0;

endmodule
