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

architecture behavioral of Accelerometer is

    ----------------------------------------------------------------
    -- Tunable thresholds (0..4095 range after scaling)
    -- Map magnitude into 9 buckets:
    --  0 ..  T0     -> lane 0
    --  T0+1 .. T1   -> lane 1
    --  ...
    --  T7+1 .. max  -> lane 8
    ----------------------------------------------------------------
    constant T0 : signed(12 downto 0) := to_signed(  455, 13);
    constant T1 : signed(12 downto 0) := to_signed(  910, 13);
    constant T2 : signed(12 downto 0) := to_signed( 1365, 13);
    constant T3 : signed(12 downto 0) := to_signed( 1820, 13);
    constant T4 : signed(12 downto 0) := to_signed( 2275, 13);
    constant T5 : signed(12 downto 0) := to_signed( 2730, 13);
    constant T6 : signed(12 downto 0) := to_signed( 3185, 13);
    constant T7 : signed(12 downto 0) := to_signed( 3640, 13);

    -- How fast we glide between lanes (lane_reg -> target_lane)
    -- 0.2 s at 50 MHz -> 10,000,000 cycles
    constant MOVE_PERIOD  : integer := 10000000;

    -- LR cooldown so we don't spam the speaker
    -- 1.0 s at 50 MHz -> 50,000,000 cycles
    constant LR_COOLDOWN  : integer := 50000000;

    -- Minimum tilt magnitude before we consider LR "valid"
    -- (ignore tiny jitters near flat)
    constant LR_TILT_MIN  : signed(12 downto 0) := to_signed(1500, 13);

    ----------------------------------------------------------------
    -- Signals
    ----------------------------------------------------------------
    signal accel_x_s      : signed(15 downto 0);
    signal accel_x_scaled : signed(12 downto 0);
    signal accel_mag      : signed(12 downto 0);

    signal target_lane    : unsigned(4 downto 0) := (others => '0');  -- desired lane 0..8
    signal lane_reg       : unsigned(4 downto 0) := (others => '0');  -- current lane 0..8
    signal move_cnt       : integer range 0 to MOVE_PERIOD := 0;

    signal lane_reg_prev  : unsigned(4 downto 0) := (others => '0');
    signal LR_reg         : std_logic := '0';

    -- LR cooldown counter
    signal lr_cool_cnt    : integer range 0 to LR_COOLDOWN := 0;

begin

    ----------------------------------------------------------------
    -- Main process: map |accel| to target_lane, then glide lane_reg
    ----------------------------------------------------------------
    process(clk, rst_l)
        variable accel_x_scaled_v : signed(12 downto 0);
        variable accel_mag_v      : signed(12 downto 0);
        variable lane_int_target  : integer range 0 to 8;
    begin
        if rst_l = '0' then
            accel_x_s      <= (others => '0');
            accel_x_scaled <= (others => '0');
            accel_mag      <= (others => '0');

            target_lane    <= (others => '0');
            lane_reg       <= (others => '0');
            move_cnt       <= 0;

            lane_reg_prev  <= (others => '0');
            LR_reg         <= '0';
            lr_cool_cnt    <= 0;

        elsif rising_edge(clk) then

            -- Interpret incoming vector as signed two's complement
            accel_x_s <= signed(accel_x);

            -- Drop 3 LSBs -> smoother 13-bit value
            accel_x_scaled_v := accel_x_s(15 downto 3);
            accel_x_scaled   <= accel_x_scaled_v;

            -- Magnitude = |accel_x_scaled_v|
            if accel_x_scaled_v(12) = '1' then
                accel_mag_v := -accel_x_scaled_v;
            else
                accel_mag_v := accel_x_scaled_v;
            end if;
            accel_mag <= accel_mag_v;

            --------------------------------------------------------
            -- Map magnitude into target lane 0..8
            --------------------------------------------------------
            if accel_mag_v <= T0 then
                lane_int_target := 0;
            elsif accel_mag_v <= T1 then
                lane_int_target := 1;
            elsif accel_mag_v <= T2 then
                lane_int_target := 2;
            elsif accel_mag_v <= T3 then
                lane_int_target := 3;
            elsif accel_mag_v <= T4 then
                lane_int_target := 4;
            elsif accel_mag_v <= T5 then
                lane_int_target := 5;
            elsif accel_mag_v <= T6 then
                lane_int_target := 6;
            elsif accel_mag_v <= T7 then
                lane_int_target := 7;
            else
                lane_int_target := 8;
            end if;

            target_lane <= to_unsigned(lane_int_target, 5);

            --------------------------------------------------------
            -- Glide: step lane_reg by at most 1 toward target_lane
            --------------------------------------------------------
            if lane_reg = target_lane then
                -- already there: no motion, reset move counter
                move_cnt <= 0;
            else
                if move_cnt >= MOVE_PERIOD - 1 then
                    move_cnt <= 0;

                    -- Move one lane toward target (no jumps)
                    if lane_reg < target_lane then
                        lane_reg <= lane_reg + 1;
                    else
                        lane_reg <= lane_reg - 1;
                    end if;

                else
                    move_cnt <= move_cnt + 1;
                end if;
            end if;

            --------------------------------------------------------
            -- LR cooldown & pulse generation
            --------------------------------------------------------
            -- default: LR low
            LR_reg <= '0';

            -- Cooldown counter
            if lr_cool_cnt > 0 then
                lr_cool_cnt <= lr_cool_cnt - 1;
            end if;

            -- Only fire LR when:
            --  * lane actually changed
            --  * cooldown expired
            --  * tilt magnitude is above LR_TILT_MIN (ignore tiny jitters)
            if (lane_reg /= lane_reg_prev) and
               (lr_cool_cnt = 0)          and
               (accel_mag_v > LR_TILT_MIN) then

                LR_reg      <= '1';           -- one-clock pulse
                lr_cool_cnt <= LR_COOLDOWN;   -- start cooldown
            end if;

            lane_reg_prev <= lane_reg;

        end if;
    end process;

    ----------------------------------------------------------------
    -- Drive outputs
    ----------------------------------------------------------------
    lane <= lane_reg;
    LR   <= LR_reg;

    -- One-hot LED decode for 9 lanes
    process(lane_reg)
        variable v : std_logic_vector(8 downto 0);
        variable i : integer;
    begin
        v := (others => '0');
        i := to_integer(lane_reg);
        if (i >= 0) and (i <= 8) then
            v(i) := '1';
        end if;
        lane_out <= v;
    end process;

end architecture behavioral;
