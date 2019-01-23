module ISR(
    input reset,
    input [63:0] value,
    input clock,
    output logic [31:0] result,
    output logic done
);

    logic [63:0] cal_value; // Input value
    logic [4:0] for_counter;// For loop counter
    logic start_mult;       // Flag for starting calculating square
    logic reset_sig;        // Signal for reset

    logic [31:0] temp_res;  // Temporary result. Move from top bit to bottom bit
    logic [63:0] sqr_res;   // Sqaure of temporary result
    logic partial_done;     // Flag for finishing the partial multiplication
    logic clear_mult;       // Flag for waiting the multiplier to restart
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset == 1'b1) begin
            // Init for reseting
            cal_value <= #1 value;
            for_counter <= #1 5'b11111;
            start_mult <= #1 1'b0;
            reset_sig <= #1 1'b1;
            temp_res[31:0] <= #1 32'h80000000;
            clear_mult <= #1 1'b0;
        end
        else begin
            reset_sig <= #1 1'b0;
            if (clear_mult == 1'b1 && partial_done == 1'b1) begin
                start_mult <= #1 1'b0;
            end // Wait for the multiplier to restart
            else if (clear_mult == 1'b1 && partial_done == 1'b0) begin
                start_mult <= #1 1'b1;
                clear_mult <= #1 1'b0;
            end // Restart the multiplier
            else start_mult <= #1 1'b1;
            if (for_counter != 5'b00000 && partial_done == 1'b1 && clear_mult == 1'b0) begin
                // Transit to next bit
                temp_res[for_counter] <= #1 result[for_counter];
                temp_res[for_counter - 1] <= #1 1'b1;
                for_counter <= #1 (for_counter - 1);
		        clear_mult <= #1 1'b1;
            end
        end
    end

    mult mult_pipe (.clock(clock), .reset(reset), .mcand({32'h00000000, temp_res[31:0]}),
     .mplier({32'h00000000, temp_res[31:0]}), .start(start_mult), .product(sqr_res), .done(partial_done));

    always_comb begin
        if (reset_sig == 1'b1) begin
            done = 1'b0;
            result[31:0] = 32'h00000000;
        end
        else begin
            done = partial_done & ~for_counter[0] & ~for_counter[1]
             & ~for_counter[2] & ~for_counter[3] & ~for_counter[4] & ~clear_mult;
            result[for_counter] = ((sqr_res > cal_value) ? 1'b0 : 1'b1) & partial_done;
        end
    end

endmodule
