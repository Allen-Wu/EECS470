// ps2
module ps2(
    input [1:0] req,
    input en,
    output logic [1:0] gnt,
    output logic req_up
);
    
    always_comb begin
        if (req[1] == 1'b1 || req[0] == 1'b1) req_up = 1'b1;
        else req_up = 1'b0;
        if (en == 1'b0) gnt = 2'b00;
        else if (req[1] == 1'b1) gnt = 2'b10;
        else if (req[0] == 1'b1) gnt = 2'b01;
        else gnt = 2'b00;
    end
 
endmodule

// ps4
module ps4(
    input [3:0] req,
    input en,
    output logic [3:0] gnt,
    output logic req_up
);
    logic [1:0] req_up_temp;
    logic [1:0] gnt_temp;

    ps2 left(.req(req[3:2]), .en(gnt_temp[1]), .gnt(gnt[3:2]), .req_up(req_up_temp[1]));
    ps2 right(.req(req[1:0]), .en(gnt_temp[0]), .gnt(gnt[1:0]), .req_up(req_up_temp[0]));
    ps2 top(.req(req_up_temp[1:0]), .en(en), .gnt(gnt_temp[1:0]), .req_up(req_up));

endmodule

// ps8
module ps8(
    input [7:0] req,
    input en,
    output logic [7:0] gnt,
    output logic req_up
);

    logic [1:0] req_up_temp;
    logic [1:0] gnt_temp;

    ps4 left(.req(req[7:4]), .en(gnt_temp[1]), .gnt(gnt[7:4]), .req_up(req_up_temp[1]));
    ps4 right(.req(req[3:0]), .en(gnt_temp[0]), .gnt(gnt[3:0]), .req_up(req_up_temp[0]));
    ps2 top(.req(req_up_temp[1:0]), .en(en), .gnt(gnt_temp[1:0]), .req_up(req_up));

endmodule