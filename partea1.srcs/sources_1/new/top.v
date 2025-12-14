`timescale 1ns / 1ps
module top(
    input clk,
    input rst_n,
    input sclk,
    input cs_n,
    output miso,
    input wire mosi,
    output pwm_out
);
// Semnale interconectate
wire byte_sync_spi; // Iesirea nesincronizata din spi_bridge
wire[7:0] data_in;
wire[7:0] data_out;
wire read;
wire write;
wire[5:0] addr;
wire[7:0] data_read;
wire[7:0] data_write;
wire[15:0] counter_val;
wire[15:0] period;
wire en;
wire count_reset;
wire upnotdown;
wire[7:0] prescale;
// A fost redenumit, acum folosim numele standard:
//wire pwm_en; 
wire pwm_en_force = 1'b1;
wire[7:0] functions;
wire[15:0] compare1;
wire[15:0] compare2;

// Semnale pentru Sincronizarea Domeniilor de Ceas (CDC)
reg sync1_byte_sync;
reg sync2_byte_sync;
wire sync_byte_sync; // Pulsul sincronizat, gata de utilizare in instr_dcd

// Sincronizare pe 2 Flops (Transfer SCLK -> CLK)
reg sync2_prev;


always @(posedge clk or negedge rst_n) begin
 if (write)
$display("WRITE-> addr=%02h data=%02h | period=%d compare1=%d en=%b pwm_en=%b functions=%b",
                 addr, data_write, period, compare1, en, pwm_en, functions);
    if (!rst_n) begin
        sync1_byte_sync <= 0;
        sync2_byte_sync <= 0;
        sync2_prev      <= 0;
    end else begin
        sync1_byte_sync <= byte_sync_spi;
        sync2_byte_sync <= sync1_byte_sync;
        sync2_prev      <= sync2_byte_sync;
    end
end

assign byte_sync_pulse = sync2_byte_sync & ~sync2_prev;

// assign pwm_en = 1'b1; 

spi_bridge i_spi_bridge (
    .clk(clk),
    .rst_n(rst_n),
    .sclk(sclk),
    .cs_n(cs_n),
    .mosi(mosi),
    .miso(miso),
    .byte_sync(byte_sync_spi), // Conectat la semnalul nesincronizat
    .data_in(data_in),
    .data_out(data_out)
);

instr_dcd i_instr_dcd (
    .clk(clk),
    .rst_n(rst_n),
    .byte_sync(byte_sync_pulse), // FIX: Folosim semnalul sincronizat
    .data_in(data_in),
    .data_out(data_out),
    .read(read),
    .write(write),
    .addr(addr),
    .data_read(data_read),
    .data_write(data_write)
);

regs i_regs (
    .clk(clk),
    .rst_n(rst_n),
    .read(read),
    .write(write),
    .addr(addr),
    .data_read(data_read),
    .data_write(data_write),
    .counter_val(counter_val),
    .period(period),
    .en(en),
    .count_reset(count_reset),
    .upnotdown(upnotdown),
    .prescale(prescale),
    .pwm_en(pwm_en), // Renumirea temporara a fost eliminata
    .functions(functions),
    .compare1(compare1),
    .compare2(compare2)
);

counter i_counter (
    .clk(clk),
    .rst_n(rst_n),
    .count_val(counter_val),
    .period(period),
    .en(en),
    .count_reset(count_reset),
    .upnotdown(upnotdown),
    .prescale(prescale)
);

pwm_gen i_pwm_gen (
    .clk(clk),
    .rst_n(rst_n),
    .pwm_en(pwm_en_force),
    .period(period),
    .functions(functions),
    .compare1(compare1),
    .compare2(compare2),
    .count_val(counter_val),
    .pwm_out(pwm_out)
);

endmodule
