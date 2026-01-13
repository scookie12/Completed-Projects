library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_Top is
  port (
    MAX10_CLK1_50 : in  std_logic;                      -- 50 MHz board clock
    KEY           : in  std_logic_vector(1 downto 0);   -- KEY(0)=reset button, KEY(1)=add/cycle
    VGA_HS        : out std_logic;
    VGA_VS        : out std_logic;
    VGA_R         : out std_logic_vector(3 downto 0);
    VGA_G         : out std_logic_vector(3 downto 0);
    VGA_B         : out std_logic_vector(3 downto 0)
  );
end entity VGA_Top;

architecture top of VGA_Top is
  signal clk_VGA   : std_logic;
  signal pll_ok    : std_logic;
  signal sys_rst_l : std_logic;   -- active-low reset after PLL lock
  signal pll_arst  : std_logic;

  -- Unsigned buses from VGA core
  signal R_u, G_u, B_u : unsigned(3 downto 0);

  component VGA_PLL
    port (
      areset : in  std_logic;     -- PLL async reset (active-high)
      inclk0 : in  std_logic;     -- 50 MHz input clock
      c0     : out std_logic;     -- pixel clock out (e.g., 25/12.5 MHz)
      locked : out std_logic      -- PLL locked indicator
    );
  end component;

  component VGA
    port(
      clk        : in  std_logic;
      rst_l      : in  std_logic;
      but_press  : in  std_logic;       -- debounced externally
      Hsync      : out std_logic; 
      Vsync      : out std_logic;
      Red_out    : out unsigned(3 downto 0);
      Blue_out   : out unsigned(3 downto 0);
      Green_out  : out unsigned(3 downto 0)
    );
  end component;

begin
  -- PLL reset: make active-high (invert button if KEY(0) is active-high)
  pll_arst <= not KEY(0);

  u0_pll : VGA_PLL
    port map (
      areset => pll_arst,
      inclk0 => MAX10_CLK1_50,
      c0     => clk_VGA,
      locked => pll_ok
    );

  -- Release core reset only when button released AND PLL locked
  sys_rst_l <= KEY(0) and pll_ok;

  -- Cast unsigned color buses to top-level std_logic_vector
  VGA_R <= std_logic_vector(R_u);
  VGA_G <= std_logic_vector(G_u);
  VGA_B <= std_logic_vector(B_u);

  u1_VGA : VGA
    port map(
      clk        => clk_VGA,
      rst_l      => sys_rst_l,       -- use post-PLL active-low reset
      but_press  => KEY(1),
      Hsync      => VGA_HS,
      Vsync      => VGA_VS,
      Red_out    => R_u,
      Blue_out   => B_u,
      Green_out  => G_u
    );

end architecture top;
