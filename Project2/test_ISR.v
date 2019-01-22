module testbench();

	logic [63:0] val;
	logic clock, reset;

	logic [31:0] result;
	logic done;
    logic [31:0] ground_truth;

	wire correct = (cres===result)|~done;

    ISR isr(.reset(reset), .value(val), .clock(clock),
     .result(result), .done(done));

	always @(posedge clock)
		#2 if(!correct) begin 
			$display("Incorrect at time %4.0f",$time);
			$display("cres = %h result = %h",cres,result);
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
			if(done) disable wait_until_done;
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
		$monitor("Time:%4.0f done:%b a:%h b:%h product:%h result:%h",$time,done,a,b,cres,result);
		a=2;
		b=3;
		reset=1;
		clock=0;

		@(negedge clock);
		reset=0;
		@(negedge clock);
        val = 24;
        cal_ground_truth(val, ground_truth);
		wait_until_done();
		@(negedge clock);
        val = 109;
        cal_ground_truth(val, ground_truth);
		wait_until_done();
		@(negedge clock);
		val = 999;
        cal_ground_truth(val, ground_truth);
		wait_until_done();
		@(negedge clock);
		wait_until_done();
		quit = 0;
		quit <= #10000 1;
		while(~quit) begin
			val={$random,$random};
            cal_ground_truth(val, ground_truth);
			@(negedge clock);
			wait_until_done();
		end
		$finish;
	end

endmodule



  
  
