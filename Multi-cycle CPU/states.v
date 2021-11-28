// state encodings for each state: IDLE, IF, ID, EX, MEM, WB
// total 26 different states: 5-bits required

//IDLE, Halt
`define IDLE 6'd0
`define HALT 6'd1
//IF Stage
`define IF 6'd2
//ID Stage
`define ID 6'd3
//EX Stage
`define ADD_EX 6'd4
`define SUB_EX 6'd5
`define AND_EX 6'd6
`define ORR_EX 6'd7
`define NOT_EX 6'd8
`define TCP_EX 6'd9
`define SHL_EX 6'd10
`define SHR_EX 6'd11
`define ADI_EX 6'd12
`define ORI_EX 6'd13
`define LHI_EX 6'd14
`define BNE_EX 6'd15
`define BEQ_EX 6'd16
`define BGZ_EX 6'd17
`define BLZ_EX 6'd18
`define LWD_EX 6'd19
`define SWD_EX 6'd20
//MEM Stage
`define LWD_MEM 6'd21
`define SWD_MEM 6'd22
//WB Stage
`define R_WB 6'd23
`define I_WB 6'd24
`define LWD_WB 6'd25