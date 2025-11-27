module EX_MEM #(parameter W = 32) (
    input clk,
    input reset,
    input en,
    input clr,
    input [W-1:0] d,
    output reg [W-1:0] q
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
          q <= {W{1'b0}};
        end else if (en) begin
          if (clr) q <= {W{1'b0}};
          else     q <= d;
        end
    end
endmodule
