library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity counter_10 is
	generic (
		N : integer := 10
	);
	port (
		clk : in std_logic;
		rst_l : in std_logic;
		count10  : out unsigned((N-1) downto 0)
	);
end entity counter_10;

architecture behavioral of counter_10 is

	signal sum : unsigned(22 downto 0);
	signal sum10 : unsigned((N-1) downto 0);

begin

	process (clk, rst_l)
	begin
		if rst_l = '0' then
			sum <= (others => '0');
			sum10<= (others => '0');
		elsif rising_edge(clk) then
			sum <= sum + 1;
				if sum = to_unsigned(5_000_000, sum'length) then
				sum <= (others => '0');
				sum10 <= sum10+1;
			end if;
		end if;
		

	end process;
	
	count10 <= sum10;
	
end architecture behavioral;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity TenBitCounter is
  port (
    -- CLOCK
    ADC_CLK_10     : in  std_logic;

    -- KEY
    KEY            : in  std_logic_vector(1 downto 0);

    -- LED
    LEDR           : out std_logic_vector(9 downto 0)
  );
end entity TenBitCounter;

architecture top of TenBitCounter is
  signal cnt10_u : unsigned(9 downto 0);
begin
  u_cnt : entity work.counter_10
    generic map (
      N        => 10
    )
    port map (
      clk     => ADC_CLK_10,
      rst_l   => KEY(0),          -- press KEY0 to reset (active-low)
      count10 => cnt10_u
    );

  LEDR <= std_logic_vector(cnt10_u);
end architecture top;