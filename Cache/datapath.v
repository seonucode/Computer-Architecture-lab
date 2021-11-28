///////////////////////////////////////////////////////////////////////////
//Module: Datapath for Pipelined TSC microcomputer: Datapath.v
//Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
//Description: Datapath including BTB, RF, instruction counter, and ALU

//Define constant
`define WORD_SIZE 16

//Include file
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions


///////////////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Branch_Target_Buffer(
    input clk,
    input reset_n,
    input BtbWrite,
    input [`WORD_SIZE-1:0] read_addr,
    input [`WORD_SIZE-1:0] write_addr,
    input [`WORD_SIZE-1:0] write_data,

    output [`WORD_SIZE-1:0] read_data
);
    // branch target buffer, total 256 addresses to store for all possible pc in "memory.v"
    reg [`WORD_SIZE-1:0] BTB [255:0];
    integer i;

    assign read_data = BTB[read_addr];

    // synchronous write
    always @(posedge clk) begin
        // INITIAL RESET REQUIRED: reset all entry to "pc+1"
        if (!reset_n) begin
            for (i = 0; i < 256; i = i + 1) begin
                BTB[i] <= i + 1;
            end
        end
        else begin
            if (BtbWrite===1) begin
                BTB[write_addr] <= write_data;
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

    // register file, total 4 addresses
    reg [`WORD_SIZE-1:0] register_file [3:0];
    integer i;

    // asynchronous read
    assign read_data1 = register_file[read_addr1];
    assign read_data2 = register_file[read_addr2];
    
    // synchronous write
    always @(posedge clk) begin
        // reset all values to 0
        if (!reset_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                register_file[i] <= 0;
            end
        end
        else begin
            if (RegWrite===1) begin
                register_file[write_addr] <= write_data;
            end
        end
     end
endmodule
////////////////////////////////////////////////////////////////////
//MODULE DECLARATION
module Instruction_Counter(
    input clk,
    input reset_n,
    input [`WORD_SIZE-1:0] EX_pc_plus_one,

    output [`WORD_SIZE-1:0] num_inst
);
    reg [`WORD_SIZE-1:0] inst_count;
    reg [`WORD_SIZE-1:0] prev_address_plus_one;

    assign num_inst = inst_count;

    
    always @(posedge clk) begin
        if (!reset_n) begin
            inst_count <= 0;
            prev_address_plus_one <= 0;
        end
        else begin
            if (prev_address_plus_one !== EX_pc_plus_one) begin
                prev_address_plus_one <= EX_pc_plus_one;
                inst_count <= inst_count + 1;
            end
        end
    end


endmodule
//////////////////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
module ALU(
    input [`WORD_SIZE-1:0] src_a, 
    input [`WORD_SIZE-1:0] src_b,
    input [3:0] alucode,

    output [`WORD_SIZE-1:0] result
);

    // internal reg for port
    reg [15:0] r_result;
    assign result = r_result;

    // internal signals
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

    // operation result select
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