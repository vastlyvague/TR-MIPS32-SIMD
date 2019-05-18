`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  ALU_32.v
 * Project:    Lab_Assignment_3
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  01/24/2019
 *
 * Purpose: An arithmetic logical unit that does behavioral operations based on
 * a 5 bit function select (FS) opcode. It takes in two 32 bit inputs of (S) data
 * and (T) data and uses those in a specified operation to output a 64 bit value
 * in form of two 32 bit outputs called Y_hi for the upper 32 bit and Y_lo for
 * lower 32 bit. There are status flags of carry (c), overflow (v), negative (n),
 * and zero (z) that are checked.
 * 
 * Notes:
 * ALU OPERATION CODES
 * 0 - Pass_S   7 - SLTU   E  - SLL     15 - SP_INIT
 * 1 - Pass_T   8 - AND    F  - INC     16 - ANDI
 * 2 - ADD      9 - OR     10 - INC4    17 - ORI
 * 3 - ADDU     A - XOR    11 - DEC     18 - LUI
 * 4 - SUB      B - NOR    12 - DEC4    19 - XORI
 * 5 - SUBU     C - SRL    13 - ZEROS   1E - MUL
 * 6 - SLT      D - SRA    14 - ONES    1F - DIV
 ****************************************************************************/
module ALU_32(S, T, FS, shamt, y_hi, y_lo, c, v, n, z);
              
   input  [31:0] S, T;                                          //Inputs
   input   [4:0] FS, shamt;                                     //Function Select
   output [31:0] y_hi, y_lo;                                    //Outputs
   
   //Status Flag bits carry, overflow, negative and zero
   output        c, v, n, z;
   wire          c_w, v_w, n_w;

   wire   [63:0] prdct;
   wire   [31:0] quote, rem, Y;
   
   //Barrell Shifter
   wire [31:0] T_shift;
   wire        C_shift;

   //Instantiate MPY_32, DIV_32 and MIPS_32 modules
   MPY_32  uut0(.S(S), .T(T), .prdct(prdct));
   DIV_32  uut1(.S(S), .T(T), .quote(quote), .rem(rem));
   MIPS_32 uut2(.S(S), .T(T), .FS(FS),       .Y(Y),     .c(c_w),   .v(v_w));
   BarrellShifter bs(.D(T), .type(FS), .shamt(shamt), .Out(T_shift), .C(C_shift));
   
   //Multiplexor to determine which Operation Module is being used
   assign {y_hi, y_lo} = (FS == 5'h1e)         ? {prdct[63:32], //MULT upper 32 bit
                                                  prdct[31:0]}: //MULT lower 32 bit
                         (FS == 5'h1f)         ? {rem, quote} : //DIV
                         (FS == 5'h0C || FS == 5'h0E ||
                          FS == 5'h0D || FS == 5'h1A ||
                          FS == 5'h1B)         ? {31'h0, T_shift}://Shift
                         
                                                 {31'h0, Y}   ; //MIPS ops
   
   //Set carry flag to x if FS is MULT or DIV else take from MIPS opcodes
   assign c = (FS == 5'h1e || FS == 5'h1f)     ? 1'bX    :
              (FS == 5'h0C || FS == 5'h0E ||
               FS == 5'h0D || FS == 5'h1A ||
               FS == 5'h1B)                    ? C_shift :   c_w;
   
   //Set overflow flag to x if FS is MULT or DIV else take from MIPS opcodes
   assign v = (FS == 5'h1e || FS == 5'h1f)     ? 1'bX : v_w;
   
   //Set zero flag. Check DIV op's y_lo for zeroes else check all 64 bits
   assign z = (FS == 5'h1f && y_lo == 32'h0)   ? 1'b1:          //DIV quotient
              (y_hi == 32'h0 && y_lo == 32'h0) ? 1'b1:          //Check 64 bits
                                                 1'b0;
   
   //Set negative flag using MSB depending on FS. y_hi for mult else y_lo
   assign n = ((FS == 5'h1e))                  ? y_hi[31]:      //MULT
              ((FS == 5'h1f && y_lo[31]))      ? y_lo[31]:      //DIV quotient
              ((FS == 5'h03 || FS == 5'h05))   ? 1'b0    :      //ADDU & SUBU
                                                 y_lo[31];      //Other opcodes

endmodule
