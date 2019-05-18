`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  PC.v
 * Project:    Lab_Assignment_5
 * Designer:   Reed Ellison
 * Email:      Reed.Ellison@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  03/09/2019
 *
 * Purpose: 32'bit Register which holds the value of the Program Counter
 * This register can be incremented by four or can be set to a 32'bit input.
 *
 * Notes: 
 *
 ****************************************************************************/
module PC(clk,rst,ld,inc,PC_In,PC_Out);
   
   //Clock, reset, load signal to load PC_In to Register value
   //Increment PC which is by 4 as memory word is 4 bytes
   input clk,rst,ld,inc;
   
   //32'bit input value that can be set as PC value
   input [31:0] PC_In;
   
   //Output of PC Register
   output reg [31:0] PC_Out;
   
   //Procedural Block 
   always @(posedge clk, posedge rst)
      begin
         if(rst) //Output is all zeroes
            PC_Out <= 32'b0;
         //When load is asserted, set input PC value as register value
         else if({ld,inc} == 2'b10)
            PC_Out <= PC_In;
         //When increment is asserted, Increment current PC value by 4
         else if({ld,inc} == 2'b01)
            PC_Out <= PC_Out + 4'h4;
         else
         //Keep PC value as the same
            PC_Out <= PC_Out;
      end
         
endmodule
