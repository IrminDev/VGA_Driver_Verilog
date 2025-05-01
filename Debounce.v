/**
*	Debounce module
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

module Debounce #(
    parameter WIDTH = 3
) (
    input  clk,
    input  rst_n,
    input  in,
    output out
);

    /* output signal */
    reg out_next;
    reg out_reg; 
    assign out = out_reg;

    /* variables */
    reg [      1:0] ff_next, ff_reg;                                //previous (ff[1]) and current (ff[0]) values of the input
    reg [WIDTH-1:0] cnt_next, cnt_reg;                              //counts up to the 2**WIDTH - 1 at which point the input is stable

    assign in_changed = ff_reg[0] ^ ff_reg[1];                      //the input has changed
    assign in_stable  = (cnt_reg == {WIDTH{1'b1}}) ? 1'b1 : 1'b0;   //the input is stable

    /* sequential logic */
    always @(posedge clk, negedge rst_n)
        if(!rst_n) begin
            out_reg <= 1'b0;
            ff_reg  <= 2'b00;
            cnt_reg <= {WIDTH{1'b0}};
        end
        else begin
            out_reg <= out_next;
            ff_reg  <= ff_next;
            cnt_reg <= cnt_next;
        end

    /* combinational logic */
    always @(*) begin
        ff_next[0] = in;
        ff_next[1] = ff_reg[0];

        cnt_next = in_changed ? {WIDTH{1'b0}} : (cnt_reg + 1'b1);
        out_next = in_stable ? ff_reg[1] : out_reg;
    end

 endmodule