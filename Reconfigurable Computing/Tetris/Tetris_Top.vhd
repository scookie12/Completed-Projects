library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spi_param.all;

entity Tetris_Top is
    port(
        MAX10_CLK1_50 : in  std_logic;  -- 50 MHz board clock
        ADC_CLK_10    : in  std_logic;
        KEY           : in  std_logic_vector(1 downto 0);

        ARDUINO_IO    : out std_logic_vector (15 downto 0);

        VGA_HS        : out std_logic;
        VGA_VS        : out std_logic;
        VGA_R         : out std_logic_vector(3 downto 0);
        VGA_G         : out std_logic_vector(3 downto 0);
        VGA_B         : out std_logic_vector(3 downto 0);

        GSENSOR_CS_N  : out std_logic;
        GSENSOR_INT   : in  std_logic_vector(1 downto 0);
        GSENSOR_SCLK  : out std_logic;
        GSENSOR_SDI   : inout std_logic;
        GSENSOR_SDO   : inout std_logic;  -- unused, but kept in port list

        LEDR          : out std_logic_vector(9 downto 0)
    );
end entity;

architecture top of Tetris_Top is

    ----------------------------------------------------------------
    -- VGA / Tetris
    ----------------------------------------------------------------
    signal Cube_Color : std_logic_vector(1 downto 0);

    signal clk_VGA   : std_logic;
    signal pll_ok    : std_logic;
    signal sys_rst_l : std_logic;
    signal pll_arst  : std_logic;

    signal R_u, G_u, B_u : unsigned(3 downto 0);

    ----------------------------------------------------------------
    -- SPI / Accelerometer
    ----------------------------------------------------------------
    signal dly_rst        : std_logic;
    signal spi_clk        : std_logic;
    signal spi_clk_out    : std_logic;
    signal accel_x        : std_logic_vector(15 downto 0);

    signal gsensor_sclk_i : std_logic;
    signal gsensor_csn_i  : std_logic;

    -- debug from spi_ee_config
    signal dbg_ini_index  : std_logic_vector(3 downto 0);
    signal dbg_spi_go     : std_logic;
    signal dbg_spi_state  : std_logic;


    signal Column0        : unsigned(41 downto 0);
    signal Column1        : unsigned(41 downto 0);
    signal Column2        : unsigned(41 downto 0);
    signal Column3        : unsigned(41 downto 0);
    signal Column4        : unsigned(41 downto 0);
    signal Column5        : unsigned(41 downto 0);
    signal Column6        : unsigned(41 downto 0);
    signal Column7        : unsigned(41 downto 0);
    signal Column8        : unsigned(41 downto 0);

    signal score          : unsigned(19 downto 0);
    signal brick_stop     : std_logic; 
    signal brick_break    : std_logic; 
    signal game_over      : std_logic; 
    signal lane           : unsigned (4 downto 0);

    signal LR             :std_logic;
    ----------------------------------------------------------------
    -- Components
    ----------------------------------------------------------------
    component RNG_Color
        port (
            clk         : in std_logic;
            rst_l       : in std_logic;
            start       : in std_logic;
            random_out1 : out std_logic_vector(1 downto 0)
        );
    end component;

    component Speaker
        port (
            clk         : in std_logic;
            LR          : in std_logic;
            brick_stop  : in std_logic; 
            brick_break : in std_logic;     
            game_over   : in std_logic; 
            sound       : out std_logic
        );
    end component;

    component VGA
        port(
            clk      : in  std_logic;
            rst_l    : in  std_logic;
            score    : in unsigned(19 downto 0);   
            Column0    : in unsigned(41 downto 0);     --Mappings for VGA to look at
            Column1    : in unsigned(41 downto 0);
            Column2    : in unsigned(41 downto 0);
            Column3    : in unsigned(41 downto 0);
            Column4    : in unsigned(41 downto 0);
            Column5    : in unsigned(41 downto 0);
            Column6    : in unsigned(41 downto 0);
            Column7    : in unsigned(41 downto 0);
            Column8    : in unsigned(41 downto 0);
            Hsync    : out std_logic;
            Vsync    : out std_logic;
            Red_out  : out unsigned(3 downto 0);
            Blue_out : out unsigned(3 downto 0);
            Green_out: out unsigned(3 downto 0)
        );
    end component;

    component VGA_PLL
        port (
            areset : in  std_logic;
            inclk0 : in  std_logic;
            c0     : out std_logic;
            locked : out std_logic
        );
    end component;

    component spi_pll
        port (
            areset : in  std_logic := '0';
            inclk0 : in  std_logic := '0';
            c0     : out std_logic;
            c1     : out std_logic
        );
    end component;

    component Accelerometer
        port(
            clk      : in  std_logic;
            rst_l    : in  std_logic;
            accel_x  : in  std_logic_vector(15 downto 0);
            lane_out : out std_logic_vector(8 downto 0);
            lane     : out unsigned(4 downto 0);
            LR       : out std_logic
        );
    end component;

    component reset_delay
        port(
            iRSTN : in  std_logic;
            iCLK  : in  std_logic;
            oRST  : out std_logic
        );
    end component;

    component spi_ee_config
        port (
            iRSTN        : in    std_logic;
            iSPI_CLK     : in    std_logic;
            iSPI_CLK_OUT : in    std_logic;
            iG_INT2      : in    std_logic;

            oDATA_L      : out   std_logic_vector(SO_DataL downto 0);
            oDATA_H      : out   std_logic_vector(SO_DataL downto 0);

            SPI_SDIO     : inout std_logic;
            oSPI_CSN     : out   std_logic;
            oSPI_CLK     : out   std_logic;

            dbg_ini_index : out std_logic_vector(3 downto 0);
            dbg_spi_go    : out std_logic;
            dbg_spi_state : out std_logic
        );
    end component;

    component Tetris_Logic
        port   (
        clk        : in  std_logic;
        rst_l      : in  std_logic;
        color      : in std_logic_vector(1 downto 0);     --colors to shove into the block
        lane       : in unsigned(4 downto 0);
        start      : in std_logic;
        Column0    : out unsigned(41 downto 0);     --Mappings for VGA to look at
        Column1    : out unsigned(41 downto 0);
        Column2    : out unsigned(41 downto 0);
        Column3    : out unsigned(41 downto 0);
        Column4    : out unsigned(41 downto 0);
        Column5    : out unsigned(41 downto 0);
        Column6    : out unsigned(41 downto 0);
        Column7    : out unsigned(41 downto 0);
        Column8    : out unsigned(41 downto 0);
        score      : out unsigned(19 downto 0);
        brick_stop       : out std_logic;           --sounds for speaker to listen to
        brick_break      : out std_logic;   
        game_over        : out std_logic
    );
    end component;

begin
    ----------------------------------------------------------------
    -- VGA reset and outputs
    ----------------------------------------------------------------
    sys_rst_l <= KEY(0) and pll_ok;

    VGA_R <= std_logic_vector(R_u);
    VGA_G <= std_logic_vector(G_u);
    VGA_B <= std_logic_vector(B_u);

    pll_arst <= not KEY(0);

    u0_rng: RNG_Color
        port map(
            clk         => MAX10_CLK1_50,
            rst_l       => KEY(0),
            start       => '1',
            random_out1 => Cube_Color
        );

    u1_spk: Speaker
        port map(
            clk   => MAX10_CLK1_50,
            LR    => '0',
            brick_stop  => brick_stop, 
            brick_break => brick_break, 
            game_over   => game_over,            
            sound => ARDUINO_IO(0)
        );

    u2_vga: VGA
        port map(
            clk      => clk_VGA,
            rst_l    => sys_rst_l,
            score    => score,
            Column0  => Column0,
            Column1  => Column1,
            Column2  => Column2,
            Column3  => Column3,
            Column4  => Column4,
            Column5  => Column5,
            Column6  => Column6,
            Column7  => Column7,
            Column8  => Column8,
            Hsync    => VGA_HS,
            Vsync    => VGA_VS,
            Red_out  => R_u,
            Blue_out => B_u,
            Green_out=> G_u
        );

    u3_vgapll: VGA_PLL
        port map (
            areset => pll_arst,
            inclk0 => MAX10_CLK1_50,
            c0     => clk_VGA,
            locked => pll_ok
        );

    ----------------------------------------------------------------
    -- Accelerometer → LEDR (you can swap in your walker later)
    ----------------------------------------------------------------
    u4_accel: Accelerometer
        port map (
            clk      => MAX10_CLK1_50,
            rst_l    => Key(0),
            accel_x  => accel_x,
            lane_out => LEDR(8 downto 0),
            lane => lane
        );


    u5_logic: Tetris_Logic
        port map(
            clk         => MAX10_CLK1_50,
            rst_l       => Key(0),
            color       => Cube_color,
            lane        => lane,
            start       => Key(1),
            Column0     => Column0,
            Column1     => Column1,
            Column2     => Column2,
            Column3     => Column3,
            Column4     => Column4,
            Column5     => Column5,
            Column6     => Column6,
            Column7     => Column7,
            Column8     => Column8,
            score       => score,
            brick_stop  => brick_stop,
            brick_break => brick_break,
            game_over   => game_over  
        );
    ----------------------------------------------------------------
    -- Reset delay for SPI block
    ----------------------------------------------------------------
    u_reset_delay: reset_delay
        port map(
            iRSTN => KEY(0),           -- active-low from button
            iCLK  => MAX10_CLK1_50,
            oRST  => dly_rst
        );

    ----------------------------------------------------------------
    -- SPI PLL
    ----------------------------------------------------------------
    u_spi_pll: spi_pll
        port map(
            areset => not dly_rst,
            inclk0 => MAX10_CLK1_50,
            c0     => spi_clk,
            c1     => spi_clk_out
        );

    ----------------------------------------------------------------
    -- SPI EE Config (fills accel_x)
    ----------------------------------------------------------------
    u_spi_ee_config: spi_ee_config
        port map(
            iRSTN        => dly_rst,
            iSPI_CLK     => spi_clk,
            iSPI_CLK_OUT => spi_clk_out,
            iG_INT2      => GSENSOR_INT(1),

            -- Only the lower 8 bits in each are real data bytes
            oDATA_L      => accel_x(7 downto 0),
            oDATA_H      => accel_x(15 downto 8),

            SPI_SDIO     => GSENSOR_SDI,
            oSPI_CSN     => gsensor_csn_i,
            oSPI_CLK     => gsensor_sclk_i,

            dbg_ini_index => dbg_ini_index,
            dbg_spi_go    => dbg_spi_go,
            dbg_spi_state => dbg_spi_state
        );


    GSENSOR_CS_N <= gsensor_csn_i;
    GSENSOR_SCLK <= gsensor_sclk_i;
    -- GSENSOR_SDO is unused in this design

end architecture top;
