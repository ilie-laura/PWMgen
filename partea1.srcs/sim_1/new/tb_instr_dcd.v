`timescale 1ns / 1ps

module tb_instr_dcd;

    reg clk;
    reg rst_n;
    reg byte_sync;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire read, write;
    wire [5:0] addr;
    reg  [7:0] data_read;
    wire [7:0] data_write;
    wire high_low;  // semnal expus din modul pentru debug

    // --- instan?iere DUT ---
    instr_dcd DUT (
        .clk(clk),
        .rst_n(rst_n),
        .byte_sync(byte_sync),
        .data_in(data_in),
        .data_out(data_out),
        .read(read),
        .write(write),
        .addr(addr),
        .data_read(data_read),
        .data_write(data_write),
        .high_low(high_low)
    );

    // --- ceas ---
    always #10 clk = ~clk;

    // --- task pentru trimiterea unui byte ---
    task send_byte;
        input [7:0] value;
        begin
            @(negedge clk);
            data_in = value;
            byte_sync = 1'b1;
            @(negedge clk);
            byte_sync = 1'b0;
        end
    endtask

    // --- simulare ---
    initial begin
        $display("==== START SIMULARE DECODOR ====");
        clk = 0; rst_n = 0; byte_sync = 0; data_in = 8'h00; data_read = 8'h00;
        #50; rst_n = 1;

        // TEST 1: WRITE High
        $display("\nTEST 1: WRITE High la adresa 0x15");
        send_byte(8'hD5); send_byte(8'h55);
        #20;
        $display("WRITE=%b | READ=%b | ADDR=%02h | DATA_WRITE=%02h | HIGH_LOW=%b",
                 write, read, addr, data_write, high_low);

        // TEST 2: READ Low
        $display("\nTEST 2: READ Low la adresa 0x22");
        data_read = 8'hAB;
        send_byte(8'h22); send_byte(8'h00);
        #20;
        $display("WRITE=%b | READ=%b | ADDR=%02h | DATA_OUT=%02h | HIGH_LOW=%b",
                 write, read, addr, data_out, high_low);

        // TEST 3: RESET
        $display("\nTEST 3: RESET sistem");
        rst_n = 0; #40; rst_n = 1; #20;
        $display("Dupa reset -> ADDR=%02h | WRITE=%b | READ=%b", addr, write, read);

        // TEST 4: WRITE Low
        $display("\nTEST 4: WRITE Low la adresa 0x0A");
        send_byte(8'h8A); send_byte(8'h77);
        #20;
        $display("WRITE=%b | READ=%b | ADDR=%02h | DATA_WRITE=%02h | HIGH_LOW=%b",
                 write, read, addr, data_write, high_low);

        // TEST 5: READ High
        $display("\nTEST 5: READ High la adresa 0x0F");
        data_read = 8'hCC;
        send_byte(8'h4F); send_byte(8'h00);
        #20;
        $display("WRITE=%b | READ=%b | ADDR=%02h | DATA_OUT=%02h | HIGH_LOW=%b",
                 write, read, addr, data_out, high_low);

        // TEST 6: Instruc?iune invalid?
        $display("\nTEST 6: INSTRUCTIUNE INVALIDA");
        send_byte(8'hFF); #20;
        $display("WRITE=%b | READ=%b | ADDR=%02h", write, read, addr);

        // TEST 7: Doua instructiuni consecutive
        $display("\nTEST 7: Doua instructiuni consecutive");
        send_byte(8'hD5); send_byte(8'hAA); send_byte(8'h22); send_byte(8'h00);
        #50;
        $display("WRITE=%b | READ=%b | ADDR=%02h | DATA_OUT=%02h",
                 write, read, addr, data_out);

        $display("\n==== SFARSIT SIMULARE ====");
        $stop;
    end

endmodule
