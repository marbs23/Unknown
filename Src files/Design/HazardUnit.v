module HazardUnit(
    input [4:0] Rs1D, Rs2D, RdE, Rs2E, Rs1E,
    input PCSrcE,
    input ResultSrcE,
    input [4:0] RdM, RdW,
    input RegWriteM, RegWriteW,
    output reg StallF, StallD, FlushD, FlushE,
    output reg [1:0] ForwardAE, ForwardBE
);
    always @* begin
        if (((Rs1E == RdM) & RegWriteM)& (Rs1E != 0))
            ForwardAE = 2'b10;
        else if (((Rs1E == RdW) & RegWriteW)&(Rs1E != 0))
            ForwardAE = 2'b01;
        else 
            ForwardAE = 2'b00;
    end
    reg lwStall;
    always @* begin
        lwStall = ResultSrcE & ((Rs1D == RdE) | (Rs2D == RdE));
        StallF = lwStall;
        StallD = lwStall;
    end
    
    always @* begin
        FlushD = PCSrcE;
        FlushE = lwStall | PCSrcE;
    end
    
endmodule
