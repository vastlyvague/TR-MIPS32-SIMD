`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MIPS_SIMD.v
 * Project:    SIMD MIPS
 * Designer:   Thomas Nguyen
 * Email:      tholinngu@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  04/18/2019
 *
 * Purpose: An SIMD version of the MIPS_32 module. This will do similar ALU
 * instructions outputting 32 bits in vectors.
 *          
 * Notes:
 * 
 ****************************************************************************/
module MIPS_SIMD(SIMD_Sel, S, T, FS, Y);
   input       [1:0] SIMD_Sel; //SIMD mode select
   input      [31:0] S, T;     //Inputs
   input       [4:0] FS;       //FS opcode
   output reg [31:0] Y;        //Output
   
   //Integers to store Inputs
   integer           int_S, int_T;
   
   parameter 
   //SIMD Modes
   SIMD8 = 2'b01,  SIMD16 = 2'b10,
   PASS_S = 5'h00, PASS_T = 5'h01,    
   //SIMD8
   ADD8 = 5'h02,   SUB8 = 5'h04,
   
   AND8 = 5'h08,   OR8 = 5'h09,    XOR8 = 5'h0a,    NOR8 = 5'h0b,
   SRL8 = 5'h0c,   SRA8 = 5'h0d,   SLL8 = 5'h0e,
   //SIMD16
   ADD16 = 5'h02,  SUB16 = 5'h04,
   AND16 = 5'h08,  OR16 = 5'h09,   XOR16 = 5'h0a,   NOR16 = 5'h0b,        

   //Other Operations
   INC_8 = 5'h0f,  INC4_8 = 5'h10, DEC_8 = 5'h11,   DEC4_8= 5'h12,
   INC_16 = 5'h0f, INC4_16 = 5'h10, DEC_16 = 5'h11, DEC4_16= 5'h12,
   ZEROS = 5'h13,  ONES = 5'h14;
             
   always@(S or T or FS or SIMD_Sel) begin
      int_S = S;
      int_T = T;
      case(SIMD_Sel)
         SIMD8: begin
            case(FS)
               PASS_S : Y = S;
               PASS_T : Y = T;
               ADD8   : begin
                           Y[7:0] = S[7:0] + T[7:0];
                           Y[15:8] = S[15:8] + T[15:8];
                           Y[23:16] = S[23:16] + T[23:16];
                           Y[31:24] = S[31:24] + T[31:24];
                        end
               SUB8   : begin
                           Y[7:0] = S[7:0] - T[7:0];
                           Y[15:8] = S[15:8] - T[15:8];
                           Y[23:16] = S[23:16] - T[23:16];
                           Y[31:24] = S[31:24] - T[31:24];
                        end
               AND8   : begin
                           Y[7:0] = S[7:0] & T[7:0];
                           Y[15:8] = S[15:8] & T[15:8];
                           Y[23:16] = S[23:16] & T[23:16];
                           Y[31:24] = S[31:24] & T[31:24];
                        end
               OR8    : begin
                           Y[7:0] = S[7:0] | T[7:0];
                           Y[15:8] = S[15:8] | T[15:8];
                           Y[23:16] = S[23:16] | T[23:16];
                           Y[31:24] = S[31:24] | T[31:24];
                        end
               XOR8   : begin
                           Y[7:0] = S[7:0] ^ T[7:0];
                           Y[15:8] = S[15:8] ^ T[15:8];
                           Y[23:16] = S[23:16] ^ T[23:16];
                           Y[31:24] = S[31:24] ^ T[31:24];
                        end
               NOR8   : begin
                           Y[7:0] = ~(S[7:0] | T[7:0]);
                           Y[15:8] = ~(S[15:8] | T[15:8]);
                           Y[23:16] = ~(S[23:16] | T[23:16]);
                           Y[31:24] = ~(S[31:24] | T[31:24]);
                        end
                               
               INC_8  : begin
                           Y[7:0] = S[7:0] + 1'b1;
                           Y[15:8] = S[15:8] + 1'b1;
                           Y[23:16] = S[23:16] + 1'b1;
                           Y[31:24] = S[31:24] + 1'b1;
                        end
               
               INC4_8 : begin
                           Y[7:0] = S[7:0] + 4;
                           Y[15:8] = S[15:8] + 4;
                           Y[23:16] = S[23:16] + 4;
                           Y[31:24] = S[31:24] + 4;
                        end
                        
               DEC_8  : begin
                           Y[7:0] = S[7:0] - 1'b1;
                           Y[15:8] = S[15:8] - 1'b1;
                           Y[23:16] = S[23:16] - 1'b1;
                           Y[31:24] = S[31:24] - 1'b1;
                        end
                        
               DEC4_8 : begin
                           Y[7:0] = S[7:0] - 4;
                           Y[15:8] = S[15:8] - 4;
                           Y[23:16] = S[23:16] - 4;
                           Y[31:24] = S[31:24] - 4;
                        end
               
               default: Y = S; //Default Pass_S
            endcase
         end //SIMD8 end
         SIMD16: begin
            case(FS)
               PASS_S : Y = S;
               PASS_T : Y = T;
               ADD16  : begin
                           Y[15:0] = S[15:0] + T[15:0];
                           Y[31:16] = S[31:16] + T[31:16];
                        end
               SUB16  : begin
                           Y[15:0] = S[15:0] - T[15:0];
                           Y[31:16] = S[31:16] - T[31:16];
                        end
               AND16  : begin
                           Y[15:0] = S[15:0] & T[15:0];
                           Y[31:16] = S[31:16] & T[31:16];
                        end
               OR16   : begin
                           Y[15:0] = S[15:0] | T[15:0];
                           Y[31:16] = S[31:16] | T[31:16];
                        end
               XOR16  : begin
                           Y[15:0] = S[15:0] ^ T[15:0];
                           Y[31:16] = S[31:16] ^ T[31:16];
                        end
               NOR16  : begin
                           Y[15:0] = ~(S[15:0] | T[15:0]);
                           Y[31:16] = ~(S[31:16] | T[31:16]);
                        end    
               INC_16 : begin
                           Y[15:0] = S[15:0] + 1'b1;
                           Y[31:16] = S[31:16] + 1'b1;
                        end
               INC4_16: begin
                           Y[15:0] = S[15:0] + 4;
                           Y[31:16] = S[31:16] + 4;
                        end
               DEC_16 : begin
                           Y[15:0] = S[15:0] - 1'b1;
                           Y[31:16] = S[31:16] - 1'b1;
                        end
               DEC4_16: begin
                           Y[15:0] = S[15:0] - 4;
                           Y[31:16] = S[31:16] - 4;
                        end
               
               default: Y = S; //Default Pass_S
            endcase
         end //SIMD16 end
         default: begin //Normal mode
               Y = S;
            end
         endcase        
      end //always end
         
endmodule
