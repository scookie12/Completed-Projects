library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RNG is
    port (
        clk     : in std_logic;
        rst_l   : in std_logic;
        start   : in std_logic;
        random_out1    : out std_logic_vector(7 downto 0);
        random_out2    : out std_logic_vector(7 downto 0);
		lfsr_state	: out std_logic_vector(15 downto 0)
    );
end entity RNG;


architecture behavioral of RNG is
	type MY_MEM is array (0 to 15) of std_logic_vector(7 downto 0);

	constant LUT : MY_MEM := (
		X"C0", -- 0
		X"F9", -- 1
		X"A4", -- 2
		X"B0", -- 3
		X"99", -- 4
		X"92", -- 5
		X"82", -- 6
		X"F8", -- 7
		X"80", -- 8
		X"98", -- 9
		X"88", -- A
		X"83", -- B
		X"C6", -- C 
		X"A1", -- D 
		X"86", -- E 
		X"8E"  -- F 
	);

									
	-- The signals below represent the index to reach the different segments within the LUT for 7 Segment displays --
	signal index1 : integer range 0 to 15; 
	signal index2 : integer range 0 to 15;
	
	-- LFSR seed --
	signal lfsr_out : std_logic_vector(15 downto 0) := X"ACE1"; 
	signal feedback : std_logic;

begin
	
	feedback <= (lfsr_out(15) xor lfsr_out(13) xor lfsr_out(12) xor lfsr_out(10)) and '1';

	process(clk, rst_l)
	begin
		if rst_l = '0' then
			lfsr_out <= x"ACE1";  -- seed value
		elsif rising_edge(clk) then
			if start = '0' then  
				lfsr_out <= lfsr_out(14 downto 0) & feedback;
			end if;
		end if;
	end process;
	
	index1 <= to_integer(unsigned(lfsr_out(7 downto 4))); -- pull a nibble from the full RNG to display
	index2 <= to_integer(unsigned(lfsr_out(13 downto 10))); -- pull a second nibble from the RNG to display 

	random_out1 <= LUT(index1);
	random_out2 <= LUT(index2);
	lfsr_state <= lfsr_out;
	
end architecture;