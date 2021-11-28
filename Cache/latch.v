///////////////////////////////////////////////////////////////////////////
//File: Latches for Pipelined TSC microcomputer: Latch.v
//Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
//Description: 1 PC and 4 latches (pipeline registers)

//Define constant
`define WORD_SIZE 16

//Include file
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions

/////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Program_Counter(
    input clk,
    input reset_n,
    input Stall,
    input Halt,
    input I_miss,
    input D_miss,
    input [`WORD_SIZE-1:0] next_addr,
    
    output IRead,
    output [`WORD_SIZE-1:0] inst_addr
);

    // internal reg for port 
    reg [`WORD_SIZE-1:0] r_inst_addr;
    assign inst_addr = r_inst_addr;

    // output port assignment
    assign IRead = !Halt;


    always @(posedge clk) begin
        if (!reset_n) begin
            r_inst_addr <= 0;
        end
        else begin
            if (Stall || I_miss || D_miss || Halt) begin
            end
            else begin
                r_inst_addr <= next_addr;
            end
        end
    end
endmodule
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module IF_ID_Register(
    input clk,
    input reset_n,
    input Stall,
    input Halt,
    input Flush,
    input D_miss,
    input [`WORD_SIZE-1:0] IF_pc,
    input [`WORD_SIZE-1:0] IF_inst,
    
    output [`WORD_SIZE-1:0] ID_pc,
    output [`WORD_SIZE-1:0] ID_inst
);
    // internal reg for ports
    reg [`WORD_SIZE-1:0] r_pc;
    reg [`WORD_SIZE-1:0] r_inst;
    assign ID_pc = r_pc;
    assign ID_inst = r_inst;


    always @(posedge clk) begin
        if (!reset_n) begin
            r_pc <= 0;
            r_inst <= 0;
        end
        else begin
            if (Stall || Flush || D_miss || Halt) begin
            end
            else begin
                r_pc <= IF_pc;
                r_inst <= IF_inst;
            end
        end
    end
endmodule
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module ID_EX_Register(
    input clk,
    input reset_n,
    input Stall,
    input Flush,
    input Halt,
    input D_miss,
    input ID_OutWrite,
    input [1:0] ID_AluSrcB,
    input [3:0] ID_AluOp,
    input ID_MemRead,
    input ID_MemWrite,
    input ID_Halt,
    input ID_RegWrite,
    input [1:0] ID_RegSource,
    input [`WORD_SIZE-1:0] ID_reg_data_A,
    input [`WORD_SIZE-1:0] ID_reg_data_B,
    input [`WORD_SIZE-1:0] ID_se_immediate,
    input [1:0] ID_reg_write_addr,
    input [`WORD_SIZE-1:0] ID_pc_plus_one,
    
    output EX_OutWrite,
    output [1:0] EX_AluSrcB,
    output [3:0] EX_AluOp,
    output EX_MemRead,
    output EX_MemWrite,
    output EX_Halt,
    output [1:0] EX_RegSource,
    output EX_RegWrite,
    output [`WORD_SIZE-1:0] EX_reg_data_A,
    output [`WORD_SIZE-1:0] EX_reg_data_B,
    output [`WORD_SIZE-1:0] EX_se_immediate,
    output [1:0] EX_reg_write_addr,
    output [`WORD_SIZE-1:0] EX_pc_plus_one
);
    // internal reg for ports
    reg r_OutWrite;
    reg [1:0] r_AluSrcB;
    reg [3:0] r_AluOp;
    reg r_MemRead;
    reg r_MemWrite;
    reg r_Halt;
    reg [1:0] r_RegSource;
    reg r_RegWrite;
    reg [`WORD_SIZE-1:0] r_reg_data_A;
    reg [`WORD_SIZE-1:0] r_reg_data_B;
    reg [`WORD_SIZE-1:0] r_se_immediate;
    reg [1:0] r_reg_write_addr;
    reg [`WORD_SIZE-1:0] r_pc_plus_one;
    assign EX_OutWrite = r_OutWrite;
    assign EX_AluSrcB = r_AluSrcB;
    assign EX_AluOp = r_AluOp;
    assign EX_MemRead = r_MemRead;
    assign EX_MemWrite = r_MemWrite;
    assign EX_Halt = r_Halt;
    assign EX_RegWrite = r_RegWrite;
    assign EX_RegSource = r_RegSource;
    assign EX_reg_data_A = r_reg_data_A;
    assign EX_reg_data_B = r_reg_data_B;
    assign EX_se_immediate = r_se_immediate;
    assign EX_reg_write_addr = r_reg_write_addr;
    assign EX_pc_plus_one = r_pc_plus_one;

    //synchronous latch, reset
    always @(posedge clk) begin
        // insert bubble (pipelining NOP)
        if ((!reset_n) || Stall || Flush) begin
            r_OutWrite <= 0;
            r_AluSrcB <= 0;
            r_AluOp <= 0;
            r_MemRead <= 0;
            r_MemWrite <= 0;
            r_Halt <= 0;
            r_RegWrite <= 0;
            r_RegSource <= 0;
            r_reg_data_A <= 0;
            r_reg_data_B <= 0;
            r_se_immediate <= 0;
            r_reg_write_addr <= 0;
            r_pc_plus_one <= 0;
        end
        else begin
            if (D_miss===1 || Halt===1) begin
            end
            else begin
                r_OutWrite <= ID_OutWrite;
                r_AluSrcB <= ID_AluSrcB;
                r_AluOp <= ID_AluOp;
                r_MemRead <= ID_MemRead;
                r_MemWrite <= ID_MemWrite;
                r_Halt <= ID_Halt;
                r_RegWrite <= ID_RegWrite;
                r_RegSource <= ID_RegSource;
                r_reg_data_A <= ID_reg_data_A;
                r_reg_data_B <= ID_reg_data_B;
                r_se_immediate <= ID_se_immediate;
                r_reg_write_addr <= ID_reg_write_addr;
                r_pc_plus_one <= ID_pc_plus_one;
            end
        end
    end
endmodule
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module EX_MEM_Register(
    input clk,
    input reset_n,
    input Halt,
    input D_miss,
    
    input EX_MemRead,
    input EX_MemWrite,
    input EX_Halt,
    input EX_RegWrite,
    input [1:0] EX_RegSource,
    input [`WORD_SIZE-1:0] EX_alu_result,
    input [`WORD_SIZE-1:0] EX_reg_data_B,
    input [1:0] EX_reg_write_addr,
    input [`WORD_SIZE-1:0] EX_pc_plus_one,
    
    output MEM_MemRead,
    output MEM_MemWrite,
    output MEM_Halt,
    output MEM_RegWrite,
    output [1:0] MEM_RegSource,
    output [`WORD_SIZE-1:0] MEM_alu_result,
    output [`WORD_SIZE-1:0] MEM_reg_data_B,
    output [1:0] MEM_reg_write_addr,
    output [`WORD_SIZE-1:0] MEM_pc_plus_one
);

    // internal reg for ports
    reg r_MemRead;
    reg r_MemWrite;
    reg r_Halt;
    reg r_RegWrite;
    reg [1:0] r_RegSource;
    reg [`WORD_SIZE-1:0] r_alu_result;
    reg [`WORD_SIZE-1:0] r_reg_data_B;
    reg [1:0] r_reg_write_addr;
    reg [`WORD_SIZE-1:0] r_pc_plus_one;
    assign MEM_MemRead = r_MemRead;
    assign MEM_MemWrite = r_MemWrite;
    assign MEM_Halt = r_Halt;
    assign MEM_RegSource = r_RegSource;
    assign MEM_RegWrite = r_RegWrite;
    assign MEM_alu_result = r_alu_result;
    assign MEM_reg_data_B = r_reg_data_B;
    assign MEM_reg_write_addr = r_reg_write_addr;
    assign MEM_pc_plus_one = r_pc_plus_one;
    

    //synchronous latch, reset
    always @(posedge clk) begin
        if (!reset_n) begin
            r_MemRead <= 0;
            r_MemWrite <= 0;
            r_Halt <= 0;
            r_RegWrite <= 0;
            r_RegSource <= 0;
            r_alu_result <= 0;
            r_reg_data_B <= 0;
            r_reg_write_addr <= 0;
            r_pc_plus_one <= 0;
        end
        else begin
            if (D_miss || Halt) begin
            end
            else begin
                r_MemRead <= EX_MemRead;
                r_MemWrite <= EX_MemWrite;
                r_Halt <= EX_Halt;
                r_RegWrite <= EX_RegWrite;
                r_RegSource <= EX_RegSource;
                r_alu_result <= EX_alu_result;
                r_reg_data_B <= EX_reg_data_B;
                r_reg_write_addr <= EX_reg_write_addr;
                r_pc_plus_one <= EX_pc_plus_one;
            end
        end
    end
endmodule
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module MEM_WB_Register(
    input clk,
    input reset_n,
    input Halt,
    input D_miss,
    
    input MEM_Halt,
    input [1:0] MEM_RegSource,
    input MEM_RegWrite,
    input [`WORD_SIZE-1:0] MEM_mem_read_data,
    input [`WORD_SIZE-1:0] MEM_alu_result,
    input [1:0] MEM_reg_write_addr,
    input [`WORD_SIZE-1:0] MEM_pc_plus_one,
    
    output WB_Halt,
    output [1:0] WB_RegSource,
    output WB_RegWrite,
    output [`WORD_SIZE-1:0] WB_mem_read_data,
    output [`WORD_SIZE-1:0] WB_alu_result,
    output [1:0] WB_reg_write_addr,
    output [`WORD_SIZE-1:0] WB_pc_plus_one
);

    // internal reg for ports
    reg r_Halt;
    reg [1:0] r_RegSource;
    reg r_RegWrite;
    reg [`WORD_SIZE-1:0] r_mem_read_data;
    reg [`WORD_SIZE-1:0] r_alu_result;
    reg [1:0] r_reg_write_addr;
    reg [`WORD_SIZE-1:0] r_pc_plus_one;
    assign WB_Halt = r_Halt;
    assign WB_RegSource = r_RegSource;
    assign WB_RegWrite = r_RegWrite;
    assign WB_mem_read_data = r_mem_read_data;
    assign WB_alu_result = r_alu_result;
    assign WB_reg_write_addr = r_reg_write_addr;
    assign WB_pc_plus_one = r_pc_plus_one;
    
    
    // synchronous latch, reset
    always @(posedge clk) begin
        if (!reset_n) begin
            r_Halt <= 0;
            r_RegSource <= 0;
            r_RegWrite <= 0;
            r_mem_read_data <= 0;
            r_alu_result <= 0;
            r_reg_write_addr <= 0;
            r_pc_plus_one <= 0;
        end
        else begin
            if (D_miss || Halt) begin
            end
            else begin
                r_Halt <= MEM_Halt;
                r_RegSource <= MEM_RegSource;
                r_RegWrite <= MEM_RegWrite;
                r_mem_read_data <= MEM_mem_read_data;
                r_alu_result <= MEM_alu_result;
                r_reg_write_addr <= MEM_reg_write_addr;
                r_pc_plus_one <= MEM_pc_plus_one;
            end
        end
    end
endmodule