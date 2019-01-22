`include "pipe_mult.v"

module ISR(
    input reset,
    input [63:0] value,
    input clock,
    output logic [31:0] result,
    output logic done
);

    logic [63:0] cal_value; // Input value
    logic [4:0] for_counter;// For loop counter
    logic loop_terminate;   // Flag for the terminal of for loop
    logic start_mult;       // Flag for starting calculating square

    logic [31:0] temp_res;  // Temporary result. Move from top bit to bottom bit
    logic [63:0] sqr_res;   // Sqaure of temporary result
    logic partial_done;     // Flag for finishing the partial multiplication
    
    // Rising clock edge
    always_ff @(posedge clock) begin
        // Sync reset
        if (reset == 1'b1) begin
            cal_value = value;
            for_counter = 5'b11111;
            loop_terminate = 1'b0;
            start_mult = 1'b0;
            temp_res = 32'h00000000;
            sqr_res = 64'h0000000000000000;
            partial_done = 1'b0;
            result = 32'h00000000;
            done = 1'b0;
        end
    end

    always_ff @(reset) begin
        // Async reset
        if (reset == 1'b1) begin
            cal_value = value;
            for_counter = 5'b11111;
            loop_terminate = 1'b0;
            start_mult = 1'b0;
            temp_res = 32'h00000000;
            sqr_res = 64'h0000000000000000;
            partial_done = 1'b0;
            result = 32'h00000000;
            done = 1'b0;
        end
    end

    mult mult_pipe (.clock(clock), .reset(reset), .mcand({32'h00000000, temp_res}),
     .mplier({32'h00000000, temp_res}), .start(start_mult), .product(sqr_res), .done(partial_done));

    always_comb begin
        if (loop_terminate == 1'b0) begin
            // Keep looping every bit
            if (start_mult == 1'b0) begin
                // Haven't started
                temp_res[for_counter] = 1'b1;
                start_mult = 1'b1;
            end
            else begin
                // Already started
                if (partial_done == 1'b1) begin
                    // Finish square calculation
                    if (sqr_res > value) temp_res[for_counter] = 1'b0;
                    start_mult = 1'b0;
                    partial_done = 1'b0;
                    if (for_counter == 5'b00000) loop_terminate = 1'b1;
                    else for_counter = for_counter - 1;
                end
            end
        end
        else begin
            // Finish calculation
            result = temp_res;
            done = 1'b1;
        end
    end

endmodule