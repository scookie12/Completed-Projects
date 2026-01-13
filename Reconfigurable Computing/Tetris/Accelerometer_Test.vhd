library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Accelerometer is
    port(
        clk       : in  std_logic;                     -- 50 MHz clock
        rst_l     : in  std_logic;
        accel_x   : in  std_logic_vector(15 downto 0); -- from ADXL (DATAX1:0)
        lane      : out unsigned(4 downto 0);          -- 0..8
        lane_out  : out std_logic_vector(8 downto 0);  -- one-hot LED (9 lanes)
        LR        : out std_logic                      -- pulse on lane change
    );
end entity Accelerometer;

