module flopenrc #(parameter W=32)(
    input clk, input reset, input en, input clr,
    input  [W-1:0] d,
    output reg [W-1:0] q
);

    always @(posedge clk or posedge reset)
        if (reset) q <= {W{1'b0}};
        else if (en) 
            q <= clr ? {W{1'b0}} : d;
endmodule