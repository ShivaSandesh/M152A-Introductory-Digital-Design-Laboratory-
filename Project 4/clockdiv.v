`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:49:36 03/19/2013 
// Design Name: 
// Module Name:    clockdiv 
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
module clockdiv(
	input wire clk,		//master clock: 100MHz
	input wire rst,		//asynchronous reset
	output wire pix_en//,		//pixel clock: 25MHz
	//output wire seg_en	//7-segment clock: 381.47Hz
	);

// 17-bit counter variable
//reg [17:0] q;
reg [1:0] q;

// Clock divider --
// Each bit in q is a clock signal that is
// only a fraction of the master clock.
always @(posedge clk)
begin
	// reset condition
	if (rst == 1)
		q <= 0;
	// increment counter by one
	else
		q <= q+1;
end

// 100Mhz ÷ 2^18 = 381.47Hz
//assign seg_en = q[17];

// 100Mhz ÷ 2^2 = 25MHz
//assign pix_en = q[1];
assign pix_en = ~q[1] & ~q[0];

endmodule
