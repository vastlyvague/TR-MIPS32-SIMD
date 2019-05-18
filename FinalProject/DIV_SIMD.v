`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  DIV_SIMD.v
 * Project:    SIMD MIPS
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  04/18/2019
 *
 * Purpose: The division module is part of the function select opcode that
 * uses two 32 bit inputs S and T and two 32 bit output. The SIMD version
 * allows the output to be a vector of multiple data. The SIMD select let's
 * the user choose between 8, 16 or the normal 32 bits. Quotient is loaded
 * into one register and remainder another.
 *          
 * Notes:
 *
 ****************************************************************************/
module DIV_SIMD(simd_sel, S, T, quote, rem);
   input       [1:0] simd_sel;      //SIMD mode select
   input      [31:0] S, T;          //Inputs
   output reg [31:0] quote, rem;    //Outputs Quotient and Remainder
   
   integer           int_S, int_T;
   
   parameter simd8 = 2'b01, simd16 = 2'b10;
   
   always@(S, T, simd_sel) begin
      int_S = S;                    //Convert to integer
      int_T = T;
      case(simd_sel)
         simd8: begin
            quote[7:0] = int_S[7:0] / int_T[7:0];
            quote[15:8] = int_S[15:8] / int_T[15:8];
            quote[23:16] = int_S[23:16] / int_T[23:16];
            quote[31:24] = int_S[31:24] / int_T[31:24];
            rem[7:0] = int_S[7:0] % int_T[7:0];
            rem[15:8] = int_S[15:8] % int_T[15:8];
            rem[23:16] = int_S[23:16] % int_T[23:16];
            rem[31:24] = int_S[31:24] % int_T[31:24];
         end
         simd16: begin
            quote[15:0] = int_S[15:0] / int_T[15:0];
            quote[31:16] = int_S[31:16] / int_T[31:16];
            rem[15:0] = int_S[15:0] % int_T[15:0];
            rem[31:16] = int_S[31:16] % int_T[31:16];
         end
         default: begin
            quote = int_S / int_T;
            rem = int_S % int_T;
         end
   endcase
   end

endmodule
