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
    output high_low    // Semnal expus pentru bitul High/Low
);

    // --- FSM States (Simplificat la 1 bit) ---
    localparam S_SETUP = 1'b0, S_DATA = 1'b1;
    reg current_state;

    // --- Registre interne ---
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
    assign high_low   = instr_highlow;

    // ==========================================================
    // Secven?ial: FSM + captur? instruc?iune + transfer date
    // ==========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state    <= S_SETUP;
            instr_rw         <= 1'b0;
            instr_highlow    <= 1'b0;
            instr_addr       <= 6'h00;
            data_write_reg   <= 8'h00;
            data_out_reg     <= 8'h00;
            write_active     <= 1'b0;
            read_active      <= 1'b0;
        end else begin
            
            // Pulsele read/write revin la 0 in fiecare ciclu, DACA nu sunt re-activate.
            read_active  <= 1'b0;
            write_active <= 1'b0;

            if (byte_sync) begin
                case (current_state)
                    S_SETUP: begin // --- Faza SETUP (Ciclul 1): Primirea comenzii ---
                        
                        // Captura instruc?iunea
                        instr_rw       <= data_in[7];
                        instr_highlow  <= data_in[6];
                        
                        // Adresa este format? din instr[5:0] + bitul High/Low
                        instr_addr     <= data_in[5:0] + (data_in[6] ? 6'd1 : 6'd0); 
                        
                        // Ini?iaz? citirea (read) dac? este o comand? de citire (R/W = 0)
                        // Semnalul read trebuie activat AICI pentru ca data_read s? fie gata în S_DATA phase.
                        if (~data_in[7]) begin
                            read_active <= 1'b1;
                        end
                        
                        // Ie?irea este un dummy 0x00 în acest ciclu
                        data_out_reg <= 8'h00;
                        
                        // Trecere la starea de date
                        current_state <= S_DATA; 
                    end

                    S_DATA: begin // --- Faza DATA (Ciclul 2): Transferul efectiv ---
                        if (instr_rw) begin
                            // WRITE: Captur? date ?i activeaz? scrierea (Write Pulse)
                            data_write_reg <= data_in;
                            write_active   <= 1'b1;
                        end else begin
                            // READ: Captur? data_read (Datele de la registru, gata de la pulsul din SETUP)
                            data_out_reg   <= data_read; 
                        end
                        
                        // Trecere înapoi la starea de a?teptare
                        current_state <= S_SETUP;
                    end
                endcase
            end
        end
    end

endmodule