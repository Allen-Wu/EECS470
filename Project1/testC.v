module testbench;
    logic [3:0] req_4;
    logic [7:0] req_8;
    logic  en;
    logic [3:0] gnt_4;
    logic [3:0] tb_gnt_4;
    logic [7:0] gnt_8;
    logic [7:0] tb_gnt_8;
    logic correct_4;
    logic correct_8;
    logic req_up_4;
    logic req_up_8;

    ps4 pe4(.req(req_4), .en(en), .gnt(gnt_4), .req_up(req_up_4));
    ps8 pe8(.req(req_8), .en(en), .gnt(gnt_8), .req_up(req_up_8));

    assign tb_gnt_4[3]=en&req_4[3];
    assign tb_gnt_4[2]=en&req_4[2]&~req_4[3];
    assign tb_gnt_4[1]=en&req_4[1]&~req_4[2]&~req_4[3];
    assign tb_gnt_4[0]=en&req_4[0]&~req_4[1]&~req_4[2]&~req_4[3];
    assign correct_4=(tb_gnt_4==gnt_4 && (req_up_4 == (req_4[3] | req_4[2] | req_4[1] | req_4[0])));

    assign tb_gnt_8[7]=en&req_8[7];
    assign tb_gnt_8[6]=en&req_8[6]&~req_8[7];
    assign tb_gnt_8[5]=en&req_8[5]&~req_8[6]&~req_8[7];
    assign tb_gnt_8[4]=en&req_8[4]&~req_8[5]&~req_8[6]&~req_8[7];
    assign tb_gnt_8[3]=en&req_8[3]&~req_8[4]&~req_8[5]&~req_8[6]&~req_8[7];
    assign tb_gnt_8[2]=en&req_8[2]&~req_8[3]&~req_8[4]&~req_8[5]&~req_8[6]&~req_8[7];
    assign tb_gnt_8[1]=en&req_8[1]&~req_8[2]&~req_8[3]&~req_8[4]&~req_8[5]&~req_8[6]&~req_8[7];
    assign tb_gnt_8[0]=en&req_8[0]&~req_8[1]&~req_8[2]&~req_8[3]&~req_8[4]&~req_8[5]&~req_8[6]&~req_8[7];
    assign correct_8=(tb_gnt_8==gnt_8 && (req_up_8 == (req_8[7] | req_8[6] | 
    req_8[5] | req_8[4] |req_8[3] | req_8[2] | req_8[1] | req_8[0])));

    always @(correct_4 or correct_8)
    begin
        #2
        if(!correct_4)
        begin
            $display("@@@ Incorrect at time %4.0f", $time);
            $display("@@@ gnt_4=%b, en=%b, req=%b",gnt_4,en,req_4);
            $display("@@@ expected result=%b", tb_gnt_4);
            $finish;
        end
        if(!correct_8)
        begin
            $display("@@@ Incorrect at time %4.0f", $time);
            $display("@@@ gnt_8=%b, en=%b, req=%b",gnt_8,en,req_8);
            $display("@@@ expected result=%b", tb_gnt_8);
            $finish;
        end
    end

    initial 
    begin
        $monitor("Time:%4.0f req_4:%b en:%b gnt_4:%b req_up_4:%b\nTime:%4.0f req_8:%b en:%b gnt_8:%b req_up_8:%b",
         $time, req_4, en, gnt_4, req_up_4, $time, req_8, en, gnt_8, req_up_8);
        // $monitor("Time:%4.0f req_8:%b en:%b gnt_8:%b", $time, req_8, en, gnt_8);
        req_4=4'b0000;
        req_8=8'b00000000;
        en=1'b1;
        #5    
        req_4=4'b1000;
        req_8=8'b10000000;
        #5
        req_4=4'b0100;
        req_8=8'b00010000;
        #5
        req_4=4'b0010;
        req_8=8'b00000100;
        #5
        req_4=4'b0001;
        req_8=8'b00000001;
        #5
        req_4=4'b0101;
        req_8=8'b00101011;
        #5
        req_4=4'b0110;
        req_8=8'b01111110;
        #5
        req_4=4'b1110;
        req_8=8'b11001000;
        #5
        req_4=4'b1111;
        req_8=8'b11111111;
        #5
        en=0;
        #5
        req_4=4'b0110;
        req_8=8'b00011010;
        #5
        $finish;
     end // initial
endmodule
