module HazardUnit(
    input [4:0] Rs1D, Rs2D, RdE, Rs2E, Rs1E,
    input PCSrcE,
    input [1:0] ResultSrcE,
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
    
    wire loadUseHazard;
    
    assign loadUseHazard = (ResultSrcE == 2'b01) && (RdE != 5'b0) && 
                          ((Rs1D == RdE) || (Rs2D == RdE));
    
    // Flush logic
    always @* begin
        // Stall IF y ID cuando hay un load-use hazard
        StallF = loadUseHazard;
        StallD = loadUseHazard;
        
        // Flush ID stage cuando hay branch/jump
        FlushD = PCSrcE;
        
        // Flush EX stage cuando hay branch/jump o stall
        FlushE = loadUseHazard || PCSrcE;
    end
    
endmodule
