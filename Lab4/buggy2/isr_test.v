// Add your testbench here
`define DEBUG

module testbench();

	logic [63:0] val;
	logic clock, reset;

	logic [31:0] result;
	logic done;
    logic [31:0] ground_truth;
	logic quit;

	integer i, j;
	wire correct = (ground_truth===result)|~done|reset;
	time prev_time = $time;
	time curr_time = $time;

    ISR isr(.reset(reset), .value(val), .clock(clock),
     .result(result), .done(done));

	always @(posedge clock)
		#2 if(!correct) begin
			`ifdef DEBUG 
				$display("Incorrect at time %4.0f",$time);
				$display("done = %h ground_truth = %h result = %h",done,ground_truth,result);
			`endif
			$display("@@@Failed");
			$finish;
		end

	always begin
		#5;
		clock=~clock;
	end

	// Some students have had problems just using "@(posedge done)" because their
	// "done" signals glitch (even though they are the output of a register). This
	// prevents that by making sure "done" is high at the clock edge.
	task wait_until_done;
		forever begin : wait_loop
			@(posedge done);
			@(negedge clock);
			if(done) begin
				`ifdef DEBUG
					$display("@@@Finish one value calculation");
					curr_time = $time;
					$display("@@@ # Clock Cycle:%d", (curr_time - prev_time)/10);
					prev_time = curr_time;
				`endif
				disable wait_until_done;
			end
		end
	endtask

    // Calculate the ground truth sqrt
    task cal_ground_truth;
        input [63:0] value;
        output [31:0] ground_truth;
        begin
            integer j;
			ground_truth = 32'h00000000;
            for (j=31; j >= 0; j--) begin
				ground_truth[j] = 1'b1;
				if (ground_truth * ground_truth > value) ground_truth[j] = 1'b0;
            end
        end
    endtask


	initial begin

		//$vcdpluson;
		`ifdef DEBUG
			$monitor("Time:%4.0f done:%b Val:%b ground_truth:%h result:%h reset:%h",$time,done,val,ground_truth,result,reset);
		`endif
		// Square number with sync reset
		// val = (32'hb000_0000)*(32'hb000_0000);
		val = (32'hc000_0000)*(32'hc000_0000);
		$display("Ground truth multiplication result:%h", val);
		val = 64'h4000_0000_0000_0000;
		// val = 255;
		reset = 1;
		clock = 0;
		cal_ground_truth(val, ground_truth);
		#1
		@(negedge clock);
		reset = 0;
		wait_until_done();
		@(negedge clock);
		// None-square number
        reset = 1;
		val = 24;
		cal_ground_truth(val, ground_truth);
		@(negedge clock);
		#1
		reset = 0;
		@(negedge clock);
		wait_until_done();
		@(negedge clock);
		reset = 1;
		val = 109;
		@(negedge clock);
		cal_ground_truth(val, ground_truth);
		#1
		reset = 0;
		wait_until_done();
		val = 225;
        reset = 1;
        cal_ground_truth(val, ground_truth);
		@(negedge clock);
		#1
		reset = 0;
		// Async reset
		reset = 1;
		val = 999;
        cal_ground_truth(val, ground_truth);
		@(negedge clock);
		#1
		reset = 0;
		wait_until_done();
		reset = 1;
		val = 1001;
        cal_ground_truth(val, ground_truth);
		@(negedge clock);
		#1
		reset = 0;
		wait_until_done();
		// Large number
		reset = 1;
		val = 64'hFFFF_FFFF_FFFF_FFFF;
        cal_ground_truth(val, ground_truth);
		@(negedge clock);
		#1
		reset = 0;
		wait_until_done();
		// Zero
		reset = 1;
		val = 0;
        cal_ground_truth(val, ground_truth);
		@(negedge clock);
		#1
		reset = 0;
		wait_until_done();
		// Short loop
		i = 64'hFFFF_EEEE_DEAD_BEEF;
		for (j = 0; j < 2000; ++j) begin
			reset = 1;
			val=i;
            cal_ground_truth(val, ground_truth);
			@(negedge clock);
			reset = 0;
			wait_until_done();
			i = i - 64'h0000_0000_0000_AAAA;
		end
		// Random test.
		for (i = 0; i < 10000; ++i) begin
			reset = 1;
			val={$random,$random};
            cal_ground_truth(val, ground_truth);
			@(negedge clock);
			reset = 0;
			wait_until_done();
		end
		$display("@@@Passed");
		$finish;
	end

endmodule
