// Cache Control

module Cache_Control ( 
					   clk,
					   rst,
					   // input
					   en_R,
					   en_W,
					   hit,
					   // output
					   Read_mem,
					   Write_mem,
					   Valid_enable,
					   Tag_enable,
					   Data_enable,
					   sel_mem_core,
					   stall
					   );
	
	input clk, rst;
	input en_R;
	input en_W;
    input hit;
	
	output Read_mem;
	output Write_mem;
	output Valid_enable;
	output Tag_enable;
	output Data_enable;
	output sel_mem_core;		// 0 data from mem, 1 data from core
	output stall;
	reg Read_mem;
	reg Write_mem;
	reg Valid_enable;
	reg Tag_enable;
	reg Data_enable;
	reg sel_mem_core;
	reg stall;	
	
	parameter Read_mode	 = 2'b10,
			  Write_mode = 2'b01;
	
	// read state
	parameter R_Idle		 = 0,
			  R_wait		 = 1,
			  R_Read_Memory	 = 2;
	
	reg [1:0] cur_R_state;
	reg [1:0] nxt_R_state;
	
	wire Read_Miss;
	assign Read_Miss = !hit;/*please fill here*/
	
	// write state
	parameter Write_Miss = 0,
			  Write_Hit	 = 1;
	
	// FSM circuit
	always @ (*) begin
		// if read miss, to R_Read_Memory state
		case (cur_R_state)
		R_Idle			 : nxt_R_state = Read_Miss ?
										 R_wait : R_Idle;
		R_wait			 : nxt_R_state = R_Read_Memory;
		R_Read_Memory	 : nxt_R_state = R_Idle;
		endcase
	end
	
	// main circuit
	always @ (*) begin
		Read_mem	 = 0;
		Write_mem	 = 0;
		Valid_enable 	 = 0;
		Tag_enable	 = 0;
		Data_enable	 = 0;
		sel_mem_core 	 = 0; //default is 0 ; select data from memory
		stall = 0;
		
		if(en_R)
		begin
			if(!hit)
				stall = 1;
				
			case(cur_R_state)
			R_Idle:
			begin
				Read_mem = 1;
			end
			R_Read_Memory:
			begin
				Read_mem = 1;
				Data_enable = 1;
				Valid_enable = 1;
				Tag_enable = 1;
			end
			endcase
		end
		if(en_W)
		begin
			Write_mem = 1;
			if(hit)
			begin
				sel_mem_core = 1;
				Data_enable = 1;
				Valid_enable = 1;
				Tag_enable = 1;
			end
		end
		
	end
	
	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			cur_R_state <= R_Idle;
		end
		else begin
			cur_R_state <= nxt_R_state;	
		end
	end
	
endmodule




















