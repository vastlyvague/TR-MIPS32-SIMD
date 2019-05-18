`timescale 1ns / 100ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Top_Level_tb.v
 * Project:    Lab_Assignment_6
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.2
 * Rev. Date:  03/12/2019
 *
 * Purpose: Instantiate Instruction_Unit, Integer_Datapath,
 * Data_Memory, and Control Unit. Interconnect the four instantiated modules. 
 * Instruction Unit Output(IR_Out) becomes the data input to the 
 * Integer Datapath. The two outputs of the Integer Datapath are
 * then used in the Data Memory and fed back into the
 * Instruction Unit. The control signals are supplied the control unit.
 *
 * Notes: 
 * 
 ****************************************************************************/
module Top_Level_tb;

	//Inputs
	reg         clk, rst, intr;
   
   wire        PC_Ld, PC_Inc;
   wire  [1:0] PC_Sel;
	wire        IR_Ld;
   
	wire        IM_Cs,IM_Wr,IM_Rd;     //Instruction Memory and Data memory's
   wire        dm_cs, dm_wr, dm_rd;   //Chip select, write and read enable
   
   //Write enable, HILO load and Mux Select for IDP
   wire        D_En, HILO_ld, T_Sel;
   wire  [1:0] DA_Sel;
   wire  [2:0] Y_Sel;
   
   wire  [4:0] FS;
   
	//Outputs
   wire        C, V, N, Z;            //Status Flags   
   wire [31:0] ALU_OUT, D_OUT;        //Outputs from IDP
   wire [31:0] dMemToDY;              //Output of dMEM
   wire [31:0] PC_Out;                //Program Counter Out
	wire [31:0] IR_Out;                //Instruction Register Out
	wire [31:0] SE_16;                 //Sign Extended 16-bits
   
   integer     i;

	// Instantiate the Units Under Test (UUT)
	Instruction_Unit   IU(.clk(clk),           .rst(rst),            .PC_Ld(PC_Ld), 
                         .PC_Inc(PC_Inc),     .IM_Cs(IM_Cs),        .IM_Wr(IM_Wr), 
                         .IM_Rd(IM_Rd),       .IR_Ld(IR_Ld),        .PC_In(ALU_OUT), 
                         .PC_Out(PC_Out),     .IR_Out(IR_Out),      .SE_16(SE_16),
                         .PC_Sel(PC_Sel));
                           
   Integer_Datapath  IDP(.clk(clk),           .reset(rst),          .D_En(D_En), 
                         .HILO_ld(HILO_ld),   .T_Sel(T_Sel),        .Y_Sel(Y_Sel),
                         .PC_in(PC_Out),      .DY(dMemToDY),        .DT(SE_16),
                         .C(C),               .V(V),                .N(N),
                         .Z(Z),               .ALU_OUT(ALU_OUT),
                         .D_OUT(D_OUT),       .DA_Sel(DA_Sel),
                         .FS(FS), .shamt(IR_Out[10:6]),            .S_Addr(IR_Out[25:21]),
                         .T_Addr(IR_Out[20:16]),    .D_Addr(IR_Out[15:11]));
                       
   Data_Memory      dMEM(.clk(clk),           .Addr(ALU_OUT[11:0]), .D_in(D_OUT),
                         .dm_cs(dm_cs),       .dm_wr(dm_wr),        .dm_rd(dm_rd),
                         .D_out(dMemToDY));
                         
   Control_Unit       CU(.clk(clk),        .rst(rst),        .intr(intr),     
                         .c(C),            .n(N),            .z(Z),     .v(V),       
                         .IR(IR_Out),      .int_ack(int_ack),.pc_sel(PC_Sel), 
                         .pc_ld(PC_Ld),    .pc_inc(PC_Inc),  .ir_ld(IR_Ld), 
                         .im_cs(IM_Cs),    .im_rd(IM_Rd),    .im_wr(IM_Wr),   
                         .D_En(D_En),      .DA_sel(DA_Sel),  .T_sel(T_Sel), 
                         .HILO_ld(HILO_ld),.Y_sel(Y_Sel),    .dm_cs(dm_cs),  
                         .dm_rd(dm_rd),    .dm_wr(dm_wr),    .FS(FS));
   
   
   //Every time unit 5 is equal to 5 ns
   always #5 clk = ~clk;

	initial begin
		//Initialize Inputs
		{clk, rst, intr} = 3'b0_0_0;
      
      //Format how time is displayed and sets it to display in nanoseconds.
      $timeformat(-9, 1, " ns", 9);
      //Load contents of a .dat file into the Instruction Unit Memory
      //$readmemh("iMem_Lab6.dat", IU.IMEM.mem);
      $readmemh("iMem01_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem02_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem03_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem04_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem05_Sp19_commented.dat", IU.IMEM.mem);
 //     $readmemh("iMem06_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem07_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem08_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem09_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem10_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem11_Sp19_commented.dat", IU.IMEM.mem);
      //$readmemh("iMem12_Sp19_commented.dat", IU.IMEM.mem);
   //   $readmemh("iMem13_Sp19_commented.dat", IU.IMEM.mem);
      //Load contents of a .dat file into the data memory
      $readmemh("dMem01_Sp19.dat", Top_tb.dM.mem);
     // $readmemh("dMem06_Sp19.dat", dMEM.mem);
      //$readmemh("dMem07_Sp19.dat", dMEM.mem);
      //$readmemh("dMem08_Sp19.dat", dMEM.mem);
      //$readmemh("dMem09_Sp19.dat", dMEM.mem);
      //$readmemh("dMem10_Sp19.dat", dMEM.mem);
      //$readmemh("dMem11_Sp19.dat", dMEM.mem);
      //$readmemh("dMem12_Sp19.dat", dMEM.mem);
 //     $readmemh("dMem13_Sp19.dat", dMEM.mem);
      
      @(negedge clk)
         rst = 1;
      @(negedge clk)
         rst = 0;
	end
   
endmodule

