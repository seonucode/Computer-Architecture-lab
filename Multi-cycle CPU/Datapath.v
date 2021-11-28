///////////////////////////////////////////////////////////////////////////
//Module: Datapath of CPU for TSC microcomputer: Datapath.v
//Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
//Description: Datapath including PC, IR, RF, ALU, buffers, and multiplexors for a microarchitecture design supporting full TSC ISA

//File includes
`include "opcodes.v"    // "opcodes.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions & ALU operations
`include "constants.v"  // "constants.v" consists of "define" statements for constants, such as "WORD_SIZE"

//General Comments on variable names
//"r_" prefix indicates that the variable is a reg type
//without "r_", it's an wire
//"i_" prefix is an indication of an input signal, and "o_" prefix is an indication of an output signal (used only when necessary)
//names in "AaaBbb" format are control signals generated by the control module
//names in "aaaBbb" format are signals to communicate with the memory module (ex, inputReady or readM)
//names in "aaa_bbb" format are data bits
//"clk" signal is a clock signal for synchronization across the whole CPU module
//"reset_n" signal is a negative-edge triggered, asynchronous reset signal, and
//  it usually sets module's internal reg values to zero
/////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Program_Counter(clk, reset_n, PCWrite_, next_pc, inst_addr);
    input clk;
    input reset_n;
    input PCWrite_;
    input [`WORD_SIZE-1:0] next_pc;

    output [`WORD_SIZE-1:0] inst_addr;

    //Internal reg declaration
    reg [`WORD_SIZE-1:0] r_inst_addr;

    //Output port assignment
    assign inst_addr = r_inst_addr;

    //Synchronously write PC (or async. reset)
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            r_inst_addr <= 0;
        end
        else begin
            if (PCWrite_) begin
                r_inst_addr <= next_pc;
            end
        end
    end
endmodule
////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Instruction_Register(clk, reset_n, IRWrite, mem_data, inst);
    input clk;
    input reset_n;
    input IRWrite;
    // input inputReady;
    input [`WORD_SIZE-1:0] mem_data;

    output [`WORD_SIZE-1:0] inst;

    //Internal reg declaration
    reg [`WORD_SIZE-1:0] r_inst;

    //Output port assignment
    assign inst = r_inst;

    //Get data from memory at negedge clk, at half the clock cycle;
    //  using the fact that read delay of memory < half clock cycle
    always @(negedge clk or negedge reset_n) begin
        if (~reset_n) begin
            r_inst <= 0;
        end
        else if (IRWrite) begin
            r_inst <= mem_data;
        end
    end
endmodule
////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Memory_Data_Register(clk, reset_n, inputReady, IRWrite, i_mem_data, o_mem_data);
    input clk;
    input reset_n;
    input inputReady;
    input IRWrite;
    input [`WORD_SIZE-1:0] i_mem_data;

    output [`WORD_SIZE-1:0] o_mem_data;

    //Internal reg declaration
    reg [`WORD_SIZE-1:0] r_mem_data;

    //Output port assignment
    assign o_mem_data = r_mem_data;

    //Get data from memory at negedge clk, at half the clock cycle;
    //  using the fact that write delay of memory < half clock cycle
    always @(negedge clk or negedge reset_n) begin
        if (~reset_n) begin
            r_mem_data <= 0;
        end
        else begin  //no control signal!
            //hold value until next MEM stage
            if (~IRWrite && inputReady) begin
                r_mem_data <= i_mem_data;
                end
        end
    end
endmodule
////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Register_File(clk, reset_n, RegWrite, read_addr1, read_addr2, write_addr, write_data, read_data1, read_data2);
    input clk;
    input reset_n;
    input RegWrite;
    input [1:0] read_addr1;
    input [1:0] read_addr2;
    input [1:0] write_addr;
    input [`WORD_SIZE-1:0] write_data;

    output [`WORD_SIZE-1:0] read_data1;
    output [`WORD_SIZE-1:0] read_data2;

    //Internal reg declaration
    reg [`WORD_SIZE-1:0] register_file [3:0];
    integer i;
    
    //Asynchronous read
    assign read_data1 = register_file[read_addr1];
    assign read_data2 = register_file[read_addr2];

    //Synchronous write (or async. reset)
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                register_file[i] = 0;
            end
        end
        else begin
            if (RegWrite) begin
                register_file[write_addr] = write_data;
            end
        end
     end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Buffer(clk, reset_n, i_data, o_data);
    input clk;
    input reset_n;
    input [`WORD_SIZE-1:0] i_data;
    output [`WORD_SIZE-1:0] o_data;

    //Internal reg declaration
    reg [`WORD_SIZE-1:0] r_data;

    //Output port assignment
    assign o_data = r_data;

    //Synchronous latch (or async. reset)
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            r_data <= 0;
        end
        r_data <= i_data;
    end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module ALU(src_a, src_b, alucode, result, zero);
    input [`WORD_SIZE-1:0] src_a, src_b;
    input [3:0] alucode;
    output [`WORD_SIZE-1:0] result;
    output zero;

    //Internal reg declaration
    reg [`WORD_SIZE-1:0] r_result;
    reg r_zero;

    //Output port assignment
    assign result = r_result;
    assign zero = r_zero;

    //Internal wire declaration & assignment
    wire [15:0] result_add, result_sub, result_and, result_orr, result_not, result_tcp, result_shl, result_shr;
    wire [15:0] result_adi, result_ori, result_lhi, src_b_sign_extend, src_b_zero_extend;
    wire zero_bne, zero_beq, zero_bgz, zero_blz;
    wire [15:0] result_cat_tar, src_a_minus_1;

    assign result_add = src_a + src_b;                              //for inst ADD
    assign result_sub = src_a - src_b;                              //for inst SUB
    assign result_and = src_a & src_b;                              //for inst AND
    assign result_orr = src_a | src_b;                              //for inst ORR
    assign result_not = ~src_a;                                     //for inst NOT
    assign result_tcp = ~src_a + 1;                                 //for inst TCP
    assign result_shl = src_a <<< 1;                                //for inst SHL
    assign result_shr = {src_a[15], src_a[15:1]};                   //for inst SHR

    assign src_b_sign_extend = {{8{src_b[7]}}, src_b[7:0]};
    assign src_b_zero_extend = {8'b0, src_b[7:0]};
    assign result_adi = src_a + src_b_sign_extend;                  //for inst ADI & getting branch address at ID stage
    assign result_ori = src_a | src_b_zero_extend;                  //for inst ORI
    assign result_lhi = src_b_sign_extend << 8;                     //for inst LHI

    assign src_a_minus_1 = src_a - 1;
    
    assign zero_bne = src_a !== src_b;                              //for inst BNE
    assign zero_beq = src_a === src_b;                              //for inst BEQ
    assign zero_bgz = ~src_a_minus_1[15];                           //for inst BGZ
    assign zero_blz = src_a[15];                                    //for inst BLZ

    assign result_cat_tar = {src_a_minus_1[15:12], src_b[11:0]};    //getting Jump target address at ID stage

    //Operation result selection; combinational circuit
    always @(*) begin
        case(alucode)
            `ALUCODE_ADD : begin r_result <= result_add; r_zero <= 0; end
            `ALUCODE_SUB : begin r_result <= result_sub; r_zero <= 0; end
            `ALUCODE_AND : begin r_result <= result_and; r_zero <= 0; end
            `ALUCODE_ORR : begin r_result <= result_orr; r_zero <= 0; end
            `ALUCODE_NOT : begin r_result <= result_not; r_zero <= 0; end
            `ALUCODE_TCP : begin r_result <= result_tcp; r_zero <= 0; end
            `ALUCODE_SHL : begin r_result <= result_shl; r_zero <= 0; end
            `ALUCODE_SHR : begin r_result <= result_shr; r_zero <= 0; end
            `ALUCODE_ADI : begin r_result <= result_adi; r_zero <= 0; end
            `ALUCODE_ORI : begin r_result <= result_ori; r_zero <= 0; end
            `ALUCODE_LHI : begin r_result <= result_lhi; r_zero <= 0; end
            `ALUCODE_BNE : begin r_result <= 16'bz; r_zero <= zero_bne; end
            `ALUCODE_BEQ : begin r_result <= 16'bz; r_zero <= zero_beq; end
            `ALUCODE_BGZ : begin r_result <= 16'bz; r_zero <= zero_bgz; end
            `ALUCODE_BLZ : begin r_result <= 16'bz; r_zero <= zero_blz; end
            `ALUCODE_CAT_TAR: begin r_result <= result_cat_tar; r_zero <= 0; end
        endcase
    end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Out(clk, reset_n, OutWrite, i_data, o_data);
    input clk;
    input reset_n;
    input OutWrite;
    input [`WORD_SIZE-1:0] i_data;

    output [`WORD_SIZE-1:0] o_data;

    assign o_data = OutWrite ? i_data : `WORD_SIZE'bz;
endmodule
//////////////////////////////////////////////////////////////////////////////////////////