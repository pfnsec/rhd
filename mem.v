module blk_mem(clk_a, we_a, addr_a, din_a, dout_a, clk_b, we_b, addr_b, din_b, dout_b);
	input clk_a;
	input  [0  : 0] we_a;
	input  [11 : 0] addr_a;
	input  [15 : 0] din_a;
	output reg [15 : 0] dout_a;
	
	input clk_b;
	input  [0  : 0] we_b;
	input  [11 : 0] addr_b;
	input  [15 : 0] din_b;
	output reg [15 : 0] dout_b;

	reg [15:0] program [0:1023];

	initial begin
		$readmemb("src/program.bin", program);
	end

	always @(posedge clk_a) begin
		if(we_a) begin
			program[addr_a] <= din_a;
		end else begin
			dout_a <= program[addr_a];
		end
	end

	always @(posedge clk_b) begin
		if(we_b) begin
			program[addr_b] <= din_b;
		end else begin
			dout_b <= program[addr_b];
		end
		
	end

endmodule


