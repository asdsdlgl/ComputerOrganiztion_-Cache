// Forwarding Unit

module FU ( 		// input
			EX_Rs,
            		EX_Rt,
			M_RegWrite,
			M_WR_out,
			WB_RegWrite,
			WB_WR_out,
			// output
			enF1,
			enF2,
			sF1,
			sF2
			);

	input [4:0] EX_Rs;
    	input [4:0] EX_Rt;
    	input M_RegWrite;
    	input [4:0] M_WR_out;
    	input WB_RegWrite;
    	input [4:0] WB_WR_out;

	output enF1;
    	output enF2;
    	output sF1;
    	output sF2;

	reg enF1;
	reg enF2;
	reg sF1;
	reg sF2;

	always @(*) begin

        	enF1 = 0;
		enF2 = 0;
		sF1 = 0;
		sF2 = 0;

		if(M_RegWrite==1 && M_WR_out!=0 && M_WR_out==EX_Rs) begin				//ok
		    sF1  = 0;
		    enF1 = 1;
		end
		if(M_RegWrite==1 && M_WR_out!=0 && M_WR_out==EX_Rt) begin				//ok
		    	sF2  = 0;
		    	enF2 = 1;
		end
		
		
		if(WB_RegWrite==1 && WB_WR_out!=0 && (!(M_RegWrite&&M_WR_out == EX_Rs)) && (WB_WR_out==EX_Rs)) begin
		    sF1  = 1;
		    enF1 = 1;
		end
		
		if(WB_RegWrite==1 && WB_WR_out!=0 && (!( M_RegWrite&&M_WR_out == EX_Rt))&& WB_WR_out==EX_Rt) begin
		    	sF2  = 1;
		    	enF2 = 1;
		end
		
	end

endmodule








