`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  V_ALU.v
 * Project:    SIMD MIPS32
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  04/18/2019
 *
 * Purpose: An SIMD arithmetic logical unit that does behavioral operations based
 * on a 5 bit function select (FS) opcode. It takes in two 32 bit inputs of (S)
 * data and (T) data and uses those in a specified operation to output different
 * types of data. It can output 16-bits or 8-bits. This runs in parallel with
 * the standard ALU_32. This runs in parallel with the normal ALU. Status flags
 * are not used except for zero flag.
 * 
 * Notes:
 * 
 ****************************************************************************/
module V_ALU(simd_sel, S, T, FS, shamt, z, y_hi, y_lo);
   input  [31:0] S, T;        //Inputs
   input   [1:0] simd_sel;    //SIMD mode sel
   input   [4:0] FS, shamt;   //Function Select
   output [31:0] y_hi, y_lo;  //Outputs
   
   //Status Flag bits carry, overflow, negative and zero
   output        z;

   wire   [63:0] prdct;
   wire   [31:0] quote, rem, Y;
   wire   [31:0] T_shift;

   //Instantiate SIMD versions of the MPY_32, DIV_32 and MIPS_32 modules for
   //Vector ALU
   MPY_SIMD  uut0(.simd_sel(simd_sel), .S(S), .T(T), .prdct(prdct));
   DIV_SIMD  uut1(.simd_sel(simd_sel), .S(S), .T(T), .quote(quote), .rem(rem));
   MIPS_SIMD uut2(.SIMD_Sel(simd_sel), .S(S), .T(T), .FS(FS),       .Y(Y));
   
   BarrelShift_SIMD BS(.simd_sel(simd_sel), .D(T), .type(FS), 
                       .shamt(shamt),       .Out(T_shift));
   
   assign {y_hi, y_lo} = (FS == 5'h1e)         ? {prdct[63:32], //MULT upper 32 bit
                                                  prdct[31:0]}: //MULT lower 32 bit
                         (FS == 5'h1f)         ? {rem, quote} : //DIV
                         (FS == 5'h0C || FS == 5'h0E ||
                          FS == 5'h0D || FS == 5'h1A ||
                          FS == 5'h1B)         ? {31'h0, T_shift}://Shift
                                                 {31'h0, Y}   ; //MIPS ops
   
   //Set zero flag. Check DIV op's y_lo for zeroes else check all 64 bits
   assign z = (y_hi == 32'h0 && y_lo == 32'h0) ? 1'b1: //Check 64 bits
                                                 1'b0;

endmodule
