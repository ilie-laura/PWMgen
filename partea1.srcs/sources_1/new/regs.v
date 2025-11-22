`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2025 04:00:02 PM
// Design Name: 
// Module Name: regs
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


module regs (
    // peripheral clock signals
    input        clk,
    input        rst_n,
    // decoder facing signals
    input        read,
    input        write,
    input  [5:0] addr,
    output [7:0] data_read,
    input  [7:0] data_write,
    // counter programming signals
    input  [15:0] counter_val,
    output [15:0] period,
    output        en,
    output        count_reset,
    output        upnotdown,
    output [7:0]  prescale,
    // PWM signal programming values
    output        pwm_en,
    output [7:0]  functions,
    output [15:0] compare1,
    output [15:0] compare2
);

    // adresele registrelor (LSB/MSB pentru cele pe 16 bi?i)
    localparam ADDR_PERIOD_L      = 6'h00;
    localparam ADDR_PERIOD_H      = 6'h01;
    localparam ADDR_COUNTER_EN    = 6'h02;
    localparam ADDR_COMPARE1_L    = 6'h03;
    localparam ADDR_COMPARE1_H    = 6'h04;
    localparam ADDR_COMPARE2_L    = 6'h05;
    localparam ADDR_COMPARE2_H    = 6'h06;
    localparam ADDR_COUNTER_RESET = 6'h07;
    localparam ADDR_COUNTER_VAL_L = 6'h08;
    localparam ADDR_COUNTER_VAL_H = 6'h09;
    localparam ADDR_PRESCALE      = 6'h0A;
    localparam ADDR_UPNOTDOWN     = 6'h0B;
    localparam ADDR_PWM_EN        = 6'h0C;
    localparam ADDR_FUNCTIONS     = 6'h0D;

    // registrele 
    reg [15:0] period;
    reg        en;
    reg [15:0] compare1;
    reg [15:0] compare2;
    reg        count_reset;
    reg [7:0]  prescale;
    reg        upnotdown;
    reg        pwm_en;
    reg [7:0]  functions;

    // pentru citire
    reg [7:0] data_read_reg;
    assign data_read = data_read_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period      <= 16'h0000;
            en          <= 1'b0;
            compare1    <= 16'h0000;
            compare2    <= 16'h0000;
            count_reset <= 1'b0;
            prescale    <= 8'h00;
            upnotdown   <= 1'b1;     // default: crescator
            pwm_en      <= 1'b0;
            functions   <= 8'h00;
        end else begin
            // count_reset – puls de un singur ciclu dupa o scriere
            if (count_reset)
                count_reset <= 1'b0;

            if (write) begin
                case (addr)
                    ADDR_PERIOD_L:   period[7:0]   <= data_write;
                    ADDR_PERIOD_H:   period[15:8]  <= data_write;
                    ADDR_COUNTER_EN: en            <= data_write[0];
                    ADDR_COMPARE1_L: compare1[7:0] <= data_write;
                    ADDR_COMPARE1_H: compare1[15:8]<= data_write;
                    ADDR_COMPARE2_L: compare2[7:0] <= data_write;
                    ADDR_COMPARE2_H: compare2[15:8]<= data_write;
                    ADDR_COUNTER_RESET: begin
                        // generare puls
                        count_reset <= 1'b1;
                    end
                    ADDR_PRESCALE:   prescale      <= data_write;
                    ADDR_UPNOTDOWN:  upnotdown     <= data_write[0];
                    ADDR_PWM_EN:     pwm_en        <= data_write[0];
                    ADDR_FUNCTIONS:  functions     <= data_write;
                    default: ;
                endcase
            end
        end
    end

    // citire combinationala
    always @(*) begin
        case (addr)
            ADDR_PERIOD_L:      data_read_reg = period[7:0];
            ADDR_PERIOD_H:      data_read_reg = period[15:8];
            ADDR_COUNTER_EN:    data_read_reg = {7'b0, en};
            ADDR_COMPARE1_L:    data_read_reg = compare1[7:0];
            ADDR_COMPARE1_H:    data_read_reg = compare1[15:8];
            ADDR_COMPARE2_L:    data_read_reg = compare2[7:0];
            ADDR_COMPARE2_H:    data_read_reg = compare2[15:8];
            ADDR_COUNTER_RESET: data_read_reg = 8'h00; // write-only
            ADDR_COUNTER_VAL_L: data_read_reg = counter_val[7:0];
            ADDR_COUNTER_VAL_H: data_read_reg = counter_val[15:8];
            ADDR_PRESCALE:      data_read_reg = prescale;
            ADDR_UPNOTDOWN:     data_read_reg = {7'b0, upnotdown};
            ADDR_PWM_EN:        data_read_reg = {7'b0, pwm_en};
            ADDR_FUNCTIONS:     data_read_reg = functions;
            default:            data_read_reg = 8'h00;
        endcase
    end

endmodule
