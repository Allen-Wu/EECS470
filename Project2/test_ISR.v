module testbench();

	logic [63:0] val;
	logic clock, reset;

	logic [31:0] result;
	logic done;
    logic [31:0] ground_truth;
	logic quit;

	wire correct = (ground_truth===result)|~done|reset;

    ISR isr(.reset(reset), .value(val), .clock(clock),
     .result(result), .done(done));

	always @(posedge clock)
		#2 if(!correct) begin 
			// $display("Incorrect at time %4.0f",$time);
			// $display("done = %h ground_truth = %h result = %h",done,ground_truth,result);
			// $finish;
		end

	always begin
		#100;
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
				$display("debug************");
				disable wait_until_done;
			end
		end
	endtask

    // Calculate the ground truth sqrt
    task cal_ground_truth;
        input [63:0] value;
        output [31:0] ground_truth;
        begin
            int j;
            for (j=0; j*j <= value; j=j+1) begin
            end
            j = j -1;
            ground_truth = j;
        end
    endtask


	initial begin

		//$vcdpluson;
		$monitor("Time:%4.0f done:%b ground_truth:%h result:%h",$time,done,ground_truth,result);
		val = 144;
		reset = 1;
		clock = 0;
		cal_ground_truth(val, ground_truth);

		@(negedge clock);
		@(negedge clock);
		reset = 0;
		wait_until_done();
		$display("debug************");
		// @(negedge clock);
        // reset = 1;
		// val = 24;
		// cal_ground_truth(val, ground_truth);
		// @(negedge clock);
		// reset = 0;
		// @(negedge clock);
		// @(negedge clock);
		// wait_until_done();
		// @(negedge clock);
		// reset = 1;
		// val = 109;
		// @(negedge clock);
		// @(negedge clock);
		// reset = 0;
		// @(negedge clock);
		// val = 225;
        // reset = 1;
        // cal_ground_truth(val, ground_truth);
		// @(negedge clock);
		// reset = 0;
		// @(negedge clock);
		// wait_until_done();
		// @(negedge clock);
		// val = 999;
        // cal_ground_truth(val, ground_truth);
		// wait_until_done();
		// @(negedge clock);
		// wait_until_done();
		// quit = 0;
		// quit <= #10000 1;
		// while(~quit) begin
		// 	val={$random,$random};
        //     cal_ground_truth(val, ground_truth);
		// 	@(negedge clock);
		// 	wait_until_done();
		// end
		$finish;
	end

endmodule



  
  
