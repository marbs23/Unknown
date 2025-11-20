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
    input  [2:0]  ImmSrcD,
    output        ZeroE,
    output [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW
);
  
    localparam WIDTH = 32; // Define a local parameter for bus width
    
    wire [31:0] PCNext, PCPlus4F, PCTargetE;
    
    flopr #(WIDTH) pcreg(
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
    adder       pcaddbranch(
        .a(PC), 
        .b(ImmExt), 
        .y(PCTarget)
    );  
 
  // register file logic
    regfile     rf(
        .clk(clk), 
        .we3(RegWrite), 
        .a1(Instr[19:15]), 
        .a2(Instr[24:20]), 
        .a3(Instr[11:7]), 
        .wd3(Result), 
        .rd1(SrcA), 
        .rd2(WriteData)
    ); 

    extend      ext(
        .instr(Instr[31:7]), 
        .immsrc(ImmSrc), 
        .immext(ImmExt)
    ); 

  // ALU logic
    mux2 #(WIDTH)  srcbmux(
        .d0(WriteData), 
        .d1(ImmExt), 
        .s(ALUSrc), 
        .y(SrcB)
     ); 

    alu         alu(
        .a(SrcA), 
        .b(SrcB), 
        .alucontrol(ALUControl), 
        .result(ALUResult), 
        .zero(Zero)
    ); 

    mux3 #(WIDTH)  resultmux(
        .d0(ALUResult), 
        .d1(ReadData), 
        .d2(PCPlus4), 
        .s(ResultSrc), 
        .y(Result)
    ); 
endmodule