`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Top_tb.v
 * Project:    Final_Project
 * Designer:   Thomas Nguyen and Reed Ellison
 * Email:      tholinngu@gmail.com and notwreed@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  04/010/2019
 *
 * Purpose: Test Fixture to Implement our Top Level Design.
 * Instantiates CPU, IO Memory, and Data Memory Modules.
 * Interconnects the Memory Modules to the CPU to allow for
 * input from both memory modles. Data can also be transmitted
 * to both Memory Modules in order to access certain locations
 * of memory within the memory modules.
 *
 * Notes: 
 ****************************************************************************/
module Top_tb;

	// Inputs
	reg clk;                //Clock
	reg rst;                //Reset

	// Outputs
   wire intr;              //Interrupt Request
	wire inta;              //Interrupt Acknowledge
	wire dm_cs;             //Data Memory Chip Select
	wire dm_rd;             //Data Memory Read Select
	wire dm_wr;             //Data Memory Write Select
	wire io_cs;             //IO Memory Chip Select
	wire io_rd;             //IO Memory Read Select
	wire io_wr;             //IO Memory Write Select
   wire [31:0] mem_to_DY;  //Wire from Memory Output to DY Input of CPU
	wire [31:0] madr;       //Memory Address
	wire [31:0] idp;        //IDP Output

	CPU          cpu(.clk(clk),       .rst(rst),            .intr(intr),   
                    .inta(inta),     .dm_cs(dm_cs),        .dm_rd(dm_rd),
                    .dm_wr(dm_wr),   .io_cs(io_cs),        .io_rd(io_rd), 
                    .io_wr(io_wr),   .dMemtoDY(mem_to_DY),
                    .madr(madr),     .idp(idp));
   
   Data_Memory dMEM(.clk(clk),       .Addr(madr[11:0]),    .D_in(idp),
                    .dm_cs(dm_cs),   .dm_wr(dm_wr),        .dm_rd(dm_rd),
                    .D_out(mem_to_DY));
   
   IO_MEM        io(.clk(clk),       .cs(io_cs),           .wr(io_wr),
                    .rd(io_rd),      .inta(inta),          .addr(madr[11:0]),
                    .in(idp),        .intr(intr),          .out(mem_to_DY));
   
   //Initialize Clock
   always #5 clk = ~clk;

	initial begin
		//Initialize Inputs
		{clk, rst} = 2'b0_0;
      
      //Format how time is displayed and sets it to display in nanoseconds.
      $timeformat(-9, 1, " ns", 9);
      
      //Load contents of a .dat file into the Instruction Unit Memory
      
      //Memory Modules 1-12
      //$readmemh("iMem01_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem02_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem03_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem04_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem05_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem06_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem07_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem08_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem09_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem10_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem11_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem12_Sp19_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      
      //Memory Modules 13 and 14
      //$readmemh("iMem13_Sp19_w_isr_commented.dat", Top_tb.cpu.IU.IMEM.mem);
     // $readmemh("iMem14_Sp19_w_isr_commented.dat", Top_tb.cpu.IU.IMEM.mem);
      
      //New Enhancements
      //$readmemh("iMemEnhancements.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem14_Sp19_w_isr_commented1.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem15_Sp19_Vector.dat", Top_tb.cpu.IU.IMEM.mem);
      //$readmemh("iMem15_Sp19_Vector_2.dat", Top_tb.cpu.IU.IMEM.mem);
      $readmemh("iMem15_Sp19_Vector_3.dat", Top_tb.cpu.IU.IMEM.mem);

      
      //Load contents of a .dat file into the data memory
      //$readmemh("dMem01_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem02_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem03_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem04_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem05_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem06_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem07_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem08_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem09_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem10_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem11_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem12_Sp19.dat", Top_tb.dMEM.mem);
      //$readmemh("dMem13_Sp19.dat", Top_tb.dMEM.mem);
      $readmemh("dMem14_Sp19.dat", Top_tb.dMEM.mem);
      
      //Reset System
      @(negedge clk)
         rst = 1;
      @(negedge clk)
         rst = 0;

	end
      
endmodule

