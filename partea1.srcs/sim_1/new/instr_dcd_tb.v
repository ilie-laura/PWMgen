`timescale 1ns / 1ps

module instr_dcd_tb;

    // Semnale pentru ceas ?i reset
    reg clk;
    reg rst_n;
    
    // Semnale pentru SPI (simularea perifericului)
    reg byte_sync;
    reg [7:0] data_in;
    wire [7:0] data_out;
    
    // Semnale c?tre/din Registru (DUT ports)
    wire read;
    wire write;
    wire [5:0] addr;
    wire [7:0] data_write;
    wire [7:0] data_read;
    wire high_low; // NOU: Semnal pentru bitul High/Low din instruc?iune
    
    //-------------------------------------------------------------------------
    // 1. Instan?ierea Decodorului de Instruc?iuni (DUT)
    //-------------------------------------------------------------------------
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
        .high_low(high_low) // NOU: Conectarea portului
    );

    //-------------------------------------------------------------------------
    // 2. Instan?ierea Stub-ului de Registru (Simuleaz? memoria)
    //-------------------------------------------------------------------------
    reg_file_stub REG_STUB (
        .clk(clk),
        .rst_n(rst_n),
        .read(read),
        .write(write),
        .addr(addr),
        .data_write(data_write),
        .data_read(data_read)
    );

    //-------------------------------------------------------------------------
    // 3. Generare Ceas
    //-------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // Perioada de 10ns (frecven?? 100MHz)
    end

    //-------------------------------------------------------------------------
    // 4. Sarcini (Tasks) de Tranzac?ie
    //-------------------------------------------------------------------------

    // Task pentru a simula un ciclu de ceas cu byte_sync activ
    task pulse_sync;
        begin
            @(posedge clk);
            byte_sync = 1'b1;
            @(negedge clk);
            byte_sync = 1'b0;
        end
    endtask

    // Task pentru tranzac?ie WRITE (2 bytes)
    task write_trans;
        input [7:0] cmd;
        input [7:0] data;
        begin
            $display("\n--- Tranzactie WRITE (Cmd: %h, Data: %h) ---", cmd, data);
            
            // Ciclu 1: Comanda (S_SETUP)
            data_in = cmd;
            pulse_sync;
            
            // Asteptare pentru propagarea adresei
            #1; 
            $display("[Ciclul 1] Stare: S_SETUP -> S_DATA. Adresa: %h. Write/Read: %b/%b. High/Low: %b", addr, write, read, high_low);

            // Ciclu 2: Date (S_DATA)
            data_in = data;
            pulse_sync;
            
            #1;
            $display("[Ciclul 2] Stare: S_DATA -> S_SETUP. Adresa finala: %h. Write/Read: %b/%b. Data Scrisa: %h", addr, write, read, data_write);

            data_in = 8'h00; // Resetam data_in
        end
    endtask
    
    // Task pentru tranzac?ie READ (2 bytes)
    task read_trans;
        input [7:0] cmd;
        output [7:0] out_data;
        begin
            $display("\n--- Tranzactie READ (Cmd: %h) ---", cmd);

            // Ciclu 1: Comanda (S_SETUP)
            data_in = cmd;
            pulse_sync;
            
            #1; 
            $display("[Ciclul 1] Stare: S_SETUP -> S_DATA. Adresa: %h. Write/Read: %b/%b. High/Low: %b", addr, write, read, high_low);

            // Ciclu 2: Dummy Read (S_DATA)
            data_in = 8'hFF; // Dummy byte trimis de master in timpul citirii
            pulse_sync;
            
            #1;
            $display("[Ciclul 2] Stare: S_DATA -> S_SETUP. Adresa finala: %h. Write/Read: %b/%b. Data Citita: %h (data_out)", addr, write, read, data_out);
            
            out_data = data_out;
            data_in = 8'h00; // Resetam data_in
        end
    endtask
    
    //-------------------------------------------------------------------------
    // 5. Secven?a Principal? de Test
    //-------------------------------------------------------------------------
    initial begin
        reg [7:0] read_result;
        
        // Initializare
        byte_sync = 1'b0;
        data_in = 8'h00;
        rst_n = 1'b0;
        
        $display("---------------------------------------------------------");
        $display("                 INCEPERE SIMULARE");
        $display("---------------------------------------------------------");
        
        @(negedge clk);
        rst_n = 1'b1;
        $display("\nTEST 3: RESET sistem");
        $display("Dupa reset -> ADDR=%h | WRITE=%b | READ=%b", addr, write, read);
        
        // Asteapta cateva cicluri pentru stabilizare
        repeat(2) @(posedge clk);
        
        // --- TEST 1: WRITE High la adresa 0x15 (Comanda D5, Data 55) ---
        write_trans(8'hD5, 8'h55); 
        // Asteptat: ADDR=0x16, WRITE=1 in Ciclul 2, DATA_WRITE=0x55
        
        // --- TEST 4: WRITE Low la adresa 0x0A (Comanda 8A, Data 77) ---
        write_trans(8'h8A, 8'h77);
        // Asteptat: ADDR=0x0A, WRITE=1 in Ciclul 2, DATA_WRITE=0x77

        // --- TEST 2: READ Low la adresa 0x22 (Comanda 22) ---
        // REG_STUB are 0xAB in 0x22
        read_trans(8'h22, read_result);
        // Asteptat: ADDR=0x22, READ=1 in Ciclul 1, DATA_OUT=0xAB in Ciclul 2
        $display("VERIFICARE TEST 2: Adresa citita: %h. Data citita (expectata 0xAB): %h", addr, read_result);

        // --- TEST 5: READ High la adresa 0x0F (Comanda 4F) ---
        // 0x4F -> Base=0x0F, High=1 -> Addr=0x10. REG_STUB are 0xCC in 0x10
        read_trans(8'h4F, read_result);
        // Asteptat: ADDR=0x10, READ=1 in Ciclul 1, DATA_OUT=0xCC in Ciclul 2
        $display("VERIFICARE TEST 5: Adresa citita: %h. Data citita (expectata 0xCC): %h", addr, read_result);

        // --- TEST 6: Doua instructiuni consecutive (Write 0x1A, Read 0x01) ---
        $display("\nTEST 6: Doua instructiuni consecutive (Write 0x1A, Read 0x01)");

        // Instructiunea 1: Write Low la adresa 0x1A (Comanda 9A, Data AA)
        // 9A -> Base=0x1A, Low=0 -> Addr=0x1A. Data=0xAA
        $display("\n--- Instructiunea 1: WRITE Low 0x1A, Data 0xAA ---");
        data_in = 8'h9A; // Cmd (S_SETUP)
        pulse_sync;
        // Aici ADDR=0x1A, READ=0, WRITE=0 (inca)
        
        data_in = 8'hAA; // Data (S_DATA)
        pulse_sync;
        // Aici ADDR=0x1A, READ=0, WRITE=1, DATA_WRITE=0xAA (se scrie 0xAA in 0x1A)

        // Instructiunea 2: Read Low la adresa 0x01 (Comanda 01)
        // 01 -> Base=0x01, Low=0 -> Addr=0x01. REG_STUB are 0xBB in 0x01
        $display("\n--- Instructiunea 2: READ Low 0x01 ---");
        data_in = 8'h01; // Cmd (S_SETUP)
        pulse_sync;
        // Aici ADDR=0x01, READ=1, WRITE=0
        
        data_in = 8'hFF; // Dummy Read (S_DATA)
        pulse_sync;
        // Aici ADDR=0x01, READ=0, WRITE=0, DATA_OUT=0xBB (rezultatul citirii)

        $display("\nSTATUS FINAL TEST 6:");
        $display("Adresa finala asteptata: 0x01. Adresa curenta: %h", addr);
        $display("Data finala de iesire (asteptata 0xBB): %h", data_out);
        $display("WRITE (asteptata 0): %b | READ (asteptata 0): %b", write, read);
        
        // Finalizare
        $finish;
    end
    
endmodule