library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RNG_TB is
end RNG_TB;

architecture behavioral of RNG_TB is

	component RNG
		 port (
        clk     : in std_logic;
        rst_l   : in std_logic;
        start   : in std_logic;
        random_out1    : out std_logic_vector(7 downto 0);
        random_out2    : out std_logic_vector(7 downto 0);
		  lfsr_state 	: out std_logic_vector(15 downto 0)
		);
	end component;
	
	signal clk : std_logic := '0';
	signal rst_l : std_logic := '1';

	signal start   :  std_logic := '1' ;
	signal random_out1    :  std_logic_vector(7 downto 0);
	signal random_out2    :  std_logic_vector(7 downto 0);
	signal lfsr_state : std_logic_vector(15 downto 0);
	
	constant CLK_PERIOD : time := 20 ns;

	
begin

	uut : RNG
		port map(
			clk => clk,
			rst_l => rst_l,
			start => start,
			random_out1 => random_out1,
			random_out2 => random_out2,
			lfsr_state => lfsr_state
		);
		
	clk_process : process
	begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period/2;
	end process;
	
	stm_process : process
		variable first_state : std_logic_vector(15 downto 0);
		variable current_state : std_logic_vector(15 downto 0);
		variable cycle_count : integer := 0;
	begin
		-- Reset --
		rst_l <= '1';
		wait for clk_period * 10;
		rst_l <= '0';
		wait for clk_period * 10;
		rst_l <= '1';
		
		-- Start Generating random numbers --
		start <= '0';
		wait for clk_period * 500;
		
		-- Stop Generating numbers --
		start <= '1';
		wait for clk_period * 10;
		
		-- Restart RNG --
		start <= '0';
		wait for clk_period * 500;
		
		-- Reset while start is also pushed --
		rst_l <= '0';
		wait for clk_period * 10;
		
		-- Start is still pressed while reset is released --
		rst_l <= '1';
		wait for clk_period * 10;
		
		-- Release start --
		start <= '1';
		wait until rising_edge(clk);
		
		first_state := lfsr_state;
		
		start <= '0';
		wait for clk_period * 2;
		
		loop
			wait until rising_edge(clk);
			cycle_count := cycle_count + 1;
			current_state := lfsr_state;
			
			if current_state = first_state then
				report "Sequence repeats after " & integer'image(cycle_count) & " cycles.";
				exit;
			end if;
		end loop;
		
		wait;
	end process;
	

end architecture behavioral;