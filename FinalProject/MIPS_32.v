`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MIPS_32.v
 * Project:    Lab_Assignment_1
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  01/29/2019
 *
 * Purpose: The Microprocessor without Interlocked Pipelined Stages is a
 * 32 bit RISC ISA that uses a 5 bit function select opcode to do ALU
 * (Arithmetic Logical Unit) instructions. This uses two 32 bit input S and T
 * and does certain operations on it depending on the opcode. Flags carry and
 * overflow determined by the FS opcode. This module contains Arithmetic,
 * Logical and Other operations.
 *          
 * Notes: Logical operations do not care for carry or overflow.
 * All arithmetic operations use signed integers except ADDU and SUBU.
 * Signed add/sub operation overflow is determined by bit sign of the
 * two addend and the sum or the minuend, subtrahend and difference. If
 * result bit is different than the bit of first number than it overflows.
 * Unsigned add/sub operation's carry is also their overflow.
 * 
 ****************************************************************************/
module MIPS_32(S, T, FS, Y, c, v);

   input      [31:0] S, T;                                           //Inputs
   input       [4:0] FS;                                             //FS opcode
   output reg [31:0] Y;                                              //Output
   
   //Integers to store Inputs
   integer           int_S, int_T;
   
   //Status Flag bits carry and overflow
   output reg        c, v;
   
   //Arithmetic Operations
   parameter PASS_S = 5'h00, PASS_T = 5'h01, ADD = 5'h02,     ADDU = 5'h03,
             SUB = 5'h04,    SUBU = 5'h05,   SLT = 5'h06,     SLTU = 5'h07,
             
   //Logical Operations
             AND = 5'h08,    OR = 5'h09,     XOR = 5'h0a,     NOR = 5'h0b,
             SRL = 5'h0c,    SRA = 5'h0d,    SLL = 5'h0e,     ANDI = 5'h16,
             ORI = 5'h17,    LUI = 5'h18,    XORI = 5'h19,

   //Other Operations
             INC = 5'h0f,    INC4 = 5'h10,   DEC = 5'h11,     DEC4= 5'h12,
             ZEROS = 5'h13,  ONES = 5'h14,   SP_INIT = 5'h15;
             
   always@(S or T or FS) begin
      int_S = S;
      int_T = T;
   
      case(FS)
         PASS_S : {c, v, Y} = {1'bX, 1'bX, S};                       //Pass S
         
         PASS_T : {c, v, Y} = {1'bX, 1'bX, T};                       //Pass T

         ADD    : begin                                              //Add Signed
                     {c, Y} = S + T;
                     if((int_S < 0 && int_T < 0 && !Y[31]) ||        //Overflow logic
                        (int_S > 0 && int_T > 0 &&  Y[31]))          //addition
                        v = 1'b1;
                     else
                        v = 1'b0;
                  end
 
         ADDU   : begin                                              //Add Unsigned
                     {c, v, Y} = S + T;                              //Carry is
                     c = v;                                          //overflow in
                  end                                                //unsigned.

         SUB    : begin                                              //Subtract
                     {c, Y} = S - T;                                 //Signed
                     if((int_S < 0 && int_T > 0 && !Y[31]) ||        //Overflow logic
                        (int_S > 0 && int_T < 0 &&  Y[31]))          //subtraction.
                        v = 1'b1;
                     else
                        v = 1'b0;
                  end

         SUBU   : begin                                              //Subtract
                     {c, v, Y} = S - T;                              //Unsigned
                     c = v;
                  end
                  
         SLT    : {c, v, Y} = (int_S < int_T) ? {1'bX, 1'bX, 32'b1}: //Set on less
                                                {1'bX, 1'bX, 32'b0}; //than signed

         SLTU   : {c, v, Y} = (S < T) ? {1'bX, 1'bX, 32'b1}:         //Set on less
                                        {1'bX, 1'bX, 32'b0};         //than unsigned
                  
         AND    : {c, v, Y} = {1'bX, 1'bX, S & T};                   //Logic AND
         
         OR     : {c, v, Y} = {1'bX, 1'bX, S | T};                   //Logic OR
         
         XOR    : {c, v, Y} = {1'bX, 1'bX, S ^ T};                   //Logic XOR
         
         NOR    : {c, v, Y} = {1'bX, 1'bX, ~(S | T)};                //Logic NOR
         
         SRL    : {c, v, Y} = {T[0], 1'bX, 1'b0, T[31:1]};           //Shift Right
                                                                     //Logical

         SRA    : {c, v, Y} = {T[0], 1'bX, T[31], T[31:1]};          //Shift Right
                                                                     //Arithmetic
                                                                  
         SLL    : {c, v, Y} = {T[31], 1'bX, T[30:0], 1'b0};          //Shift Left
                                                                     //Logical
                  
         ANDI   : {c, v, Y} = {1'bX, 1'bX, S & {16'h0, T[15:0]}};    //AND Immediate
         
         ORI    : {c, v, Y} = {1'bX, 1'bX, S | {16'h0, T[15:0]}};    //OR Immediate
         
         LUI    : {c, v, Y} = {1'bX, 1'bX, {T[15:0], 16'h0}};        //Load upper
                                                                     //Immediate
                                                                  
         XORI   : {c, v, Y} = {1'bX, 1'bX, S ^ {16'h0, T[15:0]}};    //XOR Immediate
         
         INC    : begin                                              //Increment by 1
                     {c, Y} = S + 1;
                     if((int_S < 0 && int_T < 0 && !Y[31]) ||        //Overflow logic
                        (int_S > 0 && int_T > 0 &&  Y[31]))          //addition.
                        v = 1'b1;
                     else
                        v = 1'b0;
                  end
         
         INC4   : begin                                              //Increment by 4
                     {c, Y} = S + 4;
                     if((int_S < 0 && int_T < 0 && !Y[31]) ||
                        (int_S > 0 && int_T > 0 &&  Y[31]))
                        v = 1'b1;
                     else
                        v = 1'b0;
                  end
                  
         DEC    : begin                                              //Decrement by 1
                     {c, Y} = S - 1;
                     if((int_S < 0 && int_T > 0 && !Y[31]) ||        //Overflow logic
                        (int_S > 0 && int_T < 0 &&  Y[31]))          //subtraction.
                        v = 1'b1;
                     else
                        v = 1'b0;
                  end
                  
         DEC4   : begin                                              //Decrement by 4
                     {c, Y} = S - 4;
                     if((int_S < 0 && int_T > 0 && !Y[31]) ||
                        (int_S > 0 && int_T < 0 &&  Y[31]))
                        v = 1'b1;
                     else
                        v = 1'b0;
                  end
                  
         ZEROS  : {c, v, Y} = {1'bX, 1'bX, 32'h0};                   //Fill all zeros
         
         ONES   : {c, v, Y} = {1'bX, 1'bX, {32{1'hf}}};              //Fill all ones
         
         SP_INIT: {c, v, Y} = {1'bX, 1'bX, 32'h3fc};                 //Set 0x3fc
         
         default: {c, v, Y} = 1'bX;
         
      endcase
      end //begin end
         
endmodule
