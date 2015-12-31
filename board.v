/*
// Demo system for the Digilent Basys 2.
*/

`include "cpu.v"
`include "mem.v"

module board(
	clk, reset, led, sw
    );

	input clk, reset;
	output [7:0] led;
	input  [7:0] sw;
	
	reg [15:0] gpio_state;

	assign led = gpio_state[7:0];

	parameter MEM_INST = 4'b0000;
	parameter MEM_GPIO = 4'b0001;
 

	wire cpu_we_a, cpu_we_b;
	wire [11:0] cpu_addr_a;
	wire [15:0] cpu_addr_b;
	wire [15:0] cpu_din_b, cpu_dout_a, cpu_dout_b;

	wire mem_we_a, mem_we_b;
	wire [11:0] mem_addr_a, mem_addr_b;
	wire [15:0] mem_din_a, mem_din_b, mem_dout_a, mem_dout_b;

	assign cpu_we_a   = 1'b0;

	assign mem_addr_a = cpu_addr_a;

	assign mem_addr_b = cpu_addr_b;


	assign mem_din_b  = cpu_din_b;

	assign mem_we_a   = 1'b0;

	assign mem_we_b   = cpu_addr_b[15:12] == MEM_INST ? cpu_we_b : 1'b0;

	assign cpu_dout_b = cpu_addr_b[15:12] == MEM_INST ? mem_dout_b
			  : cpu_addr_b[15:12] == MEM_GPIO ? gpio_state 
			  : 16'b0;

	assign cpu_dout_a = mem_dout_a;

/*
	//Xilinx ISE Block Memory Generator
	blk_mem_gen_v7_3 pri_mem (
		.clka  (clk),        // input clka
		.wea   (mem_we_a),   // input  [0  : 0] wea
		.addra (mem_addr_a), // input  [10 : 0] addra
		.dina  (mem_din_a),  // input  [15 : 0] dina
		.douta (mem_dout_a), // output [15 : 0] douta
		.rsta  (reset),
		.clkb  (clk),        // input clkb
		.web   (mem_we_b),   // input  [0  : 0] web
		.addrb (mem_addr_b), // input  [10 : 0] addrb
		.dinb  (mem_din_b),  // input  [15 : 0] dinb
		.doutb (mem_dout_b), // output [15 : 0] doutb
		.rstb  (reset)
	);
*/

	//Inferred BRAM (for iverilog)
	blk_mem pri_mem(
		.clk_a	(clk),
		.we_a	(mem_we_a),
		.addr_a (mem_addr_a),
		.din_a  (mem_din_a),
		.dout_a (mem_dout_a),
		.clk_b	(clk),
		.we_b   (mem_we_b),
		.addr_b (mem_addr_b),
		.din_b  (mem_din_b),
		.dout_b (mem_dout_b));


	cpu pri_cpu(
		.clk    (clk),
		.reset  (reset),
		.addr_a (cpu_addr_a),
		.addr_b (cpu_addr_b),
		.dout_a (cpu_dout_a),
		.dout_b (cpu_dout_b),
		.din_b  (cpu_din_b),
		.we_b   (cpu_we_b)
	);

	//LED/Switch control
	always @(posedge clk) begin
		gpio_state[15:8] <= sw;

		if(cpu_addr_b[15:12] == MEM_GPIO) begin
			if(cpu_we_b)
				gpio_state[7:0] <= cpu_din_b[7:0];
		end
	end

	initial begin
		gpio_state[7:0] <= 0;
	end

endmodule
