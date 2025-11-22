`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2025 04:00:02 PM
// Design Name: 
// Module Name: counter
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


module counter (
    // peripheral clock signals
    input        clk,
    input        rst_n,
    // register facing signals
    output [15:0] count_val,
    input  [15:0] period,
    input        en,
    input        count_reset,
    input        upnotdown,
    input  [7:0] prescale
);

    // registrul intern al contorului
    reg [15:0] count_reg;
    // registru pentru prescaler
    reg [15:0] presc_cnt;

    // conectarre registru intern la iesire 
    assign count_val = count_reg;

    // limits pentru prescaler: 2^prescale
//folosim primii 4 biti
    wire [15:0] presc_limit = 16'd1 << prescale[3:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= 16'd0;
            presc_cnt <= 16'd0;
        end else if (count_reset) begin
            // reset explicit al contorului
            count_reg <= 16'd0;
            presc_cnt <= 16'd0;
        end else if (!en) begin
            // numarator oprit....retinem valorile
            count_reg <= count_reg;
            presc_cnt <= presc_cnt;
        end else begin
            // activ prescaler
            if (presc_cnt == presc_limit - 1) begin
                presc_cnt <= 16'd0;

                if (upnotdown) begin
                    // UP
                    if (count_reg == period - 1)
                        count_reg <= 16'd0;       // overflow
                    else
                        count_reg <= count_reg + 16'd1;
                end else begin
                    // DOWN
                    if (count_reg == 16'd0)
                        count_reg <= period - 1;  // underflow
                    else
                        count_reg <= count_reg - 16'd1;
                end
            end else begin
                // limita neintrecuta
                presc_cnt <= presc_cnt + 16'd1;
                count_reg <= count_reg;
            end
        end
    end

endmodule

