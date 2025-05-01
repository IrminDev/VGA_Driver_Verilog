/**
*	Synchronization module
*  This module is in charge of the conic render, it sends the information
*	to the VGA monitor
*
*	000: blank
*	001: circle
*	010: parabola
*	011: ellipse
*	100: hyperbola
*
*	Authors:
*	Garcia Garcia Aram Jesua
*	Hernandez Diaz Roberto Angel
*	Hernandez Jimenez Irmin
*	Trejo Flores Johann Daniel
*	Toral Hernandez Leonardo Javier
* 
**/

module Sync(
	input       		CLK,
	input[15:0]  		Data,
	output reg  		HSYNC,
	output reg  		VSYNC,
	output reg[7:0] 	R,
	output reg[7:0] 	G,
	output reg[7:0] 	B,
	output [2:0]		ConicType,
	output reg LED
);
	// Constants for a better readability
	parameter H_BP = 48;
	parameter H_SYNC = 160;
	parameter H_FP = 408;
	parameter V_BP = 1;
	parameter V_SYNC = 4;
	parameter V_FP = 42;
	parameter H_TOTAL = 1688;
	parameter V_TOTAL = 1066;

	// Counters for the horizontal and vertical config
	reg[10:0] HPOS = 0;
	reg[10:0] VPOS = 0;
	
	// Center of the cartesian plane
	parameter CENTER_X = 640;
	parameter CENTER_Y = 512;

	// Parameters of the conics
	reg [10:0] radius = 100;    // Circle radius
	reg [10:0] a = 150;         // semi-major axis for the ellipse/hyperbola
	reg [10:0] b = 80;          // semi-minor axis for the ellipse/hyperbola
	reg [10:0] p = 50;          // Paramater for the parabola
	reg [10:0] m = 50;          // Parameter for the straight line
	reg [10:0] br = 0;          // Parameter for the straight line
	
	
	// Conic type
	reg[2:0] CONIC_TYPE = 0;
	
	assign ConicType = CONIC_TYPE;
	
	/*
	*
	*	Function to draw the axes on the monitor
	*
	*/
	function draw_axes;
		input [10:0] x;
		input [10:0] y;
	begin
		reg signed[20:0] x_rel, y_rel; // X and Y in the monitor
		x_rel = x - H_FP;
		y_rel = y - V_FP;
		if(x_rel == CENTER_X || y_rel == CENTER_Y) begin // Only draws if the pixel is in the horizontal or vertical center
			 draw_axes = 1'b1;
		end else if((x_rel % 50 == 0 && (y_rel >= CENTER_Y-5 && y_rel <= CENTER_Y+5)) || 
				 (y_rel % 50 == 0 && (x_rel >= CENTER_X-5 && x_rel <= CENTER_X+5))) begin // It marks each 5 pixels (10 pixel wide)
			 draw_axes = 1'b1;
		end else begin
			 draw_axes = 1'b0;
		end
	end
	endfunction
	
	/*
	*
	*	Function to draw the conics
	*
	*/
	function draw_conic;
		input [10:0] x;
		input [10:0] y;
		input [2:0]  conic_type; // Selector
		reg signed [128:0] x_rel, y_rel;
		reg signed [128:0] eq_value; // Parameter that verifies if the conic satisfies the condition
		begin
			x_rel = (x-H_FP) - CENTER_X;
			y_rel = CENTER_Y - (y-V_FP); // Y axis reversed
			
			case(conic_type)
				 3'b001: begin // Circler (x² + y² = r²)
					  eq_value = x_rel*x_rel + y_rel*y_rel - radius*radius;
					  draw_conic = (eq_value >= -1000 && eq_value <= 1000); // Error margin
				 end
				 
				 3'b010: begin // Ellipse (x²/a² + y²/b² = 1) => (x²b² + y²a² = a²b²)
					  eq_value = (x_rel*x_rel)*(b*b) + (y_rel*y_rel)*(a*a) - (b*b)*(a*a);
					  draw_conic = (eq_value >= -10000000 && eq_value <= 10000000); // Error margin
				 end
				 
				 3'b011: begin // Parabola (x² = 4py)
					  eq_value = x_rel*x_rel - 4*p*y_rel;
					  draw_conic = (eq_value >= -500 && eq_value <= 500); // Error margin
				 end
				 
				 3'b100: begin // Hyperbola (x²/a² - y²/b² = 1) => (x²b² - y²a² = a²b²)
					  eq_value = (x_rel*x_rel)*(b*b) - (y_rel*y_rel)*(a*a) - (b*b)*(a*a);
					  draw_conic = (eq_value >= -10000000 && eq_value <= 10000000); // Error margin
				 end
				 
				 3'b101: begin // Straight line (x²/a² - y²/b² = 1)
					  eq_value = y_rel - (200/m)*x_rel - br;
					  draw_conic = (eq_value >= -25 && eq_value <= 25); // Error margin
				 end
				 
				 default: draw_conic = 1'b0;
			endcase
	  end
	endfunction
	
	//Always block that controls the keyboard input
	always@(Data) begin
		case(Data)
			16'h0016: CONIC_TYPE <= 3'b001;
			16'h001E: CONIC_TYPE <= 3'b010;
			16'h0026: CONIC_TYPE <= 3'b011;
			16'h0025: CONIC_TYPE <= 3'b100;
			16'h002E: CONIC_TYPE <= 3'b101;
			default: CONIC_TYPE <= CONIC_TYPE;
		endcase
	end
	
	// Always block that controls the VGA
	always@(posedge CLK) begin
		if(HPOS >= H_FP && VPOS >= V_FP) begin // Verifies if the positions are available to draw
			if(draw_axes(HPOS, VPOS)) begin // Draw the axes
				R <= 8'hFF;
				G <= 8'hFF;
				B <= 8'hFF;
			end else begin
				if(draw_conic(HPOS, VPOS, CONIC_TYPE)) begin // Draw the conic
					R <= 8'hFF;
					G <= 8'h00;
					B <= 8'h00;
				end else begin // Black background
					R <= 8'h00; 
					G <= 8'h00;		
					B <= 8'h00;
				end
			end
		end
		
		if(HPOS < H_TOTAL) begin // Counters for the synchronization
			HPOS <= HPOS + 1;
		end else begin
			HPOS <= 0;
			if(VPOS < V_TOTAL) begin
				VPOS <= VPOS + 1;
			end else begin
				VPOS <= 0;
				
				case(CONIC_TYPE) // Modifies the parameters of the conic on each frame
					3'b001: begin // Adjust the circle radius (up and down arrows)
						if(Data == 16'hE075) begin
							radius <= radius + 5;
						end
						if(Data == 16'hE072) begin
							radius <= radius - 5;
						end
					end

					3'b011: begin // Adjust the p parameter of the parabola (up and down arrows)
						if(Data == 16'hE075) begin
							p <= p + 5;
						end
						if(Data == 16'hE072) begin
							p <= p - 5;
						end
					end
					3'b010: begin // Adjust the axes of the ellipse (up, down, left and right arrows)
						if(Data == 16'hE075) begin
							a <= a + 5;
						end
						if(Data == 16'hE072) begin
							a <= a - 5;
						end
						if(Data == 16'hE074) begin
							b <= b + 5;
						end
						if(Data == 16'hE06B) begin
							b <= b - 5;
						end
					end
					3'b100: begin // Adjust the axes of the ellipse (up, down, left and right arrows)
						if(Data == 16'hE075) begin
							a <= a + 5;
						end
						if(Data == 16'hE072) begin
							a <= a - 5;
						end
						if(Data == 16'hE074) begin
							b <= b + 5;
						end
						if(Data == 16'hE06B) begin
							b <= b - 5;
						end
					end
					3'b101: begin // Adjust the paramters for the straight line (up, down, left and right arrows)
						if(Data == 16'hE075) begin
							m <= m + 1;
						end
						if(Data == 16'hE072) begin
							m <= m - 1;
						end
						if(Data == 16'hE074) begin
							br <= br + 5;
						end
						if(Data == 16'hE06B) begin
							br <= br - 5;
						end
					end
				endcase
			end 	
		end
		
		// Synchronization for the horizontal config
		if(HPOS > H_BP & HPOS < H_SYNC) begin
			HSYNC <= 0;
		end else begin
			HSYNC <= 1;
		end
		
		
		// Synchronization for the vertical config
		if(VPOS > V_BP & VPOS < V_SYNC) begin
			VSYNC <= 0;
		end else begin
			VSYNC <= 1;
		end
	end

endmodule