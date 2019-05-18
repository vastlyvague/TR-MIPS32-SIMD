`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:26:14 04/18/2019 
// Design Name: 
// Module Name:    ALU_FP 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ALU_FP(S, T, FS, shamt, y_hi, y_lo, c, v, n, z);
   
   input  [31:0] S, T;                                          //Inputs
   input   [4:0] FS, shamt;                                            //Function Select
   output [31:0] y_hi, y_lo;                                    //Outputs
   
   //Status Flag bits carry, overflow, negative and zero
   output        c, v, n, z;
   wire          c_w, v_w, n_w;

   wire   [63:0] prdct;
   wire   [31:0] quote, rem, Y;
   
   integer int_S_int, int_T_int;
   integer int_S_frac, int_T_frac;
   
   wire S_sign; wire T_sign;
   wire [12:0] S_int; wire [12:0] T_int;
   wire [7:0] S_frac; wire [7:0] T_frac;
   //wire [9:0] S_exp;  wire [9:0] T_exp;
   wire [12:0] S_int_; wire [12:0] T_int_;
   wire [7:0] S_frac_; wire [7:0] T_frac_;
   //wire [9:0] S_exp_;  wire [9:0] T_exp_;
   wire Y_sign; 
   wire [12:0] Y_int;
   wire [7:0] Y_frac; 
   wire [9:0] Y_exp; 
   
   wire c_frac;
   
   
   
   assign S_sign = S[31]; assign T_sign = T[31];
   assign S_int = S[30:14]; assign T_int = T[30:14];
   assign S_frac = S[13:0]; assign T_frac = T[13:0];
   
   
    //Arithmetic Operations
   parameter PASS_S = 5'h00, PASS_T = 5'h01, ADD = 5'h02,     ADDU = 5'h03,
             SUB = 5'h04,    SUBU = 5'h05,   SLT = 5'h06,     SLTU = 5'h07,
             
   //Logical Operations
             AND = 5'h08,    OR = 5'h09,     XOR = 5'h0a,     NOR = 5'h0b,
             SRL = 5'h0c,    SRA = 5'h0d,    SLL = 5'h0e,     ANDI = 5'h16,
             ORI = 5'h17,    LUI = 5'h18,    XORI = 5'h19,

   //Other Operations
             INC = 5'h0f,    INC4 = 5'h10,   DEC = 5'h11,     DEC4= 5'h12,
             ZEROS = 5'h13,  ONES = 5'h14,   SP_INIT = 5'h15,
             
   //FP Operations
             FADD = 5'h1A,  FSUB = 5'h1B, FADDU = 5'h1C, FSBU = 5'h1D;
             
   always@(S or T or FS) begin
      int_S_frac = S_frac;int_T_frac = T_frac;
      int_S_int = S_int;int_T_int = T_int;
      case(FS)
         FADD    : begin
                     {c_fract,Y_fract} = S_frac + T_frac;
                     {c,Y_int}   = S_int   + T_int;
                  end
         FSUB    : begin
                     {c_fract,Y_fract} = S_frac - T_frac;
                     {c,Y_int}   = S_int   - T_int;
                  end
         FADDU    : begin
                     {c_fract,Y_fract} = frac_S_frac + frac_T_frac;
                     {c,Y_int}   = int_S_int   + int_T_int;
                  end
         FSUBU    : begin
                     {c_fract,Y_fract} = frac_S_frac - frac_T_frac;
                     {c,Y_int}   = int_S_int   - int_T_int;
                  end
                  
         
      endcase
   end
   
   
endmodule
