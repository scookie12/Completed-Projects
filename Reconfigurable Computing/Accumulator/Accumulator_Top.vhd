library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Accumulator_Top is
	port (
	    MAX10_CLK1_50 : in  std_logic;
        KEY        : in  std_logic_vector(1 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0);
		LEDR : out std_logic_vector (9 downto 0);
		SW  : in std_logic_vector (9 downto 0)
	);
end entity;

architecture top of Accumulator_Top is 
	component Accumulator
		port(
		
		clk      : in std_logic;
        rst_l    : in std_logic;
        add_btn  : in std_logic;                  -- "Add" button
        sw       : in std_logic_vector(9 downto 0); -- 10-bit input
		led      : out std_logic_vector(9 downto 0); -- mirror switches
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0)
	);
	
end component;

begin
	u0 : Accumulator
	port map (
		clk     => MAX10_CLK1_50,
        rst_l   => KEY(0),
        add_btn => KEY(1),
		sw		=> SW,
		led		=> LEDR,
		HEX0	=> HEX0,
		HEX1	=> HEX1,
		HEX2	=> HEX2,
		HEX3	=> HEX3,
		HEX4	=> HEX4,
		HEX5	=> HEX5
		);
		
end architecture top;

		
		
		
		