///////////////////////////////////////////////////////////////////////////
//Module: CPU for TSC microcomputer, multi-cycle, sequentially controlled: CPU.v
//Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
//Description: Multi-cycle CPU, microarchitecture design supporting full TSC ISA(23 instructions)

//File includes
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions
`include "constants.v"  // "constants.v" consists of "define" statements for constants, such as "WORD_SIZE"
///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION

module cpu (
    output readM, // read from memory
    output writeM, // write to memory
    output [`WORD_SIZE-1:0] address, // current address for data
    inout [`WORD_SIZE-1:0] data, // data being input or output
    input inputReady, // indicates that data is ready from the input port
    input reset_n, // active-low RESET signal
    input clk, // clock signal
    
    // for debuging/testing purpose
    output [`WORD_SIZE-1:0] num_inst, // number of instruction during execution
    output [`WORD_SIZE-1:0] output_port, // this will be used for a "WWD" instruction
    output is_halted // 1 if the cpu is halted
);
    //Internal wire declaration
    //  "c_" prefix indicates the wire is carrying control signal
    wire [1:0] c_pcsource, c_regdst, c_alusrcb;
    wire [3:0] c_aluop;
    wire [`WORD_SIZE-1:0] c_num_inst;
    wire c_pcwritecond, c_pcwrite, c_iord, c_memread, c_memwrite, c_memtoreg, c_irwrite, c_alusrca, c_regwrite, c_halt, c_outwrite;
    //  for PC Write signal, OR and AND gate outputs
    wire c_pc_write_or, c_pc_write_and;

    //  datapath module interconnections
    //  "w_" prefix as an indication of wire
    //  "o_" prefix follows after "w_", to indicate the wire is carrying output of a latch
    wire [`WORD_SIZE-1:0] w_next_pc, w_o_pc, w_mem_addr, w_mem_data;
    wire [`WORD_SIZE-1:0] w_inst, w_o_mdr, w_rf_write_data;
    wire [1:0] w_rf_write_addr;
    wire [`WORD_SIZE-1:0] w_rf_data1, w_rf_data2, w_o_a, w_o_b, w_alu_src_a, w_alu_src_b;
    wire [`WORD_SIZE-1:0] w_alu_result, w_o_aluout, w_o_out;
    wire w_alu_zero;
    
    //output port assignments
    assign address = w_mem_addr;
    assign readM = c_memread;
    assign writeM = c_memwrite;

    assign data = c_memwrite ? w_o_b : `WORD_SIZE'bz;
    assign w_mem_data = c_memread ? data : `WORD_SIZE'bz;

    assign num_inst = c_num_inst;
    assign is_halted = c_halt;
    assign output_port = w_o_out;

    //mux selections
    assign w_mem_addr = c_iord ? w_o_aluout : w_o_pc;
    assign w_rf_write_addr = c_regdst[1] ? (c_regdst[0] ? 2'bz : 2'd2) : (c_regdst[0] ? w_inst[9:8] : w_inst[7:6]);
    assign w_rf_write_data = c_memtoreg ? w_o_mdr : w_o_aluout;
    assign w_alu_src_a = c_alusrca ? w_o_a : w_o_pc;
    assign w_alu_src_b = c_alusrcb[1] ? (c_alusrcb[0] ? `WORD_SIZE'bz : `WORD_SIZE'd1) : (c_alusrcb[0] ? w_inst : w_o_b);
    assign w_next_pc = c_pcsource[1] ? (c_pcsource[0] ? `WORD_SIZE'bz : w_rf_data1) : (c_pcsource[0] ? w_o_aluout : w_alu_result);

    //Control module instantiate
    Control control(.clk(clk), .reset_n(reset_n), .opcode(w_inst[15:12]), .function_code(w_inst[5:0]), .Halt(c_halt), .PCSource(c_pcsource), .PCWrite(c_pcwrite), .PCWriteCond(c_pcwritecond), .IorD(c_iord), .MemRead(c_memread), .MemWrite(c_memwrite), .IRWrite(c_irwrite), .RegDst(c_regdst), .MemtoReg(c_memtoreg), .RegWrite(c_regwrite), .ALUSrcA(c_alusrca), .ALUSrcB(c_alusrcb), .ALUOp(c_aluop), .OutWrite(c_outwrite), .num_inst(c_num_inst));
    and a1(c_pc_write_and, w_alu_zero, c_pcwritecond);
    or o1(c_pc_write_or, c_pc_write_and, c_pcwrite);

    //Datapath modules instantiate
    Program_Counter pc(.clk(clk), .reset_n(reset_n), .PCWrite_(c_pc_write_or), .next_pc(w_next_pc), .inst_addr(w_o_pc));
    Instruction_Register ir(.clk(clk), .reset_n(reset_n), .IRWrite(c_irwrite), .mem_data(w_mem_data), .inst(w_inst));
    Memory_Data_Register mdr(.clk(clk), .reset_n(reset_n), .inputReady(inputReady), .IRWrite(c_irwrite), .i_mem_data(w_mem_data), .o_mem_data(w_o_mdr));
    Register_File rf(.clk(clk), .reset_n(reset_n), .RegWrite(c_regwrite), .read_addr1(w_inst[11:10]), .read_addr2(w_inst[9:8]), .write_addr(w_rf_write_addr), .write_data(w_rf_write_data), .read_data1(w_rf_data1), .read_data2(w_rf_data2));
    Buffer a(.clk(clk), .reset_n(reset_n), .i_data(w_rf_data1), .o_data(w_o_a));
    Buffer b(.clk(clk), .reset_n(reset_n), .i_data(w_rf_data2), .o_data(w_o_b));
    ALU alu(.src_a(w_alu_src_a), .src_b(w_alu_src_b), .alucode(c_aluop), .result(w_alu_result), .zero(w_alu_zero));
    Buffer aluout(.clk(clk), .reset_n(reset_n), .i_data(w_alu_result), .o_data(w_o_aluout));
    Out out(.clk(clk), .reset_n(reset_n), .OutWrite(c_outwrite), .i_data(w_rf_data1), .o_data(w_o_out));
endmodule
//////////////////////////////////////////////////////////////////////////