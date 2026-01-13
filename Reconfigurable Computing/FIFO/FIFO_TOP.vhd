library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIFO_Top is
    port (
        MAX10_CLK1_50 : in  std_logic;                          -- 50 MHz board clock
        KEY           : in  std_logic_vector(1 downto 0);       -- KEY(0)=reset, KEY(1)=add
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0);
        LEDR          : out std_logic_vector(9 downto 0);
        SW            : in  std_logic_vector(9 downto 0)
    );
end entity FIFO_Top;


architecture top of FIFO_Top is

    ----------------------------------------------------------------
    -- Internal signals
    ----------------------------------------------------------------
    signal clk5      : std_logic;
    signal clk12     : std_logic;
    signal pll_ok    : std_logic;
    signal sys_rst_l : std_logic;  -- active-low reset after PLL lock
    signal pll_arst  : std_logic;  
    signal data_in : unsigned(9 downto 0);
    signal rdreq : std_logic;
    signal wrreq : std_logic;
    signal empty : std_logic;
    signal full : std_logic;
    signal data_out : unsigned(9 downto 0);
    signal rdusedw : STD_LOGIC_VECTOR(2 downto 0);
    signal wrusedw : STD_LOGIC_VECTOR(2 downto 0);
    signal fifo_data_in_slv  : std_logic_vector(9 downto 0);
    signal fifo_data_out_slv : std_logic_vector(9 downto 0);
    signal aclr      : std_logic;  -- NEW: async clear for FIFO



    ----------------------------------------------------------------
    -- Component declarations
    ----------------------------------------------------------------
    component accumulator
        port (
            clk5    : in  std_logic;                           -- 5 MHz FSM domain
            clk12   : in  std_logic;                           -- 12.5 MHz FSM domain
            rst_l   : in  std_logic;                           -- active-low reset
            add_btn : in  std_logic;                           -- "Add" button
            sw      : in  std_logic_vector(9 downto 0);
            led     : out std_logic_vector(9 downto 0);
            HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0);
            write_enable : out std_logic;
            rdusedw : in std_logic_vector(2 downto 0);
            full : in std_logic;
            data_in : out unsigned(9 downto 0);
            read_enable : out std_logic;
            data_out : in unsigned(9 downto 0);
            empty : in std_logic
        );
    end component;

    component ALT_CLKS
        port (
            areset : in  std_logic;    -- PLL async reset (active-high)
            inclk0 : in  std_logic;    -- 50 MHz input clock
            c0     : out std_logic;    -- 5 MHz clock out
            c1     : out std_logic;    -- 12.5 MHz clock out
            locked : out std_logic     -- PLL locked indicator
        );
    end component;

    component my_FIFO
        port (
            aclr		: IN STD_LOGIC  := '0';
            data		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
            rdclk		: IN STD_LOGIC ;
            rdreq		: IN STD_LOGIC ;
            wrclk		: IN STD_LOGIC ;
            wrreq		: IN STD_LOGIC ;
            q		: OUT STD_LOGIC_VECTOR (9 DOWNTO 0);
            rdempty		: OUT STD_LOGIC ;
            rdusedw		: OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
            wrfull		: OUT STD_LOGIC ;
            wrusedw		: OUT STD_LOGIC_VECTOR (2 DOWNTO 0)
        );
    end component;
begin
    pll_arst <= not KEY(0);

    fifo_data_in_slv <= std_logic_vector(data_in);
    data_out         <= unsigned(fifo_data_out_slv);
    
    ----------------------------------------------------------------
    -- PLL instantiation
    ----------------------------------------------------------------
    u0_pll : ALT_CLKS
        port map (
            areset => pll_arst,         -- PLL reset active-high (invert KEY(0))
            inclk0 => MAX10_CLK1_50,
            c0     => clk5,
            c1     => clk12,
            locked => pll_ok
        );

    ----------------------------------------------------------------
    -- System reset: active-low
    -- Hold logic in reset until PLL is locked and KEY(0) released.
    ----------------------------------------------------------------
    sys_rst_l <= KEY(0) and pll_ok;
    aclr      <= not sys_rst_l;      -- active-high clear to FIFO
    ----------------------------------------------------------------
    -- Accumulator / FIFO system instantiation
    ----------------------------------------------------------------
    u1_accum : accumulator
        port map (
            clk5    => clk5,
            clk12   => clk12,
            rst_l   => sys_rst_l,
            add_btn => KEY(1),
            sw      => SW,
            led     => LEDR,
            HEX0    => HEX0,
            HEX1    => HEX1,
            HEX2    => HEX2,
            HEX3    => HEX3,
            HEX4    => HEX4,
            HEX5    => HEX5,
            write_enable => wrreq,
            rdusedw => rdusedw,
            full => full,
            data_in => data_in,
            read_enable => rdreq,
            data_out => data_out,
            empty => empty
        );

        u2_my_FIFO : my_FIFO
        port map (
            data     => fifo_data_in_slv,
            rdclk    => clk12,
            rdreq    => rdreq,
            wrclk    => clk5,
            wrreq    => wrreq,
            q        => fifo_data_out_slv,
            rdempty  => empty,
            rdusedw  => rdusedw,
            wrfull   => full,
            wrusedw  => wrusedw,
            aclr => aclr
        );

end architecture top;
