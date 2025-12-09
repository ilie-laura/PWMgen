`timescale 1ns / 1ps

module instr_dcd (
    input        clk,
    input        rst_n,
    input        byte_sync,
    input  [7:0] data_in,
    output [7:0] data_out,
    output       read,
    output       write,
    output [5:0] addr,
    input  [7:0] data_read,
    output [7:0] data_write,
    output       high_low
);

// FSM 
localparam [1:0] ST_SETUP = 2'b00,
                 ST_DATA  = 2'b01;

reg [1:0] state, next_state;

// registre interne
reg [7:0] instr_reg;
reg       instr_rw;
reg       instr_highlow;
reg [5:0] instr_addr;

reg [7:0] data_out_reg;
reg [7:0] data_write_reg;

reg write_pulse;
reg read_pulse;

// iesiri
assign write      = write_pulse;
assign read       = read_pulse;
assign addr       = instr_addr + (instr_highlow ? 6'd1 : 6'd0);  // MSB/LSB selection
assign data_out   = data_out_reg;
assign data_write = data_write_reg;
assign high_low   = instr_highlow;

// NEXT STATE 
always @(*) begin
    next_state = state;
    case (state)
        ST_SETUP: begin
            if (byte_sync)
                next_state = ST_DATA;
        end

        ST_DATA: begin
            if (byte_sync)
                next_state = ST_SETUP;
        end
    endcase
end


// STATE sinc
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state          <= ST_SETUP;

        instr_reg      <= 8'h00;
        instr_rw       <= 1'b0;
        instr_highlow  <= 1'b0;
        instr_addr     <= 6'h00;

        data_out_reg   <= 8'h00;
        data_write_reg <= 8'h00;

        write_pulse    <= 1'b0;
        read_pulse     <= 1'b0;

    end else begin
        state <= next_state;

        // un ciclu "reset"
        write_pulse <= 1'b0;
        read_pulse  <= 1'b0;

        // SETUP 
        if (state == ST_SETUP && byte_sync) begin
            instr_reg      <= data_in;
            instr_rw       <= data_in[7];
            instr_highlow  <= data_in[6];
            instr_addr     <= data_in[5:0];
        end
        // DATA 
 
        if (state == ST_DATA && byte_sync) begin

            if (instr_rw) begin
                // WRITE 
                data_write_reg <= data_in;
                write_pulse    <= 1'b1;
            end else begin
                // READ 
                data_out_reg <= data_read;
                read_pulse   <= 1'b1;
            end
        end
    end
end

endmodule
