
module tb_counter();
    localparam PERIOD = 10;
    localparam DELAY = 1;

    logic clk;
    logic rst_n;
    logic[2:0] count;

    int num_tests;
    int num_passed;

    // Yet another way to specify ports.
    // If the signal name matches the DUT port name, you can
    // omit the parenthesis part. This can be useful if you want to
    // document which signals are connected to this device, but want
    // to omit repetition of .clk(clk), .rst_n(rst_n), ...
    counter DUT(
        .clk,
        .rst_n,
        .count
    );

    // Clock generation
    // This block will run repeatedly throughout the simulation,
    // toggling the clock every PERIOD / 2.
    always begin
        clk = 1'b0;
        #(PERIOD / 2);
        clk = 1'b1;
        #(PERIOD / 2);
    end

    // This task performs the reset of the DUT
    // The reset is *asynchronous*, but it's usually good to
    // synchronize releasing the reset with the clock
    task reset();
        // the reset is active-low, so we set it to 0 to reset,
        // and set it to 1 to release the reset.
        rst_n = 1'b0;
        // A 'repeat' loop just runs a code block for a fixed
        // number of iterations.
        // @(posedge clk) here advances the simulation to the next
        // rising edge of the clock event.
        repeat(2) @(posedge clk);
        rst_n = 1'b1;
    endtask

    task increment_counter(input logic [2:0] expected);
        num_tests += 1;
        @(posedge clk);
        #(DELAY); // allow some delay for combinational logic to update.
        if(expected != count) begin
            $display("[Time %0t] FAILED: expected %0d, got %0d\n", $time, expected, count);
        end else begin
            num_passed += 1;
        end
    endtask

    initial begin
        $dumpfile("waveform.fst");
        $dumpvars;
        rst_n = 1;
        num_tests = 0;
        num_passed = 0;
        // Reset
        reset();
        // Try to count from 0 to 7
        for(int i = 0; i < 8; i++) begin
            // i[2:0] is used here to get just the lower 3 bits of i.
            // Without this, we would be trying to connect a 32b signal
            // to a 3b signal. SystemVerilog can infer the correct behavior,
            // but this does give a warning in all simulators. It's always
            // good to be explicit!
            increment_counter(i[2:0]);
        end
        // Check rollover -- should go back to 0
        increment_counter(0);

        $display("Passed %0d/%0d tests.", num_passed, num_tests);
        $finish();
    end
endmodule

