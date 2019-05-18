`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  LD_reg32.v
 * Project:    Lab_Assignment_5
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.1
 * Rev. Date:  03/09/2019
 *
 * Purpose: A 32 bit load register that changes output when load or "ld" is
 * asserted, otherwise the output remains the same. 
 *
 * Notes: 
 ****************************************************************************/
module LD_reg32(clk, reset, ld, d, q);

   input             clk, reset, ld;
   input      [31:0] d;
   output reg [31:0] q;

   //Sequential Block. If load is set, output gets input else stays the same
   always@(posedge clk, posedge reset)
      if(reset)    q <= 32'b0;
      else if(ld)  q <= d;
      else         q <= q;

endmodule
