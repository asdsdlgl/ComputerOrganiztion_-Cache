// top
`include "PC.v"
`include "IF_ID.v"
`include "HDU.v"
`include "Controller.v"
`include "Regfile.v"
`include "Mux2to1.v"
`include "ID_EX.v"
`include "Mux4to1.v"
`include "Jump_Ctrl.v"
`include "FU.v"
`include "ALU.v"
`include "EX_M.v"
`include "M_WB.v"
`include "Mux2to1_5bit.v"

module core (
			  clk,
              rst,
			  // Instruction Cache
			  IC_stall,  
			  IC_Address,
              Instruction,
			  // Data Cache
			  DC_stall,   
			  DC_Address,
			  DC_Read_enable,  
			  DC_Write_enable,
			  DC_Write_Data,
			  DC_Read_Data
			  );

	parameter data_size = 32;
	parameter mem_size = 16;
	parameter pc_size = 18;
	
	input  clk, rst;
	
	// Instruction Cache
	input  IC_stall;
	output [mem_size-1:0] IC_Address;
	input  [data_size-1:0] Instruction;
	
	// Data Cache
	input  DC_stall;
	output [mem_size-1:0] DC_Address;
	output DC_Read_enable;
	output DC_Write_enable;
	output [data_size-1:0] DC_Write_Data;
    input  [data_size-1:0] DC_Read_Data;
	
	// Write your code here
	// Wire Declaration part-----------------------------------*/
	// PC
	wire [pc_size-1:0] PCout;	 
	wire [pc_size-1:0] PC_add4;
	
	// IF_ID pipe---------------------------------
	wire [pc_size-1:0]   ID_PC;
	wire [data_size-1:0] ID_ir;
	
	// Hazard Detection Unit
	/*please declare the wire used for Hazard Detection Unit here*/
	/*-----------------------------------------------------*/
	
	wire PCWrite;
	wire IF_IDWrite;
	wire ID_EXWrite;
	wire EX_MWrite;
	wire M_WBWrite;
	wire IF_Flush;
	wire ID_Flush;			
	
	/*-----------------------------------------------------*/
	wire Branch_Flush;
	wire Load_wait;
	
	// Controller
	wire [5:0] opcode;
	wire [5:0] funct;
	wire Reg_imm;
	wire Jump;
	wire Branch;
	wire Jal;
	wire Jr;
	wire MemtoReg;
	wire [3:0] ALUOp;
	wire RegWrite;
	wire MemWrite;
	wire ExtendLH;
	wire ExtendSH;
	// Registers
	wire [4:0] Rd;
	wire [4:0] Rs;
	wire [4:0] Rt;
	wire [data_size-1:0] Rs_data;
	wire [data_size-1:0] Rt_data;
	wire [4:0] shamt;
	
	// sign_extend	
	wire [15:0] imm;
	wire [data_size-1:0] se_imm;	
	
	// ID Mux part
	wire [4:0] Rd_Rt_out;
	wire [4:0] WR_out;
	
	// ID_EX 
	/*please declare the wire used for ID_EX pipe here*/	
	/*Tip: There are control signal part and data part*/
	/*-----------------------------------------------------*/

	// EX
	wire EX_Reg_imm;
	wire EX_Jump;
	wire EX_Branch;
	wire EX_Jr;	

	// MEM
	wire EX_MemWrite;
	wire EX_Jal;
	wire EX_ExtendLH;
	wire EX_ExtendSH;
	// WB
	wire EX_MemtoReg;
	wire EX_RegWrite;
		
	// pipe
	wire [pc_size-1:0] EX_PC;
	wire [3:0] EX_ALUOp;
	wire [4:0] EX_shamt;
	wire [data_size-1:0] EX_Rs_data;
	wire [data_size-1:0] EX_Rt_data;
	wire [data_size-1:0] EX_se_imm;
	wire [4:0] EX_WR_out;
	wire [4:0] EX_Rs;
	wire [4:0] EX_Rt;
	
	/*-----------------------------------------------------*/
	//Jump Part
	wire [pc_size-1:0] BranchAddr;
	wire [pc_size-1:0] JumpAddr;
	wire [1:0] EX_JumpOP;
	wire [pc_size-1:0] PCin;
	
	// Forwarding Unit part
	/*please declare the wire used for forwarding unit here*/
	/*-----------------------------------------------------*/

	wire enF1;
    wire enF2;
    wire sF1;
   	wire sF2;

	/*-----------------------------------------------------*/
	wire [data_size-1:0] sF1_data;
	wire [data_size-1:0] sF2_data;
	wire [data_size-1:0] enF1_data;
	wire [data_size-1:0] enF2_data;
	
	// ALU part
	wire [data_size-1:0] scr2;	
	wire [data_size-1:0] EX_ALU_result;
	wire EX_Zero;
	
	// PCplus4 adder used for Jal
	/*please declare the wire used for PCplus4 Adder (at EX stage)*/
	/*-----------------------------------------------------*/

	wire [pc_size-1:0] EX_PCplus8;
	
	/*-----------------------------------------------------*/
	// EX_M
	/*please declare the wire used for EX_M pipe*/
	/*Tip: There are control signal part and data part*/
	/*-----------------------------------------------------*/
	// WB
	wire M_MemtoReg;	
	wire M_RegWrite;	

	// MEM
	wire M_MemWrite;	
	wire M_Jal;		
	wire M_ExtendLH;
	wire M_ExtendSH;
	// pipe		  
	wire [data_size-1:0] M_ALU_result;
	wire [data_size-1:0] M_Rt_data;
	wire [pc_size-1:0] M_PCplus8;
	wire [4:0] M_WR_out;
	wire [data_size-1:0] M_Rt_data_extend;
	wire [data_size-1:0] M_DM_Write_data;
	wire [data_size-1:0] M_Rt_data_extend1;
	wire [data_size-1:0] M_DM_Read_data;
	/*-----------------------------------------------------*/
	// M Jal part
	wire [data_size-1:0] M_WD_out;
	
	// M_WB
	/*please declare the wire used for M_WB pipe*/
	/*Tip: There are control signal part and data part*/
	/*-----------------------------------------------------*/
	// WB
	wire WB_MemtoReg;
	wire WB_RegWrite;

	// pipe
    	wire [data_size-1:0] WB_DM_Read_Data;
    	wire [data_size-1:0] WB_WD_out;
    	wire [4:0] WB_WR_out;
	
	/*-----------------------------------------------------*/
	
	// WD or DM Read data mux out

	wire [data_size-1:0] WB_Final_WD_out;
	
	// Wire Connect Part
	/* -------------------------------------------------------------------------------------------*/ 
	/* Below here, you are asked to complete the wire connection with the wire you declared above.*/
	/* Determine which wire should be filled in the "please fill here" area. ---------------------*/
	/* -------------------------------------------------------------------------------------------*/
	
	// PC
	assign IC_Address = PCout[pc_size-1:2];	
	
	// Controller
	assign opcode		 = ID_ir[31:26];
	assign funct		 = ID_ir[5:0];
	
	// Registers
	assign Rd		 = ID_ir[15:11];
	assign Rs		 = ID_ir[25:21];
	assign Rt		 = ID_ir[20:16];
	
	// sign_extend
	assign imm		 = ID_ir[15:0];
	
	// shamt to ID_EX pipe
	assign shamt		 = ID_ir[10:6];
	
	//Jump Part
	assign JumpAddr		 = {EX_se_imm[15:0],2'b0};
	
	// Data Memory
	assign DC_Address	 = M_ALU_result[17:2];
	assign DC_Write_enable	 = M_MemWrite;	
	assign DC_Write_Data 	 = M_DM_Write_data;
	assign DC_Read_enable	 = M_MemtoReg;
	
	
	// IF
	/*-----------------------------------------------------------*/	
	// PC
	PC PC1 ( 
	.clk(clk), 
	.rst(rst),
	.PCWrite(PCWrite),
	.PCin(PCin), 
	.PCout(PCout)
	);
	
	assign PC_add4 = PCout + 18'd4;
	
	// IF_ID pipe
	/*-----------------------------------------------------------*/	
	IF_ID IF_ID1 ( 
	.clk(clk),
	.rst(rst),
	// input
	.IF_IDWrite(IF_IDWrite),
	.IF_Flush(IF_Flush),
	.IF_PC(PC_add4),
	.IF_ir(Instruction),
	// output
	.ID_PC(ID_PC),
	.ID_ir(ID_ir)
	);
	
	// ID
	/*-----------------------------------------------------------*/	
	// Hazard Detection Unit
	HDU HDU1 ( 
	// input
	.IC_stall(IC_stall),
	.DC_stall(DC_stall),
	.ID_Rs(Rs),
    	.ID_Rt(Rt),
	.EX_WR_out(EX_WR_out),
	.EX_MemtoReg(EX_MemtoReg),
	.EX_JumpOP(EX_JumpOP),
	// output
	.PCWrite(PCWrite),			 
	.IF_IDWrite(IF_IDWrite),
	.ID_EXWrite(ID_EXWrite),
	.EX_MWrite(EX_MWrite),
	.M_WBWrite(M_WBWrite),
	.IF_Flush(IF_Flush),
	.ID_Flush(ID_Flush),
	.Branch_Flush(Branch_Flush),
	.Load_wait(Load_wait)
	);
	
	// Controller
	Controller Controller1 ( 
	.opcode(opcode),
	.funct(funct),
	.Reg_imm(Reg_imm),
	.Jump(Jump),
	.Branch(Branch),
	.Jal(Jal),
	.Jr(Jr),
	.MemtoReg(MemtoReg),
	.ALUOp(ALUOp),
	.RegWrite(RegWrite),
	.MemWrite(MemWrite),
	.ExtendLH(ExtendLH),
	.ExtendSH(ExtendSH)
	);
	
	// Registers
	Regfile Registers1 ( 
	.clk(clk), 
	.rst(rst),
	.Read_addr_1(Rs),
	.Read_addr_2(Rt),
	.Read_data_1(Rs_data),
	.Read_data_2(Rt_data),
	.RegWrite(WB_RegWrite),
	.Write_addr(WB_WR_out),
	.Write_data(WB_Final_WD_out)
	);
	
	// sign_extend	

	assign se_imm = {{16{imm[15]}},imm[15:0]};
	
	// ID Mux part
	// Mux - select Rd or Rt
	Mux2to1_5bit Rd_Rt ( 
	.I0(Rd),
	.I1(Rt),
	.S(Reg_imm),
	.out(Rd_Rt_out)
	);
	
	// Mux - select $ra(5'd31, of jal instrction) or Rd_Rt mux out
	Mux2to1_5bit WR ( 
	.I0(Rd_Rt_out),
	.I1(5'd31),
	.S(Jal),
	.out(WR_out)
	);
	
	// ID_EX pipe
	/*-----------------------------------------------------------*/	
	ID_EX ID_EX1 ( 
	.clk(clk), 
	.rst(rst),
    	// input 
	.ID_Flush(ID_Flush),
	.ID_EXWrite(ID_EXWrite),
	// WB
	.ID_MemtoReg(MemtoReg),
	.ID_RegWrite(RegWrite),
	// M
	.ID_MemWrite(MemWrite),
	.ID_Jal(Jal),
	.ID_ExtendLH(ExtendLH),
	.ID_ExtendSH(ExtendSH),
	// EX
	.ID_Reg_imm(Reg_imm),
	.ID_Jump(Jump),
	.ID_Branch(Branch),
	.ID_Jr(Jr),			   
	// pipe
	.ID_PC(ID_PC),
	.ID_ALUOp(ALUOp),
	.ID_shamt(shamt),
	.ID_Rs_data(Rs_data),
	.ID_Rt_data(Rt_data),
	.ID_se_imm(se_imm),
	.ID_WR_out(WR_out),
	.ID_Rs(Rs),
	.ID_Rt(Rt),
	// output
	// WB
	.EX_MemtoReg(EX_MemtoReg),
	.EX_RegWrite(EX_RegWrite),
	// M
	.EX_MemWrite(EX_MemWrite),
	.EX_Jal(EX_Jal),
	.EX_ExtendLH(EX_ExtendLH),
	.EX_ExtendSH(EX_ExtendSH),
	// EX
	.EX_Reg_imm(EX_Reg_imm),
	.EX_Jump(EX_Jump),
	.EX_Branch(EX_Branch),
	.EX_Jr(EX_Jr),
	// pipe
	.EX_PC(EX_PC),
	.EX_ALUOp(EX_ALUOp),
	.EX_shamt(EX_shamt),
	.EX_Rs_data(EX_Rs_data),
	.EX_Rt_data(EX_Rt_data),
	.EX_se_imm(EX_se_imm),
	.EX_WR_out(EX_WR_out),
	.EX_Rs(EX_Rs),
	.EX_Rt(EX_Rt)		   			   
	);
	// EX
	/*-----------------------------------------------------------*/	
	// Jump Part
	
	assign BranchAddr = EX_PC + {EX_se_imm[15:0],2'b0};


	Mux4to1 PC_Mux (
	.I0(PC_add4),
	.I1(BranchAddr),
	.I2(enF1_data[pc_size-1:0]),
	.I3(JumpAddr),
	.S(EX_JumpOP),
	.out(PCin)
	);
	
	//Jump control
	Jump_Ctrl Jump_Ctrl1 (
	.Branch(EX_Branch),
    	.Zero(EX_Zero),
    	.Jr(EX_Jr),
    	.Jump(EX_Jump),
    	.JumpOP(EX_JumpOP)
	);
	
	// Forwarding Unit part
	FU FU1 ( 
	// input 
	.EX_Rs(EX_Rs),
   	.EX_Rt(EX_Rt),
	.M_RegWrite(M_RegWrite),
	.M_WR_out(M_WR_out),
	.WB_RegWrite(WB_RegWrite),
	.WB_WR_out(WB_WR_out),
	// output
	.enF1(enF1),
	.enF2(enF2),
	.sF1(sF1),
	.sF2(sF2)	
	);
	
	// Mux - select forward data from M or WB (the Rs part)
	Mux2to1 sF1_Mux ( 
	.I0(M_WD_out),
	.I1(WB_Final_WD_out),
	.S(sF1),
	.out(sF1_data)
	);
	
	// Mux - select forward data from M or WB (the Rt part)
	Mux2to1 sF2_Mux ( 
	.I0(M_WD_out),
	.I1(WB_Final_WD_out),
	.S(sF2),
	.out(sF2_data)
	);
	
	// Mux - select origin Rs or the forward data (the Rs part)
	Mux2to1 enF1_Mux ( 
	.I0(EX_Rs_data),
	.I1(sF1_data),
	.S(enF1),
	.out(enF1_data)
	);
	
	// Mux - select origin Rt or the forward data (the Rt part)
	Mux2to1 enF2_Mux ( 
	.I0(EX_Rt_data),
	.I1(sF2_data),
	.S(enF2),
	.out(enF2_data)
	);
	
	// ALU part
	// Mux - select Rt or imm (the Rt part)
	Mux2to1#(data_size) Rt_imm (
	.I0(enF2_data),
	.I1(EX_se_imm),
	.S(EX_Reg_imm),
	.out(scr2)
	);	
	
	ALU ALU1 ( 
	.ALUOp(EX_ALUOp),
	.scr1(enF1_data),
	.scr2(scr2),
	.shamt(EX_shamt),
	.ALU_result(EX_ALU_result),
	.Zero(EX_Zero)
	);
	

	assign EX_PCplus8 = EX_PC + 18'd4;
	
	// EX_M pipe
	/*-----------------------------------------------------------*/	
	EX_M EX_M1 ( 
	.clk(clk),
	.rst(rst),
	// input 
	.EX_MWrite(EX_MWrite),
	// WB
	.EX_MemtoReg(EX_MemtoReg),
	.EX_RegWrite(EX_RegWrite),
	// M
	.EX_MemWrite(EX_MemWrite),
	.EX_Jal(EX_Jal),
	.EX_ExtendLH(EX_ExtendLH),
	.EX_ExtendSH(EX_ExtendSH),
	// pipe
	.EX_ALU_result(EX_ALU_result),
	.EX_Rt_data(enF2_data),
	.EX_PCplus8(EX_PCplus8),
	.EX_WR_out(EX_WR_out),
	// output
	// WB
	.M_MemtoReg(M_MemtoReg),
	.M_RegWrite(M_RegWrite),
	// M
	.M_MemWrite(M_MemWrite),
	.M_Jal(M_Jal),
	.M_ExtendLH(M_ExtendLH),
	.M_ExtendSH(M_ExtendSH),
	// pipe
	.M_ALU_result(M_ALU_result),
	.M_Rt_data(M_Rt_data),
	.M_PCplus8(M_PCplus8),
	.M_WR_out(M_WR_out)			  		  			  
	);
	
	// M
	/*-----------------------------------------------------------*/	
	// M Jal part
	// sign_extend	

	assign M_Rt_data_extend = {{16{M_Rt_data[15]}},M_Rt_data[15:0]};
	
	Mux2to1 RT_SH_Select (
	.I0(M_Rt_data),
	.I1(M_Rt_data_extend),
	.S(M_ExtendSH),
	.out(M_DM_Write_data)
	);	

	
	assign M_Rt_data_extend1 = {{16{DC_Read_Data[15]}},DC_Read_Data[15:0]};

	Mux2to1 RT_LH_Select (
	.I0(DC_Read_Data),
	.I1(M_Rt_data_extend1),
	.S(M_ExtendLH),
	.out(M_DM_Read_data)
	);	
	// Mux - select Jal or ALU result
	Mux2to1#(data_size) Jal_RD_Select (
	.I0(M_ALU_result),
	.I1({14'b0,M_PCplus8}),
	.S(M_Jal),
	.out(M_WD_out)
	);	
	
	// M_WB pipe
	/*-----------------------------------------------------------*/	
	M_WB M_WB1 ( 
	.clk(clk),
    	.rst(rst),
	// input 
	.M_WBWrite(M_WBWrite),
	// WB
	.M_MemtoReg(M_MemtoReg),
	.M_RegWrite(M_RegWrite),
	// pipe
	.M_DM_Read_Data(M_DM_Read_data),
	.M_WD_out(M_WD_out),
	.M_WR_out(M_WR_out),
	// output
	// WB
	.WB_MemtoReg(WB_MemtoReg),
	.WB_RegWrite(WB_RegWrite),
	// pipe
	.WB_DM_Read_Data(WB_DM_Read_Data),
	.WB_WD_out(WB_WD_out),
    	.WB_WR_out(WB_WR_out)
	);
	
	// WB
	/*-----------------------------------------------------------*/	
	// Mux - select the WD or DM Read data
	
	Mux2to1 DM_RD_Select (
	.I0(WB_WD_out),
	.I1(WB_DM_Read_Data),
	.S(WB_MemtoReg),
	.out(WB_Final_WD_out)
	);
endmodule


























