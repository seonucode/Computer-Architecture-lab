///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
// Description: Single-cycle CPU design for 5 basic TSC instructions.

// DEFINITIONS
`define WORD_SIZE 16    // data word size
`define RF_ADDR_SIZE 2     // register file address size
`define OPCODE_SIZE 4   // opcode size in tsc isa
`define FUNCT_SIZE 6    // funct size in tsc isa
`define TAR_SIZE 12     // jump target size in tsc isa
`define IMM_SIZE 8      // immediate size in tsc isa
`define ALU_OPCODE_SIZE 4   // opcode size of the ALU module

// INCLUDE files
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module cpu (
  output readM,                       // read from memory
  output [`WORD_SIZE-1:0] address,    // current address for data
  inout [`WORD_SIZE-1:0] data,        // data being input or output
  input inputReady,                   // indicates that data is ready from the input port
  input reset_n,                      // active-low RESET signal
  input clk,                          // clock signal

  // for debugging/testing purpose
  output [`WORD_SIZE-1:0] num_inst,   // number of instruction during execution
  output [`WORD_SIZE-1:0] output_port // this will be used for a "WWD" instruction
);

  // SIGNAL DECLARATIONS for signals being used internally
  // Control Signals
  wire MemRead;
  wire Jump;
  wire OutWrite;
  wire AluSrcB;
  wire RegWrite;
  wire RegDest;
  wire [2:0] AluOp;
  wire [3:0] AluOpcode;
  
  // Datapath wires
  wire [`WORD_SIZE-1:0] pc_next;                            // next pc
  wire [`WORD_SIZE-1:0] pc;                                 // current pc

  wire [`WORD_SIZE-1:0] instruction;                        // current instruction
  
  wire [`RF_ADDR_SIZE-1:0] rf_addr1, rf_addr2, rf_addr3;    // register file  addresses
  wire [`WORD_SIZE-1:0] rf_data1, rf_data2;                 // read data from register file
  wire [`WORD_SIZE-1:0] write_data;                         // data to write to register file
  
  wire [`WORD_SIZE-1:0] alu_A, alu_B;                       // ALU inputs
  wire [`WORD_SIZE-1:0] alu_C;                              // ALU output C
  
  // CONTROL MODULE instantiations
  // Main control
  CONTROL control(.opcode(instruction[15:12]), .funct(instruction[5:0]), .AluOp(AluOp), .AluSrcB(AluSrcB), .RegDest(RegDest), .RegWrite(RegWrite), .OutWrite(OutWrite), .Jump(Jump));
  
  // ALU control
  ALU_CONTROL alu_control(.AluOp(AluOp), .funct(instruction[5:0]), .AluOpcode(AluOpcode));
  /////////////////////////////////////////////////////////////////////////////
  
  // DATAPATH MODULE instantiations
  // Program Counter
  Program_Counter Pc1(.clk(clk), .reset_n(reset_n), .pc_next(pc_next), .inputReady(inputReady), .pc(pc), .MemRead(MemRead), .inst_count(num_inst));
  
  // Instruction
  Instruction Inst1(.MemRead(MemRead), .inputReady(inputReady), .data(data), .instruction(instruction));

  // Register file
  Register_File Rf1(.write(RegWrite), .clk(clk), .reset_n(reset_n), .addr1(rf_addr1), .addr2(rf_addr2),
            .addr3(rf_addr3), .data3(write_data), .data1(rf_data1), .data2(rf_data2));
  
  // ALU
  ALU Alu1(.A(alu_A), .B(alu_B), .alu_opcode(AluOpcode), .C(alu_C), .Cout(bcond));
////////////////////////////////////////////////////////////////////////////////////
  
  // SIGNAL ASSIGNMENTS for output signals
  assign readM = MemRead;
  assign address = pc;
  assign output_port = OutWrite ? rf_data1 : 16'bz; // $rs to output port
  
  // SIGNAL ASSIGNMENTS for signals being used internally
  assign pc_next = Jump ? {pc[15:12], instruction[11:0]} : pc + 1;
  
  assign rf_addr1 = instruction[11:10]; // $rs
  assign rf_addr2 = instruction[9:8]; // $rt
  assign rf_addr3 = RegDest ? instruction[7:6] : instruction[9:8]; // $rd, $rt
  
  assign write_data = alu_C;    // Write back ALU result 
  
  assign alu_A = rf_data1;  // ALU source A is always $rs
  assign alu_B = AluSrcB ? rf_data2 : {{8{instruction[7]}}, instruction[7:0]};  // ALU source B is $rt or sign-extend(imm)
  
endmodule
//////////////////////////////////////////////////////////////////////////