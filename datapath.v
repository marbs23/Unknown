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
    input         JalrE,
    input  [2:0]  Funct3E,   // ← 🆕 Para determinar tipo de branch
    output        ZeroE,
    output        LtE,       // ← 🆕 Less Than
    output [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    output IsFpE
);
  
    localparam WIDTH = 32;
    
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
     
    adder pcadd4(
        .a(PCF), 
        .b({WIDTH{1'b0}} + 4),
        .y(PCPlus4F)
    ); 

    mux2 #(WIDTH) pcmux(
        .d0(PCPlus4F), 
        .d1(PCTargetE), 
        .s(PCSrcE), 
        .y(PCNext)
    );

    // IF_ID
    wire [31:0] PCD, PCPlus4D;
    IF_ID #(32+32+32) iftoid (
        .clk(clk),
        .reset(reset),
        .en(~StallD),
        .clr(FlushD),
        .d({InstrF, PCF, PCPlus4F}),
        .q({InstrD, PCD, PCPlus4D})
    );
    
    // ID Stage - Register File
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    wire [4:0] A1 = InstrD[19:15];
    wire [4:0] A2 = InstrD[24:20];
    wire [4:0] RdD = InstrD[11:7];
    wire [31:0] RD1D;
    wire [31:0] RD2D;
    wire [31:0] ResultW;
    
    regfile rf(
        .clk(~clk), 
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
    
    extend ext(
        .instr(instr_ext), 
        .immsrc(ImmSrcD),
        .opcode(InstrD[6:0]),
        .immext(ImmExtD)
    ); 
    
    // ID_EX - ← 🆕 Propagar Funct3D a Funct3E
    wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
    wire [1:0] FpOpE;
    wire [2:0] Funct3D;
    assign Funct3D = InstrD[14:12];
    
    ID_EX #(32+32+32+5+5+5+32+32+32+1+2+3) idtoex(  // +3 bits para Funct3
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clr(FlushE),
        .d({RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D, InstrD, IsFpD, FpOpD, Funct3D}),
        .q({RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E, InstrE, IsFpE, FpOpE, Funct3E})
    );

    // EX Stage - Forwarding Multiplexers
    wire [31:0] SrcAE;
    mux3 #(WIDTH) mux1(
        .d0(RD1E), 
        .d1(ResultW), 
        .d2(ALUResultM), 
        .s(ForwardAE), 
        .y(SrcAE)
    );
    
    wire [31:0] WriteDataE;
    mux3 #(WIDTH) mux2(
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
    
    // Cálculo de destino de salto
    wire [31:0] PCTargetBranchJal;
    adder pcaddbranch(
        .a(PCE), 
        .b(ImmExtE), 
        .y(PCTargetBranchJal)
    );
    
    wire [31:0] PCTargetJalrRaw;
    adder pcaddjalr(
        .a(SrcAE),
        .b(ImmExtE),        
        .y(PCTargetJalrRaw)
    );
    
    wire [31:0] PCTargetJalr;
    assign PCTargetJalr = {PCTargetJalrRaw[31:1], 1'b0};
    
    mux2 #(WIDTH) pcjumpmux(
        .d0(PCTargetBranchJal),
        .d1(PCTargetJalr),
        .s(JalrE),           
        .y(PCTargetE)        
    );
  
    // ALU Integer con salida LT
    wire [31:0] ALUResultE;
    alu alu(
        .a(SrcAE), 
        .b(SrcBE), 
        .alucontrol(ALUControlE), 
        .result(ALUResultE), 
        .zero(ZeroE),
        .lt(LtE)       // ← 🆕 Less Than
    ); 
    
    // ALU Floating Point
    wire [31:0] FPResultE;
    wire FPValidE;
    alu_fp alu_fp_u(
        .op_a(SrcAE),
        .op_b(SrcBE),
        .op_code(FpOpE),
        .clk(clk),
        .rst(reset),
        .start(1'b1),
        .mode_fp(1'b0),
        .result(FPResultE),
        .flags(),
        .valid_out(FPValidE)
    );
    
    wire [31:0] EXResultE;
    assign EXResultE = IsFpE ? FPResultE : ALUResultE;
    
    // EX_MEM
    wire [31:0] PCPlus4M;
    EX_MEM #(32+32+5+32+32) extomem (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clr(1'b0),
        .d({EXResultE, WriteDataE, RdE, PCPlus4E, InstrE}),
        .q({ALUResultM, WriteDataM, RdM, PCPlus4M, InstrM}) 
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
    
    // WB Stage
    mux3 #(WIDTH) resultmux(
        .d0(ALUResultW), 
        .d1(ReadDataW), 
        .d2(PCPlus4W), 
        .s(ResultSrcW), 
        .y(ResultW)
    ); 
    
endmodule