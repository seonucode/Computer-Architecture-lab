`timescale 1ns/1ns
///////////////////////////////////////////////////////////////////////////
//Module: Separate Cache modules for a pipelined TSC microcomputer; CPU.v
//Author: Seonu Kim (kadash.sean_kim@snu.ac.kr)
//Description: cache module

//Define constants
`define WORD_SIZE 16    // data and address word size

//File includes
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions

///////////////////////////////////////////////////////////////////////////
//Module declaration
module Cache (
    input clk,
    input reset_n,

    // cpu interface
    input readM_cpu,
    input writeM_cpu,
    input [`WORD_SIZE-1:0] address_cpu,
    inout [`WORD_SIZE-1:0] data_cpu,
    output miss,

    // memory interface
    inout [4*`WORD_SIZE-1:0] data_mem,
    output [`WORD_SIZE-1:0] address_mem,
    output readM_mem,
    output writeM_mem
);

    // internal reg for ports
    reg hit;
    reg r_readM_mem;
    reg r_writeM_mem;
    reg [`WORD_SIZE-1:0] r_outputData_cpu;
    reg [4*`WORD_SIZE-1:0] r_outputData_mem;
    reg [`WORD_SIZE-1:0] r_address_mem;
    
    assign data_cpu = readM_cpu ? r_outputData_cpu : `WORD_SIZE'bz;
    assign miss = !hit;

    assign data_mem = r_writeM_mem ? r_outputData_mem : `WORD_SIZE'bz;
    assign address_mem = r_address_mem;
    assign readM_mem = r_readM_mem;
    assign writeM_mem = r_writeM_mem;
    
    // internal reg to count memory latency
    reg [2:0] memory_latency_count;

    // tag, data bank. total 4-lines each
    reg [12:0] tag_bank [3:0];                // 12-bit tag, 1-bit valid
    reg [4*`WORD_SIZE-1:0] data_bank [3:0];   // 4-words per line
    integer line;

    // internal wires
    wire [11:0] w_tag;
    wire [1:0] w_idx;
    wire [1:0] w_bo;
    assign w_tag = address_cpu[15:4];
    assign w_idx = address_cpu[3:2];
    assign w_bo = address_cpu[1:0];


    always @(posedge clk) begin
        if (!reset_n) begin
            for (line = 0; line <= 3; line = line + 1) begin
                // reset all valid bits to 0
                tag_bank[line][0] <= 0;
            end
            // reset hit to 1, for initial non-stall
            hit <= 1;
            // reset latency count to 0
            memory_latency_count <= 0;
        end

        else begin
            // Read
            if (readM_cpu === 1) begin
                // hit
                if ((tag_bank[w_idx][12:1] === w_tag) && tag_bank[w_idx][0] === 1) begin
                    hit <= 1;
                    case (w_bo)
                        0: r_outputData_cpu <= data_bank[w_idx][`WORD_SIZE-1:0];
                        1: r_outputData_cpu <= data_bank[w_idx][2*`WORD_SIZE-1:`WORD_SIZE];
                        2: r_outputData_cpu <= data_bank[w_idx][3*`WORD_SIZE-1:2*`WORD_SIZE];
                        3: r_outputData_cpu <= data_bank[w_idx][4*`WORD_SIZE-1:3*`WORD_SIZE];
                    endcase
                    memory_latency_count <= 0;
                end

                // miss
                else begin
                    hit <= 0;
                    r_outputData_cpu <= `WORD_SIZE'bx;
                    r_readM_mem <= 1;
                    r_address_mem <= {address_cpu[`WORD_SIZE-1:2], 2'b00};
                    
                    // memory access takes 4 cycles
                    if (memory_latency_count === 3'd4) begin
                        // fetch 4 words from memory and write to data bank
                        data_bank[w_idx] <= data_mem;
                        // write to tag bank
                        tag_bank[w_idx][12:1] <= w_tag;
                        tag_bank[w_idx][0] <= 1;
                        memory_latency_count <= 0;
                    end
                    else begin
                        memory_latency_count <= memory_latency_count + 1;
                    end
                end
            end
            
            // Write (not at same cycle as read)
            else if (writeM_cpu === 1) begin
                // hit
                if ((tag_bank[w_idx][12:1] === w_tag) && tag_bank[w_idx][0] === 1) begin
                    hit <= 1;
                    // write to memory & cache
                    if (memory_latency_count === 3'd4) begin
                        r_writeM_mem <= 1;
                        case(w_bo)
                            0: begin r_outputData_mem <= {data_bank[w_idx][4*`WORD_SIZE-1:`WORD_SIZE], data_cpu};
                                     data_bank[w_idx][w_bo] <= data_cpu; end
                            1: begin r_outputData_mem <= {data_bank[w_idx][4*`WORD_SIZE-1:2*`WORD_SIZE], data_cpu, data_bank[w_idx][`WORD_SIZE-1:0]};
                                     data_bank[w_idx][w_bo] <= data_cpu; end
                            2: begin r_outputData_mem <= {data_bank[w_idx][4*`WORD_SIZE-1:3*`WORD_SIZE], data_cpu, data_bank[w_idx][2*`WORD_SIZE-1:0]};
                                     data_bank[w_idx][w_bo] <= data_cpu; end
                            3: begin r_outputData_mem <= {data_cpu, data_bank[w_idx][3*`WORD_SIZE-1:0]};
                                     data_bank[w_idx][w_bo] <= data_cpu; end
                        endcase
                        memory_latency_count <= 0;
                    end
                    else begin
                        memory_latency_count <= memory_latency_count + 1;
                    end
                end

                //miss
                else begin
                    hit <= 0;
                    // write to memory
                    if (memory_latency_count === 3'd5) begin
                        hit <= 1;
                        r_writeM_mem <= 1;
                        case(w_bo)
                            0: begin r_outputData_mem <= {data_bank[w_idx][4*`WORD_SIZE-1:`WORD_SIZE], data_cpu}; end
                            1: begin r_outputData_mem <= {data_bank[w_idx][4*`WORD_SIZE-1:2*`WORD_SIZE], data_cpu, data_bank[w_idx][`WORD_SIZE-1:0]}; end
                            2: begin r_outputData_mem <= {data_bank[w_idx][4*`WORD_SIZE-1:3*`WORD_SIZE], data_cpu, data_bank[w_idx][2*`WORD_SIZE-1:0]}; end
                            3: begin r_outputData_mem <= {data_cpu, data_bank[w_idx][3*`WORD_SIZE-1:0]}; end
                        endcase
                        memory_latency_count <= 0;
                    end
                    else begin
                        memory_latency_count <= memory_latency_count + 1;
                    end
                end
            end
        end
    end

endmodule