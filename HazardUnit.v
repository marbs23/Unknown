module HazardUnit(
    input [4:0] Rs1D, Rs2D, RdE, Rs2E, Rs1E,
    input PCSrcE,
    input [1:0] ResultSrcE,        // ⭐ CAMBIO 1: De input a input [1:0]
    input IsFpE,
    input [4:0] RdM, RdW,
    input RegWriteM, RegWriteW,
    output reg StallF, StallD, FlushD, FlushE,
    output reg [1:0] ForwardAE, ForwardBE
);

    // Forwarding para operando A
    always @* begin
        if ((Rs1E == RdM) && RegWriteM && (Rs1E != 0))
            ForwardAE = 2'b10;
        else if ((Rs1E == RdW) && RegWriteW && (Rs1E != 0))
            ForwardAE = 2'b01;
        else 
            ForwardAE = 2'b00;
    end
    
    // Forwarding para operando B
    always @* begin
        if ((Rs2E == RdM) && RegWriteM && (Rs2E != 0))
            ForwardBE = 2'b10;
        else if ((Rs2E == RdW) && RegWriteW && (Rs2E != 0))
            ForwardBE = 2'b01;
        else 
            ForwardBE = 2'b00;
    end
    
    // Detección de hazards
    reg lwHazard, fpHazard, stall_any;
    always @* begin
        // ⭐ CAMBIO 2: Comparar con 2'b01 en lugar de solo ResultSrcE
        lwHazard = (ResultSrcE == 2'b01) && (RdE != 5'b0) && 
           ((Rs1D == RdE) || (Rs2D == RdE));        
        // ⭐ CAMBIO 3: Detectar hazards FP en lugar de 1'b0
        fpHazard = IsFpE && (RdE != 5'b0) && ((Rs1D == RdE) || (Rs2D == RdE));
        
        stall_any = lwHazard || fpHazard;
        StallF = stall_any;
        StallD = stall_any;
    end
    
    // Flush logic
    always @* begin
        FlushD = PCSrcE;
        FlushE = stall_any || PCSrcE;
    end
    
endmodule
