`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.07.2025 11:32:27
// Design Name: 
// Module Name: risc_processor_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
module risc_processor_top(
  input clk,
  input reset,
  output [31:0] WB_instruction,
  output [31:0] WB_result,
  output WB_RegWrite
);
  wire [31:0] pc_current, pc_plus_4;
  wire PCWrite;
  wire [31:0] instruction;
  wire EnIM;
  wire [31:0] ID_pc_plus_4, ID_instruction;
  wire IF_ID_Write;
  wire [3:0] ID_opcode, ID_RegisterRd, ID_RegisterRs, ID_RegisterRt;
  wire [15:0] ID_immediate;
  wire [31:0] ID_read_data1, ID_read_data2;
  wire ALUSrc, MR, MW, MReg, EnRW;
  wire [1:0] ALUOp;
  wire stall_control;

  wire EX_ALUSrc, EX_MR, EX_MW, EX_MReg, EX_EnRW;
  wire [1:0] EX_ALUOp;
  wire [31:0] EX_read_data1, EX_read_data2;
  wire [15:0] EX_immediate;
  wire [3:0] EX_RegisterRs, EX_RegisterRt, EX_RegisterRd;
  wire [31:0] EX_ALU_input1, EX_ALU_input2, EX_ALU_result;
  wire [1:0] ForwardA, ForwardB;
  wire [31:0] EX_ALU_input2_mux;

  wire MEM_MR, MEM_MW, MEM_MReg, MEM_EnRW;
  wire [31:0] MEM_ALU_result, MEM_read_data2;
  wire [3:0] MEM_RegisterRd;
  wire [31:0] MEM_read_data;

  wire WB_MReg, WB_EnRW;
  wire [31:0] WB_read_data, WB_ALU_result;
  wire [3:0] WB_RegisterRd;
  wire [31:0] WB_write_data;

  wire [31:0] EX_instruction;
  wire [31:0] MEM_instruction;
  wire [31:0] WB_instruction_internal;

  assign ID_opcode      = ID_instruction[31:28];
  assign ID_RegisterRd  = ID_instruction[27:24];
  assign ID_RegisterRs  = ID_instruction[23:20];
  assign ID_RegisterRt  = ID_instruction[19:16];
  assign ID_immediate   = ID_instruction[15:0];

  assign WB_instruction = WB_instruction_internal;
  assign WB_result      = WB_write_data;
  assign WB_RegWrite    = WB_EnRW;
  assign pc_plus_4      = pc_current + 4;

  // PC register
  program_counter pc_reg(
    .clk(clk),
    .reset(reset),
    .PCWrite(PCWrite),
    .next_pc(pc_plus_4),
    .pc(pc_current)
  );

  // Instruction memory
  instruction_memory imem(
    .pc(pc_current),
    .EnIM(EnIM),
    .instruction(instruction)
  );

  // IF/ID pipeline register
  IF_ID_register if_id_reg(
    clk,
    reset,
    IF_ID_Write,
    pc_plus_4,
    instruction,
    ID_pc_plus_4,
    ID_instruction
  );

  // Register file
  register_file reg_file(
    .clk(clk),
    .reset(reset),
    .read_reg1(ID_RegisterRs),
    .read_reg2(ID_RegisterRt),
    .write_reg(WB_RegisterRd),
    .write_data(WB_write_data),
    .EnRW(WB_EnRW),
    .read_data1(ID_read_data1),
    .read_data2(ID_read_data2)
  );

  // Control unit
  control_unit ctrl_unit(
    .opcode(ID_opcode),
    .stall_control(stall_control),
    .ALUSrc(ALUSrc),
    .ALUOp(ALUOp),
    .MR(MR),
    .MW(MW),
    .MReg(MReg),
    .EnIM(EnIM),
    .EnRW(EnRW)
  );

  // Hazard detection unit
  hazard_detection_unit hazard_unit(
    .ID_EX_RegisterRt(EX_RegisterRd),
    .ID_EX_MemRead(EX_MR),
    .IF_ID_RegisterRs(ID_RegisterRs),
    .IF_ID_RegisterRt(ID_RegisterRt),
    .PCWrite(PCWrite),
    .IF_ID_Write(IF_ID_Write),
    .stall_control(stall_control)
  );

  // ID/EX pipeline register
  ID_EX_register id_ex_reg(
    .clk(clk),
    .reset(reset),
    .ALUSrc(ALUSrc),
    .MR(MR),
    .MW(MW),
    .MReg(MReg),
    .EnRW(EnRW),
    .ALUOp(ALUOp),
    .ID_read_data1(ID_read_data1),
    .ID_read_data2(ID_read_data2),
    .ID_immediate(ID_immediate),
    .ID_RegisterRs(ID_RegisterRs),
    .ID_RegisterRt(ID_RegisterRt),
    .ID_RegisterRd(ID_RegisterRd),
    .EX_ALUSrc(EX_ALUSrc),
    .EX_MR(EX_MR),
    .EX_MW(EX_MW),
    .EX_MReg(EX_MReg),
    .EX_EnRW(EX_EnRW),
    .EX_ALUOp(EX_ALUOp),
    .EX_read_data1(EX_read_data1),
    .EX_read_data2(EX_read_data2),
    .EX_immediate(EX_immediate),
    .EX_RegisterRs(EX_RegisterRs),
    .EX_RegisterRt(EX_RegisterRt),
    .EX_RegisterRd(EX_RegisterRd),
    .ID_instruction(ID_instruction),
    .EX_instruction(EX_instruction)
  );

  // Forwarding unit
  forwarding_unit forward_unit(
    .ID_EX_RegisterRs(EX_RegisterRs),
    .ID_EX_RegisterRt(EX_RegisterRt),
    .EX_MEM_RegisterRd(MEM_RegisterRd),
    .MEM_WB_RegisterRd(WB_RegisterRd),
    .EX_MEM_RegWrite(MEM_EnRW),
    .MEM_WB_RegWrite(WB_EnRW),
    .ForwardA(ForwardA),
    .ForwardB(ForwardB)
  );

  // Forward mux for ALU input 1
  forward_mux forward_muxA(
    .forward_control(ForwardA),
    .reg_value(EX_read_data1),
    .ex_mem_value(MEM_ALU_result),
    .mem_wb_value(WB_write_data),
    .forward_out(EX_ALU_input1)
  );

  // Forward mux for ALU input 2
  forward_mux forward_muxB(
    .forward_control(ForwardB),
    .reg_value(EX_read_data2),
    .ex_mem_value(MEM_ALU_result),
    .mem_wb_value(WB_write_data),
    .forward_out(EX_ALU_input2_mux)
  );

  // ALU source mux
  alu_src_mux alu_src_mux_inst(
    .ALUSrc(EX_ALUSrc),
    .read_data2(EX_ALU_input2_mux),
    .immediate(EX_immediate),
    .alu_input2(EX_ALU_input2)
  );

  // ALU
  alu alu_inst(
    .a(EX_ALU_input1),
    .b(EX_ALU_input2),
    .ALUOp(EX_ALUOp),
    .result(EX_ALU_result),
    .zero() // Not used in this implementation
  );

  // EX/MEM pipeline register
  EX_MEM_register ex_mem_reg(
    .clk(clk),
    .reset(reset),
    .EX_MR(EX_MR),
    .EX_MW(EX_MW),
    .EX_MReg(EX_MReg),
    .EX_EnRW(EX_EnRW),
    .EX_ALU_result(EX_ALU_result),
    //.EX_read_data2(EX_ALU_input2_mux), // Forward the value for store instructions
    .EX_RegisterRd(EX_RegisterRd),
    .MEM_MR(MEM_MR),
    .MEM_MW(MEM_MW),
    .MEM_MReg(MEM_MReg),
    .MEM_EnRW(MEM_EnRW),
    .MEM_ALU_result(MEM_ALU_result),
    //.MEM_read_data2(MEM_read_data2),
    .MEM_RegisterRd(MEM_RegisterRd),
    .EX_instruction(EX_instruction),
    .MEM_instruction(MEM_instruction),
    .EX_pc(ID_pc_plus_4),       // Using ID_pc_plus_4 as a placeholder
    .MEM_pc()                   // Not used
  );

  // Data memory
  data_memory dmem(
    .clk(clk),
    .address(MEM_ALU_result),
    .write_data(MEM_read_data2),
    .MR(MEM_MR),
    .MW(MEM_MW),
    .read_data(MEM_read_data)
  );

  // MEM/WB pipeline register
  MEM_WB_register mem_wb_reg(
    .clk(clk),
    .reset(reset),
    .MEM_MReg(MEM_MReg),
    .MEM_EnRW(MEM_EnRW),
    .MEM_read_data(MEM_read_data),
    .MEM_ALU_result(MEM_ALU_result),
    .MEM_RegisterRd(MEM_RegisterRd),
    .WB_MReg(WB_MReg),
    .WB_EnRW(WB_EnRW),
    .WB_read_data(WB_read_data),
    .WB_ALU_result(WB_ALU_result),
    .WB_RegisterRd(WB_RegisterRd),
    .MEM_instruction(MEM_instruction),
    .WB_instruction(WB_instruction_internal)
  );

  // Write back mux
  wb_mux wb_mux_inst(
    .MReg(WB_MReg),
    .alu_result(WB_ALU_result),
    .mem_data(WB_read_data),
    .wb_data(WB_write_data)
  );
endmodule

module program_counter(
  input clk,
  input reset,
  input PCWrite,
  input [31:0] next_pc,
  output reg [31:0] pc
);
  always @(posedge clk or posedge reset) begin
    if (reset)
      pc <= 32'b0;
    else if (PCWrite)
      pc <= next_pc;
  end
endmodule

module instruction_memory(
  input [31:0] pc,
  input EnIM,
  output [31:0] instruction
);
  reg [7:0] memory [0:31];

  initial begin
    memory[3]  = 8'b00000001;
    memory[2]  = 8'b00100011;
    memory[1]  = 8'b00000000;
    memory[0]  = 8'b00000000;
    memory[7]  = 8'b00010100;
    memory[6]  = 8'b00010000;
    memory[5]  = 8'b10010000;
    memory[4]  = 8'b00000001;
    memory[11] = 8'b00110110;
    memory[10] = 8'b01010000;
    memory[9]  = 8'b00000000;
    memory[8]  = 8'b00001001;
    memory[15] = 8'b01111000;
    memory[14] = 8'b01100111;
    memory[13] = 8'b00000000;
    memory[12] = 8'b00000000;
    memory[19] = 8'b11111010;
    memory[18] = 8'b10011000;
    memory[17] = 8'b00000000;
    memory[16] = 8'b00000000;
  end

  assign instruction = EnIM ? {memory[pc+3], memory[pc+2], memory[pc+1], memory[pc]} : 32'h0;
endmodule

module register_file(
  input clk,
  input reset,
  input [3:0] read_reg1,
  input [3:0] read_reg2,
  input [3:0] write_reg,
  input [31:0] write_data,
  input EnRW,
  output reg [31:0] read_data1,
  output reg [31:0] read_data2
);
  reg [31:0] registers [0:15];

  initial begin
    registers[0]  = 32'h0;
    registers[2]  = 32'h671EB;
    registers[3]  = 32'h409AF;
    registers[5]  = 32'h7;
    registers[7]  = 32'hF1129;
    registers[9]  = 32'hCAB77;
    registers[1]  = 32'h0;
    registers[4]  = 32'h0;
    registers[6]  = 32'h0;
    registers[8]  = 32'h0;
    registers[10] = 32'h0;
    registers[11] = 32'h0;
    registers[12] = 32'h0;
    registers[13] = 32'h0;
    registers[14] = 32'h0;
    registers[15] = 32'h0;
  end

  always @(posedge clk) begin
    read_data1 = registers[read_reg1];
    read_data2 = registers[read_reg2];
  end

  always @(negedge clk) begin
    if (EnRW && write_reg != 0)
      registers[write_reg] <= write_data;
  end
endmodule

module alu(
  input [31:0] a,
  input [31:0] b,
  input [1:0] ALUOp,
  output reg [31:0] result,
  output zero
);
  always @(*) begin
    case (ALUOp)
      2'b00: result = a + b;           // ADD or LW
      2'b01: result = (a < b) ? 32'h1 : 32'h0;  // SLTI
      2'b10: result = ~(a & b);        // NAND
      2'b11: result = a - b;           // SUB
      default: result = 32'h0;
    endcase
  end

  assign zero = (result == 32'h0);
endmodule

module data_memory(
  input clk,
  input [31:0] address,
  input [31:0] write_data,
  input MR,
  input MW,
  output [31:0] read_data
);
  reg [31:0] memory [0:23];

  initial begin
    memory[4] = 32'ha;
  end

  assign read_data = MR ? memory[address[9:2]] : 32'h0;
endmodule

module control_unit(
  input [3:0] opcode,
  input stall_control,
  output reg ALUSrc,
  output reg [1:0] ALUOp,
  output reg MR,
  output reg MW,
  output reg MReg,
  output reg EnIM,
  output reg EnRW
);
  always @(*) begin
    if (stall_control) begin
      ALUSrc = 1'b0;
      ALUOp  = 2'b00;
      MR     = 1'b0;
      MW     = 1'b0;
      MReg   = 1'b0;
      EnIM   = 1'b0;
      EnRW   = 1'b0;
    end else begin
      ALUSrc = 1'b0;
      ALUOp  = 2'b00;
      MR     = 1'b0;
      MW     = 1'b0;
      MReg   = 1'b0;
      EnIM   = 1'b1;
      EnRW   = 1'b1;
      case (opcode)
        4'b0000: begin // ADD
          ALUSrc = 1'b0;
          ALUOp  = 2'b00;
          EnRW   = 1'b1;
        end
        4'b0001: begin // SLTI
          ALUSrc = 1'b1;
          ALUOp  = 2'b01;
          EnRW   = 1'b1;
        end
        4'b0011: begin // LW
          ALUSrc = 1'b1;
          ALUOp  = 2'b00;
          MR     = 1'b1;
          MReg   = 1'b1;
          EnRW   = 1'b1;
        end
        4'b0111: begin // NAND
          ALUSrc = 1'b0;
          ALUOp  = 2'b10;
          EnRW   = 1'b1;
        end
        4'b1111: begin // SUB
          ALUSrc = 1'b0;
          ALUOp  = 2'b11;
          EnRW   = 1'b1;
        end
        default: begin
          ALUSrc = 1'b0;
          ALUOp  = 2'b00;
          MR     = 1'b0;
          MW     = 1'b0;
          MReg   = 1'b0;
          EnIM   = 1'b1;
          EnRW   = 1'b0;
        end
      endcase
    end
  end
endmodule

module hazard_detection_unit(
  input [3:0] ID_EX_RegisterRt,
  input ID_EX_MemRead,
  input [3:0] IF_ID_RegisterRs,
  input [3:0] IF_ID_RegisterRt,
  output reg PCWrite,
  output reg IF_ID_Write,
  output reg stall_control
);
  always @(*) begin
    PCWrite       = 1'b1;
    IF_ID_Write   = 1'b1;
    stall_control = 1'b0;
    if (ID_EX_MemRead &&
       ((ID_EX_RegisterRt == IF_ID_RegisterRs) ||
        (ID_EX_RegisterRt == IF_ID_RegisterRt))) begin
      PCWrite     = 1'b0;
      IF_ID_Write = 1'b0;
      stall_control = 1'b1;
    end
  end
endmodule

module forwarding_unit(
  input [3:0] ID_EX_RegisterRs,
  input [3:0] ID_EX_RegisterRt,
  input [3:0] EX_MEM_RegisterRd,
  input [3:0] MEM_WB_RegisterRd,
  input EX_MEM_RegWrite,
  input MEM_WB_RegWrite,
  output reg [1:0] ForwardA,
  output reg [1:0] ForwardB
);
  always @(*) begin
    ForwardA = 2'b00;
    ForwardB = 2'b00;
    // EX hazard
    if (EX_MEM_RegWrite &&
       (EX_MEM_RegisterRd != 4'b0) &&
       (EX_MEM_RegisterRd == ID_EX_RegisterRs))
      ForwardA = 2'b10;
    if (EX_MEM_RegWrite &&
       (EX_MEM_RegisterRd != 4'b0) &&
       (EX_MEM_RegisterRd == ID_EX_RegisterRt))
      ForwardB = 2'b10;
    // MEM hazard
    if (MEM_WB_RegWrite &&
       (MEM_WB_RegisterRd != 4'b0) &&
       !(EX_MEM_RegWrite && (EX_MEM_RegisterRd != 4'b0) &&
         (EX_MEM_RegisterRd == ID_EX_RegisterRs)) &&
       (MEM_WB_RegisterRd == ID_EX_RegisterRs))
      ForwardA = 2'b01;
    if (MEM_WB_RegWrite &&
       (MEM_WB_RegisterRd != 4'b0) &&
       !(EX_MEM_RegWrite && (EX_MEM_RegisterRd != 4'b0) &&
         (EX_MEM_RegisterRd == ID_EX_RegisterRt)) &&
       (MEM_WB_RegisterRd == ID_EX_RegisterRt))
      ForwardB = 2'b01;
  end
endmodule

module IF_ID_register(
  input clk,
  input reset,
  input IF_ID_Write,
  input [31:0] pc_plus_4,
  input [31:0] instruction,
  output reg [31:0] ID_pc_plus_4,
  output reg [31:0] ID_instruction
);
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      ID_pc_plus_4 <= 32'b0;
      ID_instruction <= 32'b0;
    end else if (IF_ID_Write) begin
      ID_pc_plus_4 <= pc_plus_4;
      ID_instruction <= instruction;
    end
  end
endmodule

module ID_EX_register(
  input clk,
  input reset,
  input ALUSrc,
  input MR,
  input MW,
  input MReg,
  input EnRW,
  input [1:0] ALUOp,
  input [31:0] ID_read_data1,
  input [31:0] ID_read_data2,
  input [15:0] ID_immediate,
  input [3:0] ID_RegisterRs,
  input [3:0] ID_RegisterRt,
  input [3:0] ID_RegisterRd,
  input [31:0] ID_instruction,
  output reg EX_ALUSrc,
  output reg EX_MR,
  output reg EX_MW,
  output reg EX_MReg,
  output reg EX_EnRW,
  output reg [1:0] EX_ALUOp,
  output reg [31:0] EX_read_data1,
  output reg [31:0] EX_read_data2,
  output reg [15:0] EX_immediate,
  output reg [3:0] EX_RegisterRs,
  output reg [3:0] EX_RegisterRt,
  output reg [3:0] EX_RegisterRd,
  output reg [31:0] EX_instruction
);
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      EX_ALUSrc      <= 1'b0;
      EX_MR          <= 1'b0;
      EX_MW          <= 1'b0;
      EX_MReg        <= 1'b0;
      EX_EnRW        <= 1'b0;
      EX_ALUOp       <= 2'b0;
      EX_read_data1  <= 32'b0;
      EX_read_data2  <= 32'b0;
      EX_immediate   <= 16'b0;
      EX_RegisterRs  <= 4'b0;
      EX_RegisterRt  <= 4'b0;
      EX_RegisterRd  <= 4'b0;
      EX_instruction <= 32'b0;
    end else begin
      EX_ALUSrc      <= ALUSrc;
      EX_MR          <= MR;
      EX_MW          <= MW;
      EX_MReg        <= MReg;
      EX_EnRW        <= EnRW;
      EX_ALUOp       <= ALUOp;
      EX_read_data1  <= ID_read_data1;
      EX_read_data2  <= ID_read_data2;
      EX_immediate   <= ID_immediate;
      EX_RegisterRs  <= ID_RegisterRs;
      EX_RegisterRt  <= ID_RegisterRt;
      EX_RegisterRd  <= ID_RegisterRd;
      EX_instruction <= ID_instruction;
    end
  end
endmodule

module EX_MEM_register(
  input clk,
  input reset,
  // Control signals
  input EX_MR,
  input EX_MW,
  input EX_MReg,
  input EX_EnRW,
  // Data input
  input [31:0] EX_ALU_result,
  //input [31:0] EX_read_data2, //for SW instructions
  input [3:0] EX_RegisterRd,
  // Outputs - Control signals
  output reg MEM_MR,
  output reg MEM_MW,
  output reg MEM_MReg,
  output reg MEM_EnRW,
  // Outputs - Data
  output reg [31:0] MEM_ALU_result,
  //output reg [31:0] MEM_read_data2,
  output reg [3:0] MEM_RegisterRd,
  input [31:0] EX_pc,
  input [31:0] EX_instruction,
  output reg [31:0] MEM_pc,
  output reg [31:0] MEM_instruction
);
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Reset control signals
      MEM_MR <= 1'b0;
      MEM_MW <= 1'b0;
      MEM_MReg <= 1'b0;
      MEM_EnRW <= 1'b0;
      // Reset data
      MEM_ALU_result <= 32'b0;
      //MEM_read_data2 <= 32'b0;
      MEM_RegisterRd <= 4'b0;
      MEM_pc <= 32'b0;
      MEM_instruction <= 32'b0;
    end else begin
      // Pass control signals
      MEM_MR <= EX_MR;
      MEM_MW <= EX_MW;
      MEM_MReg <= EX_MReg;
      MEM_EnRW <= EX_EnRW;
      // Pass data
      MEM_ALU_result <= EX_ALU_result;
      //MEM_read_data2 <= EX_read_data2;
      MEM_RegisterRd <= EX_RegisterRd;
      MEM_pc <= EX_pc;
      MEM_instruction <= EX_instruction;
    end
  end
endmodule

module MEM_WB_register(
  input clk,
  input reset,
  // Control signals
  input MEM_MReg,
  input MEM_EnRW,
  // Data input
  input [31:0] MEM_read_data,
  input [31:0] MEM_ALU_result,
  input [3:0] MEM_RegisterRd,
  input [31:0] MEM_instruction,
  // Outputs - Control signals
  output reg WB_MReg,
  output reg WB_EnRW,
  // Outputs - Data
  output reg [31:0] WB_read_data,
  output reg [31:0] WB_ALU_result,
  output reg [3:0] WB_RegisterRd,
  output reg [31:0] WB_instruction
);
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Reset control signals
      WB_MReg <= 1'b0;
      WB_EnRW <= 1'b0;
      // Reset data
      WB_read_data <= 32'b0;
      WB_ALU_result <= 32'b0;
      WB_RegisterRd <= 4'b0;
      WB_instruction <= 32'b0;
    end else begin
      // Pass control signals
      WB_MReg <= MEM_MReg;
      WB_EnRW <= MEM_EnRW;
      // Pass data
      WB_read_data <= MEM_read_data;
      WB_ALU_result <= MEM_ALU_result;
      WB_RegisterRd <= MEM_RegisterRd;
      WB_instruction <= MEM_instruction;
    end
  end
endmodule

module alu_src_mux(
  input ALUSrc,
  input [31:0] read_data2,
  input [15:0] immediate,
  output [31:0] alu_input2
);
  // Sign-extend the immediate value
  wire [31:0] sign_extended_imm = {{16{immediate[15]}}, immediate};
  assign alu_input2 = ALUSrc ? sign_extended_imm : read_data2;
endmodule

module forward_mux(
  input [1:0] forward_control,
  input [31:0] reg_value,
  input [31:0] ex_mem_value,
  input [31:0] mem_wb_value,
  output [31:0] forward_out
);
  assign forward_out = (forward_control == 2'b00) ? reg_value :
                       (forward_control == 2'b01) ? mem_wb_value :
                       (forward_control == 2'b10) ? ex_mem_value :
                       reg_value;
endmodule

// Write back multiplexer
module wb_mux(
  input MReg,
  input [31:0] alu_result,
  input [31:0] mem_data,
  output [31:0] wb_data
);
  assign wb_data = MReg ? mem_data : alu_result;
endmodule
