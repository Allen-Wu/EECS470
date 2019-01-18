// rps2
module rps2(
    input [1:0] req,
    input en,
    input sel,
    output logic [1:0] gnt,
    output logic req_up
);
    
    always_comb begin
        if (req[1] == 1'b1 || req[0] == 1'b1) req_up = 1'b1;
        else req_up = 1'b0;
        // Decide based on the sel bit
        if (en == 1'b0) gnt = 2'b00;
        else if (sel == 1'b1) begin
            // req[1] has higher priority
            if (req[1] == 1'b1) gnt = 2'b10;
            else if (req[0] == 1'b1) gnt = 2'b01;
            else gnt = 2'b00;
        end
        else if (sel == 1'b0) begin
            if (req[0] == 1'b1) gnt = 2'b01;
            else if (req[1] == 1'b1) gnt = 2'b10;
            else gnt = 2'b00;
        end
    end

endmodule

// rps4
module rps4(
    input clock,
    input reset,
    input [3:0] req,
    input en,
    output logic [3:0] gnt,
    output logic [1:0] count
);

    always_ff @(posedge clock) begin
        if (reset) count <= 2'b00;
        else if (count == 2'b00) count <= 2'b01;
        else if (count == 2'b01) count <= 2'b10;
        else if (count == 2'b10) count <= 2'b11;
        else if (count == 2'b11) count <= 2'b00;
    end

    logic [1:0] req_up_temp;
    logic [1:0] gnt_temp;
    logic req_up;

    rps2 left(.req(req[3:2]), .en(gnt_temp[1]), .sel(count[0]),
     .gnt(gnt[3:2]), .req_up(req_up_temp[1]));
    rps2 right(.req(req[1:0]), .en(gnt_temp[0]), .sel(count[0]),
     .gnt(gnt[1:0]), .req_up(req_up_temp[0]));
    rps2 top(.req(req_up_temp[1:0]), .en(en), .sel(count[1]),
     .gnt(gnt_temp[1:0]), .req_up(req_up));

endmodule