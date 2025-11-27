module controller (
        input clk,
        input reset,
        input [31:0] InstrD, 
        input ZeroE,
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
        output IsFpD, // new
        output [1:0] FpOpD // new
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
    
assign FpOpD =
    (!IsFpD) ? 2'b00 :
    (funct7 == 7'b0000000) ? 2'b00 :
    (funct7 == 7'b0100000) ? 2'b01 : 
    (funct7 == 7'b0000001) ? 2'b10 :  
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
    
    // ID_EX
    wire RegWriteE, MemWriteE, JumpE, BranchE;
    // ⭐ NOTA: ResultSrcE ahora se declara implícitamente como output [1:0]
    
    flopenrc #(1+2+1+1+1+3+1) regCtrlDtoE (
        .clk(clk),
        .reset(reset),
        .en(1'b1),        
        .clr(FlushE),       
        .d({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD}),
        .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE})
    );
    
    assign PCSrcE = (JumpE) | (BranchE & ZeroE);
    
    wire opb5 = op[5];
    aludec ad(
        .opb5(opb5),
        .funct3(funct3), 
        .funct7b5(funct7b5), 
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
    
    // ⭐ CAMBIO 2: ELIMINAR esta línea
    // assign ResultSrcEb0 = ResultSrcE[0];  // ❌ YA NO SE NECESITA
    
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