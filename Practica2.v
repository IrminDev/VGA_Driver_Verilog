/**
*	Practice exercise 2: Monocycle processor
*
*  This design is a monocycle processor to process the conic sections
*	on a 1280x1024@60 monitor
*	
*	Authors:
*	Garcia Garcia Aram Jesua
*	Hernandez Diaz Roberto Angel
*	Hernandez Jimenez Irmin
*	Trejo Flores Johann Daniel
*	Toral Hernandez Leonardo Javier
* 
**/

module Practica2(
	input 		CLK_50,
	input			Sw,
	input			KEY,
	input 		ps2_clk,   
	input 		ps2_data,
	output 		VGA_HS,
	output 		VGA_VS,
	output 		VGA_CLK,
	output 		VGA_SYNC_N,
	output 		VGA_BLANK_N,
	output[7:0] VGA_R,
	output[7:0] VGA_G,
	output[7:0] VGA_B,
	output[7:0] LCD_Data,
	output		LCD_En,
	output		LCD_Rw,
	output		LCD_Rs,
	output 		LED,
	output[6:0]	HEX0,
	output[6:0]	HEX1,
	output[6:0]	HEX2,
	output[6:0]	HEX3
);
	wire 				CLK_108, Reset;
	wire [2:0]		ConicType;
	wire [15:0] 	Kb_Data;

	assign VGA_BLANK_N = 1'b1;
	assign VGA_SYNC_N = 1'b1;
	assign Reset = 1'b0;
	
	// PS2 Keyboard Controller
	Keyboard Kb (
		.CLOCK_50(CLK_50),
		.Reset(KEY),
		.ps2_clk(ps2_clk),
		.ps2_data(ps2_data),
		.Data(Kb_Data),
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3)
	);
	
	// Phase locked loop (to increase the clock frequency up to 108 MHz)
	PLL u0 (
		.clk_in_clk   (CLK_50),   //   clk_in.clk
		.clk0_clk (CLK_108), // clk_out1.clk
		.clk1_clk (VGA_CLK), // clk_out2.clk
		.reset_reset  (Reset)   //    reset.reset
	);
	
	// Synchronization module for the VGA monitor
	Sync U1 (
		.CLK(CLK_108),
		.Data(Kb_Data),
		.HSYNC(VGA_HS),
		.VSYNC(VGA_VS),
		.R(VGA_R),
		.G(VGA_G),
		.B(VGA_B),
		.ConicType(ConicType),
		.LED(LED)
	);
	
	// LCD Display controller to show the name of the conic
	LCD lcdCtrl (
		.Sw(Sw),
		.Clr(KEY),
		.Clk(CLK_50),
		.ConicType(ConicType),
		.Data(LCD_Data),
		.E(LCD_En),
		.Rs(LCD_Rs),
		.Rw(LCD_Rw),
	);
	
	
endmodule