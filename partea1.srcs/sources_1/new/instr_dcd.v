`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Design Name: Decodor de instructiuni SPI (FSM 2 faze)
// Module Name: instr_dcd
// Description: 
//  - FSM cu 2 st?ri: SETUP (decodare instruc?iune) ?i DATA (transfer efectiv)
//  - Instruc?iunea are structura: 
//      bit 7 = Read/Write (1=Write, 0=Read)
//      bit 6 = High/Low (zona din registru [15:8] / [7:0])
//      bit [5:0] = Adresa registrului
//////////////////////////////////////////////////////////////////////////////////

module instr_dcd (
    input clk,
    input rst_n,
    input byte_sync,
    input [7:0] data_in,
    output [7:0] data_out,
    output read,
    output write,
    output [5:0] addr,
    input  [7:0] data_read,
    output [7:0] data_write,
    output high_low   // <-- semnal expus pentru debug/testbench
);

    // --- FSM States ---
    localparam [1:0] SETUP = 2'b00, DATA = 2'b01;
    reg [1:0] current_state, next_state;

    // --- Registre interne ---
    reg [7:0] instr_reg;
    reg [7:0] data_write_reg;
    reg [7:0] data_out_reg;
    reg instr_rw;
    reg instr_highlow;
    reg [5:0] instr_addr;

    // --- Semnale active WRITE/READ ---
    reg write_active;
    reg read_active;

    // --- Ie?iri ---
    assign write = write_active;
    assign read  = read_active;
    assign addr  = instr_addr;
    assign data_write = data_write_reg;
    assign data_out   = data_out_reg;
    assign high_low   = instr_highlow;   // <-- ie?ire pentru debug

    // ==========================================================
    // Combinatoriu: FSM next state
    // ==========================================================
    always @(*) begin
        next_state = current_state;
        case (current_state)
            SETUP: if (byte_sync) next_state = DATA;
            DATA : if (byte_sync) next_state = SETUP;
            default: next_state = SETUP;
        endcase
    end

    // ==========================================================
    // Secven?ial: FSM + captur? instruc?iune + transfer date
    // ==========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state    <= SETUP;
            instr_reg        <= 8'h00;
            instr_rw         <= 1'b0;
            instr_highlow    <= 1'b0;
            instr_addr       <= 6'h00;
            data_write_reg   <= 8'h00;
            data_out_reg     <= 8'h00;
            write_active     <= 1'b0;
            read_active      <= 1'b0;
        end else begin
            current_state <= next_state;

            // Captur?m instruc?iunea în SETUP
            if (current_state == SETUP && byte_sync) begin
                instr_reg      <= data_in;
                instr_rw       <= data_in[7];
                instr_highlow  <= data_in[6];
                instr_addr     <= data_in[5:0];
            end

            // Transferul efectiv în DATA phase
            if (current_state == DATA && byte_sync) begin
                if (instr_rw)
                    data_write_reg <= data_in;  // WRITE
                else
                    data_out_reg   <= data_read; // READ
            end

            // Semnale WRITE / READ
            write_active <= (current_state == DATA) && byte_sync && instr_rw;
            read_active  <= (current_state == DATA) && byte_sync && ~instr_rw;
        end
    end

endmodule
