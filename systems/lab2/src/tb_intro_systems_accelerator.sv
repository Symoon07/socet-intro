module tb_intro_systems_accelerator();
    // Define parameters
    localparam CLK_PERIOD = 10;

    localparam ADDR_WIDTH   = 32;
    localparam DATA_WIDTH   = 32;
    localparam STROBE_WIDTH =  4;

    // tb signals
    logic CLK, nRST;
    int test_num;
    string test_name;
    logic [DATA_WIDTH-1:0] test_data;
    logic [ADDR_WIDTH-1:0] test_addr;

    // Bus interface
    bus_protocol_if busif();

    // DUT
    intro_systems_accelerator DUT (
        .CLK(CLK),
        .nRST(nRST),
        .busif(busif)
    );

    // Clock gen
    always begin
        CLK = 1'b0;
        #(CLK_PERIOD / 2);
        CLK = 1'b1;
        #(CLK_PERIOD / 2);
    end

    task reset_dut;
    begin
        nRST = 1'b0;
        busif.addr = '0;
        busif.wen = 1'b0;
        busif.ren = 1'b0;
        busif.wdata = '0;
        busif.strobe = '1;

        @(posedge CLK);
        @(posedge CLK);

        @(negedge CLK);
        nRST = 1'b1;

        @(negedge CLK);
        @(negedge CLK);
    end
    endtask

    task write_word;
        input logic [31:0] data;
        input logic [31:0] addr;
    begin
        @(negedge CLK);
        busif.addr = addr;
        busif.wen = 1'b1;
        busif.ren = 1'b0;
        busif.wdata = data;
        @(negedge CLK);
        busif.wen = 1'b0;
    end
    endtask

    task read_word;
        input logic [31:0] exp_data;
        input logic [31:0] addr;
    begin
        @(negedge CLK);
        busif.addr = addr;
        busif.wen = 1'b0;
        busif.ren = 1'b1;
        @(negedge CLK);

        // Check that correct data was read/stored
        if (busif.rdata == exp_data) begin
            $info("Read 0x%x from address 0x%x as expected", busif.rdata, addr);
        end else begin
            $info("Read 0x%x from address 0x%x -- incorrect value, expecected: 0x%x", busif.rdata, addr, exp_data);
        end

        busif.ren = 1'b0;
    end
    endtask

    //*****************************************************************************
    // Main testbench process
    //*****************************************************************************
    initial begin
        $dumpfile("waveform.fst");
        $dumpvars;
        // Initialize values
        test_name = "Initialization";
        test_num = -1;
        test_data = '0;

        #(1);
        reset_dut();

        // TODO: write some tests here!
        write_word(32'h3, 32'h0);
        read_word(32'h2, 32'h4);
        write_word(32'h0, 32'h0);
        read_word(32'h0, 32'h4);
        write_word(32'h7, 32'h0);
        read_word(32'h3, 32'h4);
        write_word(32'h1B, 32'h0);
        read_word(32'h4, 32'h4);
        write_word(32'hFFFFFFFF, 32'h0);
        read_word(32'h20, 32'h4);

        $finish;
    end
endmodule
// Simon Xu