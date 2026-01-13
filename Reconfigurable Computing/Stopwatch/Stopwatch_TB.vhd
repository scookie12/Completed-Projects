library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stopwatch_TB is
end stopwatch_TB;

architecture behavioral of stopwatch_TB is

	component stopwatch
		port (
			clk : in std_logic;
			rst_l : in std_logic;
			start   : in std_logic;
			min2    : out std_logic_vector(7 downto 0);
			min1    : out std_logic_vector(7 downto 0);
			sec2    : out std_logic_vector(7 downto 0);
			sec1    : out std_logic_vector(7 downto 0);
			tenth2  : out std_logic_vector(7 downto 0);
			tenth1  : out std_logic_vector(7 downto 0)
		);
	end component;
	
	signal clk : std_logic := '0';
	signal rst_l : std_logic := '1';

	signal start   :  std_logic := '1' ;
	signal min2    :  std_logic_vector(7 downto 0);
	signal min1    :  std_logic_vector(7 downto 0);
	signal sec2    :  std_logic_vector(7 downto 0);
	signal sec1    :  std_logic_vector(7 downto 0);
	signal tenth2  :  std_logic_vector(7 downto 0);
	signal tenth1  :  std_logic_vector(7 downto 0);
	
	constant CLK_PERIOD : time := 20 ns;

	
begin

	uut : stopwatch
		port map(
			clk => clk,
			rst_l => rst_l,
			start => start,
			tenth1 => tenth1,
			tenth2 => tenth2,
			sec1 => sec1,
			sec2 => sec2, 
			min1 => min1,
			min2 => min2
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
		start <= '0';
		wait for clk_period * 5000000;
		rst_l <= '0';
		wait for clk_period * 50000;
		rst_l <= '1';
		wait for clk_period * 500000;
		start <= '1';
		wait for clk_period * 50000;
		start <= '0';
		wait;
	end process;
	

end architecture behavioral;