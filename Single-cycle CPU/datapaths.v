// DEFINITIONS
`define WORD_SIZE 16
`define NUM_REG 4

// INCLUDE files
`include "opcodes.v"    // "opcodes.v" consists of "define" statements for
                          // the opcodes and function codes for all instructions & ALU operations.
/////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module Program_Counter(clk, reset_n, pc_next, inputReady, pc, MemRead, inst_count);
    input clk;
    input reset_n;
    input [`WORD_SIZE-1:0] pc_next;
    input inputReady;
    output reg [`WORD_SIZE-1:0] pc;
    output reg MemRead;
    output reg [`WORD_SIZE-1:0] inst_count;
    
    always @ (posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            pc <= -1;
            MemRead <= 0;
            inst_count <= 0;
        end
        else begin
            pc <= pc_next;
            MemRead <= 1;
            inst_count <= inst_count + 1;
        end
    end
    always @ (negedge inputReady) begin
        MemRead <= 0;
    end
endmodule
////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module Instruction(MemRead, inputReady, data, instruction);
    input MemRead;
    input inputReady;
    input [`WORD_SIZE-1:0] data;
    output reg [`WORD_SIZE-1:0] instruction;

    always @(data) begin
        if (MemRead == 1 && inputReady == 1) begin
            instruction <= data;
        end
    end
endmodule
////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module Register_File(write, clk, reset_n, addr1, addr2, addr3, data3, data1, data2);
    input write;
    input clk;
    input reset_n;
    input [1:0] addr1;
    input [1:0] addr2;
    input [1:0] addr3;
    input [`WORD_SIZE - 1:0] data3;
    output [`WORD_SIZE - 1:0] data1;
    output [`WORD_SIZE - 1:0] data2;

    reg [`WORD_SIZE - 1:0] register_file [`NUM_REG - 1:0];
    integer i;
    
    assign data1 = register_file[addr1];
    assign data2 = register_file[addr2];

    // asynchronous reset or synchronous write
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            for (i = 0; i < `NUM_REG; i = i + 1) begin
                register_file[i] <= 0;
            end
        end
        else begin   
            // write, if write is asserted
            if (write == 1) begin
                    register_file[addr3] <= data3;
            end
        end
     end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module ALU(
    input [15:0] A, B,
    input [3:0] alu_opcode,
    output reg [15:0] C,
    output reg Cout);

    // SIGNAL DECLARATIONS for operation result C
    wire [16:0] C_ADD, C_SUB;       // C = A + B, A - B (with carry in, out)    * 0 - B = 2's complement of B
    wire [15:0] C_AND, C_OR, C_NOT; // C = A & B, A | B, ~A (bitwise logical operations)
    wire [15:0] C_TCP;              // C = ~A + 1 (2's complement)
    wire [15:0] C_ALS, C_ARS;       // C = A <<< 1, A >>> 1 (arithmetic shift operations)
    wire [15:0] C_LHI;              // C = B <<< 8; (8-bit B into left halfword of C)

    // ASSIGNMENT of operation results
    assign C_ADD = A + B;
    assign C_SUB = A - B;
    assign C_AND = A & B;
    assign C_OR = A | B;
    assign C_NOT = ~A;
    assign C_TCP = ~A + 1;
    assign C_ALS = A <<< 1;
    assign C_ARS = {A[15], A[15:1]};
    assign C_LHI = B << 8;

    // OUTPUT PORT assignment, selecting operation result according to i_opcode
    always @(*) begin
        // Output 1. "C"
        case(alu_opcode)
            `ALU_ADD : C <= C_ADD[15:0];
            `ALU_SUB : C <= C_SUB[15:0];
            `ALU_AND : C <= C_AND;
            `ALU_OR  : C <= C_OR;
            `ALU_NOT : C <= C_NOT;
            `ALU_TCP : C <= C_TCP;
            `ALU_ALS : C <= C_ALS;
            `ALU_ARS : C <= C_ARS;
            `ALU_LHI : C <= C_LHI;
            `ALU_BNE : C <= C_ADD[15:0];
            `ALU_BEQ : C <= C_ADD[15:0];
            `ALU_BGZ : C <= C_ADD[15:0];
            `ALU_BLZ : C <= C_ADD[15:0];
            default:   C <= 16'bz;
        endcase
        // Output 2. "Cout"
        case (alu_opcode)
            `ALU_ADD: Cout <= C_ADD[16];
            `ALU_SUB: Cout <= C_SUB[16];
            `ALU_AND : Cout <= 0;
            `ALU_OR  : Cout <= 0;
            `ALU_NOT : Cout <= 0;
            `ALU_TCP : Cout <= 0;
            `ALU_ALS : Cout <= 0;
            `ALU_ARS : Cout <= 0;
            `ALU_LHI : Cout <= 0;
            `ALU_BNE : Cout <= A !== B;
            `ALU_BEQ : Cout <= A === B;
            `ALU_BGZ : Cout <= A > 0;
            `ALU_BLZ : Cout <= A < 0;
            default: Cout <= 1'bz;
        endcase
    end
endmodule
///////////////////////////////////////////////////////////////////////////////