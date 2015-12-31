`timescale 1ns / 1ps

`include "board.v"

module stimulus;

	// Outputs

	reg clk, reset;
	wire [7:0] led;
	reg [7:0]  sw;

	// Instantiate the Unit Under Test (UUT)
	board uut (
		.clk (clk),
		.reset (reset),
		.led (led),
		.sw (sw)
	);

	initial begin
		// Initialize Inputs
		reset = 1;
		clk   = 0;
		sw    = 1'b1;
		
		// Wait 20 ns for global reset to finish
		#20;
		// Add stimulus here
		reset = 0;

	end

	always begin
		#10 clk = ~clk;
	end
      
endmodule

