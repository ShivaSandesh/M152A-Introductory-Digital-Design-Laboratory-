/*  Lab 3
    Stopwatch
    
    In this lab, you will be designing a stopwatch on the FPGA.
    
    Brandon Tai, Fnu Shiva Sandesh, Junyoung Kim */

module stopwatch (CLK, SEL, ADJ, RESET, PAUSE, AN, C);

// Input declaration
input wire CLK;   // INPUT: Master Clock signal
input wire ADJ;   // INPUT: When the ADJ input is set to logic high, the clock is in adjustment mode. 
input wire SEL;   // INPUT: SEL is a select switch which will choose minutes or seconds in the adjusting mode.
input wire RESET; // INPUT: RESET will force all of your counters to the initial state 00:00.
input wire PAUSE; // INPUT: PAUSE will pause the counter when the button is pressed, and continue the counter if it is pressed again

// Output declaration
output reg [0:3] AN; // OUTPUT: LED number selector, (least significant -> most significant) ==> (AN[0] -> AN[3])
output reg [0:7] C;  // OUTPUT: 7-segment individual segment selector, (CA, CB, CC, CD, CE, CF, CG, DP) ==> (C[0], C[1], ..., C[6], C[7])

reg [0:1] digit_select;

reg [0:3] SEC_ones = 4'b0000; // Seconds ones place
reg [0:2] SEC_tens = 3'b000;  // Seconds tens place
reg [0:3] MIN_ones = 4'b0000; // Minutes ones place
reg [0:2] MIN_tens = 3'b000;  // Minutes tens place

reg [0:1] update256 = 2'b00;

// Clock 

reg [0:18] COUNT_256Hz = 19'b0; // Convert 100 MHz -> 256 Hz ==> 1011111010111100001
reg [0:4]  COUNT_8Hz   = 5'b0;  // Convert  256 Hz -> 8 Hz   ==> 11111
reg [0:1]  COUNT_2Hz   = 2'b0;  // Convert    8 Hz -> 2 Hz   ==> 11
reg        COUNT_1Hz   = 1'b0;  // Convert    2 Hz -> 1 Hz   ==> 1

reg CLK_256Hz = 1'b0;  // 256 Hz
reg CLK_8Hz   = 1'b0;  // 8 Hz
reg CLK_2Hz   = 1'b0;  // 2 Hz
reg CLK_1Hz   = 1'b0;  // 1 Hz

reg [0:5] blink_count = 6'b0;
reg BLINK = 1'b0;

reg paused = 1'b0;

always @(posedge(CLK)) begin

    if (COUNT_256Hz == 19'b1111010000100100) begin
        CLK_256Hz = ~CLK_256Hz;
        COUNT_256Hz = 19'b0;
    end else begin
        COUNT_256Hz = COUNT_256Hz + 1;
    end

end

always @(posedge(CLK_256Hz)) begin

    if (COUNT_8Hz == 5'b11111) begin
        CLK_8Hz = ~CLK_8Hz;
        COUNT_8Hz = 5'b0;
    end else begin
        COUNT_8Hz = COUNT_8Hz + 1;
    end
    
end

always @(posedge(CLK_8Hz)) begin

    if (COUNT_2Hz == 2'b11) begin
        CLK_2Hz = ~CLK_2Hz;
        COUNT_2Hz = 2'b0;
    end else begin
        COUNT_2Hz = COUNT_2Hz + 1;
    end

end

// Counter 
always @(posedge(CLK_2Hz)) begin

    if (RESET == 1) begin
    
        SEC_ones = 4'b0000;
        SEC_tens = 3'b000;
        MIN_ones = 4'b0000;
        MIN_tens = 3'b000;
        
    end
    
    if (PAUSE == 1) begin
        paused = ~paused;
    end

    if (COUNT_1Hz == 1'b1 && paused == 0) begin // Technically every 1 Hz
        CLK_1Hz = ~CLK_1Hz;
    
        if (ADJ == 0) begin
        
            if (SEC_ones == 4'b1001) begin
                SEC_ones = 4'b0000;
                
                if (SEC_tens == 3'b101) begin
                    SEC_tens = 3'b000;
                
                    if (MIN_ones == 4'b1001) begin
                        MIN_ones = 4'b0000;
                    
                        if (MIN_tens == 3'b101) begin
                            MIN_tens = 3'b000;
                        
                        end else begin
                            MIN_tens = MIN_tens + 1;
                        end
                    
                    end else begin
                        MIN_ones = MIN_ones + 1;
                    end
                
                end else begin
                    SEC_tens = SEC_tens + 1;
                end
                
            end else begin
                SEC_ones = SEC_ones + 1;
            end
        
        end
        
    end

    COUNT_1Hz = ~COUNT_1Hz;
    
    if (ADJ == 1 && paused == 0) begin
    
        if (SEL == 1) begin
        
            if (SEC_ones == 4'b1001) begin
                SEC_ones = 4'b0000;
            
                if (SEC_tens == 3'b101) begin
                    SEC_tens = 3'b000;
                
                end else begin
                    SEC_tens = SEC_tens + 1;
                end
            
            end else begin
                SEC_ones = SEC_ones + 1;
            end
        
        end else begin
        
            if (MIN_ones == 4'b1001) begin
                MIN_ones = 4'b0000;
            
                if (MIN_tens == 3'b101) begin
                    MIN_tens = 3'b000;
                
                end else begin
                    MIN_tens = MIN_tens + 1;
                end
            
            end else begin
                MIN_ones = MIN_ones + 1;
            end
        
        end
    
    end

end

// change the sensitivity list to whenever the secs. minutes changes rather than this 
always @(posedge(CLK_256Hz)) begin

    if (ADJ == 1) begin
        blink_count = blink_count + 1;
        if (blink_count == 6'b111111) begin
            BLINK = ~BLINK;
        end
        
    end

    case (digit_select)
    
    2'b00 : begin 
        if (update256 == 2'b00) begin
            if (ADJ == 1 && SEL == 1 && ~BLINK) begin
                AN = 4'b1111;
            end else begin
                AN = 4'b0111; 
                C = numToDisplay(SEC_ones); 
            end
            update256 = 2'b01;
        end
    end
    
    2'b01 : begin 
        if (update256 == 2'b01) begin
            if (ADJ == 1 && SEL == 1 && ~BLINK) begin
                AN = 4'b1111;
            end else begin
                AN = 4'b1011; 
                C = numToDisplay(threeToFourBit(SEC_tens));
            end
            update256 = 2'b10;
        end
    end
    
    2'b10 : begin  
        if (update256 == 2'b10) begin
            if (ADJ == 1 && SEL == 0 && ~BLINK) begin
                AN = 4'b1111;
            end else begin
                AN = 4'b1101; 
                C = numToDisplay(MIN_ones);
            end
            update256 = 2'b11;
        end
    end
    
    2'b11 : begin  
        if (update256 == 2'b11) begin
            if (ADJ == 1 && SEL == 0 && ~BLINK) begin
                AN = 4'b1111;
            end else begin
                AN = 4'b1110; 
                C = numToDisplay(threeToFourBit(MIN_tens));
            end
            update256 = 2'b00;
        end
    end
    
    endcase
    
    digit_select = digit_select + 1;

end

function [0:3] threeToFourBit;
input [0:2] num;

    threeToFourBit = {0, num};

endfunction

// Seven-Segment Display 

function [0:7] numToDisplay;
input [0:3] num;

    case (num)
    
    4'b0000 : numToDisplay = 8'b00000011;   // Display 0
    
    4'b0001 : numToDisplay = 8'b10011111;   // Display 1
    
    4'b0010 : numToDisplay = 8'b00100101;   // Display 2
    
    4'b0011 : numToDisplay = 8'b00001101;   // Display 3
		
    4'b0100 : numToDisplay = 8'b10011001;   // Display 4
    
    4'b0101 : numToDisplay = 8'b01001001;   // Display 5
    
    4'b0110 : numToDisplay = 8'b01000001;   // Display 6
    
    4'b0111 : numToDisplay = 8'b00011111;   // Display 7
    
    4'b1000 : numToDisplay = 8'b00000001;   // Display 8
    
    4'b1001 : numToDisplay = 8'b00001001;   // Display 9
    
    endcase

endfunction


// Debouncers


endmodule