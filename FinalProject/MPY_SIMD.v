`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MPY_SIMD.v
 * Project:    SIMD MIPS
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  01/24/2019
 *
 * Purpose: The multiplication module is part of the function select opcode
 * that uses two 32 bit inputs of S and T data and converts those registers
 * to integer and does the calculation. The SIMD version allows to select
 * 4 16 or 2 32 bits of output to a 64 bit register.
 *          
 * Notes:
 *
 ****************************************************************************/
module MPY_SIMD(simd_sel, S, T, prdct);
   input       [1:0] simd_sel;      //SIMD mode selector
   input      [31:0] S, T;          //Inputs
   output reg [63:0] prdct;         //Output Product
   
   integer           int_S, int_T;
   parameter simd8 = 2'b01, simd16 = 2'b10;  
   always@(S, T) begin
      int_S = S;                    //Convert to integer
      int_T = T;
      case(simd_sel)
         simd8: begin
            prdct[15:0] = int_S[7:0] * int_T[7:0];
            prdct[31:16] = int_S[15:8] * int_T[15:8];
            prdct[47:32] = int_S[23:16] * int_T[23:16];
            prdct[63:48] = int_S[31:24] * int_T[31:24];
         end
         simd16: begin
            prdct[31:0] = int_S[15:0] * int_T[15:0];
            prdct[63:32] = int_S[31:16] * int_T[31:16];
         end
         default:
            prdct = int_S * int_T;
      endcase
   end

endmodule
