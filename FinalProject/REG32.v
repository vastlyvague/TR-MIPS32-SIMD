`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  REG32.v
 * Project:    Lab_Assignment_4
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  03/01/2019
 *
 * Purpose: A 32 bit register that passes input of D to Q on every active
 * edge of the clock. Used as a pipeline register.
 *
 * Notes: 
 ****************************************************************************/
module REG32(clk, reset, D, Q);

   input             clk, reset;
   input      [31:0] D;
   output reg [31:0] Q;

   //Sequential Block. Output gets input else gets 0 on reset
   always@(posedge clk, posedge reset)
      if(reset)
         Q <= 32'b0;
      else
         Q <= D;

endmodule
