/**
*	PS2 Keyboard controller
*	Author: Jovan Vukic
*	
*	Modified by:
*	Garcia Garcia Aram Jesua
*	Hernandez Diaz Roberto Angel
*	Hernandez Jimenez Irmin
*	Trejo Flores Johann Daniel
*	Toral Hernandez Leonardo Javier
* 
**/
module Keyboard(
    input 				CLOCK_50,
    input 				Reset,
	 output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
	 output [15:0]		Data,
    input 				ps2_clk,
    input 				ps2_data
	 
);
	localparam DEB_PARAMETER = 3;					//2^3 of the same values are enough for a stable signal

	localparam PARITY_REG_INITIAL_VALUE = 1'b1;			//the initial value for 'parity_reg' variable (odd parity)
	localparam ERROR_REG_INITIAL_VALUE  = 1'b0;			//the initial value for 'error_reg' variable
	localparam ERROR_OCCURED            = 1'b1;			//the value of 'error_reg' if there is an error in a package

	hex hex_inst_1 (.in(data_reg[15:12]), .out(HEX3));
	hex hex_inst_2 (.in(data_reg[11:8]),  .out(HEX2));
	hex hex_inst_3 (.in(data_reg[7:4]),   .out(HEX1));
	hex hex_inst_4 (.in(data_reg[3:0]),   .out(HEX0));
	
	/* main variables */
	reg [10:0] package_reg, package_next;				//stores one whole package (STOP bit, PARITY bit, SCAN_CODE_BYTE[7:0] bits, START bit, respectively)
	reg [15:0] data_reg, data_next;					//stores the lowest two bytes of the scan code
	reg        parity_reg, parity_next;				//stores parity check result
	reg        error_reg, error_next;				//stores package error check result

	reg [3:0] cnt_reg, cnt_next;					//package bit counter (counts from 0 to 10)

	reg ps2_clk_deb_previous_reg, ps2_clk_deb_previous_next;	//used for the ps2_clk_deb falling edge detection
	
	reg f0_flag_reg, f0_flag_next;					//indicates that the F0 byte has arrived
	reg e0_flag_reg, e0_flag_next;					//indicates that the E0 byte has arrived

	localparam STATE_IDLE    = 1'b0;				//package is not being received
	localparam STATE_RECEIVE = 1'b1;				//package is being received

	reg state_reg, state_next;					//stores the current state
	wire ps2_clk_deb;

	assign Data = data_reg;
	
	Debounce #(DEB_PARAMETER) deb_inst (
		.rst_n(Reset      ),
		.clk  (CLOCK_50        ),
		.in   (ps2_clk    ),
		.out  (ps2_clk_deb)
	);
	
	/* sequential logic */
	always @(posedge CLOCK_50, negedge Reset) begin
		if (!Reset) begin
			package_reg <= 11'b0;
			data_reg    <= 15'b0;
			parity_reg  <= PARITY_REG_INITIAL_VALUE;
			error_reg   <= ERROR_REG_INITIAL_VALUE;

			cnt_reg   <= 4'b0;
			state_reg <= STATE_IDLE;

			ps2_clk_deb_previous_reg <= 1'b0; //the initial value of 'ps2_clk_deb' is 1'b0
			f0_flag_reg              <= 1'b0;
			e0_flag_reg              <= 1'b0;
		end else begin
			package_reg <= package_next;
			data_reg    <= data_next;
			parity_reg  <= parity_next;
			error_reg   <= error_next;

			cnt_reg   <= cnt_next;
			state_reg <= state_next;

			ps2_clk_deb_previous_reg <= ps2_clk_deb_previous_next;
			f0_flag_reg              <= f0_flag_next;
			e0_flag_reg              <= e0_flag_next;
		end
	end

	/* combinational logic */
	always @(*) begin
		/* latch prevention*/
		package_next = package_reg;
		data_next    = data_reg;
		parity_next  = parity_reg;
		error_next   = error_reg;

		cnt_next   = cnt_reg;
		state_next = state_reg;

		f0_flag_next = f0_flag_reg;
		e0_flag_next = e0_flag_reg;

		/* implementation logic */
		case (state_reg)
			STATE_IDLE : begin
				if (~ps2_clk_deb && ps2_clk_deb_previous_reg) begin					//falling edge detection
					package_next = { ps2_data, package_reg[10:1] };					//right shift ps2_data (START bit) into the 'package_next' variable

					/* preparation to receive a new package */
					parity_next = PARITY_REG_INITIAL_VALUE;
					error_next  = ERROR_REG_INITIAL_VALUE;

					cnt_next   = 4'd0;								//there are 10 bits left to read
					state_next = STATE_RECEIVE;							//transition to the new state
				end
			end

			STATE_RECEIVE : begin
				if (~ps2_clk_deb && ps2_clk_deb_previous_reg) begin					//falling edge detection
					package_next = { ps2_data, package_reg[10:1] };					//right shift ps2_data

					/* evaluate the final value of 'parity_reg' and 'error_reg' */
					if (cnt_reg <= 4'd7) parity_next = parity_reg ^ ps2_data;			//ps2_data == SCAN_CODE_BYTE[0:7] for cnt_reg == [0:7]
					else if (cnt_reg == 4'd8) begin							//ps2_data == PARITY bit for cnt_reg == 4'd8
						if (parity_reg != ps2_data)	error_next = ERROR_OCCURED;		//there is an error, the PARITY bit does not match
					end else begin									//ps2_data == STOP bit for cnt_reg == 4'd9
						if (package_next[0] != 1'b0 || package_next[10] != 1'b1)		//START bit != 0 or STOP bit != 1
							error_next = ERROR_OCCURED;
					end
					cnt_next = cnt_reg + 4'b1;							//updating the counter
				end

				/* after the new package has been received */
				if (cnt_next == 4'd10 && error_next != ERROR_OCCURED) begin				//MUST use cnt_next and error_next (not cnt_reg and error_reg)
					case (package_next[8:1])
						8'hF0 : f0_flag_next = 1'b1;						//do not insert the F0 byte immediately, just mark that it has arrived
						8'hE0 : e0_flag_next = 1'b1;						//do not insert the E0 byte immediately, just mark that it has arrived

						default : begin
							data_next = { data_reg[7:0], package_next[8:1] };		//by default just insert the next byte of the scan code

							/* improving the 7SEG display fluidity */
							if (data_reg[15:8] == 8'hF0 || data_reg[15:8] == 8'hE0)
								data_next = { 8'b0, package_next[8:1] };
							else if (data_reg[7:0] == package_next[8:1] && data_reg[7:0] != 8'b0)
								data_next = { 8'b0, package_next[8:1] };

							/* insert the marked F0/E0 byte and the one that just arrived */
							if (f0_flag_reg == 1'b1) begin
								data_next    = { 8'hF0, package_next[8:1] };
								f0_flag_next = 1'b0;					//clear the f0_flag
								e0_flag_next = 1'b0;					//necessary due to the situation when we receive E0 F0 respectively (example: [make: E0 14 | break: E0 F0 14])
							end else if (e0_flag_reg == 1'b1) begin
								data_next    = { 8'hE0, package_next[8:1] };
								e0_flag_next = 1'b0;					//clear the e0_flag
								f0_flag_next = 1'b0;
							end
						end
					endcase
				end

				if (cnt_next == 4'd10) state_next = STATE_IDLE;						//return to the idle state
			end
		endcase

		ps2_clk_deb_previous_next = ps2_clk_deb;
	end

endmodule