module CAM #(parameter SIZE=8) (

	input clock, reset,
	input enable,
	
	input COMMAND command,
	
	input [31:0] data,
	
	input [$clog2(SIZE)-1:0] write_idx,
	
	output logic [$clog2(SIZE)-1:0] read_idx,
	output logic hit
	);
	
	// Fill in design here

	// Valid bit for each CAM entry
	logic valid_bit [(SIZE - 1):0];
	// CAM entry
	logic [31:0] CAM_entry [(SIZE - 1):0];
	// Counter
	logic [$clog2(SIZE):0] counter;
	logic find_idx;
	integer i;

	always_ff @(posedge clock) begin
		if (reset) begin
			for (i = 0; i < SIZE; i = i + 1) valid_bit[i] <= 1'b0;
		end
		else if (enable == 1'b1 && command == WRITE) begin
			// This a write request
			if (write_idx < SIZE) begin
				// If valid index
				CAM_entry[write_idx] <= #1 data;
				valid_bit[write_idx] <= #1 1'b1;
			end
		end
	end

	always_comb begin
		hit = 1'b0;
		if (enable == 1'b1 && command == READ) begin
			find_idx = 1'b0;
			for (counter = 0; counter < SIZE && find_idx == 1'b0; counter = counter + 1) begin
				if (valid_bit[counter] == 1'b1 && data == CAM_entry[counter]) begin
					find_idx = 1'b1;
					read_idx = counter;
					hit = 1'b1;
				end
			end
			if (find_idx == 1'b0) hit = 1'b0;
			else hit = 1'b1;
		end
	end
		
endmodule
			