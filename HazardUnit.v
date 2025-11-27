module HazardUnit(
    input clk,
    input reset,
    input [4:0] Rs1D, Rs2D, RdE, Rs2E, Rs1E,
    input PCSrcE,
    input [1:0] ResultSrcE,
    input IsFpE,
    input [1:0] FpOpE,  // Para determinar latencia según operación
    input [4:0] RdM, RdW,
    input RegWriteM, RegWriteW,
    output reg StallF, StallD, FlushD, FlushE,
    output reg [1:0] ForwardAE, ForwardBE
);

    // Contador de latencia FP
    reg [2:0] fp_stall_counter;
    reg [2:0] fp_latency;
    
    // Determinar latencia según operación FP
    always @* begin
        case (FpOpE)
            2'b00: fp_latency = 3'd3;  // FADD.S - 3 ciclos
            2'b01: fp_latency = 3'd3;  // FSUB.S - 3 ciclos
            2'b10: fp_latency = 3'd4;  // FMUL.S - 4 ciclos
            2'b11: fp_latency = 3'd6;  // FDIV.S - 6 ciclos
            default: fp_latency = 3'd1;
        endcase
    end
    
    // Contador para stalls FP
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fp_stall_counter <= 3'd0;
        end else begin
            if (IsFpE && fp_stall_counter == 0) begin
                // Iniciar contador cuando detectamos una op FP
                fp_stall_counter <= fp_latency - 1;
            end else if (fp_stall_counter > 0) begin
                fp_stall_counter <= fp_stall_counter - 1;
            end
        end
    end

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
        // Load hazard
        lwHazard = (ResultSrcE == 2'b01) && (RdE != 5'b0) && 
                   ((Rs1D == RdE) || (Rs2D == RdE));
        
        // FP hazard - detectar si instrucción en Decode necesita resultado FP
        fpHazard = (fp_stall_counter > 0) && (RdE != 5'b0) && 
                   ((Rs1D == RdE) || (Rs2D == RdE));
        
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