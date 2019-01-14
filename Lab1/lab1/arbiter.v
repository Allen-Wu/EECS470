module arbiter (
    input a_req, b_req, reset, clock, 
    output logic a_res, b_res);

    // 00 for neither, 01 for A, 10 for B
    logic [1:0] state;
    logic [1:0] next_state;
    
    // Sequential logic
    always_ff @(posedge clock) begin
        if (reset)
            state <= 2'b00;
        else
            state <= next_state;
    end

    // Combinational logic
    always_comb begin
        case (state)
            2'b00: begin
                a_res = 1'b0;
                b_res = 1'b0;
                if (a_req == 1'b0 & b_req == 1'b0) next_state = 2'b00;
                else if (a_req == 1'b1) next_state = 2'b01;
                else if (b_req == 1'b1) next_state = 2'b10;
            end
            2'b01: begin
                a_res = 1'b1;
                b_res = 1'b0;
                if (a_req == 1'b1) next_state = 2'b01;
                else next_state = 2'b00;
            end
            2'b10: begin
                a_res = 1'b0;
                b_res = 1'b1;
                if (b_req == 1'b1) next_state = 2'b10;
                else next_state = 2'b00;
            end
            2'b11: begin
                // Invalid state
                next_state = 2'b00;
            end
        endcase
    end

endmodule