module ps4(
    input [3:0] req,
    input en,
    output logic [3:0] gnt
);

    always_comb begin
        if (en == 1'b0) gnt = 4'b0000;
        else if (req[3] == 1'b1) gnt = 4'b1000;
        else if (req[2] == 1'b1) gnt = 4'b0100;
        else if (req[1] == 1'b1) gnt = 4'b0010;
        else if (req[0] == 1'b1) gnt = 4'b0001;
        else gnt = 4'b0000;
    end

endmodule