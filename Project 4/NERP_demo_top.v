`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// Module Name:    NERP_demo_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module NERP_demo_top(
	input wire clk,			//master clock = 100MHz
	input wire clr,			//right-most pushbutton for reset
    input wire up_in,
    input wire down_in,
    input wire pause_in,
	//output wire [6:0] seg,	//7-segment display LEDs
	//output wire [3:0] an,	//7-segment display anode enable
	//output wire dp,			//7-segment display decimal point
	output wire [2:0] red,	//red vga output - 3 bits
	output wire [2:0] green,//green vga output - 3 bits
	output wire [1:0] blue,	//blue vga output - 2 bits
	output wire hsync,		//horizontal sync out
	output wire vsync,			//vertical sync out
    output wire [0:3] AN, // OUTPUT: LED number selector, (least significant -> most significant) ==> (AN[0] -> AN[3])
    output wire [0:7] C  // OUTPUT: 7-segment individual segment selector, (CA, CB, CC, CD, CE, CF, CG, DP) ==> (C[0], C[1], ..., C[6], C[7])
	);

// VGA display clock interconnect
wire pix_en;

	reg rst;
	reg rst_ff;
    reg up;
    reg up_ff;
    reg down;
    reg down_ff;
    reg pause;
    reg pause_ff;
 
	always @(posedge clk) begin
		if (clr) begin
			{rst,rst_ff} <= 2'b11;
		end
		else begin
			{rst,rst_ff} <= {rst_ff,1'b0};
		end
        
        if (up_in) begin
			{up,up_ff} <= 2'b11;
        end
        else begin
			{up,up_ff} <= {up_ff,1'b0};
        end
        
        if (down_in) begin
			{down,down_ff} <= 2'b11;
        end
        else begin
			{down,down_ff} <= {down_ff,1'b0};
        end
        
        if (pause_in) begin
			{pause,pause_ff} <= 2'b11;
        end
        else begin
			{pause,pause_ff} <= {pause_ff,1'b0};
        end
	end


// generate 7-segment clock & display clock
clockdiv U1(
	.clk(clk),
	.rst(rst),
	.pix_en(pix_en)
	);

// VGA controller
pong U3(
	.pix_en(pix_en),
	.clk(clk),
	.rst(rst),
    .up(up),
    .down(down),
    .pause(pause),
	.hsync(hsync),
	.vsync(vsync),
	.red(red),
	.green(green),
	.blue(blue),
    .AN(AN),
    .C(C)
	);

endmodule
