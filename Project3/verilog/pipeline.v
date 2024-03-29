/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline togeather.                      //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
//t

`timescale 1ns/100ps

module pipeline (

    input         clock,                    // System clock
    input         reset,                    // System reset
    input [3:0]   mem2proc_response,        // Tag from memory about current request
    input [63:0]  mem2proc_data,            // Data coming back from memory
    input [3:0]   mem2proc_tag,              // Tag from memory about current reply

    output logic [1:0]  proc2mem_command,    // command sent to memory
    output logic [63:0] proc2mem_addr,      // Address sent to memory
    output logic [63:0] proc2mem_data,      // Data sent to memory

    output logic [3:0]  pipeline_completed_insts,
    output ERROR_CODE   pipeline_error_status,
    output logic [4:0]  pipeline_commit_wr_idx,
    output logic [63:0] pipeline_commit_wr_data,
    output logic        pipeline_commit_wr_en,
    output logic [63:0] pipeline_commit_NPC,


    // testing hooks (these must be exported so we can test
    // the synthesized version) data is tested by looking at
    // the final values in memory


    // Outputs from IF-Stage 
    output logic [63:0] if_NPC_out,
    output logic [31:0] if_IR_out,
    output logic        if_valid_inst_out,

    // Outputs from IF/ID Pipeline Register
    output logic [63:0] if_id_NPC,
    output logic [31:0] if_id_IR,
    output logic        if_id_valid_inst,


    // Outputs from ID/EX Pipeline Register
    output logic [63:0] id_ex_NPC,
    output logic [31:0] id_ex_IR,
    output logic        id_ex_valid_inst,


    // Outputs from EX/MEM Pipeline Register
    output logic [63:0] ex_mem_NPC,
    output logic [31:0] ex_mem_IR,
    output logic        ex_mem_valid_inst,


    // Outputs from MEM/WB Pipeline Register
    output logic [63:0] mem_wb_NPC,
    output logic [31:0] mem_wb_IR,
    output logic        mem_wb_valid_inst

  );

  // Pipeline register enables
  logic   if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;

  // Outputs from IF-Stage
  logic [63:0] proc2Imem_addr;

  // Outputs from ID stage
  logic [63:0]   id_rega_out;
  logic [63:0]   id_regb_out;
  ALU_OPA_SELECT id_opa_select_out;
  ALU_OPB_SELECT id_opb_select_out;
  logic  [4:0]   id_dest_reg_idx_out;
  ALU_FUNC       id_alu_func_out;
  logic          id_rd_mem_out;
  logic          id_wr_mem_out;
  logic          id_cond_branch_out;
  logic          id_uncond_branch_out;
  logic          id_halt_out;
  logic          id_illegal_out;
  logic          id_valid_inst_out;

  // Outputs from ID/EX Pipeline Register
  logic  [63:0]   id_ex_rega;
  logic  [63:0]   id_ex_regb;
  ALU_OPA_SELECT  id_ex_opa_select;
  ALU_OPB_SELECT  id_ex_opb_select;
  logic   [4:0]   id_ex_dest_reg_idx;
  ALU_FUNC        id_ex_alu_func;
  logic           id_ex_rd_mem;
  logic           id_ex_wr_mem;
  logic           id_ex_cond_branch;
  logic           id_ex_uncond_branch;
  logic           id_ex_halt;
  logic           id_ex_illegal;
  // output logic         id_ex_valid_inst;

  // Outputs from EX-Stage
  logic [63:0] ex_alu_result_out;
  logic        ex_take_branch_out;

  // Outputs from EX/MEM Pipeline Register
  logic   [4:0] ex_mem_dest_reg_idx;
  logic         ex_mem_rd_mem;
  logic         ex_mem_wr_mem;
  logic         ex_mem_halt;
  logic         ex_mem_illegal;
  logic  [63:0] ex_mem_rega;
  logic  [63:0] ex_mem_alu_result;
  logic         ex_mem_take_branch;

  // Outputs from MEM-Stage
  logic [63:0] mem_result_out;

  logic [63:0] proc2Dmem_addr;
  logic [1:0]  proc2Dmem_command;

  // Outputs from MEM/WB Pipeline Register
  logic        mem_wb_halt;
  logic        mem_wb_illegal;
  logic  [4:0] mem_wb_dest_reg_idx;
  logic [63:0] mem_wb_result;
  logic        mem_wb_take_branch;

  // Outputs from WB-Stage  (These loop back to the register file in ID)
  logic [63:0] wb_reg_wr_data_out;
  logic  [4:0] wb_reg_wr_idx_out;
  logic        wb_reg_wr_en_out;

  assign pipeline_completed_insts = {3'b0, mem_wb_valid_inst};
  assign pipeline_error_status =  mem_wb_illegal            ? HALTED_ON_ILLEGAL :
                                  mem_wb_halt                ? HALTED_ON_HALT :
                                  (mem2proc_response==4'h0)  ? HALTED_ON_MEMORY_ERROR :
                                  NO_ERROR;

  assign pipeline_commit_wr_idx = wb_reg_wr_idx_out;
  assign pipeline_commit_wr_data = wb_reg_wr_data_out;
  assign pipeline_commit_wr_en = wb_reg_wr_en_out;
  assign pipeline_commit_NPC = mem_wb_NPC;

  assign proc2mem_command =
       (proc2Dmem_command == BUS_NONE) ? BUS_LOAD : proc2Dmem_command;
  assign proc2mem_addr =
       (proc2Dmem_command == BUS_NONE) ? proc2Imem_addr : proc2Dmem_addr;


  // New added registers for hazard detecting
  logic if_noop_sig; // Signal for inserting noop in the IF/ID registers.
  logic branch_squash_sig; // Signal for squash operations in IF/IF, IF/EX, EX/MEM regs

  assign if_noop_sig = (id_ex_rd_mem || id_ex_wr_mem) ? 1'b1 : 1'b0; // TODO: handling structural hazard
  assign branch_squash_sig = ex_mem_take_branch; // TODO: Check correctness


  // Forwarding/Data hazard
  DATA_HAZARD_ENTRY [2:0] data_hazard_table;
  logic data_hazard_stall_sig;

  // Temp regsiters for data hazard detection
  DATA_HAZARD_ENTRY entry_to_write;

  logic mem_wb_forwardA_flag;
  logic mem_wb_forwardB_flag;
  logic ex_mem_forwardA_flag;
  logic ex_mem_forwardB_flag;

  assign mem_wb_forwardA_flag = (mem_wb_dest_reg_idx != `ZERO_REG)
   & (id_ex_opa_select == ALU_OPA_IS_REGA  || id_ex_opa_select == ALU_OPA_IS_MEM_DISP || id_ex_opa_select == ALU_OPA_IS_NPC) & (id_ex_IR[25:21] == mem_wb_dest_reg_idx);
  
  assign mem_wb_forwardB_flag = (mem_wb_dest_reg_idx != `ZERO_REG)
   & (id_ex_opb_select == ALU_OPB_IS_REGB) & (id_ex_IR[20:16] == mem_wb_dest_reg_idx);

  assign ex_mem_forwardA_flag = (ex_mem_dest_reg_idx != `ZERO_REG)
   & (id_ex_opa_select == ALU_OPA_IS_REGA  || id_ex_opa_select == ALU_OPA_IS_MEM_DISP || id_ex_opa_select == ALU_OPA_IS_NPC) & (id_ex_IR[25:21] == ex_mem_dest_reg_idx);

  assign ex_mem_forwardB_flag = (ex_mem_dest_reg_idx != `ZERO_REG)
   & (id_ex_opb_select == ALU_OPB_IS_REGB) & (id_ex_IR[20:16] == ex_mem_dest_reg_idx);

  logic [63:0] rega_val;
  assign rega_val = (ex_mem_forwardA_flag && ex_mem_IR[31:26] != `LDQ_INST) ? ex_mem_alu_result:
                    (ex_mem_forwardA_flag && ex_mem_IR[31:26] == `LDQ_INST) ? mem_result_out:
                    (mem_wb_forwardA_flag) ? mem_wb_result: id_ex_rega;

  logic [63:0] regb_val;
  assign regb_val = (ex_mem_forwardB_flag && ex_mem_IR[31:26] != `LDQ_INST) ? ex_mem_alu_result:
                    (ex_mem_forwardB_flag && ex_mem_IR[31:26] == `LDQ_INST) ? mem_result_out:
                    (mem_wb_forwardB_flag) ? mem_wb_result: id_ex_regb;


  //////////////////////////////////////////////////
  //                                              //
  //                  IF-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  if_stage if_stage_0 (
    // Inputs
    .clock (clock),
    .reset (reset),
    .mem_wb_valid_inst(mem_wb_valid_inst),
    .ex_mem_take_branch(ex_mem_take_branch),
    .ex_mem_target_pc(ex_mem_alu_result),
    .Imem2proc_data(mem2proc_data),
    .noop_sig(if_noop_sig),
    .data_hazard_stall_sig(data_hazard_stall_sig),

    // Outputs
    .if_NPC_out(if_NPC_out), 
    .if_IR_out(if_IR_out),
    .proc2Imem_addr(proc2Imem_addr),
    .if_valid_inst_out(if_valid_inst_out)
  );


  //////////////////////////////////////////////////
  //                                              //
  //            IF/ID Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign if_id_enable = (data_hazard_stall_sig == 1'b1) ? 1'b0 : 1'b1; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if(reset || branch_squash_sig == 1'b1) begin
      if_id_NPC        <= `SD 0;
      if_id_IR         <= `SD `NOOP_INST;
      if_id_valid_inst <= `SD `FALSE;
    end // if (reset)
    else if (if_id_enable) begin
      if_id_NPC        <= `SD if_NPC_out;
      if_id_IR         <= `SD if_IR_out;
      if_id_valid_inst <= `SD if_valid_inst_out;
    end // if (if_id_enable)
  end // always


  // Comb logic for data hazard detection
  // TODO: Forwading logic
  always_comb begin
    data_hazard_stall_sig = 1'b0;
    if (if_id_valid_inst == 1'b1) begin
      // If the instruction is not NOOP
      // Only need to check the first entry for stalling
      if (id_opa_select_out == ALU_OPA_IS_REGA || id_opa_select_out == ALU_OPA_IS_MEM_DISP || id_opa_select_out == ALU_OPA_IS_NPC) begin
        if (data_hazard_table[0].valid == 1'b1
         && data_hazard_table[0].mem_load_flag == 1'b1
         && data_hazard_table[0].dest_reg_idx == if_id_IR[25:21]) begin
           data_hazard_stall_sig = 1'b1;
         end
      end
      else if (id_opb_select_out == ALU_OPB_IS_REGB) begin
        if (data_hazard_table[0].valid == 1'b1
         && data_hazard_table[0].mem_load_flag == 1'b1
         && data_hazard_table[0].dest_reg_idx == if_id_IR[20:16]) begin
           data_hazard_stall_sig = 1'b1;
         end
      end
    end
    // Entry to write
    if (data_hazard_stall_sig == 1'b0) begin
      // Insert proper information
      entry_to_write.valid = 1'b1;
      if (id_dest_reg_idx_out != `ZERO_REG) begin
        entry_to_write.w_dest_flag = 1'b1;
        entry_to_write.dest_reg_idx = id_dest_reg_idx_out;
      end
      else begin
        entry_to_write.w_dest_flag = 1'b0;
        entry_to_write.dest_reg_idx = 5'b00000;
      end
      if (id_rd_mem_out == 1'b1) begin
        // If read mem, namely, load
        entry_to_write.mem_load_flag = 1'b1;
      end
      else entry_to_write.mem_load_flag = 1'b0;
    end
    else begin
      entry_to_write.valid = 1'b0;
      entry_to_write.w_dest_flag = 1'b0;
      entry_to_write.dest_reg_idx = 5'b00000;
      entry_to_write.mem_load_flag = 1'b0;
    end
  end

  // Sequential logic for data hazard detection
  // Shift the entry to right
  always_ff @(posedge clock) begin
    data_hazard_table[2] <= `SD data_hazard_table[1];
    data_hazard_table[1] <= `SD data_hazard_table[0];
    data_hazard_table[0] <= `SD entry_to_write;
  end

   
  //////////////////////////////////////////////////
  //                                              //
  //                  ID-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  id_stage id_stage_0 (// Inputs
    .clock     (clock),
    .reset   (reset),
    .if_id_IR   (if_id_IR),
    .if_id_valid_inst(if_id_valid_inst),
    .wb_reg_wr_en_out   (wb_reg_wr_en_out),
    .wb_reg_wr_idx_out  (wb_reg_wr_idx_out),
    .wb_reg_wr_data_out (wb_reg_wr_data_out),

    // Outputs
    .id_ra_value_out(id_rega_out),
    .id_rb_value_out(id_regb_out),
    .id_opa_select_out(id_opa_select_out),
    .id_opb_select_out(id_opb_select_out),
    .id_dest_reg_idx_out(id_dest_reg_idx_out),
    .id_alu_func_out(id_alu_func_out),
    .id_rd_mem_out(id_rd_mem_out),
    .id_wr_mem_out(id_wr_mem_out),
    .id_cond_branch_out(id_cond_branch_out),
    .id_uncond_branch_out(id_uncond_branch_out),
    .id_halt_out(id_halt_out),
    .id_illegal_out(id_illegal_out),
    .id_valid_inst_out(id_valid_inst_out)
  );


  //////////////////////////////////////////////////
  //                                              //
  //            ID/EX Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign id_ex_enable = 1'b1; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset || branch_squash_sig == 1'b1 || data_hazard_stall_sig == 1'b1) begin
      id_ex_NPC           <= `SD 0;
      id_ex_IR            <= `SD `NOOP_INST;
      id_ex_rega          <= `SD 0;
      id_ex_regb          <= `SD 0;
      id_ex_opa_select    <= `SD ALU_OPA_IS_REGA;
      id_ex_opb_select    <= `SD ALU_OPB_IS_REGB;
      id_ex_dest_reg_idx  <= `SD `ZERO_REG;
      id_ex_alu_func      <= `SD ALU_ADDQ;
      id_ex_rd_mem        <= `SD 0;
      id_ex_wr_mem        <= `SD 0;
      id_ex_cond_branch   <= `SD 0;
      id_ex_uncond_branch <= `SD 0;
      id_ex_halt          <= `SD 0;
      id_ex_illegal       <= `SD 0;
      id_ex_valid_inst    <= `SD 0;
    end else begin // if (reset)
      if (id_ex_enable) begin
        id_ex_NPC           <= `SD if_id_NPC;
        id_ex_IR            <= `SD if_id_IR;
        id_ex_rega          <= `SD id_rega_out;
        id_ex_regb          <= `SD id_regb_out;
        id_ex_opa_select    <= `SD id_opa_select_out;
        id_ex_opb_select    <= `SD id_opb_select_out;
        id_ex_dest_reg_idx  <= `SD id_dest_reg_idx_out;
        id_ex_alu_func      <= `SD id_alu_func_out;
        id_ex_rd_mem        <= `SD id_rd_mem_out;
        id_ex_wr_mem        <= `SD id_wr_mem_out;
        id_ex_cond_branch   <= `SD id_cond_branch_out;
        id_ex_uncond_branch <= `SD id_uncond_branch_out;
        id_ex_halt          <= `SD id_halt_out;
        id_ex_illegal       <= `SD id_illegal_out;
        id_ex_valid_inst    <= `SD id_valid_inst_out;
      end // if
    end // else: !if(reset)
  end // always


  //////////////////////////////////////////////////
  //                                              //
  //                  EX-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  ex_stage ex_stage_0 (
    // Inputs
    .clock(clock),
    .reset(reset),
    .id_ex_NPC(id_ex_NPC), 
    .id_ex_IR(id_ex_IR),
    .id_ex_rega(rega_val),
    .id_ex_regb(regb_val),
    .id_ex_opa_select(id_ex_opa_select),
    .id_ex_opb_select(id_ex_opb_select),
    .id_ex_alu_func(id_ex_alu_func),
    .id_ex_cond_branch(id_ex_cond_branch),
    .id_ex_uncond_branch(id_ex_uncond_branch),

    // Outputs
    .ex_alu_result_out(ex_alu_result_out),
    .ex_take_branch_out(ex_take_branch_out)
    );


  //////////////////////////////////////////////////
  //                                              //
  //           EX/MEM Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign ex_mem_enable = 1'b1; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset || branch_squash_sig == 1'b1) begin
      ex_mem_NPC          <= `SD 0;
      ex_mem_IR           <= `SD `NOOP_INST;
      ex_mem_dest_reg_idx <= `SD `ZERO_REG;
      ex_mem_rd_mem       <= `SD 0;
      ex_mem_wr_mem       <= `SD 0;
      ex_mem_halt         <= `SD 0;
      ex_mem_illegal      <= `SD 0;
      ex_mem_valid_inst   <= `SD 0;
      ex_mem_rega         <= `SD 0;
      ex_mem_alu_result   <= `SD 0;
      ex_mem_take_branch  <= `SD 0;
    end else begin
      if (ex_mem_enable)   begin
        // these are forwarded directly from ID/EX latches
        ex_mem_NPC          <= `SD id_ex_NPC;
        ex_mem_IR           <= `SD id_ex_IR;
        ex_mem_dest_reg_idx <= `SD id_ex_dest_reg_idx;
        ex_mem_rd_mem       <= `SD id_ex_rd_mem;
        ex_mem_wr_mem       <= `SD id_ex_wr_mem;
        ex_mem_halt         <= `SD id_ex_halt;
        ex_mem_illegal      <= `SD id_ex_illegal;
        ex_mem_valid_inst   <= `SD id_ex_valid_inst;
        ex_mem_rega         <= `SD rega_val;
        // these are results of EX stage
        ex_mem_alu_result   <= `SD ex_alu_result_out;
        ex_mem_take_branch  <= `SD ex_take_branch_out;
      end // if
    end // else: !if(reset)
  end // always

   
  //////////////////////////////////////////////////
  //                                              //
  //                 MEM-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  mem_stage mem_stage_0 (// Inputs
     .clock(clock),
     .reset(reset),
     .ex_mem_rega(ex_mem_rega),
     .ex_mem_alu_result(ex_mem_alu_result), 
     .ex_mem_rd_mem(ex_mem_rd_mem),
     .ex_mem_wr_mem(ex_mem_wr_mem),
     .Dmem2proc_data(mem2proc_data),
     
     // Outputs
     .mem_result_out(mem_result_out),
     .proc2Dmem_command(proc2Dmem_command),
     .proc2Dmem_addr(proc2Dmem_addr),
     .proc2Dmem_data(proc2mem_data)
  );


  //////////////////////////////////////////////////
  //                                              //
  //           MEM/WB Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign mem_wb_enable = 1'b1; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      mem_wb_NPC          <= `SD 0;
      mem_wb_IR           <= `SD `NOOP_INST;
      mem_wb_halt         <= `SD 0;
      mem_wb_illegal      <= `SD 0;
      mem_wb_valid_inst   <= `SD 0;
      mem_wb_dest_reg_idx <= `SD `ZERO_REG;
      mem_wb_take_branch  <= `SD 0;
      mem_wb_result       <= `SD 0;
    end else begin
      if (mem_wb_enable) begin
        // these are forwarded directly from EX/MEM latches
        mem_wb_NPC          <= `SD ex_mem_NPC;
        mem_wb_IR           <= `SD ex_mem_IR;
        mem_wb_halt         <= `SD ex_mem_halt;
        mem_wb_illegal      <= `SD ex_mem_illegal;
        mem_wb_valid_inst   <= `SD ex_mem_valid_inst;
        mem_wb_dest_reg_idx <= `SD ex_mem_dest_reg_idx;
        mem_wb_take_branch  <= `SD ex_mem_take_branch;
        // these are results of MEM stage
        mem_wb_result       <= `SD mem_result_out;
      end // if
    end // else: !if(reset)
  end // always


  //////////////////////////////////////////////////
  //                                              //
  //                  WB-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  wb_stage wb_stage_0 (
    // Inputs
    .clock(clock),
    .reset(reset),
    .mem_wb_NPC(mem_wb_NPC),
    .mem_wb_result(mem_wb_result),
    .mem_wb_dest_reg_idx(mem_wb_dest_reg_idx),
    .mem_wb_take_branch(mem_wb_take_branch),
    .mem_wb_valid_inst(mem_wb_valid_inst),

    // Outputs
    .reg_wr_data_out(wb_reg_wr_data_out),
    .reg_wr_idx_out(wb_reg_wr_idx_out),
    .reg_wr_en_out(wb_reg_wr_en_out)
  );

endmodule  // module verisimple
