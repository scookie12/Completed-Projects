library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADC_TOP is 
    port (
        ADC_CLK_10    : in  std_logic;                      -- 10 MHz ADC clock
        KEY           : in  std_logic_vector(1 downto 0);   -- KEY(0)=reset button, KEY(1)=add/cycle
        HEX0, HEX1, HEX2 : out std_logic_vector(7 downto 0)
    );
end entity;

architecture top of ADC_TOP is 

    signal clk_ADC   : std_logic;
    signal pll_arst  : std_logic;  
    signal pll_ok    : std_logic;
    signal rst_l     : std_logic;

    component ADC
        port(
            sys_clk              : in std_logic;
            pll_clk              : in std_logic;
            locked               : in std_logic;
            HEX0, HEX1, HEX2     : out std_logic_vector(7 downto 0);
            rst_l                : in std_logic
        );

    end component;

    component ADC_PLL
        port (
            areset : in  std_logic;     -- PLL async reset (active-high)
            inclk0 : in  std_logic;     -- 50 MHz input clock
            c0     : out std_logic;     -- pixel clock out (e.g., 25/12.5 MHz)
            locked : out std_logic      -- PLL locked indicator
        );
    end component;

    begin
    
    pll_arst <= not KEY(0);
    rst_l    <= KEY(0);

    u0_pll : ADC_PLL
        port map (
            areset => pll_arst,
            inclk0 => ADC_CLK_10,
            c0     => clk_ADC,
            locked => pll_ok
        );

    u1_ADC : ADC
        port map(
            sys_clk => ADC_CLK_10,
            pll_clk => clk_ADC,                                
            HEX0	=> HEX0,
            HEX1	=> HEX1,
            HEX2	=> HEX2,
            rst_l   => rst_l,  
            locked  => pll_ok
        );

    end architecture top;