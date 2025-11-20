module controller (
        input clk,
        input reset,
        input [31:0] InstrD, 
        input ZeroE,
        output RegWriteW,
        output [1:0] ResultSrcW,
        output MemWriteM,
        output  RegWriteM, 
        output PCSrcE,
        output [1:0] ImmSrcD,
        output ALUSrcE, 
        output [2:0] ALUControlE,
        output ResultSrcE
    ); 
    wire [6:0] op = InstrD[6:0];
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
    
    // ID_EX
    wire RegWriteE, MemWriteE, JumpE, BranchE;

    
    flopenrc #(1+2+1+1+1+3+1) regCtrlDtoE (
    .clk(clk),
    .reset(reset),
    .en(1'b1),          // fjdfjdjfa;ojd DUDAAAA
    .clr(FlushE),       
    .d({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD}),
    .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE})
    );
    
    assign PCSrcE = JumpE | (BranchE & ZeroE);
    aludec  ad(
        .funct3(funct3), 
        .funct7b5(funct7b5), 
        .ALUOp(ALUOp), 
        .ALUControl(ALUControlE)
    );
    
    // EX_MEM
    wire [1:0] ResultSrcM;
    
    flopenrc #(1+2+1) regCtrlEtoMEM (
    .clk(clk),
    .reset(reset),
    .en(1'b1),          // fjdfjdjfa;ojd DUDAAAA
    .clr(1'b0),       
    .d({RegWriteD, ResultSrcE, MemWriteE}),
    .q({RegWriteM, ResultSrcM, MemWriteM})
    );
    
    // MEM_WB
    
    flopenrc #(1+2) regCtrlMEMtoWB (
    .clk(clk),
    .reset(reset),
    .en(1'b1),          // fjdfjdjfa;ojd DUDAAAA
    .clr(1'b0),       
    .d({RegWriteM, ResultSrcM}),
    .q({RegWriteW, ResultSrcW})
    ); 
    
    

endmodule