module regs (
    // peripheral clock signals
    input clk,
    input rst_n,
    // decoder facing signals
    input read,
    input write,
    input[5:0] addr,
    output reg[7:0] data_read, // Schimbat in 'reg' pentru a putea fi atribuit
    input[7:0] data_write,
    // counter programming signals
    input[15:0] counter_val,
    output[15:0] period,
    output en,
    output count_reset,
    output upnotdown,
    output[7:0] prescale,
    // PWM signal programming values
    output pwm_en,
    output[7:0] functions, 
    output[15:0] compare1,
    output[15:0] compare2
);


// PERIOD (0x00 - 0x01)
reg[15:0] period_reg;
assign period = period_reg;

// COUNTER_EN (0x02)
reg en_reg;
assign en = en_reg;

// COMPARE1 (0x03 - 0x04)
reg[15:0] compare1_reg;
assign compare1 = compare1_reg;

// COMPARE2 (0x05 - 0x06)
reg[15:0] compare2_reg;
assign compare2 = compare2_reg;

// PRESCALE (0x0A)
reg[7:0] prescale_reg;
assign prescale = prescale_reg;

// UPNOTDOWN (0x0B)
reg upnotdown_reg;
assign upnotdown = upnotdown_reg;

// PWM_EN (0x0C)
reg pwm_en_reg;
assign pwm_en = pwm_en_reg;

// FUNCTIONS (0x0D)
    reg[1:0] functions_reg; 
assign functions = functions_reg;

reg count_reset_pulse; 
assign count_reset = count_reset_pulse;


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // Resetare
        period_reg      <= 16'h0000;
        en_reg          <= 1'b0;
        compare1_reg    <= 16'h0000;
        compare2_reg    <= 16'h0000;
        prescale_reg    <= 8'h00;
        upnotdown_reg   <= 1'b1; // Default: incrementare 
        pwm_en_reg      <= 1'b0;
        functions_reg   <= 2'b00;
        count_reset_pulse <= 1'b0; 
    end
    else begin
      
        count_reset_pulse <= 1'b0; 
        if (write) begin
            case(addr)
                // PERIOD [15:8]
                6'h00: period_reg[7:0] <= data_write; // Adresa inferioara
                // PERIOD [7:0]
                6'h01: period_reg[15:8] <= data_write; // Adresa superioara

                // COUNTER_EN
                6'h02: en_reg <= data_write[0]; // Doar bitul 0 este util

                // COMPARE1 [7:0]
                6'h03: compare1_reg[7:0] <= data_write; // Adresa inferioara
                // COMPARE1 [15:8]
                6'h04: compare1_reg[15:8] <= data_write; // Adresa superioara

                // COMPARE2 [7:0]
                6'h05: compare2_reg[7:0] <= data_write; // Adresa inferioara
                // COMPARE2 [15:8]
                6'h06: compare2_reg[15:8] <= data_write; // Adresa superioara

                // COUNTER_RESET (Scriere declanseaza un puls de reset)
               
                6'h07: count_reset_pulse <= 1'b1; 

                // PRESCALE
                6'h0A: prescale_reg <= data_write;
                // UPNOTDOWN
                6'h0B: upnotdown_reg <= data_write[0];
                // PWM_EN
                6'h0C: pwm_en_reg <= data_write[0];
                // FUNCTIONS
                6'h0D: functions_reg <= data_write[1:0];
                default: ; 
            endcase
        end
    end
end

always@(*) begin
    data_read = 8'h00; 

    if (read) begin
        case(addr)
            // PERIOD [7:0]
            6'h00: data_read = period_reg[7:0];
            // PERIOD [15:8]
            6'h01: data_read = period_reg[15:8];
            // COUNTER_EN
            6'h02: data_read = {7'h00, en_reg}; // valoarea pe bitul LSB
            // COMPARE1 [7:0]
            6'h03: data_read = compare1_reg[7:0];
            // COMPARE1 [15:8]
            6'h04: data_read = compare1_reg[15:8];
            // COMPARE2 [7:0]
            6'h05: data_read = compare2_reg[7:0];
            // COMPARE2 [15:8]
            6'h06: data_read = compare2_reg[15:8];
            // COUNTER_VAL [7:0] (Citire valoare curenta)
            6'h08: data_read = counter_val[7:0];
            // COUNTER_VAL [15:8]
            6'h09: data_read = counter_val[15:8];
            // PRESCALE
            6'h0A: data_read = prescale_reg;
            // UPNOTDOWN
            6'h0B: data_read = {7'h00, upnotdown_reg};
            // PWM_EN
            6'h0C: data_read = {7'h00, pwm_en_reg};
            // FUNCTIONS
            6'h0D: data_read = {6'h00, functions_reg}; 
            default: data_read = 8'h00; 
        endcase
    end
end

endmodule
