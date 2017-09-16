/*  Test Bench for Lab 2 
    Floating Pointeger Conversion
    
    In this lab, you will learn how to use the Xilinx ISE program 
    to design and test a floating pointeger converter.
    
    Shiva Sandesh, Junyoung Kim, Brandon Tai */

`timescale 1ns/1ps

module float_converter_tb;

reg [11:0] D_in_T;  // Input 12-bit two's complement representation
wire S_T;           // Output Sign Bit
wire [3:0] F_T;     // Output 4-bit Mantissa
wire [2:0] E_T;     // Output 3-bit Exponent

wire [11:0] D_T;

float_converter UUT (.D_in(D_in_T),
                      .S(S_T),
                      .F(F_T),
                      .E(E_T)
    );

initial begin
    D_in_T <= 12'b0000000000000;
end

initial begin
    #5 D_in_T = 12'b000011110000;
end

initial begin
    #10 D_in_T = 12'b000001111000;
end

initial begin
    #15 D_in_T = 12'b100011110000;
end

initial begin
    #20 D_in_T = 12'b111111111111;
end

initial begin
    #25 D_in_T = 12'b011111000000;
end

initial begin
    #30 D_in_T = 12'b000000101110;
end
initial begin
    #35 D_in_T = 12'b000000101100 ;
end
initial begin
    #40 D_in_T = 12'b000000101101 ;
end
initial begin
    #45 D_in_T = 12'b000000101110 ;
end
initial begin
    #50 D_in_T = 12'b000000101111  ;
end
initial begin
    #55 $finish; // After 55 timeunits, terminate simulation.
end

endmodule