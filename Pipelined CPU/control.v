///////////////////////////////////////////////////////////////////////////
//Module: Control for Pipelined TSC microcomputer: Control.v
//Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
//Description: Generates control signal for input instruction, for every following stages. supports full TSC ISA(23 instructions)

//Define constant
`define WORD_SIZE 16

//File includes
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module Control(
    input reset_n,
    input [3:0] OPCODE,
    input [5:0] FUNCTION_CODE,

    //control signals for each pipeline stage
    output [1:0] RegDst,
    output use_rs,
    output use_rt,
    output [1:0] is_J_JR_Branch,

    output OutWrite,
    output [3:0] AluOp,
    output [1:0] AluSrcB,

    output MemRead,
    output MemWrite,
    output Halt,

    output RegWrite,
    output [1:0] RegSource
);

    //Internal reg variable declaration
    reg [1:0] r_RegDst;
    reg r_use_rs;
    reg r_use_rt;
    reg [1:0] r_is_J_JR_Branch;
    reg r_OutWrite;
    reg [3:0] r_AluOp;
    reg r_AluSrcB;
    reg r_MemRead;
    reg r_MemWrite;
    reg r_Halt;
    reg [1:0] r_RegSource;
    reg r_RegWrite;
    //Output port assignment
    assign RegDst = r_RegDst;
    assign use_rs = r_use_rs;
    assign use_rt = r_use_rt;
    assign is_J_JR_Branch = r_is_J_JR_Branch;
    assign OutWrite = r_OutWrite;
    assign AluOp = r_AluOp;
    assign AluSrcB = r_AluSrcB;
    assign MemRead = r_MemRead;
    assign MemWrite = r_MemWrite;
    assign Halt = r_Halt;
    assign RegSource = r_RegSource;
    assign RegWrite = r_RegWrite;

    //Synchronous signal generation
    always @(OPCODE, FUNCTION_CODE, negedge reset_n) begin
        if (!reset_n) begin
            r_RegDst <= 0; r_use_rs <= 0;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
            r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
            r_RegSource <= 0; r_RegWrite <= 0;
        end
        else begin
            case (OPCODE)
                `OPCODE_R:
                    case (FUNCTION_CODE)
                        `FUNC_ADD: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 1; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALUCODE_ADD; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                            r_RegSource <= 0; r_RegWrite <= 1;
                        end
                        `FUNC_SUB: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 1; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALUCODE_SUB; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                            r_RegSource <= 0; r_RegWrite <= 1;
                        end
                        `FUNC_AND: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 1; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALUCODE_AND; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0; 
                            r_RegSource <= 0; r_RegWrite <= 1;
                        end
                        `FUNC_ORR: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 1; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALUCODE_ORR; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0; 
                            r_RegSource <= 0; r_RegWrite <= 1;
                        end
                        `FUNC_NOT: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALUCODE_NOT; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0; 
                            r_RegSource <= 0; r_RegWrite <= 1;
                        end
                        `FUNC_TCP: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALUCODE_TCP; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                            r_RegSource <= 0; r_RegWrite <= 1;
                        end
                        `FUNC_SHL: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALUCODE_SHL; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                            r_RegSource <= 0; r_RegWrite <= 1;
                        end
                        `FUNC_SHR: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALUCODE_SHR; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                            r_RegSource <= 0; r_RegWrite <= 1;
                        end
                        `FUNC_WWD: begin
                            r_RegDst <= 0; r_use_rs <= 1; r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 1; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0; 
                            r_RegSource <= 0; r_RegWrite <= 0;
                        end
                        `FUNC_JPR: begin
                            r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 2;
                            r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                            r_RegSource <= 0; r_RegWrite <= 0;
                        end
                        `FUNC_JRL: begin
                            r_RegDst <= 2; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 2;
                            r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                            r_RegSource <= 2; r_RegWrite <= 1;
                        end
                        `FUNC_HLT: begin
                            r_RegDst <= 0; r_use_rs <= 0;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                            r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                            r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 1;
                            r_RegSource <= 0; r_RegWrite <= 0;
                        end
                    endcase
                `OPCODE_ADI: begin
                        r_RegDst <= 1; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                        r_OutWrite <= 0; r_AluOp <= `ALUCODE_ADD; r_AluSrcB <= 1;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0; 
                        r_RegSource <= 0; r_RegWrite <= 1;
                    end
                `OPCODE_ORI: begin
                        r_RegDst <= 1; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                        r_OutWrite <= 0; r_AluOp <= `ALUCODE_ORI; r_AluSrcB <= 1;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 1;
                    end
                `OPCODE_LHI: begin
                        r_RegDst <= 1; r_use_rs <= 0;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                        r_OutWrite <= 0; r_AluOp <= `ALUCODE_LHI; r_AluSrcB <= 1;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 1;
                    end
                `OPCODE_LWD: begin
                        r_RegDst <= 1; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                        r_OutWrite <= 0; r_AluOp <= `ALUCODE_ADD; r_AluSrcB <= 1;
                        r_MemRead <= 1; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 1; r_RegWrite <= 1;
                    end
                `OPCODE_SWD: begin
                        r_RegDst <= 1; r_use_rs <= 1;  r_use_rt <= 1; r_is_J_JR_Branch <= 0;
                        r_OutWrite <= 0; r_AluOp <= `ALUCODE_ADD; r_AluSrcB <= 1;
                        r_MemRead <= 0; r_MemWrite <= 1; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 0;
                    end
                `OPCODE_BNE: begin
                        r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 1; r_is_J_JR_Branch <= 3;
                        r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 0;
                    end
                `OPCODE_BEQ: begin
                        r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 1; r_is_J_JR_Branch <= 3;
                        r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 0;
                    end
                `OPCODE_BGZ: begin
                        r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 3;
                        r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 0;
                    end
                `OPCODE_BLZ: begin
                        r_RegDst <= 0; r_use_rs <= 1;  r_use_rt <= 0; r_is_J_JR_Branch <= 3;
                        r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 0;
                    end
                `OPCODE_JMP: begin
                        r_RegDst <= 0; r_use_rs <= 0;  r_use_rt <= 0; r_is_J_JR_Branch <= 1;
                        r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 0;
                    end
                `OPCODE_JAL: begin
                        r_RegDst <= 2; r_use_rs <= 0;  r_use_rt <= 0; r_is_J_JR_Branch <= 1;
                        r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 2; r_RegWrite <= 1;
                    end
                default: begin
                        r_RegDst <= 0; r_use_rs <= 0;  r_use_rt <= 0; r_is_J_JR_Branch <= 0;
                        r_OutWrite <= 0; r_AluOp <= `ALU_NOT_USED; r_AluSrcB <= 0;
                        r_MemRead <= 0; r_MemWrite <= 0; r_Halt <= 0;
                        r_RegSource <= 0; r_RegWrite <= 0;
                    end
            endcase
        end
    end
endmodule
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module Branch_Condition(
    input reset_n,
    input [3:0] OPCODE,
    input [`WORD_SIZE-1:0] A,
    input [`WORD_SIZE-1:0] B,

    output taken
);
    //internal reg variable, to assign value in always block
    reg r_taken;
    assign taken = r_taken;

    always @(*) begin
        if (!reset_n) begin
            r_taken <= 0;
        end
        else begin
            case (OPCODE)
                `OPCODE_BNE: begin r_taken <= (A !== B) ? 1 : 0; end
                `OPCODE_BEQ: begin r_taken <= (A === B) ? 1 : 0; end
                `OPCODE_BGZ: begin r_taken <= (A !== `WORD_SIZE'b0) ? ~A[`WORD_SIZE-1] : 0; end
                `OPCODE_BLZ: begin r_taken <= A[`WORD_SIZE-1]; end
                default: begin r_taken <= 0; end
            endcase
        end
    end
endmodule
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module Hazard_Detection(
    input reset_n,
    input [1:0] is_J_JR_Branch,

    input branch_taken,
    input [15:0] target_address,
    input [15:0] IF_pc,
    input [15:0] ID_pc,
    
    input use_rs,
    input use_rt,
    input EX_RegWrite,
    input MEM_RegWrite,
    input WB_RegWrite,
    input [1:0] ID_rs,
    input [1:0] ID_rt,
    input [1:0] EX_reg_write_addr,
    input [1:0] MEM_reg_write_addr,
    input [1:0] WB_reg_write_addr,

    output Stall,
    output Flush,
    output BtbWrite,
    output [15:0] correct_address
);

    //internal reg variable
    reg r_Stall, r_Flush, r_BtbWrite;
    reg [15:0] r_correct_address;
    //output port assignment
    assign Stall = r_Stall;
    assign Flush = r_Flush;
    assign BtbWrite = r_BtbWrite;
    assign correct_address = r_correct_address;

    always @(negedge reset_n) begin
        r_Stall <= 0;
        r_Flush <= 0;
        r_BtbWrite <= 0;
        r_correct_address <= 0;
    end

    //Synchronous hazard detection & response
    always @(*) begin
        //Data Hazard: Stall (insert bubbles, stall fetching)
        r_Stall <= (EX_RegWrite && ((use_rs && (EX_reg_write_addr===ID_rs)) || (use_rt && (EX_reg_write_addr===ID_rt)))) || (MEM_RegWrite && ((use_rs && (MEM_reg_write_addr===ID_rs)) || (use_rt && (MEM_reg_write_addr===ID_rt)))) || (WB_RegWrite && ((use_rs && (WB_reg_write_addr===ID_rs)) || (use_rt && (WB_reg_write_addr===ID_rt))));
        
        //Control Hazard: Flush, BtbWrite
        if (is_J_JR_Branch !== 2'b0) begin
            r_BtbWrite <= (IF_pc !== target_address) ? 1 : 0;
            case (is_J_JR_Branch)
                1: begin r_Flush <= (IF_pc !== target_address) ? 1 : 0; r_correct_address <= target_address; end
                2: begin r_Flush <= (IF_pc !== target_address) ? 1 : 0; r_correct_address <= target_address; end
                3: begin r_Flush <= (IF_pc !== target_address) ? (branch_taken ? 1: 0) : (branch_taken ? 0: 1); 
                         r_correct_address <= branch_taken ? target_address : ID_pc + 1; end
                default: begin r_BtbWrite <= 0; r_Flush <= 0; end
            endcase
        end
        else begin
            r_BtbWrite <= 0;
            r_Flush <= 0;
        end
    end
endmodule