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
    input         IsFpD,
    input  [1:0]  FpOpD,
    output        ZeroE,
    output [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    output IsFpE
);
  
    localparam WIDTH = 32; // Define a local parameter for bus width
    
    wire [31:0] PCNext, PCPlus4F, PCTargetE;
    wire [31:0] InstrE, InstrM, InstrW;
    
    
    flopenrc #(32) pcreg(
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
    .d0(PCPlus4F), 
    .d1(PCTargetE), 
    .s(PCSrcE), 
    .y(PCNext)
    );

    // IM_RF
    // Aqu� est� la l�gica de la primera fase

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
    assign Rs2D = InstrD[24:20];
    wire [4:0] A1 = InstrD[19:15];
    wire [4:0] A2 = InstrD[24:20];
    wire [4:0] RdD = InstrD[11:7];
    wire [31:0] RD1D;
    wire [31:0] RD2D;
    wire [31:0] ResultW;
    regfile     rf(
        .clk(clk), 
        .we3(RegWriteW), 
        .a1(A1), 
        .a2(A2), 
        .a3(RdW), 
        .wd3(ResultW), 
        .rd1(RD1D), 
        .rd2(RD2D)
    ); 
    wire [24:0] instr_ext = InstrD[31:7];
    wire [31:0] ImmExtD;
    extend      ext(
        .instr(instr_ext), 
        .immsrc(ImmSrcD),
         .opcode(InstrD[6:0]),
        .immext(ImmExtD)
    ); 
    wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;

    wire [1:0]  FpOpE; //NUEVO
    ID_EX #(32+32+32+5+5+5+32+32+32+1+2) idtoex(  // +1+2 bits
    .clk(clk),
    .reset(reset),
    .en(1'b1),
    .clr(FlushE),
    .d({RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D, InstrD, IsFpD, FpOpD}), // 👈 NUEVO
    .q({RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E, InstrE, IsFpE, FpOpE})  // 👈 NUEVO
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
    
    wire [31:0] FPResultE;
    wire        FPValidE;
    alu_fp      alu_fp_u(
        .op_a    (SrcAE),      // usamos operandos ya forwardeados
        .op_b    (SrcBE),
        .op_code (FpOpE),      // 2 bits: 00 add, 01 sub, 10 mul, 11 div
        .clk     (clk),
        .rst     (reset),
        .start   (1'b1),       // tu diseño no lo usa, siempre combinacional
        .mode_fp (1'b0),       // 0 = FP32
        .result  (FPResultE),
        .flags   (),           // ignoramos flags por ahora
        .valid_out(FPValidE)   // siempre 1 en tu diseño
    );
    wire [31:0] EXResultE;
    assign EXResultE = IsFpE ? FPResultE : ALUResultE;
    
    wire [31:0] PCPlus4M;
    EX_MEM #(32+32+5+32+32) extomem (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clr(1'b0),
        .d({EXResultE, WriteDataE, RdE, PCPlus4E,InstrE}),
        .q({ALUResultM, WriteDataM, RdM, PCPlus4M,InstrM}) 
    
    );
    // MEM_WB
    wire [31:0] PCPlus4W, ALUResultW, ReadDataW;
    MEM_WB #(32+5+32+32+32) memtowb(
    .clk(clk),
    .reset(reset),
    .en(1'b1),
    .clr(1'b0),
    .d({ALUResultM, RdM, PCPlus4M, ReadDataM, InstrM}),
    .q({ALUResultW, RdW, PCPlus4W, ReadDataW, InstrW})
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