library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Accumulator_TB is
end Accumulator_TB;

architecture behavioral of Accumulator_TB is

	component Accumulator
		port (
		
		clk      : in std_logic;
        rst_l    : in std_logic;
        add_btn  : in std_logic;                  -- "Add" button
        sw       : in std_logic_vector(9 downto 0); -- 10-bit input
        led      : out std_logic_vector(9 downto 0); -- mirror switches
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0)
		);
		
	end component;
	
	signal 	clk      :  std_logic := '0';
    signal  rst_l    :  std_logic := '1';
    signal  add_btn  :  std_logic := '1';                  -- "Add" button
    signal  sw       :  std_logic_vector(9 downto 0) := (others => '0'); -- 10-bit input
    signal  led      :  std_logic_vector(9 downto 0); -- mirror switches
    signal  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 :  std_logic_vector(7 downto 0);
	
	constant CLK_PERIOD : time := 20 ns;
	
	begin

	uut : Accumulator
		port map(
			clk => clk,
			rst_l => rst_l,
			add_btn => add_btn,
			sw => sw,
			led => led,
			HEX0	=> HEX0,
			HEX1	=> HEX1,
			HEX2	=> HEX2,
			HEX3	=> HEX3,
			HEX4	=> HEX4,
			HEX5	=> HEX5
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
		add_btn <= '0';
		wait for clk_period * 10;
		add_btn <= '1';
		wait for clk_period * 10;
		add_btn <= '0';
		wait for clk_period * 1000000;
		add_btn <= '1';
		wait for clk_period * 10;
		
		rst_l <= '0';
		sw <= "0000000011";
		
		--First button press
		wait for clk_period * 10;
		rst_l <= '1';
		add_btn <= '0';
		wait for clk_period * 10;
		add_btn <= '1';
		wait for clk_period * 10;
		add_btn <= '0';
		wait for clk_period * 1000000;
		add_btn <= '1';
		wait for clk_period * 10;
		
		--Second Button Press
		add_btn <= '0';
		wait for clk_period * 10;
		add_btn <= '1';
		wait for clk_period * 10;
		add_btn <= '0';
		wait for clk_period * 1000000;
		add_btn <= '1';
		wait for clk_period * 10;
		
		
		--Third button press
		add_btn <= '0';
		wait for clk_period * 10;
		add_btn <= '1';
		wait for clk_period * 10;
		add_btn <= '0';
		wait for clk_period * 1000000;
		add_btn <= '1';
		wait for clk_period * 10;
		
		--Bad button press
		add_btn <= '0';
		wait for clk_period * 10;
		add_btn <= '1';
		wait for clk_period * 10;
		add_btn <= '0';
		wait for clk_period * 1000;
		add_btn <= '1';
		wait for clk_period * 10;
		
		
		
	end process;
	

end architecture behavioral;
			