module ps4(
    input   [3:0] req,
    input         en, 
    output logic [3:0] gnt
);

    assign gnt[3] = en & req[3];
    assign gnt[2] = en & ~req[3] & req[2];
    assign gnt[1] = en & ~req[3] & ~req[2] & req[1];
    assign gnt[0] = en & ~req[3] & ~req[2] & ~req[1] & req[0];

endmodule