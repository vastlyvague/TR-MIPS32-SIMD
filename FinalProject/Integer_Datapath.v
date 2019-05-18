`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Integer_Datapath.v
 * Project:    Lab_Assignment_6
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.3
 * Rev. Date:  03/18/2019
 *
 * Purpose: This module is the hardware that does all the required operations
 * for a processor. It contains and connects the ALU to an array of registers
 * allowing operations to modify array registers and memory. Inside of
 * this are also 2 32-bit registers called HI and LO that holds the upper
 * and lower 32-bits of a 64-bit result of the MULT and DIV instruction.
 * When the two instructions are selected, the HILO_ld is set in order to
 * load the the registers. ALU_OUT contains the values inside an array register.
 * DY and DT are input from memory and PC_in is a value from the PC.
 * The IDP has 4 Pipelining registers: RS, RT, ALU_PIP and DIN.
 *
 * Notes: 3/01/2019 - This revision added the Pipeline Registers to the IDP
 *        3/07/2019 - Added a mux to select the destination address depending
 *                    on instruction type. When I-Type, DA_OUT = T_Addr
 *                    Else if R-Type, DA_OUT = D_Addr.
 *        3/17/2019 - Expanded the destination address mux to a 4 to 1
 *                    hex 2 and 3 have the value of 5'h1F and 5'h1D
 *        4/08/2019 - Added the Barrel shifter to do shifts
 *        4/17/2019 - Expanded the T_sel and added sp_outFlags and sp_inFlags,
 *                    sp_sel and s_sel to do stack related instructions.
 ****************************************************************************/
module Integer_Datapath(clk, reset, sp_sel, s_sel, D_En, HILO_ld, T_Sel, Y_Sel,
                        DA_Sel, D_Addr, S_Addr, T_Addr, FS, shamt, sp_inFlags,
                        PC_in, DY, DT, C, V, N, Z, sp_outFlags, ALU_OUT, D_OUT,
                        simd_sel);

   input         clk, reset;     //Clock, Reset
   input         sp_sel, s_sel;  //Stack Pointer Select and S Data Select
   input         D_En, HILO_ld;  //Write enable, HILO load         
   
   //Selector for Destination address depending on instruction type
   input   [1:0] DA_Sel, T_Sel, simd_sel;
   
   //Address of Registers
   input   [4:0] D_Addr, S_Addr, T_Addr;

   input   [2:0] Y_Sel;          //Mux Select
   input   [4:0] FS, shamt;      //Function Select
   input   [4:0] sp_inFlags;     //Stack Pointer Input Flags
   input  [31:0] PC_in;          //Value from PC
   input  [31:0] DY;             //Value from dMem
   input  [31:0] DT;             //Value from iMem
   
   output        C, V, N, Z;     //Status Flag Output
   output  [4:0] sp_outFlags;    //Stack Pointer Out Flags
   output [31:0] ALU_OUT, D_OUT; //Output of IDP
   
   wire          c, v, n, z;     //Output status flag wires from ALU_32
   wire          simdz;
   wire    [4:0] DA_OUT;         //Output from Destination Address MUX
   wire   [31:0] RS_Out;         //Output S from regfile32
   wire   [31:0] DY_Out;         //Output from D_in Pipeline register
   wire   [31:0] ALU_wire;       //Output from ALU_PIP Pipeline register
   wire   [31:0] HI_out, LO_out; //Output from HI and LO register
   wire   [31:0] Y_hi, Y_lo;     //Output from ALU. Upper and Lower 32 bit
   wire   [31:0] Y_hi_std, Y_lo_std;
   wire   [31:0] Y_hi_simd;      //Output from V_ALU. Upper and Lower 32 bit
   wire   [31:0] Y_lo_simd;
   wire   [31:0] Reg_S, Reg_T;   //Output from Register File
   wire   [31:0] T_MUX;          //Output from multiplexor
   
   wire [4:0] sp_muxOut;         //Stack Pointer Mux Output Wire
   wire [31:0] s_muxOut;         //S Mux Output Wire

   //Arithmetic Logical Unit
   ALU_32       uut0(.S(s_muxOut),  .T(D_OUT),   .FS(FS), .shamt(shamt),
                     .y_hi(Y_hi_std), .y_lo(Y_lo_std),
                     .c(c), .v(v), .n(n), .z(z));
                     
   V_ALU        SIMD(.simd_sel(simd_sel), .S(s_muxOut), .T(D_OUT), .FS(FS),
                     .shamt(shamt), .y_hi(Y_hi_simd), .y_lo(Y_lo_simd), .z(simdz));

   //32x32 Register
   regfile32    uut1(.clk(clk),       .reset(reset),   .D_En(D_En), .D_Addr(DA_OUT),
                     .S_Addr(sp_muxOut), .T_Addr(T_Addr), .D(ALU_OUT), .S(Reg_S),
                     .T(Reg_T));

   //HI and LO load registers that are used when MULTI or DIV operations are used
   LD_reg32       HI(.clk(clk), .reset(reset), .ld(HILO_ld), .d(Y_hi), .q(HI_out));
   LD_reg32       LO(.clk(clk), .reset(reset), .ld(HILO_ld), .d(Y_lo), .q(LO_out));
   
   //32-bit pipeline registers that take output operands of the regfile32's S and T
   REG32          RS(.clk(clk), .reset(reset), .D(Reg_S), .Q(RS_Out));
   REG32          RT(.clk(clk), .reset(reset), .D(T_MUX), .Q(D_OUT));
   
   //32-bit pipeline register that loads the y_lo value from the ALU32
   REG32     ALU_PIP(.clk(clk), .reset(reset), .D(Y_lo), .Q(ALU_wire));
   
   //32-bit pipeline register that loads the value from memory (DY)
   REG32         DIN(.clk(clk), .reset(reset), .D(DY),   .Q(DY_Out));

   //A 2 to 1 multiplexor that sets T_MUX to DT from iMem or T from the regfile
   assign T_MUX   = (T_Sel == 2'b01) ? DT    : 
                    (T_Sel == 2'b10) ? PC_in :
                    (T_Sel == 2'b11) ? {27'b0, sp_inFlags} : 
                                       Reg_T;

   //A 5 to 1 multiplexor that sets ALU_OUT to HI LO registers, ALU, DY
   //or PC_in. Defaults is Y_lo of the ALU
   assign ALU_OUT = (Y_Sel == 3'h1) ? HI_out:
                    (Y_Sel == 3'h2) ? LO_out:
                    (Y_Sel == 3'h3) ? DY_Out:
                    (Y_Sel == 3'h4) ? PC_in:
                                      ALU_wire;
                                
   //MUX Output allows for the S_Addr to Reg File to either be the
   //passed in S_Addr or the Stack Pointer Register Location(5'h1D)
   assign sp_muxOut = (sp_sel) ? 5'h1D : S_Addr;
   
   //Select the Input to the S input of the ALU
   //If s_sel is active, input the ALU_OUT Value
   //Otherwise, input the value from the RS_Out Register
   assign s_muxOut = (s_sel) ? ALU_OUT : RS_Out;
   
   //Captures Stack Pointer Output Flags from DY_Out[4:0]
   assign sp_outFlags = DY_Out[4:0];
                                      
   //When I-Type instruction is being used, DA_Sel = 0 so that the destination
   //address will use the T_Addr. If R-type then D_Addr will be use (DA_Sel = 1)
   //When in RESET state of the MCU, DA_Sel == 3 and when in INTR_1 state it is 2
   assign DA_OUT  = (DA_Sel == 2'h1) ? D_Addr:
                    (DA_Sel == 2'h2) ? 5'h1F:
                    (DA_Sel == 2'h3) ? 5'h1D:
                                       T_Addr;

   //Select Status flags and Y_hi/Y_lo data based on simd mode. 0 is standard
   assign {C, V, N, Z} = (simd_sel == 2'b0) ? {c, v, n, z} :
                                              {1'bx, 1'bx, 1'bx, simdz};
                                              
   assign {Y_hi, Y_lo} = (simd_sel == 2'b0) ? {Y_hi_std, Y_lo_std} :
                                              {Y_hi_simd, Y_lo_simd};

endmodule
