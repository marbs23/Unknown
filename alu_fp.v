module alu_fp (
    input  [31:0] op_a, op_b,
    input  [1:0]  op_code,        
    input         clk, rst,
    input         start,
    input         mode_fp,        
    output reg [31:0] result,
    output reg [4:0]  flags,      
    output reg        valid_out
);

    wire [7:0] bias_sel     = mode_fp ? 8'd15  : 8'd127;
    wire [7:0] exp_max_sel  = mode_fp ? 8'd30  : 8'd254;
    wire [7:0] exp_min_sel  = 8'd1;

    reg sign_a, sign_b, sign_res;
    reg [7:0] exp_a, exp_b, exp_res;
    reg [23:0] mant_a, mant_b;
    reg [24:0] mant_sum;
    reg [7:0]  exp_diff;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    reg [47:0] q, div_numer, remainder;
    reg [22:0] frac_div;
    reg [23:0] frac_round;
    reg guard_bit, sticky_bit, lsb_bit;
    reg round_inc, overflow, underflow;
    reg [47:0] product;
    reg [22:0] frac_mul;
    reg did_round;

    always @(*) begin
        result     = 32'b0;
        flags      = 5'b00000;
        valid_out  = 1'b0;

        if (mode_fp) begin
            sign_a = op_a[15];
            sign_b = op_b[15];
            exp_a  = {3'b000, op_a[14:10]};
            exp_b  = {3'b000, op_b[14:10]};
            mant_a = (exp_a[4:0]==5'd0) ? {1'b0, op_a[9:0], 13'b0} : {1'b1, op_a[9:0], 13'b0};
            mant_b = (exp_b[4:0]==5'd0) ? {1'b0, op_b[9:0], 13'b0} : {1'b1, op_b[9:0], 13'b0};

            a_is_nan  = (exp_a[4:0]==5'h1F) && (op_a[9:0]!=0);
            b_is_nan  = (exp_b[4:0]==5'h1F) && (op_b[9:0]!=0);
            a_is_inf  = (exp_a[4:0]==5'h1F) && (op_a[9:0]==0);
            b_is_inf  = (exp_b[4:0]==5'h1F) && (op_b[9:0]==0);
            a_is_zero = (exp_a[4:0]==5'd0)  && (op_a[9:0]==0);
            b_is_zero = (exp_b[4:0]==5'd0)  && (op_b[9:0]==0);
        end else begin
            sign_a = op_a[31];
            sign_b = op_b[31];
            exp_a  = op_a[30:23];
            exp_b  = op_b[30:23];
            mant_a = (exp_a==8'd0) ? {1'b0, op_a[22:0]} : {1'b1, op_a[22:0]};
            mant_b = (exp_b==8'd0) ? {1'b0, op_b[22:0]} : {1'b1, op_b[22:0]};

            a_is_nan  = (exp_a==8'hFF) && (op_a[22:0]!=0);
            b_is_nan  = (exp_b==8'hFF) && (op_b[22:0]!=0);
            a_is_inf  = (exp_a==8'hFF) && (op_a[22:0]==0);
            b_is_inf  = (exp_b==8'hFF) && (op_b[22:0]==0);
            a_is_zero = (exp_a==8'd0)  && (op_a[22:0]==0);
            b_is_zero = (exp_b==8'd0)  && (op_b[22:0]==0);
        end

        case (op_code)
        // ========================================
        // SUMA Y RESTA
        // ========================================
        2'b00, 2'b01: begin
            if (a_is_nan || b_is_nan) begin
                result = mode_fp ? {16'b0, 16'h7E00} : 32'h7FC00000;
                flags[4] = 1'b1;
            end else if (a_is_inf && b_is_inf && (sign_a != (op_code==2'b01 ? ~sign_b : sign_b))) begin
                result = mode_fp ? {16'b0, 16'h7E00} : 32'h7FC00000;
                flags[4] = 1'b1;
            end else begin
                if (op_code == 2'b01) sign_b = ~sign_b;

                if (exp_a > exp_b) begin
                    exp_diff = exp_a - exp_b;
                    mant_b = mant_b >> exp_diff;
                    exp_res = exp_a;
                end else if (exp_b > exp_a) begin
                    exp_diff = exp_b - exp_a;
                    mant_a = mant_a >> exp_diff;
                    exp_res = exp_b;
                end else begin
                    exp_res = exp_a;
                end

                if (sign_a == sign_b) begin
                    mant_sum = mant_a + mant_b;
                    sign_res = sign_a;
                end else begin
                    if (mant_a >= mant_b) begin
                        mant_sum = mant_a - mant_b;
                        sign_res = sign_a;
                    end else begin
                        mant_sum = mant_b - mant_a;
                        sign_res = sign_b;
                    end
                end

                if (mant_sum[24]) begin
                    mant_sum = mant_sum >> 1;
                    exp_res  = exp_res + 1;
                end else if (!mant_sum[23] && mant_sum != 0) begin
                    mant_sum = mant_sum << 1;
                    exp_res  = exp_res - 1;
                end

                guard_bit = mant_sum[0];
                lsb_bit   = mant_sum[1];
                did_round = guard_bit & ~lsb_bit;

                flags[2] = (exp_res > exp_max_sel);
                flags[1] = (exp_res < exp_min_sel);
                flags[0] = did_round | guard_bit;

                if (flags[2])
                    result = mode_fp ? {16'b0, sign_res, 5'h1F, 10'd0} : {sign_res, 8'hFF, 23'd0};
                else if (flags[1] || mant_sum==0)
                    result = {sign_res, 31'd0};
                else if (mode_fp)
                    result = {16'b0, sign_res, exp_res[4:0], mant_sum[22:13]};
                else
                    result = {sign_res, exp_res[7:0], mant_sum[22:0]};
            end
        end

        // ========================================
        // MULTIPLICACIÓN (CORREGIDA)
        // ========================================
        2'b10: begin
            if (a_is_nan || b_is_nan || (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
                result = mode_fp ? {16'b0, 16'h7E00} : 32'h7FC00000;
                flags[4] = 1'b1;
            end else if (a_is_inf || b_is_inf) begin
                sign_res = sign_a ^ sign_b;
                result = mode_fp ? {16'b0, sign_res, 5'h1F, 10'd0} : {sign_res, 8'hFF, 23'd0};
            end else if (a_is_zero || b_is_zero) begin
                result = {sign_a ^ sign_b, 31'd0};
            end else begin
                sign_res = sign_a ^ sign_b;
                product = mant_a * mant_b;
                exp_res = exp_a + exp_b - bias_sel;

                // Normalizar: producto puede estar en bit[47] o bit[46]
                if (product[47]) begin
                    // Producto normalizado en bit 47
                    // Mantisa está en bits [46:24], tomamos [46:24] = 23 bits
                    frac_mul = product[46:24];
                    lsb_bit = product[24];
                    guard_bit = product[23];
                    sticky_bit = |product[22:0];
                    exp_res = exp_res + 1;
                end else begin
                    // Producto normalizado en bit 46
                    // Mantisa está en bits [45:23], tomamos [45:23] = 23 bits
                    frac_mul = product[45:23];
                    lsb_bit = product[23];
                    guard_bit = product[22];
                    sticky_bit = |product[21:0];
                end

                // Round to nearest, ties to even
                round_inc = guard_bit & (sticky_bit | lsb_bit);
                frac_round = {1'b0, frac_mul} + round_inc;

                // Si hay overflow en el redondeo
                if (frac_round[23]) begin
                    frac_round = frac_round >> 1;
                    exp_res = exp_res + 1;
                end

                overflow = (exp_res > exp_max_sel);
                underflow = (exp_res < exp_min_sel);
                flags[2] = overflow;
                flags[1] = underflow;
                flags[0] = round_inc | guard_bit | sticky_bit;

                if (overflow)
                    result = mode_fp ? {16'b0, sign_res, 5'h1F, 10'd0} : {sign_res, 8'hFF, 23'd0};
                else if (underflow)
                    result = {sign_res, 31'd0};
                else if (mode_fp)
                    result = {16'b0, sign_res, exp_res[4:0], frac_round[22:13]};
                else
                    result = {sign_res, exp_res[7:0], frac_round[22:0]};
            end
        end

        // ========================================
        // DIVISIÓN (CORREGIDA)
        // ========================================
        2'b11: begin
            if (a_is_nan || b_is_nan) begin
                result = mode_fp ? {16'b0, 16'h7E00} : 32'h7FC00000;
                flags[4] = 1'b1;
            end else if ((a_is_zero && b_is_zero) || (a_is_inf && b_is_inf)) begin
                result = mode_fp ? {16'b0, 16'h7E00} : 32'h7FC00000;
                flags[4] = 1'b1;
            end else if (b_is_zero) begin
                flags[3] = 1'b1;
                result = mode_fp ? {16'b0, sign_a ^ sign_b, 5'h1F, 10'd0} : {sign_a ^ sign_b, 8'hFF, 23'd0};
            end else if (a_is_zero) begin
                result = {sign_a ^ sign_b, 31'd0};
            end else if (a_is_inf) begin
                sign_res = sign_a ^ sign_b;
                result = mode_fp ? {16'b0, sign_res, 5'h1F, 10'd0} : {sign_res, 8'hFF, 23'd0};
            end else begin
                sign_res = sign_a ^ sign_b;
                
                // División: {mant_a, 24'b0} / mant_b
                div_numer = {mant_a, 24'b0};
                q = div_numer / mant_b;
                remainder = div_numer % mant_b;
                
                // Ajustar exponente
                exp_res = (exp_a - exp_b) + bias_sel;

                // Normalizar el cociente
                // El cociente puede estar en bit[24] o bit[23]
                if (q[24]) begin
                    // Cociente en bit 24, ya normalizado
                    // Tomar bits [23:1] como fracción
                    frac_div = q[23:1];
                    lsb_bit = q[1];
                    guard_bit = q[0];
                    sticky_bit = (remainder != 0);
                end else begin
                    // Cociente en bit 23 o menor, desplazar
                    q = q << 1;
                    exp_res = exp_res - 1;
                    frac_div = q[23:1];
                    lsb_bit = q[1];
                    guard_bit = q[0];
                    sticky_bit = (remainder != 0);
                end

                // Round to nearest, ties to even
                round_inc = guard_bit & (sticky_bit | lsb_bit);
                frac_round = {1'b0, frac_div} + round_inc;

                // Si hay overflow en el redondeo
                if (frac_round[23]) begin
                    frac_round = frac_round >> 1;
                    exp_res = exp_res + 1;
                end

                overflow = (exp_res > exp_max_sel);
                underflow = (exp_res < exp_min_sel);
                flags[2] = overflow;
                flags[1] = underflow;
                flags[0] = guard_bit | sticky_bit;

                if (overflow)
                    result = mode_fp ? {16'b0, sign_res, 5'h1F, 10'd0} : {sign_res, 8'hFF, 23'd0};
                else if (underflow)
                    result = {sign_res, 31'd0};
                else if (mode_fp)
                    result = {16'b0, sign_res, exp_res[4:0], frac_round[22:13]};
                else
                    result = {sign_res, exp_res[7:0], frac_round[22:0]};
            end
        end
        endcase

        valid_out = 1'b1;
    end
endmodule
