module datapath(
    input  clk, reset,
    output [31:0] PCF,
    input  [31:0] InstrF,
    output [31:0] InstrD,
    output [31:0] ALUResultM, WriteDataM,
    input  [31:0] ReadDataM,
    input         ALUSrcE,  
    input  [2:0]  ALUControlE,
    input         RegWriteW,
    input  [1:0]  ResultSrcW,
    input         PCSrcE,
    input         StallF, StallD, FlushD, FlushE, 
    input  [1:0]  ForwardAE, ForwardBE, 
    input  [1:0]  ImmSrcD,
    output        ZeroE,
    output [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW
);
  
    localparam WIDTH = 32; // Define a local parameter for bus width
    
    wire [31:0] PCNext, PCPlus4F, PCTargetE;
    wire [31:0] InstrE, InstrM, InstrW;
    
    
    flopr #(32) pcreg(
    .clk(clk), 
    .reset(reset),
    .clr(1'b0),
    .en(~StallF), 
    .d(PCNext), 
    .q(PCF)
    );
     
    adder       pcadd4(
        .a(PCF), 
        .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
        .y(PCPlus4F)
    ); 

    mux2 #(WIDTH)  pcmux(
        .d0(PCPlus4), 
        .d1(PCTargetE), 
        .s(PCSrcE), 
        .y(PCNext)
    );
    
    flopenrc pccontrol(
        .clk(clk),
        .reset(reset),
        .en(~StallF),
        .clr(1'b0),
        .d({PCF}),
        .q()
    );
    // IM_RF
    // Aquí está la lógica de la primera fase

    wire [31:0] PCD, PCPlus4D;
    IF_ID #(32+32+32) iftoid (
        .clk(clk),
        .reset(reset),
        .en(~StallD),
        .clr(FlushD),
        .d({InstrF, PCF, PCPlus4F}),
        .q({InstrD, PCD, PCPlus4D})
    );
    
    // RF_EX
     
 
  // register file logic
  
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[25:20];
    wire [4:0] rdD = InstrD[11:7];
    wire [31:0] RD1D, RD2D;
    wire ResultW;
    regfile     rf(
        .clk(~clk), 
        .we3(RegWriteW), 
        .a1(Rs1D), 
        .a2(Rs2D), 
        .a3(RdW), 
        .wd3(ResultW), 
        .rd1(RD1D), 
        .rd2(RD2D)
    ); 
    wire instr_ext = InstrD[31:7];
    wire [31:0] ImmExtD;
    extend      ext(
        .instr(instr_ext), 
        .immsrc(ImmSrcD), 
        .immext(ImmExtD)
    ); 
    wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
    ID_EX #(32+32+32+5+5+5+32+32+32) idtoex(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clr(FlushE),
        .d({RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D, InstrD}),
        .q({RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E, InstrE}) 
    );

    //EX To MEM
    wire [31:0] SrcAE;
    mux3 #(WIDTH)  mux1(
        .d0(RD1E), 
        .d1(ResultW), 
        .d2(ALUResultM), 
        .s(ForwardAE), 
        .y(SrcAE)
    );
    wire [31:0] WriteDataE;
    mux3 #(WIDTH)  mux2(
        .d0(RD2E), 
        .d1(ResultW), 
        .d2(ALUResultM), 
        .s(ForwardBE), 
        .y(WriteDataE)
    );
    wire [31:0] SrcBE;
    mux2 #(WIDTH) mux3(
        .d0(WriteDataE),
        .d1(ImmExtE),
        .s(ALUSrcE),
        .y(SrcBE)    
    );
    
    adder       pcaddbranch(
        .a(PCE), 
        .b(ImmExtE), 
        .y(PCTargetE)
    ); 
  // ALU logic
     
    wire [31:0] ALUResultE;
    alu         alu(
        .a(SrcAE), 
        .b(SrcBE), 
        .alucontrol(ALUControlE), 
        .result(ALUResultE), 
        .zero(ZeroE)
    ); 
    wire [31:0] PCPlus4M;
    EX_MEM #(32+32+5+32+32) extomem (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clr(1'b0),
        .d({ALUResultE, WriteDataE, RdE, PCPlus4E,InstrE}),
        .q({ALUResultM, WriteDataM, RdM, PCPlus4M,InstrM}) 
    
    );
    // MEM_WB
    wire [31:0] PCPlus4W, ALUResultW, ReadDataW;
    MEM_WB #(32+5+32+32+32) memtowb(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clr(1'b0),
        .d({AluResultM, RdM, PCPLus4M, ReadDataM, InstrM}),
        .q({AluResultW, RdW, PCPlus4W, ReadDataW, InstrW})
    );
    //WB Final
    mux3 #(WIDTH)  resultmux(
        .d0(ALUResultW), 
        .d1(ReadDataW), 
        .d2(PCPlus4W), 
        .s(ResultSrcW), 
        .y(ResultW)
    ); 
endmodule
