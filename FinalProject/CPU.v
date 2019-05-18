`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  CPU.v
 * Project:    Final_Project
 * Designer:   Thomas Nguyen and Reed Ellison
 * Email:      tholinngu@gmail.com and notwreed@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  04/05/2019
 *
 * Purpose: Central Processing Unit Module that instantiates
 * the Instruction Unit, Integer Datapath, and Control Unit. 
 * Input to the CPU comes from the Data Memory and Input/Output
 * Memory Modules. 
 *
 * Notes: 
 ****************************************************************************/
module CPU(clk, rst, intr, inta, dm_cs, dm_rd, dm_wr,
          io_cs, io_rd, io_wr, dMemtoDY, madr, idp);

	input        clk, rst, intr;     //Clock, Reset, and Interrupt Request
   
   input [31:0] dMemtoDY;           //Output of data memory module
   
   output inta;                     //Interrupt Acknowledge
   
   output dm_cs, dm_rd, dm_wr,      //Data Memory Chip Select, Read, and Write
          io_cs, io_rd, io_wr;      //IO Memory Chip Select, Read, and Write
   
   output [31:0] madr, idp;         //Memory Address and IDP Output
   
   wire        PC_Ld, PC_Inc;       //PC Load and Increment Signals
   wire  [1:0] PC_Sel;              //PC Select Signal
	wire        IR_Ld;               //IR Load Signal
   wire        sp_sel, s_sel;       //Stack Pointer and S Data Signals
   
	wire        IM_Cs,IM_Wr,IM_Rd;   //Instruction Memory and Data memory's
   
   wire        D_En, HILO_ld;       //Write Enable for Registers, HILO Load
   wire  [1:0] DA_Sel, T_Sel;       //MUX Select for IDP and for T Address
   wire  [2:0] Y_Sel;               //MUX Select for input to ALU_OUT Reg
   
   wire  [4:0] FS;                  //Function Select Value
   
   wire        C, V, N, Z;          //Status Flags   
   wire [31:0] ALU_OUT, D_OUT;      //Outputs from IDP
   wire [31:0] PC_Out;              //Program Counter Out
	wire [31:0] IR_Out;              //Instruction Register Out
	wire [31:0] SE_16;               //Sign Extended 16-bits
   wire [4:0]  sp_outFlags, sp_inFlags; //Stack Pointer Flags
   wire [1:0]  simd;                //SIMD mode select

   assign madr = ALU_OUT;           //Memory Address = ALU_OUT
   
   assign idp = D_OUT;              //IDP Output = D_OUT
   
   //Instantiate Instruction Unit
   Instruction_Unit   IU(.clk(clk),           .rst(rst),            .PC_Ld(PC_Ld), 
                         .PC_Inc(PC_Inc),     .IM_Cs(IM_Cs),        .IM_Wr(IM_Wr), 
                         .IM_Rd(IM_Rd),       .IR_Ld(IR_Ld),        .PC_In(ALU_OUT), 
                         .PC_Out(PC_Out),     .IR_Out(IR_Out),      .SE_16(SE_16),
                         .PC_Sel(PC_Sel));
                           
   //Instantiate Integer Datapath
   Integer_Datapath  IDP(.clk(clk),             .reset(rst),   .sp_sel(sp_sel), 
                         .s_sel(s_sel),         .D_En(D_En),   .HILO_ld(HILO_ld), 
                         .T_Sel(T_Sel),         .Y_Sel(Y_Sel), .PC_in(PC_Out),  
                         .DY(dMemtoDY),         .DT(SE_16),    .C(C),          
                         .V(V),                 .N(N),         .sp_inFlags(sp_inFlags),
                         .ALU_OUT(ALU_OUT),     .D_OUT(D_OUT), .DA_Sel(DA_Sel),
                         .Z(Z),                 .sp_outFlags(sp_outFlags), 
                         .FS(FS),               .shamt(IR_Out[10:6]), 
                         .S_Addr(IR_Out[25:21]),.T_Addr(IR_Out[20:16]),    
                         .D_Addr(IR_Out[15:11]),.simd_sel(simd));
   
   //Instantiate Control Unit
   Control_Unit       CU(.clk(clk),        .rst(rst),        .intr(intr),     
                         .c(C),            .n(N),            .z(Z),     .v(V),       
                         .IR(IR_Out),      .int_ack(inta),   .pc_sel(PC_Sel), 
                         .pc_ld(PC_Ld),    .pc_inc(PC_Inc),  .ir_ld(IR_Ld), 
                         .im_cs(IM_Cs),    .im_rd(IM_Rd),    .im_wr(IM_Wr),   
                         .D_En(D_En),      .DA_sel(DA_Sel),  .T_sel(T_Sel),
                         .sp_sel(sp_sel),  .s_sel(s_sel),    .dm_cs(dm_cs),  
                         .HILO_ld(HILO_ld),.Y_sel(Y_Sel),
                         .dm_rd(dm_rd),    .dm_wr(dm_wr), 
                         .io_cs(io_cs),    .sp_inFlags(sp_inFlags), 
                         .sp_outFlags(sp_outFlags),
                         .io_rd(io_rd),    .io_wr(io_wr), .FS(FS), .simd_sel(simd));


endmodule
