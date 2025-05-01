/**
*	LCD Display controller
*	Author: U581
*	
*	Modified by:
*	Garcia Garcia Aram Jesua
*	Hernandez Diaz Roberto Angel
*	Hernandez Jimenez Irmin
*	Trejo Flores Johann Daniel
*	Toral Hernandez Leonardo Javier
* 
**/
module LCD(
	input 				Clr, Clk, Sw,
	input[2:0]			ConicType,
	output reg[7:0]	Data,
	output reg			E, Rs,
	output 				Rw
);
	// Frequency divider parameters and counters
	parameter 	BaseDLY = 1000000;
	reg[19:0]	ClkCnt = 0;
	reg 			CLK_DLY;
	
	// States
	parameter 	LCD_INI = 1, D_OFF = 2, LCD_CLR = 3,
					D_ON = 4, ENTRY = 5, ASK1 = 6, MSG1 = 7,
					ASK2 = 8, MSG2 = 9,ASK3 = 10, L1 = 11, L2 = 12;
	
	reg[3:0] 	CurrentState, NextState;
	
	// Counters to synchronize the LCD Display
	reg[3:0] 	CNT1, CNT2;
	reg 			EN = 0;
	
	assign 		Rw = 0;
	
	// Regs for the characters of each conic
	reg[7:0] 	CircleChars[0:15];
	reg[7:0] 	EllipseChars[0:15];
	reg[7:0] 	ParabolaChars[0:15];
	reg[7:0] 	HyperbolaChars[0:15];
	reg[7:0] 	LinearChars[0:15];	
	
	initial begin
		// Chars for the circle
		CircleChars[0] = 8'h43;
		CircleChars[1] = 8'h69;
		CircleChars[2] = 8'h72;
		CircleChars[3] = 8'h63;
		CircleChars[4] = 8'h6C;
		CircleChars[5] = 8'h65;
		CircleChars[6] = 8'hFE;
		CircleChars[7] = 8'hFE;
		CircleChars[8] = 8'hFE;
		CircleChars[9] = 8'hFE;
		CircleChars[10] = 8'hFE;
		CircleChars[11] = 8'hFE;
		CircleChars[12] = 8'hFE;
		CircleChars[13] = 8'hFE;
		CircleChars[14] = 8'hFE;
		CircleChars[15] = 8'hFE;
		
		
		// Chars for the ellipse
		EllipseChars[0] = 8'h45;
		EllipseChars[1] = 8'h6C;
		EllipseChars[2] = 8'h6C;
		EllipseChars[3] = 8'h69;
		EllipseChars[4] = 8'h70;
		EllipseChars[5] = 8'h73;
		EllipseChars[6] = 8'h65;
		EllipseChars[7] = 8'hFE;
		EllipseChars[8] = 8'hFE;
		EllipseChars[9] = 8'hFE;
		EllipseChars[10] = 8'hFE;
		EllipseChars[11] = 8'hFE;
		EllipseChars[12] = 8'hFE;
		EllipseChars[13] = 8'hFE;
		EllipseChars[14] = 8'hFE;
		EllipseChars[15] = 8'hFE;
		
		
		// Chars for the parabola
		ParabolaChars[0] = 8'h50;
		ParabolaChars[1] = 8'h61;
		ParabolaChars[2] = 8'h72;
		ParabolaChars[3] = 8'h61;
		ParabolaChars[4] = 8'h62;
		ParabolaChars[5] = 8'h6F;
		ParabolaChars[6] = 8'h6C;
		ParabolaChars[7] = 8'h61;
		ParabolaChars[8] = 8'hFE;
		ParabolaChars[9] = 8'hFE;
		ParabolaChars[10] = 8'hFE;
		ParabolaChars[11] = 8'hFE;
		ParabolaChars[12] = 8'hFE;
		ParabolaChars[13] = 8'hFE;
		ParabolaChars[14] = 8'hFE;
		ParabolaChars[15] = 8'hFE;
		
		
		// Chars for the hyperbola
		HyperbolaChars[0] = 8'h48;
		HyperbolaChars[1] = 8'h79;
		HyperbolaChars[2] = 8'h70;
		HyperbolaChars[3] = 8'h65;
		HyperbolaChars[4] = 8'h72;
		HyperbolaChars[5] = 8'h62;
		HyperbolaChars[6] = 8'h6F;
		HyperbolaChars[7] = 8'h6C;
		HyperbolaChars[8] = 8'h61;
		HyperbolaChars[9] = 8'hFE;
		HyperbolaChars[10] = 8'hFE;
		HyperbolaChars[11] = 8'hFE;
		HyperbolaChars[12] = 8'hFE;
		HyperbolaChars[13] = 8'hFE;
		HyperbolaChars[14] = 8'hFE;
		HyperbolaChars[15] = 8'hFE;
		
		// Chars for the linear
		LinearChars[0] = 8'h4C;
		LinearChars[1] = 8'h69;
		LinearChars[2] = 8'h6E;
		LinearChars[3] = 8'h65;
		LinearChars[4] = 8'h61;
		LinearChars[5] = 8'h72;
		LinearChars[6] = 8'hFE;
		LinearChars[7] = 8'hFE;
		LinearChars[8] = 8'hFE;
		LinearChars[9] = 8'hFE;
		LinearChars[10] = 8'hFE;
		LinearChars[11] = 8'hFE;
		LinearChars[12] = 8'hFE;
		LinearChars[13] = 8'hFE;
		LinearChars[14] = 8'hFE;
		LinearChars[15] = 8'hFE;
	end
	
	/*
	*
	*	Task to display the message according to the counter, line and conic
	*
	*/
	task DisplayMessage(
		input 				Line,
		input	[3:0]			Sel,
		output reg[7:0]	Data
	);
		
		if(Line == 1'b0) begin
			case(ConicType)
				3'b001: Data <= CircleChars[Sel];
				3'b010: Data <= EllipseChars[Sel];
				3'b011: Data <= ParabolaChars[Sel];
				3'b100: Data <= HyperbolaChars[Sel];
				3'b101: Data <= LinearChars[Sel];
				default: Data <= 8'hFE;
			endcase
		end else begin
			 Data <= 8'hFE;
		end
	endtask
	
	always@(posedge CLK_DLY) begin
		case(CurrentState)
			LCD_INI: begin
				Rs <= 0;
				Data <= 8'h38;
				if(CNT1 < 4) begin
					EN = ~EN;
					E <= EN;
					CNT1 = CNT1 + 1;
				end else begin
					CNT1 = 0;
					NextState <= D_OFF;
				end
			end
			D_OFF: begin
				Data <= 8'h08;
				if(CNT1 < 2) begin
					EN = ~EN;
					E <= EN;
					CNT1 = CNT1 + 1;
				end else begin
					CNT1 = 0;
					NextState <= LCD_CLR;
				end
			end
			LCD_CLR: begin
				Data <= 8'h01;
				if(CNT1 < 2) begin
					EN = ~EN;
					E <= EN;
					CNT1 = CNT1 + 1;
				end else begin
					CNT1 = 0;
					NextState <= ENTRY;
				end
			end
			ENTRY: begin
				Data <= 8'h06;
				if(CNT1 < 2) begin
					EN = ~EN;
					E <= EN;
					CNT1 = CNT1 + 1;
				end else begin
					CNT1 = 0;
					NextState <= D_ON;
				end
			end
			D_ON: begin
				Data <= 8'h0F;
				if(CNT1 < 2) begin
					EN = ~EN;
					E <= EN;
					CNT1 = CNT1 + 1;
				end else begin
					CNT1 = 0;
					NextState <= L1;
				end
			end
			L1: begin
				Data <= 8'h80;
				if(CNT1 < 2) begin
					EN = ~EN;
					E <= EN;
					CNT1 = CNT1 + 1;
				end else begin
					CNT1 = 0;
					NextState <= ASK1;
				end
			end
			ASK1: begin
				if(Sw == 1'b0) begin
					NextState <= ASK1;
				end else begin
					Rs <= 1'b1;
					NextState <= MSG1;
				end
			end
			MSG1: begin
				if(CNT2 < 15) begin
					DisplayMessage(1'b0, CNT2, Data);
					if(CNT1 < 2) begin							
						EN = ~EN;
						E <= EN;
						CNT1 = CNT1 + 1;
					end else begin
						CNT1 = 0;
						CNT2 = CNT2+1;
						NextState <= MSG1;
					end
				end else begin
						CNT2 = 0;
						NextState <= L2;
				end
			end
			L2: begin
				Rs <= 1'b0;
				Data <= 8'hC0;
				if(CNT1 < 2) begin
					EN = ~EN;
					E <= EN;
					CNT1 = CNT1 + 1;
				end else begin
					CNT1 = 0;
					NextState <= ASK2;
				end
			end
			ASK2: begin
				if(Sw == 1'b0) begin
					NextState <= ASK2;
				end else begin
					Rs <= 1'b1;
					NextState <= MSG2;
				end
			end
			MSG2: begin
				if(CNT2 < 15) begin
					DisplayMessage(1'b1, CNT2, Data);
					if(CNT1 < 2) begin							
						EN = ~EN;
						E <= EN;
						CNT1 = CNT1 + 1;
					end else begin
						CNT1 = 0;
						CNT2 = CNT2+1;
						NextState <= MSG2;
					end
				end else begin
						CNT2 = 0;
						NextState <= ASK3;
				end
			end
			ASK3: begin
				if(Sw == 1'b0) begin
					NextState <= ASK3;
				end else begin
					Rs <= 1'b0;
					NextState <= LCD_CLR;
				end
			end
		endcase
	end
	
	always@(posedge Clk, negedge Clr) begin
		if(~Clr) begin
			CurrentState <= LCD_CLR;
		end else begin
			if(ClkCnt < BaseDLY) begin
				ClkCnt <= ClkCnt + 1;
			end else begin
				CurrentState <= NextState;
				CLK_DLY <= ~CLK_DLY;
				ClkCnt <= 0;
			end
		end
	end
endmodule