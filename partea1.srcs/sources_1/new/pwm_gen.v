`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2025 04:00:02 PM
// Design Name: 
// Module Name: pwm_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pwm_gen (
    // peripheral clock signals
    input        clk,
    input        rst_n,
    // PWM signal register configuration
    input        pwm_en,
    input  [15:0] period,
    input  [7:0]  functions,
    input  [15:0] compare1,
    input  [15:0] compare2,
    input  [15:0] count_val,
    // top facing signals
    output       pwm_out
);

    reg pwm_reg;
    assign pwm_out = pwm_reg;

    reg pwm_next;

  always @* begin
    case (functions[1:0])

        2'b00:  // ALIGN_LEFT
            pwm_next = (count_val <= compare1);

        2'b01:  // ALIGN_RIGHT
            pwm_next = (count_val >= compare1);

        2'b10:  
            pwm_next = (count_val >= compare1) && (count_val < compare2);

        default:
            pwm_next = 1'b0;
    endcase
end


    // registru de iiesire,PWN en
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_reg <= 1'b0;
        end else if (!pwm_en) begin
            // când pwm_en = 0, blocare iesire
            pwm_reg <= pwm_reg;
        end else begin
            pwm_reg <= 1'b0;
        end
    end

endmodule
