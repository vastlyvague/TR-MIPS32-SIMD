`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  regfile32.v
 * Project:    Lab_Assignment_4
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  02/07/2019
 *
 * Purpose: This is a 32 x 32 dual port register. It contains general registers
 * and address registers used to support addressing modes. These registers are
 * for the MIPS processor use. This uses a write enable called "D_En" that allows 
 * for the registers to be written to and sets the register to the value on the
 * 32-bit D data input. It contains outputs S and T that take their -bit hex
 * values from specific registers depending on their correlating S_Addr and T_Addr
 * values. They are asynchronous outputs from the register.
 * $r0 is always to have the value 0 and cannot be written to because it is
 * a "Read Only Register".
 *
 * Notes: Registers are referred to as $rX where X is a number between 0 - 31 in
 * this document.
 ****************************************************************************/
module regfile32(clk, reset, D_En, D_Addr, S_Addr, T_Addr, D, S, T);

   input         clk, reset, D_En;       //clk, reset and write enable
   input   [4:0] D_Addr, S_Addr, T_Addr; //read address and write addresses
   input  [31:0] D;                      //value to write to
   output [31:0] S, T;                   //outputs to ALU_32

   //32x32 Register from $r0 to $r31
   reg    [31:0] RegFile [31:0];

   //Assign Outputs to equal register at specific addresses
   assign S = RegFile[S_Addr];
   assign T = RegFile[T_Addr];

   always@(posedge clk, posedge reset)
      if(reset)
         RegFile[0] <= 32'h0;         //$r0 should always be 0
      else if(D_En && D_Addr != 5'h0) //Checks to make write enable is on and not $r0
         RegFile[D_Addr] <= D;        //Writes to register
      else
         RegFile[D_Addr] <= RegFile[D_Addr];

endmodule
