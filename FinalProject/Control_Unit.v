`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Instruction_Unit.v
 * Project:    Lab_Assignment_6
 * Designer:   Reed  Ellison
 * Email:      Reed.Ellison@student.csulb.edu
 * Rev. No.:   Version 1.5
 * Rev. Date:  04/17/2019
 *
 * Purpose: State machine implementing the MIPS Control Unit (MCU) for the
 * major cycles of fetch, decode and various execute instructions and write
 * back states.
 *
 * Notes: 4/08/2019 - Added lui, ori, sw, addi and shift instructions.
 *        4/13/2019 - Added bne, beq, lw, ori, mflo, mfhi, mult, div instructions
 *        4/14/2019 - Added xor, xori, slt, slti, jr instructions
 *        4/15/2019 - Added blez, bgtz, setie instructions
 *        4/17/2019 - Expanded the T_sel and added sp_outFlags and sp_inFlags,
 *                    sp_sel and s_sel to do stack related instructions.
 *                    Added reti and expanded interrupt states.
 ****************************************************************************/
module Control_Unit(clk, rst, intr, c, n, z, v, IR, int_ack, pc_sel, pc_ld, 
                    pc_inc, ir_ld, im_cs, im_rd, im_wr, D_En, DA_sel, T_sel, 
                    sp_sel, s_sel, HILO_ld, Y_sel, sp_inFlags, sp_outFlags,
                    dm_cs, dm_rd, dm_wr, io_cs, io_rd, io_wr, FS, simd_sel);
   
   input             clk, rst, intr;//Clock, Reset, and Interrupt Request
   input             c, n, z, v;    //Flags
   input      [4:0]  sp_inFlags;    //Stack Pointer In Flags
   input      [31:0] IR;            //Instruction Register
   
   //Outputs
   output reg        pc_ld, pc_inc; //Program Counter load and increment
   output reg  [1:0] pc_sel, DA_sel;//Program Counter Input select
                                    //and Dest. Addr Select
   output reg        ir_ld, im_cs,  //Instruction Reg. load and
                     im_rd, im_wr;  //Instruction Memory Chip Select and
                                    //Read and Write signals                                                          
   output reg        D_En, HILO_ld; //Write Enable, T Select and Hi Lo Load
   output reg  [1:0] T_sel;         //T Value Select
   output reg  [2:0] Y_sel;         //ALU Out Select
   output reg        dm_cs, dm_rd, dm_wr;//Data Memory chip select, read and write
   output reg        io_cs, io_rd, io_wr;//IO Memory chip select, read and write
   output reg  [4:0] FS;            //Function Select
   output reg  [4:0] sp_outFlags;   //Stack Pointer Output Flags
   output reg        s_sel, sp_sel; //S_Sel and Stack Pointer Select
   output reg  [1:0] simd_sel;      //SIMD mode select. 0=std, 1=8bit, 2=16bit
   output       int_ack;            //interrupt acknowledge
   reg          int_ack;
   
   integer i;
   
   //States of control unit
   parameter
      RESET  = 00,  FETCH      = 01,  DECODE   = 02,  ADD    = 10,
      ADDU   = 11,  AND        = 12,  ORI      = 20,  JR     = 8,
      JR2    = 408, BEQ        = 24,  BEQ2     = 424, 
      BNE    = 25,  BNE2       = 425, SRL      = 50,
      ADDI   = 51,  SRA        = 52,  SLT      = 53,  SLL    = 54,
      SLTI   = 55,  LW_2       = 57,  MULT     = 58,  MFLO   = 59,
      MFHI   = 60,  SLTU       = 61,  OR       = 62,  NOR    = 63,
      XOR    = 64,  DIV        = 65,  XORI     = 66,  SLTIU  = 67,
      ANDI   = 68,  SUB        = 69,  BLEZ     = 70,  BLEZ_2 = 71,
      BGTZ   = 72,  BGTZ_2     = 73,  SETIE    = 74,  INPUT  = 75,
      INPUT_2 = 76, OUTPUT     = 77,  OUTPUT_2 = 78,
      RETI    = 79, RETI_2     = 80,  RETI_3   = 81,
      RETI_4  = 82, RETI_5     = 83,  RETI_6   = 84,
      ROTL    = 88, ROTR       = 89,  CLR      = 90,
      CLR_2   = 91, NOP        = 92,  MOV      = 93,
      MOV_2   = 94, PUSH       = 95,  PUSH_2   = 96,
      PUSH_3  = 97, PUSH_4     = 98,  POP      = 99,
      POP_2   = 100, POP_3     = 101, POP_4    = 102,
      POP_5   = 103, SUBU      = 104, 
      LUI    = 21,  LW         = 22,  SW     = 23, 
      WB_ALU = 30,  WB_IMM     = 31,  WB_DIN = 32,
      WB_HI  = 33,  WB_LO      = 34,  WB_MEM = 35,
      J      = 37,  JAL        = 38,
      
      SIMD8  = 300, SIMD16     = 301, WB_ALU_SIMD = 302,
      ADD_SIMD = 303, SUB_SIMD = 304, MULT_SIMD = 305,
      DIV_SIMD = 305, AND_SIMD = 306, OR_SIMD = 307,
      XOR_SIMD = 308, NOR_SIMD = 309, SLL_SIMD = 310,
      SRL_SIMD = 311, SRA_SIMD = 312, ROTL_SIMD = 313,
      ROTR_SIMD = 314,
      
      INTR_1 = 501, INTR_2     = 502, INTR_3 = 503,
      INTR_4 = 504, INTR_5     = 505, INTR_6 = 506,
      BREAK  = 510, ILLEGAL_OP = 511;
   
   //ALU Opcodes for Function Select
   parameter 
      pass_s_  = 5'h00, pass_t_ = 5'h01, add_  = 5'h02,
      addu_    = 5'h03, sub_    = 5'h04, subu_ = 5'h05,
      slt_     = 5'h06, sltu_   = 5'h07, and_  = 5'h08,
      or_      = 5'h09, xor_    = 5'h0A, nor_  = 5'h0B,
      srl_     = 5'h0C, sra_    = 5'h0D, sll_  = 5'h0E,
      inc_     = 5'h0F, inc4_   = 5'h10, dec_  = 5'h11,
      dec4_    = 5'h12, zeros_  = 5'h13, ones_ = 5'h14,
      sp_init_ = 5'h15, andi_   = 5'h16, ori_  = 5'h17,
      lui_     = 5'h18, xori_   = 5'h19, rotl_ = 5'h1A,
      rotr_    = 5'h1B, clr_    = 5'h1C, mul_   = 5'h1E, 
      div_ = 5'h1F;   
      
   reg [8:0] state;
   
   //Flags
   reg   psi, psc, psv, psn, psz;
   reg   nsi, nsc, nsv, nsn, nsz;
   
   always@(posedge clk, posedge rst)
      if(rst)
         {psi, psc, psv, psn, psz} <= 5'b0;
      else begin
         {psi, psc, psv, psn, psz} <= {nsi, nsc, nsv, nsn, nsz};
         $display("PC = %h, IR = %h", Top_tb.cpu.IU.PC_Out, Top_tb.cpu.IU.IR_Out);
         end
   
   always @(posedge clk, posedge rst)
      if(rst)
         begin
            //control word assignments for "deasserting" everything
            @(negedge clk)
            {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
            {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
            {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
            {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
            {io_cs, io_rd, io_wr}                 = 3'b0_0_0;         
            {sp_sel, s_sel}                       = 2'b0_0;
            int_ack = 1'b0;                    FS = sp_init_; //Gets value 0x3FC
            simd_sel = 2'b00;
            #1 {nsi, nsc, nsv, nsn, nsz} = 5'b0;
            state   = RESET;
         end
      else
         case (state)
            FETCH:
               if(int_ack == 0 && (intr == 1 && psi == 1))
                  begin /*new interrupt pending, prepare for ISR*/
                     //control word assignments for "deasserting" everything
                     @(negedge clk)
                     {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                     {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                     {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                     {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                     {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                     {sp_sel, s_sel}                       = 2'b0_0;
                     int_ack = 1'b0;                    FS = 5'h0;
                     simd_sel = 2'b00;
                     #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                     state   = INTR_1;
                  end
               else
                  begin /*no new interrupt pending, fetch and instruction*/
                     if((int_ack == 1 && intr == 0) || (psi == 1 && intr == 0))
                        int_ack = 1'b0;
                     // control word assignemtns: IR <-- iM[PC], PC <-- PC + 4
                     @(negedge clk)
                     {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_1_1;
                     {im_cs, im_rd, im_wr}                 = 3'b1_1_0;
                     {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                     {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                     {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                     {sp_sel, s_sel}                       = 2'b0_0;
                     int_ack = 1'b0;                    FS = 5'h0;
                     simd_sel = 2'b00;
                     #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                     state   = DECODE;
                  end
            RESET:
               begin
                  // control word assignments: $sp <-- ALU_OUT(32'h3FC)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_11_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  simd_sel = 2'b00;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
               end
            DECODE:
               begin
                  @(negedge clk)
                  if(IR[31:26] == 6'h0) // check for MIPS format
                     begin // it is an R-type format
                           // control word assignements: RS <-- 4rs,
                           //RT <-- $rt (default)
                        {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                        {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                        {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                        {sp_sel, s_sel}                       = 2'b0_0;
                        int_ack = 1'b0;                    FS = 5'h0;
                        simd_sel = 2'b00;
                        #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                        case (IR[5:0])
                           6'h00  : state = SLL;
                           6'h02  : state = SRL;
                           6'h03  : state = SRA;
                           6'h04  : state = ROTL;
                           6'h05  : state = ROTR;
                           6'h06  : state = CLR;
                           6'h07  : state = NOP;
                           6'h09  : state = MOV;
                           6'h08  : state = JR;
                           6'h10  : state = MFHI;
                           6'h12  : state = MFLO;
                           6'h13  : state = PUSH;
                           6'h14  : state = POP;
                           6'h0D  : state = BREAK;
                           6'h18  : state = MULT;
                           6'h1A  : state = DIV;
                           6'h1F  : state = SETIE;
                           6'h20  : state = ADD;
                           6'h21  : state = ADDU;
                           6'h22  : state = SUB;
                           6'h23  : state = SUBU;
                           6'h24  : state = AND;
                           6'h25  : state = OR;
                           6'h26  : state = XOR;
                           6'h27  : state = NOR;
                           6'h2A  : state = SLT;
                           6'h2B  : state = SLTU;
                           default: state = ILLEGAL_OP;
                        endcase
                     end  // end of if statement for R-type format
                  else
                     begin // it is an I-type or J-type format
                           // control word assignments: RS <-- $rs,
                           //RT <-- DT(se_16)
                        {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_01_0_000;
                        {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                        {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                        {sp_sel, s_sel}                       = 2'b0_0;
                        int_ack = 1'b0;                    FS = 5'h0;
                        simd_sel = 2'b00;
                        #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                        case (IR[31:26])
                           6'h02  : state = J;
                           6'h03  : state = JAL;
                           6'h04  : state = BEQ;
                           6'h05  : state = BNE;
                           6'h06  : state = BLEZ;
                           6'h07  : state = BGTZ;
                           6'h08  : state = ADDI;
                           6'h0A  : state = SLTI;
                           6'h0B  : state = SLTIU;
                           6'h0C  : state = ANDI;
                           6'h0D  : state = ORI;
                           6'h0E  : state = XORI;
                           6'h0F  : state = LUI;
                           6'h1C  : state = INPUT;
                           6'h1D  : state = OUTPUT;
                           6'h1E  : state = RETI;
                           6'h23  : state = LW;
                           6'h2B  : state = SW;
                           6'h2C  : state = SIMD8;
                           6'h2D  : state = SIMD16;
                           default: state = ILLEGAL_OP;
                        endcase
                        // Case of Branches
                        //    if T_sel = 0, RT <- $rt
                        //    IR[15:0] will be used
                        if(state == BEQ || state == BNE || state == BGTZ || state == BLEZ)
                           T_sel = 2'b0;
                        else
                           T_sel = 2'b1;
                           
                        // Case when SIMD8 or SIMD16. Checks again for IR[5:0]
                        if(state == SIMD8 || state == SIMD16) begin
                           if(state == SIMD8)
                              simd_sel = 2'b01;
                           else
                              simd_sel = 2'b10;
                           T_sel = 2'b0;
                           case(IR[5:0])
                              6'h00  : state = SLL_SIMD;
                              6'h02  : state = SRL_SIMD;
                              6'h03  : state = SRA_SIMD;
                              6'h04  : state = ROTL_SIMD;
                              6'h05  : state = ROTR_SIMD;
                              6'h18  : state = MULT_SIMD;
                              6'h1A  : state = DIV_SIMD;
                              6'h20  : state = ADD_SIMD;
                              6'h22  : state = SUB_SIMD;
                              6'h24  : state = AND_SIMD;
                              6'h25  : state = OR_SIMD;
                              6'h26  : state = XOR_SIMD;
                              6'h27  : state = NOR_SIMD;
                              default: state = ILLEGAL_OP;
                           endcase
                        end
                           
                     end   // end of else statement for I-type or J-type formats
               end   // end of DECODE
            ADD:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) + RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = add_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = WB_ALU;
               end
             SUB:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) - RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = sub_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = WB_ALU;
               end
            ADDU:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) + RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = addu_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = WB_ALU;
               end
             SUBU:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) - RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = subu_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = WB_ALU;
               end
            CLR:
               begin
                  // control word assignments: ALU_OUT <-- 0x0000
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_01_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = zeros_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = CLR_2;
               end
            CLR_2:
               begin
                  // control word assignments: RT($rt) <-- ALU_OUT
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            MOV:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = MOV_2;
               end
            MOV_2:
               begin
                  // control word assignments: RT($rt) <-- ALU_OUT
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            XOR:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) ^ {16'h0, RT($rt[15:0])}
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = xor_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_ALU;
               end
            XORI:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) ^ RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = xori_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_IMM;
               end
            AND:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) & RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = and_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_ALU;
               end
            PUSH:
               begin $display("PUSH1 ");
                  // control word assignments: DM[--$SP] <-- $RT
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_01_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b1_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = PUSH_2;
               end
            PUSH_2:
               begin $display("PUSH2 ");
                  // control word assignments: ALU_OUT <-- RS($sp)-4; RT <-- R[$RT]
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_01_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = dec4_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = PUSH_3;
               end
            PUSH_3:
               begin $display("PUSH3 ");
                  // control word assignments: DM[ALU_OUT] <-_ RT($rt)
                  //                           ALU_OUT <-- ALU_OUT($SP-4)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_01_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_0_1;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = PUSH_4;
               end
            PUSH_4:
               begin $display("PUSH4 ");
                  // control word assignments: R[$SP] <-- ALU_OUT($sp-4)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_11_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            POP:
               begin $display("POP1 ");
                  // control word assignments:  RT[$rt] <-- DM[$SP++]
                  //                            RS <-- R[$SP]
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b1_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = POP_2;
               end
            POP_2:
               begin
                  // control word assignments:  ALU_OUT <-- RS($SP)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = POP_3;
               end
            POP_3:
               begin
                  // control word assignments:  D_IN <-- DM[ALU_OUT]
                  //                            ALU_OUT <-- ALU_OUT($SP)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_1_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = POP_4;
               end
            POP_4:
               begin
                  // control word assignments:  RT[$rt] <- D_IN
                  //                            ALU_OUT <-- ALU_OUT($sp) + 4
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_00_00_0_011;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = inc4_;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = POP_5;
               end
            POP_5:
               begin
                  // control word assignments:  R(sp) <-- ALU_OUT((sp+4)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_11_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            NOP:
               begin
                  // control word assignments: Do Nothing - ALU_OUT <- ALU_OUT
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            ANDI:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) & RT(se_16)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = andi_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_IMM;
               end
            OR:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) | RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = or_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_ALU;
               end
            NOR:
               begin
                  // control word assignments: ALU_OUT <-- ~(RS($rs) | RT($rt))
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = nor_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_ALU;
               end
            ROTL:
               begin
                  // control word assignments: ALU_OUT <-- 
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = rotl_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, psv, n, z};
                  state   = WB_ALU;
               end
            ROTR:
               begin
                  // control word assignments: ALU_OUT <-- 
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = rotr_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, psv, n, z};
                  state   = WB_ALU;
               end
            MULT:
               begin
                  // control word assignments: {Hi,Lo} <-- RS($rs) * RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_1_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = mul_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = FETCH;
               end
            DIV:
               begin
                  // control word assignments: {Hi} <-- RS($rs) / RT($rt)
                  // {Lo} <-- RS($rs) % RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_1_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = div_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = FETCH;
               end
            MFLO:
               begin
                  // control word assignments: RD($rd) <-- Lo
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_01_00_0_010;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
             MFHI:
               begin
                  // control word assignments: RD($rd) <-- Hi
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_01_00_0_001;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            SETIE:
               begin
                  // control word assignments: psi <- 1'b1
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {1'b1, psc, psv, psn, psz};
                  state   = FETCH;
               end   
            BEQ:
               begin
                  // control word assignments: ALU_OUT <-- 
                  //RS($rs) - RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sub_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = BEQ2;                 
               end
            BEQ2:
               begin
                  // control word assignments: PC <--
                  //PC + signext(IR[15:0])<<2
                  @(negedge clk)
                  if(psz == 1'b1)
                     {pc_sel, pc_ld, pc_inc, ir_ld}     = 5'b10_1_0_0;
                  else
                     {pc_sel, pc_ld, pc_inc, ir_ld}     = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 5'h00; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;                 
               end
            BNE:
               begin
               //Dump_Registers;
                  // control word assignments: ALU_OUT <-- 
                  //RS($rs) - RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sub_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = BNE2;                 
               end
            BNE2:
               begin
                  // control word assignments: PC <--
                  //PC + signext(IR[15:0])<<2
                  @(negedge clk)
                  if(psz == 1'b0)
                     {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b10_1_0_0;
                  else
                     {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 5'h00;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;                 
               end
            BLEZ:
               begin
                  // control word assignments: ALU_OUT <-- 
                  //RS($rs) - RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sub_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = BLEZ_2;                 
               end
            BLEZ_2:
               begin
                  // control word assignments: RS($rs) <= 0 ? PC <- PC+s_ext(IR[15:0] << 2
                  @(negedge clk)
                  if(psn == 1 || psz == 1)
                     {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b10_1_0_0;
                  else
                     {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 0; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;                 
               end
            BGTZ:
               begin
                  // control word assignments: ALU_OUT <-- 
                  //RS($rs) - RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sub_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = BGTZ_2;                 
               end
            BGTZ_2:
               begin
                  // control word assignments: RS($rs) >= 0 ? PC <- PC+s_ext(IR[15:0] << 2
                  @(negedge clk)
                  if(psn == 0 || psz == 1)
                     {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b10_1_0_0;
                  else
                     {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 0; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;                 
               end
            ORI:
               begin
                  // control word assignments: ALU_OUT <-- 
                  //RS($rs) | {16'h0, RT[15:0]}
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_01_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = ori_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_IMM;                 
               end
            LUI:
               begin
                  // control word assignments: ALU_OUT <-- {RT[15:0], 16'h0}
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_01_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = lui_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_IMM;                  
               end
            ADDI:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) + RT(se_16)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = add_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = WB_IMM; 
               end
            SRL:
               begin
                  // control word assignments: ALU_OUT <-- RT($rt) >> shamt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = srl_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, psv, n, z};
                  state   = WB_ALU;                  
               end
             SRA:
               begin
                  // control word assignments: ALU_OUT <-- RT($rt) >> shamt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sra_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, psv, n, z};
                  state   = WB_ALU;                  
               end
            SLL:
               begin
                  // control word assignments: ALU_OUT <-- RT($rt) << shamt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sll_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, psv, n, z};
                  state   = WB_ALU;                  
               end
            SLT:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) < RT($rt) ? 1'b1: 1'b0
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = slt_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_ALU;                  
               end
            SLTI:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) < RT($rt_se_16) ? 1'b1: 1'b0
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = slt_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_IMM;                  
               end
            SLTIU:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) < RT($rt_se_16) ? 1'b1: 1'b0
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sltu_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_IMM;                  
               end
            SLTU:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) < RT($rt) ? 1'b1: 1'b0
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sltu_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, n, z};
                  state   = WB_ALU;                  
               end
            SW:
               begin
                  // control word assignments: ALU_OUT <-- 
                  // RS($rs) + RT(se_16), RT <-- $rt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = add_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = WB_MEM;
               end
            LW:
               begin
                  // control word assignments: ALU_OUT <-- 
                  // RS($rs) + RT(se_16), RT <-- $rt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = add_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = LW_2;
               end
            LW_2:
               begin
                  // control word assignments: D_in <-- 
                  // M[ALU_Out]
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_1_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = add_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = WB_DIN;
               end
            J:
               begin
                  // control word assignments: PC <- PC + signext(IR[25:0]) << 2
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b01_1_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_100;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            JAL:
               begin
                  // control word assignments: PC <- PC + signext(IR[25:0]) << 2
                  // R[$31(ra)] <- PC
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b01_1_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_10_00_0_100;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            JR:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = JR2;
               end
            JR2:
               begin
                  // control word assignments: PC_Out <-- ALU_Out($rs)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b11_1_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 5'h0; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            INPUT:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) + sign_ext(RT($rt))
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = add_;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = INPUT_2;
               end
            INPUT_2:
               begin
                  // control word assignments: D_IN <-- IOMem[ALU_OUT]
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b1_1_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = WB_DIN;
               end
            OUTPUT:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) + sign_ext(RT($rt))
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = add_;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state   = OUTPUT_2;
               end
            OUTPUT_2:
               begin
                  // control word assignments: IOMem[ALU_OUT] <-- D_IN
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b1_0_1;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            //SIMD Instruction Execution states
            SLL_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RT($rt) << shamt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sll_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU;                  
               end
            SRL_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RT($rt) >> shamt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = srl_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU;                  
               end
             SRA_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RT($rt) >> shamt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = sra_; 
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU;                  
               end
            ROTL_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RT($rt) << shamt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = rotl_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU;
               end
            ROTR_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RT($rt) >> shamt
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = rotr_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU;
               end
            ADD_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) + RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = add_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU_SIMD;
               end
             SUB_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) - RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = sub_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU_SIMD;
               end
            XOR_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) ^ {16'h0, RT($rt[15:0])}
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = xor_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU_SIMD;
               end
            AND_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) & RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = and_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU_SIMD;
               end
            OR_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- RS($rs) | RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = or_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU_SIMD;
               end
            NOR_SIMD:
               begin
                  // control word assignments: ALU_OUT <-- ~(RS($rs) | RT($rt))
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = nor_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = WB_ALU_SIMD;
               end
            MULT_SIMD:
               begin
                  // control word assignments: {Hi,Lo} <-- RS($rs) * RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_1_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = mul_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = FETCH;
               end
            DIV_SIMD:
               begin
                  // control word assignments: {Hi} <-- RS($rs) / RT($rt)
                  // {Lo} <-- RS($rs) % RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_1_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = div_;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, z};
                  state   = FETCH;
               end
            //END of SIMD Instructions
            WB_ALU_SIMD:
               begin
                  // control word assignments: R[rd] <-- ALU_OUT
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_01_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            WB_DIN:
               begin
                  // control word assignments: RT[$rt] <-- D_IN[M[ALU_Out]] 
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_00_00_0_011;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            WB_ALU:
               begin
                  // control word assignments: R[rd] <-- ALU_OUT
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_01_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            WB_IMM:
               begin
                  // control word assignments: R[rt] <-- ALU_OUT
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_00_01_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            WB_MEM:
               begin
                  // control word assignments for 
                  // M[ALU_OUT($rs + se_16)] <-- RT($rt)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_0_1;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
            BREAK:
               begin
                  $display("BREAK INSTRUCTION FETCHED %t", $time);
                  //control word assignments for "deasserting" everything
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  
                  $display(" REGISTERS AFTER BREAK");
                  $display("  ");
                  Dump_Registers; // task to output MIPs RegFile
                  $display("  ");
                  $display(" MEMORY AFTER BREAK");
                  Dump_Mems;
                  $finish;
               end
            ILLEGAL_OP:
               begin
                  $display("ILLEGAL OPCODE FETCHED %t", $time);
                  //control word assignments for "deasserting" everything
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  
                  $display(" REGISTERS AFTER ILLEGAL OPCODE");
                  $display("  ");
                  Dump_Registers;
                  $display("  ");
                  $display(" PC AND IR AFTER ILLEGAL OPCODE");
                  $display("  ");
                  Dump_PC_and_IR;
                  $finish;
               end
            INTR_1:
               begin
                  $display("Interrupt");
                  // PC gets address of interrupt vector; Save PC in $ra
                  // control word assignments: RS <-- R[$sp], R[$ra] <-- PC
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_10_00_0_100;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b1_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = INTR_2;
               end
            INTR_2:
               begin
                  // Pass $sp from RS to ALU_OUT;
                  // control word assignments: ALU_OUT <-- RS($sp)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b1_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = INTR_3;
               end
            INTR_3:
               begin
                  // Read address of ISR into D_in;
                  // control word assignments: D_in <-- dM[ALU_OUT(0x3FC)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_1_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b0;                    FS = 5'h0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = INTR_4;
               end
            INTR_4:
               begin
                  // Load PC with M[$sp], pre-decrement $sp. prepare PUSH
                  // control word assignments: PC <-- D_in(dM[$sp]),
                  //                           ALU_OUT <-- ALU_OUT - 4,
                  //                           RT <-- PC
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b11_1_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_10_0_011;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  int_ack = 1'b0;                    FS = dec4_;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = INTR_5;
               end
            INTR_5:
               begin
                  // DM[$SP-4] <-- RT(PC)
                  // ALU_OUT <-- ALU_OUT($SP-4)-4;
                  // RT <-- flags
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_11_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_0_1;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  int_ack = 1'b0;                    FS = dec4_;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = INTR_6;
               end
            INTR_6:
               begin
                  // DM[ALU_OUT($SP-8)] <-- RT(flags)
                  // R[$SP] <-- ALU_OUT($SP-8)
                  // int_ack <-- 1'b1;
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_11_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_0_1;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  int_ack = 1'b1;                    FS = 0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {1'b0, psc, psv, psn, psz};
                  state   = FETCH;
               end
               
            RETI:
               begin
                  // ALU_OUT <- RS($SP)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = RETI_2;
               end
            RETI_2:
               begin
                  // D_IN <- DM[ALU_OUT[$SP]]
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_1_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = RETI_3;
               end
            RETI_3:
               begin
                  // ALU_OUT <-- ALU_OUT($sp) + 4
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = inc4_;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {sp_inFlags};
                  state   = RETI_4;
               end
            RETI_4:
               begin
                  // D_IN <-- DM[ALU_OUT($sp+4)]
                  // ALU_OUT <-- ALU_OUT($sp+4)+4
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b1_1_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = inc4_;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = RETI_5;
               end
            RETI_5:
               begin
                  // PC <-- D_IN(PC)
                  // ALU_OUT <-- ALU_OUT($sp+8)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b11_1_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b0_00_00_0_011;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_1;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = RETI_6;
               end
            RETI_6:
               begin
                  // R[$SP] <-- ALU_OUT($sp+8)
                  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
                  {D_En, DA_sel, T_sel, HILO_ld, Y_sel} = 9'b1_11_00_0_000;
                  {dm_cs, dm_rd, dm_wr}                 = 3'b0_0_0;
                  {io_cs, io_rd, io_wr}                 = 3'b0_0_0;
                  int_ack = 1'b0;                    FS = 0;
                  {sp_sel, s_sel}                       = 2'b0_0;
                  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state   = FETCH;
               end
         endcase // end of FSM logic              
   
   //Implements a reusable code to display contents of the 32x32 array registers.
   task Dump_Registers;
      for(i = 0; i<16; i = i + 1) begin
            $display("Time =%t: REG_ADDR[%h] = %h || REG_ADDR[%h] = %h",
            $time, i[4:0],       Top_tb.cpu.IDP.uut1.RegFile[i],
                   i[4:0]+5'd16, Top_tb.cpu.IDP.uut1.RegFile[i+16]);
         end
   endtask
   
   //Implements a reusable code to display contents of the PC and IR registers.
   task Dump_PC_and_IR;
      begin
         $display("PC = %h --- IR = %h",
                   Top_tb.cpu.IU.pc.PC_Out, Top_tb.cpu.IU.IR.q);
      end
   endtask
   
   //Implements a reusable code to display contents in Memory.
   task Dump_Mem;
      for(i = 9'h0C0; i < 9'h100; i = i + 4) begin
         $display("Time =%t: DM[%h] = %h",
                  $time, i[11:0], {Top_tb.dMEM.mem[i],
                                   Top_tb.dMEM.mem[i+1],
                                   Top_tb.dMEM.mem[i+2],
                                   Top_tb.dMEM.mem[i+3]});
      end
   endtask
   
   //Implements a reusable code to display contents
   //in IO and Data Memories.
   task Dump_Mems;
   begin
      for(i = 9'h0C0; i < 9'h100; i = i + 4) begin
         $display("Time =%t: DM[%h] = %h || IOM[%h] = %h",
                  $time, i[11:0], {Top_tb.dMEM.mem[i],
                                   Top_tb.dMEM.mem[i+1],
                                   Top_tb.dMEM.mem[i+2],
                                   Top_tb.dMEM.mem[i+3]},
                         i[11:0], {Top_tb.io.mem[i],
                                   Top_tb.io.mem[i+1],
                                   Top_tb.io.mem[i+2],
                                   Top_tb.io.mem[i+3]},);
      end
      $display("DM[3f0] = %h",    {Top_tb.dMEM.mem[12'h3F0],
                                   Top_tb.dMEM.mem[12'h3F1],
                                   Top_tb.dMEM.mem[12'h3F2],
                                   Top_tb.dMEM.mem[12'h3F3]});
                                   
      $display("DM[3f8] = %h",    {Top_tb.dMEM.mem[12'h3F8],
                                   Top_tb.dMEM.mem[12'h3F9],
                                   Top_tb.dMEM.mem[12'h3FA],
                                   Top_tb.dMEM.mem[12'h3FB]});
                                   
      /*$display("DM[3fC] = %h",    {Top_tb.dMEM.mem[12'h3FC],
                                   Top_tb.dMEM.mem[12'h3FD],
                                   Top_tb.dMEM.mem[12'h3FE],
                                   Top_tb.dMEM.mem[12'h3FF]});*/
                                   
   end
   endtask
   
   
endmodule
