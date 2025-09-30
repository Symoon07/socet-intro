// Simon Xu
module copier(
    input CLK, nRST,
    input logic [7:0] src_addr, dst_addr,
    input logic [7:0] copy_size,
    input logic start,
    output logic finished,
    memory_if.request memif
);

    // TODO: Use module instantiations + glue logic to implement
    // a module which copies 'copy_size' bytes of data from 'src_addr' 
    // to 'dst_addr' when 'start' goes high, and sets 'finished' when
    // the transfer is complete.
    // This behavior is similar to a simple DMA, or "Direct Memory Access"
    // unit, which is used to move data around memory without wasting processor
    // compute time.
    //
    // HINT: Draw out an RTL diagram of this module first using the submodules
    // "data_register" and "flex_counter"

    typedef enum logic [2:0] {
        IDLE,
        READ,
        WRITE,
        FINISH
    } state_t;

    state_t state, state_n;
    logic [7:0] cnt;
    logic clear, count_enable, done, wen;
    
    data_register data_reg(
        .CLK(CLK),
        .nRST(nRST),
        .WEN(wen),
        .wdata(memif.rdata),
        .data(memif.wdata)
    );

    flex_counter #(.NUM_CNT_BITS(8)) counter(
        .clk(CLK),
        .n_rst(nRST),
        .clear(clear),
        .count_enable(count_enable),
        .rollover_val(copy_size),
        .count_out(cnt),
        .rollover_flag(done)
    );

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            state <= IDLE;
        end else begin
            state <= state_n;
        end
    end

    always_comb begin
        finished = 1'b0;
        memif.ren = 1'b0;
        memif.wen = 1'b0;
        memif.addr = 8'h00;
        clear = 1'b0;
        count_enable = 1'b0;
        wen = 1'b0;
        state_n = state;
        casez (state)
            IDLE: begin
                if (start) begin
                    clear = 1'b1;
                    state_n = READ;
                end
            end
            READ: begin
                memif.addr = src_addr + cnt;
                memif.ren = 1'b1;
                wen = 1'b1;
                state_n = WRITE;
            end
            WRITE: begin
                memif.addr = dst_addr + cnt;
                memif.wen = 1'b1;
                if (done) begin
                    state_n = FINISH;
                end else begin
                    count_enable = 1'b1;
                    state_n = READ;
                end
            end
            FINISH: begin
                finished = 1'b1;
                state_n = IDLE;
            end
            default: ;
        endcase
    end

endmodule
// Simon Xu