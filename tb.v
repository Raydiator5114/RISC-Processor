`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.07.2025 12:22:44
// Design Name: 
// Module Name: tb
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

module risc_processor_tb; 
    reg clk; 
    reg reset; 
    wire [31:0] WB_instruction; 
    wire [31:0] WB_result; 
    wire WB_RegWrite; 
    wire [31:0] reg1_value; 
    wire [31:0] reg4_value; 
    wire [31:0] reg6_value; 
    wire [31:0] reg8_value; 
    wire [31:0] reg10_value; 
    wire stall_control; 
    
risc_processor_top dut( 
    .clk(clk), 
    .reset(reset), 
    .WB_instruction(WB_instruction)
    , .WB_result(WB_result), 
    .WB_RegWrite(WB_RegWrite) 
); 

assign reg1_value = dut.reg_file.registers[1]; 
assign reg4_value = dut.reg_file.registers[4]; 
assign reg6_value = dut.reg_file.registers[6]; 
assign reg8_value = dut.reg_file.registers[8]; 
assign reg10_value = dut.reg_file.registers[10]; 
assign stall_control= dut.hazard_unit.stall_control; 

initial begin
    clk = 0; 
    forever #5 clk = ~clk; // 10ns clock period
end 

initial begin 
    reset = 1; 
    #10; reset = 0; 
    #100; 
    $finish; 
end 
endmodule
