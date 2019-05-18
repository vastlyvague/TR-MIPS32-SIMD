`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  DIV_32.v
 * Project:    Lab_Assignment_1
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  01/24/2019
 *
 * Purpose: The division module is part of the function select opcode that
 * uses two 32 bit inputs S and T and two 32 bit output. S and T are converted
 * to integer and then the quotient and remainder are calculated using S in
 * the numerator and T in the denominator. Modulus is used to find the remainder.
 * This uses signed integer.
 *          
 * Notes:
 *
 ****************************************************************************/
module DIV_32(S, T, quote, rem);

   input      [31:0] S, T;          //Inputs
   output reg [31:0] quote, rem;    //Outputs Quotient and Remainder
   
   integer           int_S, int_T;
   
   always@(S, T) begin
      int_S = S;                    //Convert to integer
      int_T = T;

      quote = int_S / int_T;        //Lower 32 bit output
      
      rem   = int_S % int_T;        //Upper 32 bit output
      
   end

endmodule
