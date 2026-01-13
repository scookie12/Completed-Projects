library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RNG_Color is
    port (
        clk     : in std_logic;
        rst_l   : in std_logic;
        start   : in std_logic;
        random_out1    : out std_logic_vector(1 downto 0)
    );
end entity RNG_Color;

architecture behavioral of RNG_Color is

    signal index1 : integer range 0 to 3; 
    signal lfsr_reg : std_logic_vector(15 downto 0) := X"ACE1"; 
    signal feedback : std_logic;

begin
	
	feedback <= lfsr_reg(15) xor lfsr_reg(13) xor lfsr_reg(12) xor lfsr_reg(10);

	process(clk, rst_l)
	begin
		if rst_l = '0' then
			lfsr_reg <= x"ACE1";  -- seed value
		elsif rising_edge(clk) then
			if start = '1' then  
				lfsr_reg <= lfsr_reg(14 downto 0) & feedback;
			end if;
		end if;
	end process;
	
	random_out1 <= std_logic_vector((lfsr_reg(7 downto 6))); -- pull a nibble from the full RNG to display



end architecture behavioral;
