`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Instruction_Unit.v
 * Project:    Lab_Assignment_6
 * Designer:   Reed  Ellison
 * Email:      Reed.Ellison@student.csulb.edu
 * Rev. No.:   Version 1.2
 * Rev. Date:  03/19/2019
 *
 * Purpose: Instantiate PC register which holds the current PC value. 
 * The PC value can be incremented or loaded based on its control signals.
 * The PC Output access the Instruction Memory which transfers the selected
 * 32'bit instruction and transfers it to the IR Register. The IR Register
 * value is then output from the Instruction Unit in addition to a sign
 * extended value of the first 16 bits from the IR Output.
 *
 * Notes: 3/17/2019 - PC Mux was added to for PC+4, jumps, and branches
 *
 ****************************************************************************/
module Instruction_Unit(clk, rst, PC_Ld, PC_Inc, IM_Cs, IM_Wr, IM_Rd, IR_Ld,
                        PC_In, PC_Out, IR_Out, SE_16, PC_Sel);
   
   //Clock, reset, PC load, PC Incrementer, Instruction Memory Chip Select
   //Instruction Memory Write Enable, Instruction Memory Read Enable
   //Instruction Register Load
   input         clk, rst, PC_Ld, PC_Inc, IM_Cs, IM_Wr, IM_Rd, IR_Ld;
   
   input   [1:0] PC_Sel;
   
   //32'bit input to PC_Mux to do PC + 4.
   input  [31:0] PC_In;
   
   //Program Counter Output, Instruction Register Output
   //IR Output 16 bits extended to 32 bits
   output [31:0] PC_Out, IR_Out, SE_16;
   
   wire   [31:0] SE_16;
   wire   [31:0] IMEM_Out;
   
   //Output of PC Mux and into PC register
   wire   [31:0] PC_M_Out;
   
   //Program Counter
   PC            pc(.clk(clk),     .rst(rst),     .ld(PC_Ld), 
                    .inc(PC_Inc),  .PC_In(PC_M_Out), .PC_Out(PC_Out));
   
   //Instruction Memory
   Data_Memory IMEM(.clk(clk),     .Addr(PC_Out[11:0]), .D_in(32'h0),
                    .dm_cs(IM_Cs), .dm_wr(IM_Wr),       .dm_rd(IM_Rd),
                    .D_out(IMEM_Out));
   
   //32'bit Loadable Register
   LD_reg32      IR(.clk(clk), .reset(rst), .ld(IR_Ld), .d(IMEM_Out),
                    .q(IR_Out));
   
   //Assign Sign Extended IR Output
   assign SE_16 = {{16{IR_Out[15]}}, IR_Out[15:0]};
   
   //Assign PC Mux output
   //PC+4:   PC_Sel = 0 (default)
   //Jump:   PC_Sel = 1
   //Branch: PC_sel = 2
   //JR:     PC_sel = 3
   assign PC_M_Out = (PC_Sel == 2'b01) ? {PC_Out[31:28], IR_Out[25:0], 2'b00}:
                     (PC_Sel == 2'b10) ? {PC_Out + {SE_16[29:0], 2'b00}}:
                     (PC_Sel == 2'b11) ? PC_In:
                                         PC_Out;
                                         
   
endmodule
