module intro_systems_accelerator(
    input logic CLK, nRST,
    bus_protocol_if.peripheral_vital busif
);

    logic [31:0] in, in_n, out, out_n;

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            in <= 32'b0;
            out <= 32'hDEADBEEF;
        end else begin
            in <= in_n;
            out <= out_n;
        end
    end

    logic [31:0] popcnt;

    always_comb begin
        out_n = out;
        popcnt = 32'b0;
        for (int i = 0; i < 32; i++) begin
            popcnt += {31'b0, in[i]};
        end
        out_n = popcnt;
    end

    always_comb begin
        in_n = in;
        busif.error = 1'b0;
        if (busif.wen) begin
            if (busif.addr == 32'h0) begin
                in_n = busif.wdata;
            end else begin
                busif.error = 1'b1;
            end
        end else if (busif.ren) begin
            casez(busif.addr)
                32'h0: busif.rdata = in;
                32'h4: busif.rdata = out;
            endcase
        end
    end

endmodule
// Simon Xu