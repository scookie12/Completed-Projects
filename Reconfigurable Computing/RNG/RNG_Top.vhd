library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity RNG_Top is
    port (
        MAX10_CLK1_50 : in  std_logic;
        KEY        : in  std_logic_vector(1 downto 0);
        HEX0, HEX1 : out std_logic_vector(7 downto 0)
    );
end entity;

architecture top of RNG_Top is
  component RNG
	port (
		clk : in std_logic;
		rst_l : in std_logic;
        start   : in std_logic;
        random_out1    : out std_logic_vector(7 downto 0);
        random_out2    : out std_logic_vector(7 downto 0);
		  lfsr_state	: out std_logic_vector(15 downto 0)
	);
end component;

begin
	u0 : RNG
    port map (
        clk     => MAX10_CLK1_50,
        rst_l   => KEY(0),
        start   => KEY(1),
        random_out1  => HEX0,
        random_out2  => HEX1
    );

end architecture top;