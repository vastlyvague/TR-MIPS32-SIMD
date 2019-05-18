`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MPY_32.v
 * Project:    Lab_Assignment_1
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  01/24/2019
 *
 * Purpose: The multiplication module is part of the function select opcode
 * that uses two 32 bit inputs of S and T data and converts those registers
 * to integer and does the calculation. The output is then 64 bits and then
 * goes back to the ALU_32 and split into half of Y_hi and Y_lo.
 * This uses signed integer.
 *          
 * Notes:
 *
 ****************************************************************************/
module MPY_32(S, T, prdct);

   input      [31:0] S, T;          //Inputs
   output reg [63:0] prdct;         //Output Product
   
   integer           int_S, int_T;
   
   always@(S, T) begin
      int_S = S;                    //Convert to integer
      int_T = T;

      prdct = int_S * int_T;        //Use integers to fill register

   end

endmodule
