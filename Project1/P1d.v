module rps2(
    input [1:0] req,
    input en,
    input sel,
    output logic [1:0] gnt
);
    
    always_comb begin
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

    logic [3:0] gnt_temp;

    rps2 left(.req(req[3:2]), .en(en), .sel(count[0]), .gnt(gnt_temp[3:2]));
    rps2 right(.req(req[1:0]), .en(en), .sel(count[0]), .gnt(gnt_temp[1:0]));

    always_comb begin
        gnt = 4'b0000;
        if (en == 1'b1 && count[1] == 1'b1) begin
            if (gnt_temp[3:2] == 2'b00) gnt[1:0] = gnt_temp[1:0];
            else gnt[3:2] = gnt_temp[3:2];
        end
        else if (en == 1'b1 && count[1] == 1'b0) begin
            if (gnt_temp[1:0] == 2'b00) gnt[3:2] = gnt_temp[3:2];
            else gnt[1:0] = gnt_temp[1:0];
        end
    end

endmodule