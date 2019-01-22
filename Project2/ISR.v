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
    logic reset_sig;        // Signal for reset

    logic [31:0] temp_res;  // Temporary result. Move from top bit to bottom bit
    logic [63:0] sqr_res;   // Sqaure of temporary result
    logic partial_done;     // Flag for finishing the partial multiplication
    
    // Rising clock edge
    always_ff @(posedge clock) begin
        // Sync reset
        if (reset == 1'b1) begin
            cal_value <= #1 value;
            reset_sig <= #1 1'b1;
            for_counter <= #1 5'b11111;
            loop_terminate <= #1 1'b0;
            start_mult <= #1 1'b0;
        end
        else begin
            reset_sig <= #1 1'b0;
            if (for_counter == 5'b00000 && partial_done == 1'b1) begin
                start_mult = 1'b0;
                loop_terminate <= #1 1'b1;
            end
            else if (partial_done == 1'b1) for_counter <= #1 (for_counter - 1'b1);
        end
    end

    mult mult_pipe (.clock(clock), .reset(reset), .mcand({32'h00000000, temp_res[31:0]}),
     .mplier({32'h00000000, temp_res[31:0]}), .start(start_mult), .product(sqr_res), .done(partial_done));

    always_comb begin
        if (reset_sig == 1'b1) begin
            done = 1'b0;
            result[31:0] = 32'h00000000;
            temp_res[31:0] = 32'h00000000;
        end
        else begin
            if (loop_terminate == 1'b0) begin
                // Keep looping every bit
                if (start_mult == 1'b0) begin
                    // Haven't started
                    temp_res[for_counter] = 1'b1;
                end
                else begin
                    // Already started
                    if (partial_done == 1'b1) begin
                        // Finish square calculation
                        if (sqr_res > cal_value) temp_res[for_counter] = 1'b0;
                        else temp_res[for_counter] = 1'b1;
                    end
                end
            end
            else begin
                // Finish calculation
                if (done == 1'b0) begin
                    result[31:0] = temp_res[31:0];
                    done = 1'b1;
                end
            end
        end
    end

endmodule