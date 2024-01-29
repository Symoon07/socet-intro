
module tb_copier;

    // TB Signals (connect to DUT)
    logic CLK = 0, nRST;
    logic [7:0] src_addr, dst_addr, copy_size;
    logic start, finished;

    // TODO: (optional) declare any other debugging-related
    // metadata signals you want here.
    // Adding things like a test number, or a string containing
    // the name of the test can be helpful for discerning when tests
    // start/stop when viewed in the waveforms.

    // TODO: Instantiate another memory_if interface
    // for connecting the copier to the memory
    memory_if testif();

    // Clock generation
    always #(10) CLK++;

    copier DUT(
        .CLK,
        .nRST,
        .src_addr,
        .dst_addr,
        .copy_size,
        .start,
        .finished,
        // TODO: Add your memory interface here!
    );
    
    memory MEM(
        .CLK,
        .nRST,
        .testif,
        //TODO: Add your memory interface here!
    );

    task reset();
    begin
        nRST = '0;
        repeat(2) @(posedge CLK);
        nRST = '1;
        @(posedge CLK);
        #(1);
    end
    endtask

    /*
    * reset_signals
    *
    * Set all signals to a "neutral" value. Can be helpful between tests.
    */
    task reset_signals();
    begin
        src_addr = 0;
        dst_addr = 0;
        copy_size = 0;
        start = 0;

        testif.wen = 0;
        testif.ren = 0;
        testif.wdata = 0;
        testif.addr = 0;
    end
    endtask

    /*
    * initialize_memory
    *
    * Uses 'testif' to perform 'size' number of writes
    * sequentially starting at address 'src'. The writes
    * contain random data.
    */
    task initialize_memory(
        input logic [7:0] src,
        input logic [7:0] size
    );
    begin
        testif.ren = 1'b0;
        for(int i = 0; i < size; i++) begin
            testif.wen = 1'b1;
            testif.addr = (src + i);
            testif.wdata = $random();
            while(!testif.ready) begin
                @(posedge CLK);
                #(1);
            end
        end
    end
    endtask

    /*
    * TODO: Fill in the task to perform a copy. The
    * testbench should send a start signal, and wait
    * for a finished signal.
    *
    * Then, fill in code for the testbench to read back the
    * data and compare the values between source and dest to
    * check that they're the same, and produce an error message
    * when they aren't. You may print a "passed" message if you like,
    * but this is not required.
    *
    * HINT: This will require 2-3 loops: 1 for waiting on the
    * copy operation, and 1-2 for reading back from memory with
    * the "testif" interface.
    *
    * If you would prefer the checking to be broken out into separate
    * task(s), you are welcome to add any tasks or functions you want.
    */
    task do_copy(
        input logic [7:0] src, dst, size
    );
    begin

    end
    endtask

    initial begin
        nRST = 1'b1;

        reset_signals();
        reset();

        // TODO: Make more test cases to run your design!
        initialize_memory(8'h0, 8'h8); // Init 8 bytes starting at 0x0
        do_copy(8'h0, 8'hF0, 8'h8); // Test copying 8 bytes from 0x0 to 0xF0

    end

endmodule
