module extend(
    input  [31:7] instr,
    input  [1:0]  immsrc,
    input  [6:0]  opcode,        // *** NUEVO ***
    output [31:0] immext
);

    reg [31:0] immext_reg;
    assign immext = immext_reg;

    always @* begin
        case (immsrc)

            // -------------------------
            // I-TYPE
            // -------------------------
            2'b00: immext_reg = {{20{instr[31]}}, instr[31:20]};

            // -------------------------
            // S-TYPE
            // -------------------------
            2'b01: immext_reg = {{20{instr[31]}},
                                  instr[31:25],
                                  instr[11:7]};

            // -------------------------
            // B-TYPE
            // -------------------------
            2'b10: immext_reg = {{20{instr[31]}},
                                  instr[7],
                                  instr[30:25],
                                  instr[11:8],
                                  1'b0};

            // -------------------------
            // 11 → depende del opcode
            // -------------------------
            2'b11: begin
                if (opcode == 7'b1101111) begin
                    // J-TYPE (JAL)
                    immext_reg = {{12{instr[31]}},
                                   instr[19:12],
                                   instr[20],
                                   instr[30:21],
                                   1'b0};
                end else begin
                    // U-TYPE (LUI / AUIPC)
                    immext_reg = {instr[31:12], 12'b0};
                end
            end

            default: immext_reg = 32'bx;
        endcase
    end

endmodule
