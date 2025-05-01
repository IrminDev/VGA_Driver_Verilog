	component PLL is
		port (
			clk_in_clk  : in  std_logic := 'X'; -- clk
			reset_reset : in  std_logic := 'X'; -- reset
			clk0_clk    : out std_logic;        -- clk
			clk1_clk    : out std_logic         -- clk
		);
	end component PLL;

	u0 : component PLL
		port map (
			clk_in_clk  => CONNECTED_TO_clk_in_clk,  -- clk_in.clk
			reset_reset => CONNECTED_TO_reset_reset, --  reset.reset
			clk0_clk    => CONNECTED_TO_clk0_clk,    --   clk0.clk
			clk1_clk    => CONNECTED_TO_clk1_clk     --   clk1.clk
		);

