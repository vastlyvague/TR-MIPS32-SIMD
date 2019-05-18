`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  IO_MEM.v
 * Project:    Final_Project
 * Designer:   Thomas Nguyen and Reed Ellison
 * Email:      tholinngu@gmail.com and notwreed@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  04/10/2019
 *
 * Purpose: A 4096 x 8 array register. 
 * Input/Output module that recieves a 32 bit input for address and a 32 bit input for
 * its data input. This module has a 32 bit output for the data at the specificed
 * address. There are three status signals that indicate what the memory module 
 * should do. IO_CS flag functions as a chip select that activates the Memory
 * Module. The IO_WR flag allows the memory module to be written to given the 
 * input address and data. The IO_RD flag allows the module to read the data 
 * at the given address and outputs the data at that memory location.
 * The IO Memory Module has additional Interrupt Signals to allow for
 * the CPU to be interrupted and then execute IO Instructions
 *
 * Notes: 
 ****************************************************************************/
module IO_MEM(clk,cs,wr,rd,inta,addr,in,intr,out);
   
   input        clk, inta; //Clock, Interrupt Acknowledge
   input        cs, wr, rd;//Chip Select, Write Select, Read Select
   
   input [11:0] addr;      //Address for Accessing Memory
   
   input [31:0] in;        //Input Data to Memory Module
   
   output intr;            //Interrupt Request
   reg intr;
   
   output [31:0] out;      //Output of Memory Module
   wire [31:0] out;
   
   reg [7:0] mem [0:4095]; //Array for Memory
   
   //Initial Block to Have the IO Subsystem
   //Output an Interrupt Request after
   //a Discrete Amount of Time to Check Interrupt
   //Functionality is accurate
   initial 
   begin
      intr = 0;
      #200;
      intr = 1;
      @(posedge inta)
         intr = 0;
   end
   
   //Output of IO Mem Module is based on address input only when 
   //Chip Select and RD Signals are active and WR is inactive
   //Otherwise, the output is High Impedance
   assign out = (cs & !wr & rd)? {mem[addr+0], mem[addr+1],
                                  mem[addr+2], mem[addr+3]}:
                                  32'hz;
         
   //Input Data to IO Memory when CS and WR are active
   //Otherwise, Data at the Addresses remain the same
   always@ (posedge clk)
      begin
         if(cs & wr & !rd)
            {mem[addr+0], mem[addr+1],
             mem[addr+2], mem[addr+3]} <= in;
         else
            {mem[addr+0], mem[addr+1],
             mem[addr+2], mem[addr+3]} <=
            {mem[addr+0], mem[addr+1],
             mem[addr+2], mem[addr+3]};
      end
   
   
endmodule
