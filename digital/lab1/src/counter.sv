module counter(
    input logic clk,
    input logic rst_n,
    output logic [2:0] count
);
    // TODO: There are bugs here!

    // An 'always_ff' block indicates that we're making
    // logic that includes a flip-flop. The list of events
    // after the '@' is the sensitivity list. This block of code will
    // 'run' whenever one of these events happens. In this case,
    // we're specifying that our circuit updates on a rising edge of the clock
    // or a falling edge of the asynchronous active-low reset.
    //
    // IMPORTANT: In 'always_ff' blocks, you should *always* use the '<=' (nonblocking) assignment
    // operator! Using the '=' (blocking) assignment operator can and will produce strange bugs or errors.
    // The difference may be covered later on, but it is sufficient to know that
    // you should use '<=' for sequential logic (updating FFs), and '=' for pure combinational logic
    // (e.g. in assign or always_comb). 
    always_ff @(posedge clk, negedge rst_n) begin
        // If the reset signal is low, that means we're executing this block
        // due to the asynchronous reset condition. Initialize the FFs to
        // a chosen value.
        if (!rst_n) begin
            count <= 3'd4;
        // Otherwise, we're here because of a clock edge. Perform the normal
        // update logic.
        end else begin
            count <= count + 3'd2;
        end
    end
endmodule
