library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity StopWatch_Top is
    port (
        MAX10_CLK1_50 : in  std_logic;
        KEY        : in  std_logic_vector(1 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0)
    );
end entity;

architecture top of StopWatch_Top is
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

begin
	u0 : Stopwatch
    port map (
        clk     => MAX10_CLK1_50,
        rst_l   => KEY(0),
        start   => KEY(1),
        tenth1  => HEX0,
        tenth2  => HEX1,
        sec1    => HEX2,
        sec2    => HEX3,
        min1    => HEX4,
        min2    => HEX5
    );

  --Assign 7 segments
end architecture top;