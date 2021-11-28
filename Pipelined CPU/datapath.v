///////////////////////////////////////////////////////////////////////////
//Module: Datapath for Pipelined TSC microcomputer: Datapath.v
//Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
//Description: Datapath including ...

//Define constant
`define WORD_SIZE 16

//File includes
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions


///////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module Branch_Target_Buffer(
    input clk,
    input reset_n,
    input BtbWrite,
    input [`WORD_SIZE-1:0] read_addr,
    input [`WORD_SIZE-1:0] write_addr,
    input [`WORD_SIZE-1:0] write_data,

    output [`WORD_SIZE-1:0] read_data
);
    //Internal reg variable declaration
    reg [`WORD_SIZE-1:0] r_BTB [255:0];
    integer i;

    assign read_data = r_BTB[read_addr];

    //Synchronous write, read, reset
    always @(posedge clk) begin
        if (!reset_n) begin //INITIAL RESET REQUIRED      
            for (i = 0; i < 256; i = i + 1) begin
                r_BTB[i] <= i + 1;
            end
        end
        else begin
            if (BtbWrite) begin
                r_BTB[write_addr] <= write_data;
            end
        end
    end
endmodule
////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Register_File(
    input clk,
    input reset_n,
    input RegWrite,

    input [1:0] read_addr1,
    input [1:0] read_addr2,
    input [1:0] write_addr,
    input [`WORD_SIZE-1:0] write_data,

    output [`WORD_SIZE-1:0] read_data1,
    output [`WORD_SIZE-1:0] read_data2
);

    //Internal reg declaration
    reg [`WORD_SIZE-1:0] r_register_file [3:0];
    integer i;

    //Port signal assignment
    //Async.read
    assign read_data1 = r_register_file[read_addr1];
    assign read_data2 = r_register_file[read_addr2];
    
    //Synchronous write, reset
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                r_register_file[i] <= 0;
            end
        end
        else begin
            if (RegWrite) begin
                r_register_file[write_addr] <= write_data;
            end
        end
     end
endmodule
////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Instruction_Counter(
    input clk,
    input reset_n,
    input Stall,
    input Flush,
    input Halt,

    output [`WORD_SIZE-1:0] num_inst
);

    //Internal reg declaration
    reg [`WORD_SIZE-1:0] r_inst_count;
    reg r_first_flag;
    reg [1:0] r_consecutive_stall_or_flush;
    //Output port assignment
    assign num_inst = (r_consecutive_stall_or_flush!==2'b0) ? `WORD_SIZE'bz : r_inst_count;

    //Synchronous increment, reset
    always @(posedge clk) begin
        //INITIAL RESET REQUIRED
        if (!reset_n) begin
            r_inst_count <= 0;
            r_first_flag <= 1;
            r_consecutive_stall_or_flush <= 0;
        end
        else begin
            if (Stall || Flush) begin
                r_consecutive_stall_or_flush <= r_consecutive_stall_or_flush + 1;
            end
            else begin
                r_consecutive_stall_or_flush <= 0;
            end
            if (r_first_flag) begin
                r_first_flag <= 0;
            end
            else begin
                if (!Stall && !Flush && !Halt) begin
                    r_inst_count <= r_inst_count + 1;
                end
            end
        end
     end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module ALU(src_a, src_b, alucode, result);
    input [15:0] src_a, src_b;
    input [3:0] alucode;
    output [15:0] result;

    //Internal reg declaration
    reg [15:0] r_result;
    //Output signal assignment
    assign result = r_result;

    //Internal wire declaration & assignment
    wire [15:0] result_add, result_sub, result_and, result_orr, result_not, result_tcp, result_shl, result_shr, result_ori, result_lhi;

    assign result_add = src_a + src_b;                              //for inst ADD, ADI
    assign result_sub = src_a - src_b;                              //for inst SUB
    assign result_and = src_a & src_b;                              //for inst AND
    assign result_orr = src_a | src_b;                              //for inst ORR
    assign result_not = ~src_a;                                     //for inst NOT
    assign result_tcp = ~src_a + 1;                                 //for inst TCP
    assign result_shl = src_a <<< 1;                                //for inst SHL
    assign result_shr = {src_a[15], src_a[15:1]};                   //for inst SHR
    assign result_ori = src_a | {8'b0, src_b[7:0]};                 //for inst ORI (src_b = sign-extended immediate)
    assign result_lhi = src_b << 8;                                 //for inst LHI

    //Operation result selection; combinational circuit
    always @(*) begin
        case(alucode)
            `ALUCODE_ADD : begin r_result <= result_add; end
            `ALUCODE_SUB : begin r_result <= result_sub; end
            `ALUCODE_AND : begin r_result <= result_and; end
            `ALUCODE_ORR : begin r_result <= result_orr; end
            `ALUCODE_NOT : begin r_result <= result_not; end
            `ALUCODE_TCP : begin r_result <= result_tcp; end
            `ALUCODE_SHL : begin r_result <= result_shl; end
            `ALUCODE_SHR : begin r_result <= result_shr; end
            `ALUCODE_ORI : begin r_result <= result_ori; end
            `ALUCODE_LHI : begin r_result <= result_lhi; end
            default: begin r_result <= 16'bz; end
        endcase
    end
endmodule