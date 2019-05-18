`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Data_Memory.v
 * Project:    Lab_Assignment_5
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.1
 * Rev. Date:  03/09/2019
 *
 * Purpose: A 4096 x 8 array register. 
 * Memory module that recieves a 32 bit input for address and a 32 bit input for
 * its data input. This module has a 32 bit output for the data at the specificed
 * address. There are three status signals that indicate what the memory module 
 * should do. DM_CS flag functions as a chip select that activates the Memory
 * Module. The DM_WR flag allows the memory module to be written to given the 
 * input address and data. The DM_RD flag allows the module to read the data 
 * at the given address and outputs the data at that memory location.
 *
 * Notes: 
 ****************************************************************************/
module Data_Memory(clk, Addr, D_in, dm_cs, dm_wr, dm_rd, D_out);

   input             clk, dm_cs, dm_wr, dm_rd;
   input      [11:0] Addr;        //Starting Address for memory access
   input      [31:0] D_in;        //Data Input
   output     [31:0] D_out;       //Data Output

   reg         [7:0] mem [4095:0];//4096 by 8 Memory Register

   //Sequential Block. When Chip Select and Write flags are enable
   //Write to the Memory Register starting at the given address for 4 bytes
   always@(posedge clk)
      if(dm_cs == 1'b1 && dm_wr == 1'b1)
         {mem[Addr], mem[Addr + 1], mem[Addr + 2], mem[Addr + 3]} <= D_in;
      else
         {mem[Addr], mem[Addr + 1], mem[Addr + 2], mem[Addr + 3]} <=
         {mem[Addr], mem[Addr + 1], mem[Addr + 2], mem[Addr + 3]};
   
   //Continuous Assignment that assigns the 32 bit output based on cs and rd flags
   //The data at the four memory locations specified by the memory address is output
   //Else the output is High Impedence
   assign D_out = (dm_cs == 1'b1 && dm_rd == 1'b1) ? 
                  {mem[Addr], mem[Addr + 1], mem[Addr + 2], mem[Addr + 3]} : 32'bZ;
         
endmodule
