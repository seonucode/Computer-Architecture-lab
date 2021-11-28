// operation codes for each instruction
`define OPCODE_R 4'd15
`define OPCODE_ADI 4'd4
`define OPCODE_ORI 4'd5
`define OPCODE_LHI 4'd6
`define OPCODE_LWD 4'd7
`define OPCODE_SWD 4'd8
`define OPCODE_BNE 4'd0
`define OPCODE_BEQ 4'd1
`define OPCODE_BGZ 4'd2
`define OPCODE_BLZ 4'd3
`define OPCODE_JMP 4'd9
`define OPCODE_JAL 4'd10


// function codes for R-type instructions
`define FUNC_ADD 6'd0
`define FUNC_SUB 6'd1
`define FUNC_AND 6'd2
`define FUNC_ORR 6'd3
`define FUNC_NOT 6'd4
`define FUNC_TCP 6'd5
`define FUNC_SHL 6'd6
`define FUNC_SHR 6'd7
`define FUNC_WWD 6'd28
`define FUNC_JPR 6'd25
`define FUNC_JRL 6'd26
`define FUNC_HLT 6'd29

// ALU operation codes for each operation
`define ALUCODE_ADD 4'd0
`define ALUCODE_SUB 4'd1
`define ALUCODE_AND 4'd2
`define ALUCODE_ORR  4'd3
`define ALUCODE_NOT 4'd4
`define ALUCODE_TCP 4'd5
`define ALUCODE_SHL 4'd6
`define ALUCODE_SHR 4'd7
`define ALUCODE_ADI 4'd8
`define ALUCODE_ORI 4'd9
`define ALUCODE_LHI 4'd10
`define ALUCODE_BNE 4'd11
`define ALUCODE_BEQ 4'd12
`define ALUCODE_BGZ 4'd13
`define ALUCODE_BLZ 4'd14
`define ALUCODE_CAT_TAR 4'd15