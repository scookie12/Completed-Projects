library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity StopWatch is
    port (
        clk     : in std_logic;
        rst_l   : in std_logic;
        start   : in std_logic;
		-- not sure about below for 7 segments
        min2    : out std_logic_vector(7 downto 0);
        min1    : out std_logic_vector(7 downto 0);
        sec2    : out std_logic_vector(7 downto 0);
        sec1    : out std_logic_vector(7 downto 0);
        tenth2  : out std_logic_vector(7 downto 0);
        tenth1  : out std_logic_vector(7 downto 0)
    );
end entity StopWatch;


architecture behavioral of StopWatch is
	type MY_MEM is array (0 to 9) of std_logic_vector(7 downto 0);

	constant HEX_NODP : MY_MEM := (
		X"C0", -- 0
		X"F9", -- 1
		X"A4", -- 2
		X"B0", -- 3
		X"99", -- 4
		X"92", -- 5
		X"82", -- 6
		X"F8", -- 7
		X"80", -- 8
		X"98"  -- 9
	);

	constant HEX_DP : MY_MEM := (
		X"40", -- 0 with DP
		X"79", -- 1 with DP
		X"24", -- 2 with DP
		X"30", -- 3 with DP
		X"19", -- 4 with DP
		X"12", -- 5 with DP
		X"02", -- 6 with DP
		X"78", -- 7 with DP
		X"00", -- 8 with DP
		X"18"  -- 9 with DP
	);
									
	-- The signals below represent the index to reach the different segments within the LUT for 7 Segment displays --
	signal m2 : integer range 0 to 9; 
	signal m1 : integer range 0 to 9;
	signal s2 : integer range 0 to 9;
	signal s1 : integer range 0 to 9;
	signal t2 : integer range 0 to 9;
	signal t1 : integer range 0 to 9;
	
	signal count : unsigned(25 downto 0); -- count to a 500000 (100 Hz update to the hundredth of a second)

begin
	
	process (clk, rst_l)
	begin
		if rst_l = '0' then
			m2 <= 0;
			m1 <= 0;
			s2 <= 0;
			s1 <= 0;
			t2 <= 0;
			t1 <= 0;
			count <= (others => '0');
		elsif rising_edge(clk) then
			if start = '0' then -- must press and hold to run stopwatch
			count <= count + 1;
				if count = to_unsigned(500_000-1, count'length) then
					count <= (others => '0'); 
					if t1 < 9 then
						t1 <= t1 + 1;
					elsif t2 < 9 then
						t2 <= t2+1;
						t1 <= 0;
					elsif s1 < 9 then
						s1 <= s1 + 1;
						t2 <= 0;
						t1 <= 0;
					elsif s2 < 5 then -- rolls over at 59.99 seconds
						s2 <= s2 + 1;
						s1 <= 0;
						t2 <= 0;
						t1 <= 0;
					elsif m1 < 9 then
						m1 <= m1 + 1;
						s2 <= 0;
						s1 <= 0;
						t2 <= 0;
						t1 <= 0;
					elsif m2 < 9 then
						m2 <= m2 + 1;
						m1 <= 0;
						s2 <= 0;
						s1 <= 0;
						t2 <= 0;
						t1 <= 0;
					else -- defining timer overflow to restart from 00.00.00 --
						m2 <= 0;
						m1 <= 0;
						s2 <= 0;
						s1 <= 0;
						t2 <= 0;
						t1 <= 0;
					end if;
				end if;
			end if;
		end if;
			
	end process;
	
	-- FORMAT {MM.SS.TT} -> {min2 min1. sec2 sec1. tenth2 tenth 1} --
	min2   <= HEX_NODP(m2);
	min1   <= HEX_DP(m1);    
	sec2   <= HEX_NODP(s2);
	sec1   <= HEX_DP(s1);
	tenth2 <= HEX_NODP(t2);
	tenth1 <= HEX_NODP(t1);
	
	
end architecture;

