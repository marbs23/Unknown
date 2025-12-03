module controller (
        input clk,
        input reset,
        input [31:0] InstrD, 
        input ZeroE,
        input LtE,         // ← 🆕 Less Than desde ALU
        input FlushE,
        output RegWriteW,
        output [1:0] ResultSrcW,
        output MemWriteM,
        output RegWriteM, 
        output PCSrcE,
        output [1:0] ImmSrcD,
        output ALUSrcE, 
        output [2:0] ALUControlE,
        output [1:0] ResultSrcE,
        output IsFpD,
        output [1:0] FpOpD,
        output JalrE,
        output [2:0] Funct3E  // ← 🆕 Para datapath
    ); 
    
    wire [6:0] op = InstrD[6:0];
    assign IsFpD = (op == 7'b1010011);
    wire [2:0] funct3 = InstrD[14:12];
    wire funct7b5 = InstrD[30];
    wire BranchD;
    wire ALUSrcD;
    wire RegWriteD;
    wire JumpD;
    wire [1:0] ALUOp; 
    wire [1:0] ResultSrcD;
    wire MemWriteD;
    wire [2:0] ALUControlD;
    wire [6:0] funct7 = InstrD[31:25];
    
    wire JalrD = (op == 7'b1100111);
    wire [2:0] Funct3D = funct3;
    
    assign FpOpD =
        (!IsFpD) ? 2'b00 :
        (funct7 == 7'b0000000) ? 2'b00 :
        (funct7 == 7'b0000100) ? 2'b01 :
        (funct7 == 7'b0001000) ? 2'b10 :
        (funct7 == 7'b0001100) ? 2'b11 :
        2'b00;
    
    maindec md(
        .op(op), 
        .ResultSrc(ResultSrcD), 
        .MemWrite(MemWriteD), 
        .Branch(BranchD),
        .ALUSrc(ALUSrcD), 
        .RegWrite(RegWriteD), 
        .Jump(JumpD), 
        .ImmSrc(ImmSrcD), 
        .ALUOp(ALUOp)
    ); 
    
    // ID_EX - ← 🆕 Propagar Funct3D
    wire RegWriteE, MemWriteE, JumpE, BranchE;
    
    flopenrc #(1+2+1+1+1+3+1+1+3) regCtrlDtoE (  // +3 bits para Funct3
        .clk(clk),
        .reset(reset),
        .en(1'b1),        
        .clr(FlushE),       
        .d({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD, JalrD, Funct3D}),
        .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE, JalrE, Funct3E})
    );
    
    // ← 🆕 LÓGICA DE BRANCH con múltiples tipos
    wire BranchTaken;
    assign BranchTaken = (Funct3E == 3'b000 && ZeroE) ||      // BEQ: rs1 == rs2
                         (Funct3E == 3'b001 && !ZeroE) ||     // BNE: rs1 != rs2
                         (Funct3E == 3'b100 && LtE) ||        // BLT: rs1 < rs2 (signed)
                         (Funct3E == 3'b101 && !LtE);         // BGE: rs1 >= rs2 (signed)
    
    assign PCSrcE = (JumpE) | (BranchE & BranchTaken);
    
    wire opb5 = op[5];
    aludec ad(
        .opb5(opb5),
        .funct3(funct3), 
        .funct7b5(funct7b5),
        .funct7(funct7),
        .ALUOp(ALUOp), 
        .ALUControl(ALUControlD)
    );
    
    // EX_MEM
    wire [1:0] ResultSrcM;
    
    flopenrc #(1+2+1) regCtrlEtoMEM (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clr(1'b0),
        .d({RegWriteE, ResultSrcE, MemWriteE}),
        .q({RegWriteM, ResultSrcM, MemWriteM})
    );
    
    // MEM_WB
    flopenrc #(1+2) regCtrlMEMtoWB (
        .clk(clk),
        .reset(reset),
        .en(1'b1),         
        .clr(1'b0),       
        .d({RegWriteM, ResultSrcM}),
        .q({RegWriteW, ResultSrcW})
    ); 
    
endmodule