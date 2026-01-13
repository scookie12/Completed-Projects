library ieee;
use ieee.std_logic_1164.all;

package spi_param is

    -- Data MSB Bit
    constant IDLE_MSB : integer := 14;
    constant SI_DataL : integer := 15;  -- P2S width-1
    constant SO_DataL : integer := 7;   -- S2P width-1

    -- Write/Read Mode (2-bit)
    constant SPI_WRITE_MODE : std_logic_vector(1 downto 0) := "00";
    constant SPI_READ_MODE  : std_logic_vector(1 downto 0) := "10";

    -- Initial Reg Number
    constant INI_NUMBER : integer := 11;  -- 0..10 -> 11 writes

    -- Write Reg Address (6-bit)
    constant BW_RATE        : std_logic_vector(5 downto 0) := "101100"; -- 6'h2c
    constant POWER_CONTROL  : std_logic_vector(5 downto 0) := "101101"; -- 6'h2d
    constant DATA_FORMAT    : std_logic_vector(5 downto 0) := "110001"; -- 6'h31
    constant INT_ENABLE     : std_logic_vector(5 downto 0) := "101110"; -- 6'h2e
    constant INT_MAP        : std_logic_vector(5 downto 0) := "101111"; -- 6'h2f
    constant THRESH_ACT     : std_logic_vector(5 downto 0) := "100100"; -- 6'h24
    constant THRESH_INACT   : std_logic_vector(5 downto 0) := "100101"; -- 6'h25
    constant TIME_INACT     : std_logic_vector(5 downto 0) := "100110"; -- 6'h26
    constant ACT_INACT_CTL  : std_logic_vector(5 downto 0) := "100111"; -- 6'h27
    constant THRESH_FF      : std_logic_vector(5 downto 0) := "101000"; -- 6'h28
    constant TIME_FF        : std_logic_vector(5 downto 0) := "101001"; -- 6'h29"

    -- Read Reg Address (6-bit)
    constant INT_SOURCE : std_logic_vector(5 downto 0) := "110000"; -- 6'h30
    constant X_LB       : std_logic_vector(5 downto 0) := "110010"; -- 6'h32
    constant X_HB       : std_logic_vector(5 downto 0) := "110011"; -- 6'h33
    constant Y_LB       : std_logic_vector(5 downto 0) := "110100"; -- 6'h34
    constant Y_HB       : std_logic_vector(5 downto 0) := "110101"; -- 6'h35
    constant Z_LB       : std_logic_vector(5 downto 0) := "110110"; -- 6'h36
    constant Z_HB       : std_logic_vector(5 downto 0) := "110111"; -- 6'h37

end package spi_param;

package body spi_param is
end package body spi_param;
