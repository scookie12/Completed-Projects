library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_TB is 
end VGA_TB;

architecture behavioral of VGA_TB is
    component VGA
    port(
        clk          : in std_logic;
        rst_l        : in std_logic;
        but_press    : in std_logic;
        Hsync        : out std_logic; 
        Vsync        : out std_logic;
        Red_out      : out unsigned [3 downto 0];
        Blue_out     : out unsigned [3 downto 0];
        Green_out    : out unsigned [3 downto 0]
    );

    end component;

    constant CLK_PERIOD : time := 39.722 ns;

    begin

        uut : VGA
            