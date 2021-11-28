// DEFINITIONS
`define WORD_SIZE 16    // data word size
`define OPCODE_SIZE 4   // opcode size in tsc isa
`define FUNCT_SIZE 6    // funct size in tsc isa
`define ALU_OPCODE_SIZE 4   // opcode size of the ALU module

// INCLUDE files
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions
//////////////////////////////////////////////////////////////////////////////
// M0DULE DECLARATION
module CONTROL(
    input [`OPCODE_SIZE-1:0] opcode,
    input [`FUNCT_SIZE-1:0] funct,  // input for evaluating value, executing WWD
    output reg [2:0] AluOp,
    output reg AluSrcB,
    output reg RegDest,
    output reg RegWrite,
    output reg OutWrite,
    output reg Jump);
    
    initial begin
        Jump <= 0;
    end
    
    always @ (opcode, funct) begin
      case (opcode)
        15 : AluOp <= 0;    // determine according to funct
        0  : AluOp <= 4;    // BNE : calculate branch condition
        1  : AluOp <= 5;    // BEQ : calculate branch condition
        2  : AluOp <= 6;    // BGZ : calculate branch condition
        3  : AluOp <= 7;    // BLZ : calculate branch condition
        4  : AluOp <= 1;    // ADI : AND
        5  : AluOp <= 2;    // ORI : OR
        6  : AluOp <= 3;    // LHI : LHI
        7  : AluOp <= 1;    // LWD : AND
        8  : AluOp <= 1;    // SWD : AND
      endcase
      
      AluSrcB <= (opcode != 4'd8 && opcode[3] != 1'd0) ? 1 : 0;   // High: not (SWD, Branch, ADI, ORI, LHI, LWD)
    
      RegDest <= (opcode == 4'd15) ? 1 : 0;    // High: R-type
      RegWrite <= ((opcode == 4'd15 && funct != 6'd28) || (opcode[3:2] == 2'd1)) ? 1 : 0; // High: (R-type && not WWD), ADI, ORI, LHI, LWD
    
      OutWrite <= (opcode == 4'd15 && funct == 6'd28) ? 1 : 0; // High: WWD
    
      Jump <= (opcode == 4'd9) ? 1: 0;    // High: JMP
    end
    
endmodule
////////////////////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module ALU_CONTROL(
    input [2:0] AluOp,
    input [`FUNCT_SIZE-1:0] funct,
    output reg [`ALU_OPCODE_SIZE-1:0] AluOpcode);
    
   always @(AluOp, funct) begin
        if (AluOp == 0) begin
          case (funct)
            0 : AluOpcode <= `ALU_ADD;
            1 : AluOpcode <= `ALU_SUB;
            2 : AluOpcode <= `ALU_AND;
            3 : AluOpcode <= `ALU_OR;
            4 : AluOpcode <= `ALU_NOT;
            5 : AluOpcode <= `ALU_TCP;
            6 : AluOpcode <= `ALU_ALS;
            7 : AluOpcode <= `ALU_ARS;
          endcase
        end
        else begin
          case (AluOp)
            1 : AluOpcode <= `ALU_ADD;
            2 : AluOpcode <= `ALU_OR;
            3 : AluOpcode <= `ALU_LHI;
            4 : AluOpcode <= `ALU_BNE;
            5 : AluOpcode <= `ALU_BEQ;
            6 : AluOpcode <= `ALU_BGZ;
            7 : AluOpcode <= `ALU_BLZ;
          endcase
        end
    end
endmodule
///////////////////////////////////////////////////////////////////////