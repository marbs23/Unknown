module maindec(input  [6:0] op,
               output [1:0] ResultSrc,
               output MemWrite,
               output Branch, ALUSrc,
               output RegWrite, Jump,
               output [1:0] ImmSrc, 
               output [1:0] ALUOp); 
  
  reg [10:0] controls; 

  // RegWrite ImmSrc ALUSrc MemWrite ResultSrc Branch ALUOp Jump
  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls; 

  always @* case(op)
      // Instrucciones enteras básicas
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      7'b1100111: controls = 11'b1_00_0_0_10_0_00_1; // jalr
      7'b0110111: controls = 11'b1_11_1_0_00_0_00_0; // LUI

      // Operaciones FP aritméticas (FADD.S, FSUB.S, FMUL.S, FDIV.S)
      // ResultSrc = 00 → resultado de ALU/FPU
      7'b1010011: controls = 11'b1_00_0_0_00_0_11_0; // FP R-type

      // FLW (Float Load Word) - opcode 0000111
      // Similar a LW pero para registros FP
      7'b0000111: controls = 11'b1_00_1_0_01_0_00_0; // flw
      
      // FSW (Float Store Word) - opcode 0100111  
      // Similar a SW pero para registros FP
      7'b0100111: controls = 11'b0_01_1_1_00_0_00_0; // fsw

      default:    controls = 11'b0_xx_0_0_xx_0_xx_0;
    endcase
endmodule