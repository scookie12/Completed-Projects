library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_10_TB is
end counter_10_TB;

architecture behavioral of counter_10_TB is

	component counter_10
		generic (
			N : integer := 10
		);
		port (
			clk : in std_logic;
			rst_l : in std_logic;
			count10 : out unsigned((N-1) downto 0)
		);
	end component;
	
	signal clk : std_logic := '0';
	signal rst_l : std_logic := '1';
	--signal count : unsigned(22 downto 0);
	signal count10 : unsigned(9 downto 0);
	
	constant CLK_PERIOD : time := 100 ns;

	
begin

	uut : counter_10
		generic map(
			N => 10
		)
		port map(
			clk => clk,
			rst_l => rst_l,
			count10 => count10
		);
		
	clk_process : process
	begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period/2;
	end process;
	
	stm_process : process
	begin
		rst_l <= '1';
		wait for clk_period * 10;
		rst_l <= '0';
		wait for clk_period * 10;
		rst_l <= '1';
		wait for clk_period * 5000000;
		rst_l <= '0';
		wait for clk_period * 5000000;
		rst_l <= '1';
		wait;
	end process;
	

end architecture behavioral;