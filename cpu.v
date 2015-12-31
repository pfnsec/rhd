module cpu(clk, reset, addr_a, dout_a, addr_b, din_b, dout_b, we_b);
	input clk, reset;
	output [11:0] addr_a;
	output reg [15:0] addr_b;
	input  [15:0] dout_a, dout_b;
	output reg [15:0] din_b;
	output reg we_b;

	reg carry;
	reg zero;
	
	reg [11:0] pc;
	reg [11:0] ram_pc;
	reg [11:0] ft_pc;
	reg [11:0] dc_pc;
	reg [11:0] ex_pc;

	reg [15:0] inst;


	reg [11:0] branch_target;
	reg        branching;

	reg [2:0]  exec_stall;


	reg [15:0] reg_file [0:7];

	reg [2:0]  exec_unit_sel;

	reg [15:0] exec_arg_a, exec_arg_b;

	reg [2:0]  dest_reg;

	reg [4:0]  alu_op;


	assign addr_a = pc;


	//opcode constants - see isa.txt for opcode formats
	parameter OP_REL_MEM  =  5'b010xx;  //PC-relative load/store
	parameter OP_REL_BRC  =  5'b011xx;  //pc-relative conditional branch
	parameter OP_REG_MOV  =  5'b00101;  //move between registers
	parameter OP_REG_IMM  =  5'b100xx;  //set reg to imm
	parameter OP_REG_MEM  =  5'b101xx;  //load/store from address in register
	parameter OP_REG_BRC  =  5'b00110;  //branch to address in register
	parameter OP_ALU      =  5'b11xxx;  //ALU operations
	parameter OP_NOP      =  5'b00000;  //NOP


	//exec_unit_sel constants 
	parameter EXEC_NONE   =  3'b000;
	parameter EXEC_BRANCH =  3'b001;
	parameter EXEC_ALU    =  3'b010;
	parameter EXEC_MEM    =  3'b011;
	parameter EXEC_REG    =  3'b100;

	//ALU opcode constants
	parameter ALU_ADD     =  5'b00000;
	parameter ALU_ADC     =  5'b00001;
	parameter ALU_SUB     =  5'b00010;
	parameter ALU_NOT     =  5'b00011;
	parameter ALU_AND     =  5'b00100;
	parameter ALU_OR      =  5'b00101;
	parameter ALU_XOR     =  5'b00110;
	parameter ALU_CSR     =  5'b00111;
	parameter ALU_CSL     =  5'b01000;
	parameter ALU_LSR     =  5'b01001;
	parameter ALU_LSL     =  5'b01010;


	initial begin
		reg_file[0] <= 15'b0;
		reg_file[1] <= 15'b0;
		reg_file[2] <= 15'b0;
		reg_file[3] <= 15'b0;
		reg_file[4] <= 15'b0;
		reg_file[5] <= 15'b0;
		reg_file[6] <= 15'b0;
		reg_file[7] <= 15'b0;
	end


	//fetch
	always @(posedge clk) begin
		if(reset) begin
			pc     <= 15'b0;
			ram_pc <= 15'b0;
			ft_pc  <= 15'b0;
			dc_pc  <= 15'b0;
			ex_pc  <= 15'b0;
		end else begin
			inst   <= dout_a;
			ex_pc  <= dc_pc;
			dc_pc  <= ft_pc;
			ft_pc  <= pc;
			ram_pc <= pc;
			pc     <= branching ? branch_target : pc + 1'b1;
		end
	end


	//decode
	always @(posedge clk) begin
		if(reset | inst == 0) begin
			exec_unit_sel <= EXEC_NONE;
			exec_arg_a    <= 16'b0;
			exec_arg_b    <= 16'b0;
		end else begin
			casex(inst[15:11])
				OP_NOP: begin
					exec_unit_sel <= EXEC_NONE;
					we_b <= 1'b0;
				end

				OP_REL_MEM: begin
					exec_unit_sel <= EXEC_MEM;

					if(inst[12]) begin
						we_b     <= 1'b1;
						din_b    <= reg_file[inst[11:9]];
					end else begin
						we_b     <= 1'b0;
						dest_reg <= inst[11:9];
					end
					
					addr_b <= inst[10] ? dc_pc - inst[9:0] - 1'b1 : dc_pc + inst[9:0] - 1'b1;
					
				end

				OP_REG_MEM: begin 
					exec_unit_sel <= EXEC_MEM;

					if(inst[12]) begin
						we_b     <= 1'b1;
						din_b    <= reg_file[inst[11:9]];
					end else begin
						we_b     <= 1'b0;
						dest_reg <= inst[11:9];
					end

					addr_b        <= inst[5] ? reg_file[inst[8:6]] - inst[4:0] 
								 : reg_file[inst[8:6]] + inst[4:0];
				end

				OP_REG_MOV: begin
					exec_unit_sel <= EXEC_REG;
					dest_reg      <= inst[10:8];
					exec_arg_a    <= inst[4] ? reg_file[inst[7:5]] >> inst[3:0] 
								 : reg_file[inst[7:5]] << inst[3:0];

					we_b          <= 1'b0;
				end

				OP_ALU: begin
					exec_unit_sel <= EXEC_ALU;
					dest_reg      <= inst[13:11];
					exec_arg_a    <= reg_file[inst[10:8]];
					exec_arg_b    <= reg_file[inst[7:5]];
					alu_op        <= inst[4:0];

					we_b          <= 1'b0;
				end

				OP_REG_IMM: begin
					exec_unit_sel <= EXEC_REG;
					dest_reg      <= inst[12:10];
					exec_arg_a    <= inst[9:0];
					we_b          <= 1'b0;
				end

				OP_REG_BRC: begin
					exec_unit_sel <= EXEC_BRANCH;
					exec_arg_a    <= inst[5] ? reg_file[inst[8:6]] - inst[4:0] - 1 
								 : reg_file[inst[8:6]] + inst[4:0] - 1;

					we_b          <= 1'b0;
				end

				OP_REL_BRC: begin 
					exec_unit_sel <= EXEC_BRANCH;
					exec_arg_a    <= inst[10] ? dc_pc - inst[9:0] - 1 
								  : dc_pc + inst[9:0] - 1;
					we_b          <= 1'b0;
				end

				default: begin
					exec_unit_sel <= EXEC_NONE;
					we_b          <= 1'b0;
				end

			endcase
		end
	end


	//execute
	always @(posedge clk) begin
		if(reset) begin
			exec_stall <= 0;
			branching  <= 0;
		end else if(exec_stall == 0) begin
			case(exec_unit_sel)

				EXEC_BRANCH: begin
					$display("%d: EXEC_BRANCH : %d", ex_pc, exec_arg_a[11:0] + 1);
					branch_target <= exec_arg_a[11:0];
					branching     <= 1'b1;

					//Ignore the next 2 instructions
					//(2 instructions + 1 CPU clock + Ram Delay + Fetch Delay)
					exec_stall    <= 3'd5; 
				end

				EXEC_ALU: begin
					case(alu_op)
						ALU_ADD: begin
							reg_file[dest_reg] = exec_arg_a + exec_arg_b;
						end

						ALU_ADC: begin
//							{carry,reg_file[dest_reg]} = exec_arg_a + exec_arg_b;
						end

						ALU_SUB: begin
							reg_file[dest_reg] = exec_arg_a - exec_arg_b;
						end

						ALU_NOT: begin
							reg_file[dest_reg] = ~exec_arg_a;
						end

						ALU_AND: begin
							reg_file[dest_reg] = exec_arg_a & exec_arg_b;
						end

						ALU_OR : begin
							reg_file[dest_reg] = exec_arg_a | exec_arg_b;
						end

						ALU_XOR: begin
							reg_file[dest_reg] = exec_arg_a ^ exec_arg_b;
						end

						ALU_CSR: begin
				//			reg_file[dest_reg] = (exec_arg_a >> exec_arg_b) | (exec_arg_a << (16'd16 - exec_arg_b));
						end

						ALU_CSL: begin
				//			reg_file[dest_reg] = (exec_arg_a << exec_arg_b) | (exec_arg_a >> (16'd16 - exec_arg_b));
						end

						ALU_LSR: begin
							reg_file[dest_reg] = (exec_arg_a >> exec_arg_b);
						end

						ALU_LSL: begin
							reg_file[dest_reg] = (exec_arg_a << exec_arg_b);
						end

					endcase
				end

				EXEC_MEM: begin
					if(we_b == 1'b0) begin
						reg_file[dest_reg] = dout_b;
						$display("%d: LOAD : r%d = [%x], exec_stall = %d", ex_pc, dest_reg, dout_b, exec_stall);
					end else //we_b == 1 (just let the write complete)
						$display("%d: STORE : [%x] = %d, exec_stall = %d", ex_pc, addr_b, din_b, exec_stall);
				end

				EXEC_REG: begin
					$display("%d: EXEC_REG : r%d = %x, exec_stall = %d", ex_pc, dest_reg, exec_arg_a, exec_stall);
					reg_file[dest_reg] = exec_arg_a;
				end

				default: begin
				end
			endcase
		end else begin
			branching  <= 1'b0;
			exec_stall <= (exec_stall == 3'b0) ? exec_stall : exec_stall - 1'b1;
		end
	end
endmodule
