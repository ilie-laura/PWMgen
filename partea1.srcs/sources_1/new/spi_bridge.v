`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2025 04:00:02 PM
// Design Name: 
// Module Name: spi_bridge
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


module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,
    output miso,
    // internal facing 
    output byte_sync,
    output[7:0] data_in,
    input[7:0] data_out
);
// registru pentru shift-in (de pe MOSI)
    reg [7:0] in_shift;
    // registru pentru shift-out (spre MISO)
    reg [7:0] out_shift;
    // nr biti[0 7]
    reg [2:0] bit_cnt;

    reg [7:0] data_in_reg;
    reg       byte_sync_reg;
    reg       miso_reg;

    assign data_in   = data_in_reg;
    assign byte_sync = byte_sync_reg;
    assign miso      = miso_reg;

    // logica SPI: datele sunt valide pe frontul cresc al lui sclk
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            in_shift      <= 8'h00;
            out_shift     <= 8'h00;
            bit_cnt       <= 3'd0;
            data_in_reg   <= 8'h00;
            byte_sync_reg <= 1'b0;
            miso_reg      <= 1'b0;
        end else if (cs_n) begin
            // CS  inactiv, resetare stare intern
            bit_cnt       <= 3'd0;
            byte_sync_reg <= 1'b0;
            out_shift     <= data_out;
        end else begin
            byte_sync_reg <= 1'b0;

            // shift-in de pe MOSI (MSB first)
            in_shift <= {in_shift[6:0], mosi};

            // shift-out pe MISO
            miso_reg  <= out_shift[7];
            out_shift <= {out_shift[6:0], 1'b0};

            if (bit_cnt == 3'd7) begin
                // un byte complet
                bit_cnt       <= 3'd0;
                data_in_reg   <= {in_shift[6:0], mosi};
                byte_sync_reg <= 1'b1;

                // next byte de iesire
                out_shift     <= data_out;
            end else begin
                bit_cnt <= bit_cnt + 3'd1;
            end
        end
    end
endmodule
