`timescale 1ns/1ns
///////////////////////////////////////////////////////////////////////////
//Module: CPU for TSC microcomputer, multi-cycle, sequentially controlled: CPU.v
//Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
//Description: Multi-cycle CPU, microarchitecture design supporting full TSC ISA(23 instructions)

//Define constants
`define WORD_SIZE 16    // data and address word size

//File includes
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module cpu(
        input Clk, 
        input Reset_N, 

	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_address, 
        inout [`WORD_SIZE-1:0] i_data, 

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [`WORD_SIZE-1:0] d_data, 

        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted
);

        //Internal signal declarations
        //MEM->all
        wire c_Halt, c_D_miss;
        //ID->IF
        wire c_BtbWrite, c_Stall, c_Flush;
        wire [`WORD_SIZE-1:0] w_ID_pc, w_correct_address;
        //IF only
        wire c_IRead, c_I_miss;
        wire [`WORD_SIZE-1:0] w_IF_pc, w_IF_next_pc, w_btb_read_data, w_IF_inst;
        //ID only
        wire c_branch_taken;
        wire [`WORD_SIZE-1:0] w_ID_inst, w_jump_target, w_branch_target, w_target_address, w_ID_pc_plus_one;
        wire [1:0] w_ID_reg_write_addr;
        wire [`WORD_SIZE-1:0] w_ID_reg_data_A, w_ID_reg_data_B, w_ID_se_immediate;
        //EX only
        wire [1:0] w_EX_reg_write_addr;
        wire [`WORD_SIZE-1:0] w_EX_reg_data_A, w_EX_reg_data_B, w_EX_se_immediate, w_EX_alu_src_B, w_EX_pc_plus_one, w_EX_alu_result, w_num_inst;
        //MEM only
        wire [1:0] w_MEM_reg_write_addr;
        wire [`WORD_SIZE-1:0] w_MEM_alu_result, w_MEM_reg_data_B, w_MEM_pc_plus_one, w_MEM_mem_read_data;
        //WB only
        wire c_is_halted;
        wire [1:0] w_WB_reg_write_addr;
        wire [`WORD_SIZE-1:0] w_WB_mem_read_data, w_WB_reg_write_data, w_WB_alu_result, w_WB_pc_plus_one;

        //Control module signals
        wire [1:0] c_ID_RegDst; wire c_use_rs, c_use_rt; wire [1:0] c_is_j_jr_branch;
        wire c_ID_OutWrite, c_ID_AluSrcB; wire [3:0] c_ID_AluOp;
        wire c_ID_MemRead, c_ID_MemWrite, c_ID_Halt;
        wire c_ID_RegWrite; wire [1:0] c_ID_RegSource;
        
        wire c_EX_OutWrite, c_EX_AluSrcB; wire [3:0] c_EX_AluOp;
        wire c_EX_MemRead, c_EX_MemWrite, c_EX_Halt;
        wire c_EX_RegWrite; wire [1:0] c_EX_RegSource;

        wire c_MEM_MemRead, c_MEM_MemWrite, c_MEM_Halt;
        wire c_MEM_RegWrite; wire [1:0] c_MEM_RegSource;

        wire c_WB_Halt;
        wire c_WB_RegWrite; wire [1:0] c_WB_RegSource;
        

        //IF stage
        //Internal signal assignment
        assign w_IF_next_pc = c_Flush ? w_correct_address : w_btb_read_data;
        //Port signal assignment: None
        //Submodule instantiation
        Program_Counter PC(.clk(Clk), .reset_n(Reset_N), .Stall(c_Stall), .Halt(c_Halt), .I_miss(c_I_miss), .D_miss(c_D_miss), .next_addr(w_IF_next_pc), .IRead(c_IRead), .inst_addr(w_IF_pc));
        Branch_Target_Buffer BTB(.clk(Clk), .reset_n(Reset_N), .BtbWrite(c_BtbWrite), .read_addr(w_IF_pc), .write_addr(w_ID_pc), .write_data(w_target_address), .read_data(w_btb_read_data));
        Cache Icache(.clk(Clk), .reset_n(Reset_N), .readM_cpu(c_IRead), .writeM_cpu(0), .address_cpu(w_IF_pc), .data_cpu(w_IF_inst), .miss(c_I_miss), .data_mem(i_data), .address_mem(i_address), .readM_mem(i_readM), .writeM_mem(i_writeM));
        IF_ID_Register IF_ID(.clk(Clk), .reset_n(Reset_N), .Stall(c_Stall), .Halt(c_Halt), .Flush(c_Flush), .D_miss(c_D_miss), .IF_pc(w_IF_pc), .IF_inst(w_IF_inst), .ID_pc(w_ID_pc), .ID_inst(w_ID_inst));


        //ID stage
        //Internal signal assignment
        assign w_ID_pc_plus_one = w_ID_pc + 1;
        assign w_jump_target = {w_ID_pc[15:12], w_ID_inst[11:0]};
        assign w_branch_target = w_ID_pc_plus_one + w_ID_se_immediate;
        assign w_ID_se_immediate = {{8{w_ID_inst[7]}}, w_ID_inst[7:0]};
        assign w_target_address = c_is_j_jr_branch[1] ? (c_is_j_jr_branch[0] ? w_branch_target : w_ID_reg_data_A) : (c_is_j_jr_branch[0] ? w_jump_target : `WORD_SIZE'bz);
        assign w_ID_reg_write_addr = c_ID_RegDst[1] ? 2'd2 : (c_ID_RegDst[0] ? w_ID_inst[9:8] : w_ID_inst[7:6]);
        //Port signal assignment
        //assign num_inst = w_num_inst;
        //Submodule instantiation
        Control UUT(.reset_n(Reset_N), .OPCODE(w_ID_inst[15:12]), .FUNCTION_CODE(w_ID_inst[5:0]), .RegDst(c_ID_RegDst), .use_rs(c_use_rs), .use_rt(c_use_rt), .is_J_JR_Branch(c_is_j_jr_branch), .OutWrite(c_ID_OutWrite), .AluSrcB(c_ID_AluSrcB), .AluOp(c_ID_AluOp), .MemRead(c_ID_MemRead), .MemWrite(c_ID_MemWrite), .Halt(c_ID_Halt), .RegWrite(c_ID_RegWrite), .RegSource(c_ID_RegSource));
        Branch_Condition BrCond(.reset_n(Reset_N), .OPCODE(w_ID_inst[15:12]), .A(w_ID_reg_data_A), .B(w_ID_reg_data_B), .taken(c_branch_taken));
        Hazard_Detection HD(.reset_n(Reset_N), .is_J_JR_Branch(c_is_j_jr_branch), .branch_taken(c_branch_taken), .target_address(w_target_address), .IF_pc(w_IF_pc), .ID_pc(w_ID_pc), .use_rs(c_use_rs), .use_rt(c_use_rt), .EX_RegWrite(c_EX_RegWrite), .MEM_RegWrite(c_MEM_RegWrite), .WB_RegWrite(c_WB_RegWrite), .ID_rs(w_ID_inst[11:10]), .ID_rt(w_ID_inst[9:8]), .EX_reg_write_addr(w_EX_reg_write_addr), .MEM_reg_write_addr(w_MEM_reg_write_addr), .WB_reg_write_addr(w_WB_reg_write_addr), .Stall(c_Stall), .Flush(c_Flush), .BtbWrite(c_BtbWrite), .correct_address(w_correct_address));
        Register_File RF(.clk(Clk), .reset_n(Reset_N), .RegWrite(c_WB_RegWrite), .read_addr1(w_ID_inst[11:10]), .read_addr2(w_ID_inst[9:8]), .write_addr(w_WB_reg_write_addr), .read_data1(w_ID_reg_data_A), .read_data2(w_ID_reg_data_B), .write_data(w_WB_reg_write_data));
        //Instruction_Counter IC(.clk(Clk), .reset_n(Reset_N), .Stall(c_Stall), .I_miss(c_I_miss), .D_miss(c_D_miss), .Flush(c_Flush), .Halt(c_Halt), .num_inst(w_num_inst));
        ID_EX_Register ID_EX(.clk(Clk), .reset_n(Reset_N), .Stall(c_Stall), .Flush(c_Flush), .Halt(c_Halt), .D_miss(c_D_miss), .ID_OutWrite(c_ID_OutWrite), .ID_AluSrcB(c_ID_AluSrcB), .ID_AluOp(c_ID_AluOp), .ID_MemRead(c_ID_MemRead), .ID_MemWrite(c_ID_MemWrite), .ID_Halt(c_ID_Halt), .ID_RegWrite(c_ID_RegWrite), .ID_RegSource(c_ID_RegSource), .ID_reg_data_A(w_ID_reg_data_A), .ID_reg_data_B(w_ID_reg_data_B), .ID_se_immediate(w_ID_se_immediate), .ID_reg_write_addr(w_ID_reg_write_addr), .ID_pc_plus_one(w_ID_pc_plus_one), .EX_OutWrite(c_EX_OutWrite), .EX_AluSrcB(c_EX_AluSrcB), .EX_AluOp(c_EX_AluOp), .EX_MemRead(c_EX_MemRead), .EX_MemWrite(c_EX_MemWrite), .EX_Halt(c_EX_Halt), .EX_RegWrite(c_EX_RegWrite), .EX_RegSource(c_EX_RegSource), .EX_reg_data_A(w_EX_reg_data_A), .EX_reg_data_B(w_EX_reg_data_B), .EX_se_immediate(w_EX_se_immediate), .EX_reg_write_addr(w_EX_reg_write_addr), .EX_pc_plus_one(w_EX_pc_plus_one));
        

        //EX stage
        //Internal signal assignment
        assign w_EX_alu_src_B = c_EX_AluSrcB ? w_EX_se_immediate : w_EX_reg_data_B;
        //Port signal assignment
        assign output_port = c_EX_OutWrite ? w_EX_reg_data_A : `WORD_SIZE'bz;
        //Submodule instantiation
        Instruction_Counter IC(.clk(Clk), .reset_n(Reset_N), .EX_pc_plus_one(w_EX_pc_plus_one), .num_inst(num_inst));
        ALU ALU_(.src_a(w_EX_reg_data_A), .src_b(w_EX_alu_src_B), .alucode(c_EX_AluOp), .result(w_EX_alu_result));
        EX_MEM_Register EX_MEM(.clk(Clk), .reset_n(Reset_N), .Halt(c_Halt), .D_miss(c_D_miss), .EX_MemRead(c_EX_MemRead), .EX_MemWrite(c_EX_MemWrite), .EX_Halt(c_EX_Halt), .EX_RegWrite(c_EX_RegWrite), .EX_RegSource(c_EX_RegSource), .EX_alu_result(w_EX_alu_result), .EX_reg_data_B(w_EX_reg_data_B), .EX_reg_write_addr(w_EX_reg_write_addr), .EX_pc_plus_one(w_EX_pc_plus_one), .MEM_MemRead(c_MEM_MemRead), .MEM_MemWrite(c_MEM_MemWrite), .MEM_Halt(c_MEM_Halt), .MEM_RegSource(c_MEM_RegSource), .MEM_RegWrite(c_MEM_RegWrite), .MEM_alu_result(w_MEM_alu_result), .MEM_reg_data_B(w_MEM_reg_data_B), .MEM_reg_write_addr(w_MEM_reg_write_addr), .MEM_pc_plus_one(w_MEM_pc_plus_one));

        //MEM stage
        //Internal signal assignment
        assign c_Halt = c_MEM_Halt;
        //Port signal assignment: None
        //Submodule instantiation
        Cache Mcache(.clk(Clk), .reset_n(Reset_N), .readM_cpu(c_MEM_MemRead), .writeM_cpu(c_MEM_MemWrite), .address_cpu(w_MEM_alu_result), .data_cpu(w_MEM_mem_read_data), .miss(c_D_miss), .data_mem(d_data), .address_mem(d_address), .readM_mem(d_readM), .writeM_mem(d_writeM));
        MEM_WB_Register MEM_WB(.clk(Clk), .reset_n(Reset_N), .Halt(c_is_halted), .D_miss(c_D_miss), .MEM_Halt(c_MEM_Halt), .MEM_RegSource(c_MEM_RegSource), .MEM_RegWrite(c_MEM_RegWrite), .MEM_mem_read_data(w_MEM_mem_read_data), .MEM_alu_result(w_MEM_alu_result), .MEM_reg_write_addr(w_MEM_reg_write_addr), .MEM_pc_plus_one(w_MEM_pc_plus_one), .WB_Halt(c_WB_Halt), .WB_RegSource(c_WB_RegSource), .WB_RegWrite(c_WB_RegWrite), .WB_mem_read_data(w_WB_mem_read_data), .WB_alu_result(w_WB_alu_result), .WB_reg_write_addr(w_WB_reg_write_addr), .WB_pc_plus_one(w_WB_pc_plus_one));
        
        //WB stage
        //Internal signal assignment
        assign c_is_halted = c_WB_Halt;
        //Port signal assignment
        assign is_halted = c_is_halted;
        assign w_WB_reg_write_data = c_WB_RegSource[1] ? w_WB_pc_plus_one : (c_WB_RegSource[0] ? w_WB_mem_read_data : w_WB_alu_result);
        //Submodule instantiation: None

endmodule