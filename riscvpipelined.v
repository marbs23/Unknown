module riscvpipelined(input  clk, reset,
                       output [31:0] PC,
                       input  [31:0] InstrF,
                       output MemWrite,
                       output [31:0] DataAdr, 
                       output [31:0] WriteData,
                       input  [31:0] ReadData);
    wire        ALUSrcE, PCSrcE;
    wire IsFpD;
    wire [1:0] FpOpD;
    wire IsFpE;
    wire [2:0]  ALUControlE;
    wire [1:0]  ImmSrcD;
    wire [1:0]  ResultSrcE;     // ⭐ CAMBIO 1: De wire a wire [1:0]
    wire [1:0] ResultSrcW;
    wire        RegWriteM, RegWriteW, MemWriteM;
    wire        ZeroE;
    wire [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;
    wire [1:0] ForwardAE, ForwardBE;
    wire       StallF, StallD, FlushD, FlushE;  
    wire [31:0] ALUResultM, WriteDataM;                  
    wire [31:0] InstrD;
    
    controller c(
        .clk(clk),
        .reset(reset),
        .FlushE(FlushE),
        .InstrD(InstrD), 
        .ZeroE(ZeroE),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .MemWriteM(MemWriteM),
        .RegWriteM(RegWriteM), 
        .PCSrcE(PCSrcE),
        .ImmSrcD(ImmSrcD),
        .ALUSrcE(ALUSrcE), 
        .ALUControlE(ALUControlE),
        .ResultSrcE(ResultSrcE),    // ⭐ CAMBIO 2: De .ResultSrcEb0 a .ResultSrcE
        .IsFpD(IsFpD),
        .FpOpD(FpOpD)
    ); 
    
    datapath dp(
        .clk(clk), 
        .reset(reset),
        .PCF(PC),
        .InstrF(InstrF),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .ReadDataM(ReadData),
        .ALUSrcE(ALUSrcE),
        .ALUControlE(ALUControlE),
        .RegWriteW(RegWriteW), 
        .ResultSrcW(ResultSrcW), 
        .PCSrcE(PCSrcE),
        .ImmSrcD(ImmSrcD),
        .ZeroE(ZeroE), 
        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .RdM(RdM),
        .RdW(RdW),
        .InstrD(InstrD),
        .IsFpD(IsFpD),
        .FpOpD(FpOpD),
        .IsFpE(IsFpE)     
    );
    
    HazardUnit Hazard(
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .RdM(RdM),
        .RdW(RdW),
        .PCSrcE(PCSrcE),
        .ResultSrcE(ResultSrcE),    // ⭐ Sin cambios aquí, pero ahora recibe [1:0]
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .IsFpE(IsFpE),
        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE)     
    );
    
    assign MemWrite = MemWriteM;
    assign DataAdr  = ALUResultM;
    assign WriteData= WriteDataM;
   
endmodule