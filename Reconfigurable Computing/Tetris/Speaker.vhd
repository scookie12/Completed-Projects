library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Speaker is
    port(
        clk         : in std_logic;   -- assume 10 MHz
        LR          : in std_logic;
        brick_break : in std_logic;
        game_over   : in std_logic;
        brick_stop  : in std_logic;
        sound       : out std_logic
    );
end entity Speaker;

architecture behavioral of Speaker is

    -- 0.2 s at 10 MHz = 2,000,000 clock cycles
    constant CUTOFF : integer := 2000000;

    -- These are just terminal counts for the toggle counter.
    -- f_out ≈ clk / (2 * TOGGLE_MAX)
    constant LR_TOGGLE_MAX          : integer := 540540; -- your LR tone
    constant BRICK_STOP_TOGGLE_MAX  : integer := 191000;
    constant BRICK_BREAK_TOGGLE_MAX : integer := 214640;
    constant GAME_OVER_TOGGLE_MAX   : integer := 113640;

    type sound_type is (NONE, T_LR, T_BRICK_STOP, T_BRICK_BREAK, T_GAME_OVER);
    signal current_sound : sound_type := NONE;

    signal time_count : integer range 0 to CUTOFF := 0;
    signal clk_count  : integer range 0 to 1000000 := 0;  -- big enough for all

    signal sound_reg  : std_logic := '0';

    -- edge detection
    signal LR_prev, brick_break_prev, brick_stop_prev, game_over_prev : std_logic := '0';

begin

    process (clk)
    begin
        if rising_edge(clk) then

            ----------------------------------------------------------------
            -- Edge detect: choose which sound to play (0.2 s one-shot)
            -- Priority: game_over > brick_break > brick_stop > LR
            ----------------------------------------------------------------
            if (game_over_prev = '0' and game_over = '1') then
                current_sound <= T_GAME_OVER;
                time_count    <= 0;
                clk_count     <= 0;
                sound_reg     <= '0';

            elsif (brick_break_prev = '0' and brick_break = '1') then
                current_sound <= T_BRICK_BREAK;
                time_count    <= 0;
                clk_count     <= 0;
                sound_reg     <= '0';

            elsif (brick_stop_prev = '0' and brick_stop = '1') then
                current_sound <= T_BRICK_STOP;
                time_count    <= 0;
                clk_count     <= 0;
                sound_reg     <= '0';

            elsif (LR_prev = '0' and LR = '1') then
                current_sound <= T_LR;
                time_count    <= 0;
                clk_count     <= 0;
                sound_reg     <= '0';
            end if;

            -- update previous input states
            LR_prev         <= LR;
            brick_break_prev<= brick_break;
            brick_stop_prev <= brick_stop;
            game_over_prev  <= game_over;

            ----------------------------------------------------------------
            -- Tone generation for the active sound (pure counter-based)
            ----------------------------------------------------------------
            if current_sound = NONE then
                -- idle
                sound_reg  <= '0';
                time_count <= 0;
                clk_count  <= 0;

            else
                if time_count < CUTOFF then
                    time_count <= time_count + 1;

                    -- Increment counter and toggle on terminal count
                    case current_sound is
                        when T_LR =>
                            if clk_count >= LR_TOGGLE_MAX then
                                clk_count <= 0;
                                sound_reg <= not sound_reg;
                            else
                                clk_count <= clk_count + 1;
                            end if;

                        when T_BRICK_STOP =>
                            if clk_count >= BRICK_STOP_TOGGLE_MAX then
                                clk_count <= 0;
                                sound_reg <= not sound_reg;
                            else
                                clk_count <= clk_count + 1;
                            end if;

                        when T_BRICK_BREAK =>
                            if clk_count >= BRICK_BREAK_TOGGLE_MAX then
                                clk_count <= 0;
                                sound_reg <= not sound_reg;
                            else
                                clk_count <= clk_count + 1;
                            end if;

                        when T_GAME_OVER =>
                            if clk_count >= GAME_OVER_TOGGLE_MAX then
                                clk_count <= 0;
                                sound_reg <= not sound_reg;
                            else
                                clk_count <= clk_count + 1;
                            end if;

                        when others =>
                            -- safety / shouldn't hit
                            clk_count <= 0;
                            sound_reg <= '0';
                    end case;

                else
                    -- 0.2 s finished: stop sound
                    current_sound <= NONE;
                    sound_reg     <= '0';
                    time_count    <= 0;
                    clk_count     <= 0;
                end if;
            end if;

        end if;
    end process;

    sound <= sound_reg;

end architecture behavioral;
