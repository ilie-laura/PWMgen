module pwm_gen (
    input         clk,
    input         rst_n,
    input         pwm_en,
    input  [15:0] period,
    input  [7:0]  functions,
    input  [15:0] compare1,
    input  [15:0] compare2,
    input  [15:0] count_val,
    output        pwm_out
);

    reg pwm_reg;
    reg pwm_next;

    assign pwm_out = pwm_reg;

    always @* begin
        pwm_next = 1'b0;

        if (!pwm_en) begin
            pwm_next = 1'b0;
        end else begin
            case (functions[1:0])

                // ALIGN_LEFT : HIGH = compare1 + 1
                2'b00: begin
                    pwm_next = (count_val <= compare1);
                end

                // ALIGN_RIGHT
                2'b01: begin
                    pwm_next = (count_val >= compare1);
                end

                // RANGE_BETWEEN_COMPARES
                2'b10: begin 
            if (compare1 < compare2)
                pwm_next = (count_val >= compare1) &&
                           (count_val <  compare2);
            else
                pwm_next = 1'b0;  
        end

                default:
                    pwm_next = 1'b0;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_reg <= 1'b0;
        else
            pwm_reg <= pwm_next;
    end

endmodule
