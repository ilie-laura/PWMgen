// Nume fisier: regs_tb.v

`timescale 1ns/1ns

module regs_tb;

    // --- Declararea Semnalelor (Intrari/Iesiri) ---
    // Semnale pilotate de TB (stimulus) -> trebuie sa fie 'reg'
    reg clk;
    reg rst_n;
    reg read;
    reg write;
    reg [5:0] addr;
    reg [7:0] data_write;
    reg [15:0] counter_val; 

    // Semnale primite de la DUT (monitorizare) -> trebuie sa fie 'wire'
    wire [7:0] data_read;   
    wire [15:0] period;
    wire en;
    wire count_reset;
    wire upnotdown;
    wire [7:0] prescale;
    wire pwm_en;
    wire [1:0] functions;
    wire [15:0] compare1;
    wire [15:0] compare2;

    // --- Instantiere Modul de Testat (DUT - Device Under Test) ---
    // Presupunem ca modulul tau 'regs' este in fisierul regs.v
    regs DUT (
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
        .pwm_en(pwm_en),
        .functions(functions),
        .compare1(compare1),
        .compare2(compare2)
    );

    // --- Generare Ceas (Clock Generation) ---
    parameter CLK_PERIOD = 10; // 10ns -> 100MHz
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Secventa de Test ---
    initial begin
        // 1. Initializare si Reset -----------------------------------
        $display("-------------------------------------------");
        $display("Incepere Testbench...");
        
        // Setare semnale de control in repaus
        read = 1'b0;
        write = 1'b0;
        addr = 6'h00;
        data_write = 8'h00;
        counter_val = 16'hAAAA; // Valoare de test pentru COUNTER_VAL

        // Aplicare Reset
        rst_n = 1'b0;
        repeat(5) @(posedge clk);
        
        // Eliberare Reset
        rst_n = 1'b1;
        @(posedge clk);
        $display("Reset completat. Valori initiale: Period=%h, Enable=%b", period, en);

        // 2. Testare Registru pe 16 Biti (PERIOD) - Scrierea ----------------
        // Scriere Period = 16'h1234
        $display("-------------------------------------------");
        $display("Test S/C Registru 16-bit (PERIOD, 0x00-0x01)");
        
        // Scriere LSB (0x34)
        write = 1'b1;
        addr = 6'h00; 
        data_write = 8'h34;
        @(posedge clk);
        
        // Scriere MSB (0x12)
        addr = 6'h01; 
        data_write = 8'h12;
        @(posedge clk);
        
        write = 1'b0;
        $display("Scriere: PERIOD = %h (Asteptat: 1234)", period);

        // Testare Registru pe 16 Biti (PERIOD) - Citirea ----------------
        read = 1'b1;
        
        // Citire LSB (0x34)
        addr = 6'h00; 
        @(posedge clk);
        $display("Citire 0x00: %h (Asteptat: 34)", data_read);

        // Citire MSB (0x12)
        addr = 6'h01; 
        @(posedge clk);
        $display("Citire 0x01: %h (Asteptat: 12)", data_read);
        
        read = 1'b0;
        @(posedge clk);
        
        // 3. Testare Registru pe 1 Bit (COUNTER_EN) ----------------------
        $display("-------------------------------------------");
        $display("Test S/C Registru 1-bit (COUNTER_EN, 0x02)");
        
        // Scriere EN = 1
        write = 1'b1;
        addr = 6'h02;
        data_write = 8'hFF; // Orice valoare unde bitul 0 e 1
        @(posedge clk);
        write = 1'b0;
        $display("Scriere: EN = %b (Asteptat: 1)", en);
        
        // Citire EN
        read = 1'b1;
        @(posedge clk);
        $display("Citire 0x02: %h (Asteptat: 01)", data_read);
        read = 1'b0;
        @(posedge clk);

        // 4. Testare Registru Citire-Doar (COUNTER_VAL) --------------------
        $display("-------------------------------------------");
        $display("Test Registru Read-Only (COUNTER_VAL, 0x08-0x09)");
        
        // Citire LSB 
        read = 1'b1;
        addr = 6'h08; 
        @(posedge clk);
        $display("Citire 0x08: %h (Asteptat: AA - LSB din AAAA)", data_read);

        // Citire MSB 
        addr = 6'h09; 
        @(posedge clk);
        $display("Citire 0x09: %h (Asteptat: AA - MSB din AAAA)", data_read);
        read = 1'b0;
        @(posedge clk);

        // 5. Testare Registru Scriere-Doar (COUNTER_RESET) ------------------
        $display("-------------------------------------------");
        $display("Test Registru Write-Only (COUNTER_RESET, 0x07)");
        $display("count_reset initial: %b", count_reset);

        // Scriere la 0x07
        write = 1'b1;
        addr = 6'h07;
        data_write = 8'h01; 
        @(posedge clk);
        write = 1'b0;
        $display("Dupa Scriere (Ciclu 1): count_reset = %b (Asteptat: 1)", count_reset);
        
        // Verificare pulsul (Ciclu 2)
        @(posedge clk); 
        $display("Dupa al 2-lea ciclu: count_reset = %b (Asteptat: 0)", count_reset);
        @(posedge clk); // Un ciclu extra

        // 6. Testare Adresa Necunoscuta (Citire) ------------------------
        $display("-------------------------------------------");
        $display("Test Adresa Necunoscuta (0xFF)");
        read = 1'b1;
        addr = 6'h1F; // O adresa in afara celor 0x00-0x0D
        @(posedge clk);
        $display("Citire 0x1F: %h (Asteptat: 00)", data_read);
        read = 1'b0;
        
        $display("-------------------------------------------");
        $display("Testbench completat.");
        $finish; // Oprire simulare
    end

endmodule