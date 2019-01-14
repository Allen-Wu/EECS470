module testbench;

    logic a_req, b_req, reset, clock, a_res, b_res;

    arbiter arb(.a_req(a_req), .b_req(b_req), .reset(reset), 
                .clock(clock), .a_res(a_res), .b_res(b_res));

    // Clock
    always begin
        #5;
        clock=~clock;
    end

    initial begin

        $monitor("Time:%4.0f clock:%b a_req:%b b_req:%b reset:%b a_res:%b b_res:%b", 
                 $time, clock, a_req, b_req, reset, a_res, b_res);

        clock = 1'b0;
        reset = 1'b1;
        a_req = 1'b0;
        b_req = 1'b0;

        @(negedge clock);
        @(negedge clock);
        reset = 1'b0;
        // Start testing
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        // Switch to A
        a_req = 1'b1;
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        // Back to Neither
        a_req = 1'b0;
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        // Switch to A
        a_req = 1'b1;
        b_req = 1'b1;
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        // Back to neither, then to B
        a_req = 1'b0;
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        // Back to neither
        b_req = 1'b0;
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        $finish;

    end

endmodule
