/*  Lab 2 
    Floating Pointeger Conversion
    
    In this lab, you will learn how to use the Xilinx ISE program 
    to design and test a floating pointeger converter.
    
    Brandon Tai, Fnu Shiva Sandesh, Junyoung Kim */

module float_converter (D_in, S, F, E);

// Input and output declaration
input wire [11:0] D_in;  // Input 12-bit two's complement representation
output reg S;            // Output Sign Bit
output reg [3:0] F;      // Output 4-bit Mantissa
output reg [2:0] E;      // Output 3-bit Exponent

reg [11:0] D;

reg [3:0] num_zeroes;

integer i, j, exp, nonzero_iter;

reg brk;

always @(D_in) begin // Whenever D changes
    
    S = D_in[11]; // Save sign bit
    F = 4'b0000;
    E = 3'b000;
    D = D_in;
    
    num_zeroes = 3'b0000;
    brk = 1'b0;
	 
    /* CONVERT TO UNSIGNED MAGNITUDE */
    
    if (S != 0) begin
    
        for (i = 0; i < 12; i = i + 1) begin
            D[i] = ~ D[i];
        end
        
        for (i = 0; (i < 12) && (brk == 0); i = i + 1) begin
		
            if (D[i] == 0) begin
                D[i] = 1;
                brk = 1'b1;
            end else begin
                D[i] = 0;
            end
            
        end
        
    end
    
    brk = 1'b0;
    
    /* CALCULATE E */
    
    for (i = 11; (i > 3) && (brk == 0); i = i - 1) begin
    
        if (D[i] == 1) begin
            brk = 1'b1;
        end else begin
            num_zeroes = num_zeroes + 1;
        end
        
    end
    
    E = 8 - num_zeroes;
    
    /* CALCULATE F */
    
    nonzero_iter = 11 - num_zeroes;
    
    for (i = 3; i >= 0; i = i - 1) begin
        F[i] = D[nonzero_iter];
        nonzero_iter = nonzero_iter - 1;
    end
    
    /* COMPUTE ROUNDING */
    
    brk = 1'b0;
    
    if (nonzero_iter == 1) begin
    
        for (i = 0; (i < 4) && (brk == 0); i = i + 1) begin // Add 1 to F loop
        
            if (F[i] == 0) begin
                F[i] = 1;
                brk = 1'b1;
            end else begin
            
                F[i] = 0;
            
                if (i == 3) begin // F = 0xF case
                
                    F[3] = 1;
                    
                    for (j = 0; (j < 3) && (brk == 0); j = j + 1) begin
                    
                        if (E[j] == 0) begin
                            E[j] = 1;
                            brk = 1'b1;
                        end else begin
                        
                            E[j] = 0;
                            
                            if (j == 2) begin  // E = 0xF case, don't round
                                F = 4'b1111;   // set F to 0xF
                                E = 3'b111;    // set E to 0x7
                            end
                            
                        end
                        
                    end
                    
                end
            
            end
            
        end
        
    end
    
    //display(S);
    //display(F);
    //display(E);
    
end

endmodule