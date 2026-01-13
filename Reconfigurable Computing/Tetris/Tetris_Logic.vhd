library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Tetris_Logic is
    port(
        clk        : in  std_logic;
        rst_l      : in  std_logic;
        start      : in  std_logic;                     -- active-low start button
        color      : in  std_logic_vector(1 downto 0);  -- color for new cube
        lane       : in  unsigned(4 downto 0);          -- desired lane 0..8

        Column0    : out unsigned(41 downto 0);
        Column1    : out unsigned(41 downto 0);
        Column2    : out unsigned(41 downto 0);
        Column3    : out unsigned(41 downto 0);
        Column4    : out unsigned(41 downto 0);
        Column5    : out unsigned(41 downto 0);
        Column6    : out unsigned(41 downto 0);
        Column7    : out unsigned(41 downto 0);
        Column8    : out unsigned(41 downto 0);

        score      : out unsigned(19 downto 0);
        brick_stop : out std_logic;     -- pulse when a falling brick becomes stationary
        brick_break: out std_logic;     -- pulse when cubes disappear
        game_over  : out std_logic
    );
end entity Tetris_Logic;

architecture behavioral of Tetris_Logic is

    --------------------------------------------------------------------------
    -- Board representation
    --  9 columns (0..8), 14 rows (0..13, bottom..top)
    --  Each cell stores: present + 2-bit color.
    --------------------------------------------------------------------------
    type col_present_t   is array(0 to 13) of std_logic;
    type board_present_t is array(0 to 8)  of col_present_t;

    type col_color_t     is array(0 to 13) of std_logic_vector(1 downto 0);
    type board_color_t   is array(0 to 8)  of col_color_t;

    signal present_s : board_present_t := (others => (others => '0'));
    signal color_s   : board_color_t   := (others => (others => "00"));

    --------------------------------------------------------------------------
    -- Falling cube state
    --------------------------------------------------------------------------
    type game_state_t is (SPAWN, FALLING, RESOLVE_MATCHES, GAME_OVER_S);
    signal state      : game_state_t := SPAWN;

    signal fall_col   : integer range 0 to 8  := 4;      -- lane of active cube
    signal fall_row   : integer range 0 to 13 := 13;     -- row of active cube
    signal fall_color : std_logic_vector(1 downto 0) := "00";
    signal falling_blk: std_logic := '0';

    -- Game over if any stationary cube is at/above this row
    constant GAME_OVER_ROW : integer := 12;  -- rows 12 or 13

    --------------------------------------------------------------------------
    -- Slow drop timer (adjust DROP_MAX for speed)
    --------------------------------------------------------------------------
    signal drop_cnt   : unsigned(25 downto 0) := (others => '0');
    signal drop_tick  : std_logic := '0';
    constant DROP_MAX : unsigned(25 downto 0) := to_unsigned(10000000, 26); -- ~10 Hz @ 50 MHz

    -- Internal score register
    signal score_reg      : unsigned(score'range) := (others => '0');
    signal game_over_reg  : std_logic := '0';

    -- Latched start flag
    signal start_game     : std_logic := '0';

begin

    score     <= score_reg;
    game_over <= game_over_reg;

    ----------------------------------------------------------------------------
    -- Drop timer, gated by start button
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_l = '0' then
                start_game <= '0';
                drop_cnt   <= (others => '0');
                drop_tick  <= '0';
            else
                -- latch start once when button goes active-low
                if (start_game = '0') and (start = '0') then
                    start_game <= '1';
                end if;

                if start_game = '1' then
                    if drop_cnt = DROP_MAX then
                        drop_cnt  <= (others => '0');
                        drop_tick <= '1';
                    else
                        drop_cnt  <= drop_cnt + 1;
                        drop_tick <= '0';
                    end if;
                else
                    drop_cnt  <= (others => '0');
                    drop_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Main Tetris state machine
    ----------------------------------------------------------------------------
    process(clk)
        -- match-marking and gravity helpers
        variable mark           : board_present_t;
        variable tmp_present_col: col_present_t;
        variable tmp_color_col  : col_color_t;

        variable cleared        : integer;
        variable lane_int       : integer;
        variable over_v         : boolean;

        variable col_idx        : integer;
        variable row_idx        : integer;
        variable col_val        : std_logic_vector(1 downto 0);
        variable col_val2       : std_logic_vector(1 downto 0);
        variable run_len        : integer;
        variable run_len2       : integer;
    begin
        if rising_edge(clk) then
            if rst_l = '0' then
                -- Reset everything
                for c in 0 to 8 loop
                    for r in 0 to 13 loop
                        present_s(c)(r) <= '0';
                        color_s(c)(r)   <= "00";
                    end loop;
                end loop;

                score_reg      <= (others => '0');
                brick_stop     <= '0';
                brick_break    <= '0';
                game_over_reg  <= '0';
                state          <= SPAWN;
                falling_blk    <= '0';
                fall_col       <= 4;
                fall_row       <= 13;
                fall_color     <= "00";

            else
                -- default pulses low
                brick_stop  <= '0';
                brick_break <= '0';

                if drop_tick = '1' then
                    case state is

                        ------------------------------------------------------------------
                        -- SPAWN: create a new falling cube at the top
                        ------------------------------------------------------------------
                        when SPAWN =>
                            if (game_over_reg = '0') and (start_game = '1') then
                                -- Map lane input (0..8)
                                lane_int := to_integer(lane);
                                if lane_int < 0 then
                                    lane_int := 0;
                                elsif lane_int > 8 then
                                    lane_int := 8;
                                end if;

                                fall_col   <= lane_int;
                                fall_row   <= 13;        -- top row
                                fall_color <= color;     -- color supplied externally
                                falling_blk<= '1';
                                state      <= FALLING;
                            end if;

                        ------------------------------------------------------------------
                        -- FALLING: move cube down until it hits bottom or another cube
                        ------------------------------------------------------------------
                        when FALLING =>
                            -- Allow horizontal movement to requested lane if that
                            -- cell is not already occupied at the current row.
                            lane_int := to_integer(lane);
                            if lane_int < 0 then
                                lane_int := 0;
                            elsif lane_int > 8 then
                                lane_int := 8;
                            end if;

                            if present_s(lane_int)(fall_row) = '0' then
                                fall_col <= lane_int;
                            end if;

                            -- Collision check below
                            if (fall_row = 0) or (present_s(fall_col)(fall_row - 1) = '1') then
                                -- Lock brick into the board
                                present_s(fall_col)(fall_row) <= '1';
                                color_s(fall_col)(fall_row)   <= fall_color;
                                brick_stop                    <= '1';
                                falling_blk                   <= '0';

                                -- Game-over check: any cube near the top?
                                over_v := false;
                                for c in 0 to 8 loop
                                    for r in GAME_OVER_ROW to 13 loop
                                        if present_s(c)(r) = '1' then
                                            over_v := true;
                                        end if;
                                    end loop;
                                end loop;

                                if over_v then
                                    game_over_reg <= '1';
                                    state         <= GAME_OVER_S;
                                else
                                    state         <= RESOLVE_MATCHES;
                                end if;

                            else
                                -- Keep falling
                                fall_row <= fall_row - 1;
                            end if;

                        ------------------------------------------------------------------
                        -- RESOLVE_MATCHES:
                        --  1) Find all runs of >=3 same-color cubes (horizontal & vertical)
                        --  2) Remove them, update score, and apply gravity
                        --  3) If more matches appear after gravity, repeat
                        ------------------------------------------------------------------
                        when RESOLVE_MATCHES =>
                            -- Clear mark array
                            for c in 0 to 8 loop
                                for r in 0 to 13 loop
                                    mark(c)(r) := '0';
                                end loop;
                            end loop;

                            ----------------------------------------------------------------
                            -- Horizontal matches
                            ----------------------------------------------------------------
                            for r in 0 to 13 loop
                                for c0 in 0 to 8 loop
                                    if present_s(c0)(r) = '1' then
                                        col_idx := c0;
                                        col_val := color_s(c0)(r);
                                        run_len := 1;

                                        -- Count contiguous same-color cubes to the right
                                        for c2 in 0 to 8 loop
                                            if c2 > col_idx then
                                                if (present_s(c2)(r) = '1') and
                                                   (color_s(c2)(r) = col_val) then
                                                    run_len := run_len + 1;
                                                else
                                                    exit;  -- break on first mismatch/empty
                                                end if;
                                            end if;
                                        end loop;

                                        -- Mark all cubes in this run if length >= 3
                                        if run_len >= 3 then
                                            for c3 in 0 to 8 loop
                                                if (c3 >= col_idx) and (c3 < col_idx + run_len) then
                                                    mark(c3)(r) := '1';
                                                end if;
                                            end loop;
                                        end if;
                                    end if;
                                end loop;
                            end loop;

                            ----------------------------------------------------------------
                            -- Vertical matches
                            ----------------------------------------------------------------
                            for c in 0 to 8 loop
                                for r0 in 0 to 13 loop
                                    if present_s(c)(r0) = '1' then
                                        row_idx  := r0;
                                        col_val2 := color_s(c)(r0);
                                        run_len2 := 1;

                                        -- Count contiguous same-color cubes downward
                                        for r2 in 0 to 13 loop
                                            if r2 > row_idx then
                                                if (present_s(c)(r2) = '1') and
                                                   (color_s(c)(r2) = col_val2) then
                                                    run_len2 := run_len2 + 1;
                                                else
                                                    exit;  -- break on first mismatch/empty
                                                end if;
                                            end if;
                                        end loop;

                                        -- Mark all cubes in this run if length >= 3
                                        if run_len2 >= 3 then
                                            for r3 in 0 to 13 loop
                                                if (r3 >= row_idx) and (r3 < row_idx + run_len2) then
                                                    mark(c)(r3) := '1';
                                                end if;
                                            end loop;
                                        end if;
                                    end if;
                                end loop;
                            end loop;

                            ----------------------------------------------------------------
                            -- Remove marked cubes and count them
                            ----------------------------------------------------------------
                            cleared := 0;
                            for c in 0 to 8 loop
                                for r in 0 to 13 loop
                                    if mark(c)(r) = '1' then
                                        cleared := cleared + 1;
                                    end if;
                                end loop;
                            end loop;


                            if cleared > 0 then
                                -- Score + sounds
                                score_reg   <= score_reg + to_unsigned(cleared, score_reg'length);
                                brick_break <= '1';

                                -- Apply gravity column-by-column
                                for c in 0 to 8 loop
                                    -- clear temp
                                    for r in 0 to 13 loop
                                        tmp_present_col(r) := '0';
                                        tmp_color_col(r)   := "00";
                                    end loop;

                                row_idx := 0;  -- next free row from bottom
                                for r in 0 to 13 loop
                                    if (present_s(c)(r) = '1') and (mark(c)(r) = '0') then
                                        tmp_present_col(row_idx) := '1';
                                        tmp_color_col(row_idx)   := color_s(c)(r);
                                        row_idx                  := row_idx + 1;
                                    end if;
                                end loop;


                                    -- write back
                                    for r in 0 to 13 loop
                                        present_s(c)(r) <= tmp_present_col(r);
                                        color_s(c)(r)   <= tmp_color_col(r);
                                    end loop;
                                end loop;

                                -- After gravity, check for more matches next tick
                                state <= RESOLVE_MATCHES;
                            else
                                -- No more matches → spawn next brick
                                state <= SPAWN;
                            end if;

                        ------------------------------------------------------------------
                        when GAME_OVER_S =>
                            -- Stay here; board + score are frozen
                            game_over_reg <= '1';

                    end case;
                end if;  -- drop_tick
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Pack board + falling cube into 9 column vectors for VGA
    ----------------------------------------------------------------------------
    process(present_s, color_s, fall_col, fall_row, fall_color, falling_blk)
        variable col_vec : unsigned(41 downto 0);
        variable base    : integer;
        variable pres    : std_logic;
        variable clr     : std_logic_vector(1 downto 0);
    begin
        for c in 0 to 8 loop
            col_vec := (others => '0');

            for r in 0 to 13 loop
                base := r * 3;
                pres := present_s(c)(r);
                clr  := color_s(c)(r);

                -- Overlay falling cube
                if (falling_blk = '1') and (c = fall_col) and (r = fall_row) then
                    pres := '1';
                    clr  := fall_color;
                end if;

                -- present bit
                col_vec(base + 2) := pres;

                -- color bits (MSB in bit base+1, LSB in bit base)
                col_vec(base + 1) := clr(1);
                col_vec(base    ) := clr(0);
            end loop;

            case c is
                when 0 => Column0 <= col_vec;
                when 1 => Column1 <= col_vec;
                when 2 => Column2 <= col_vec;
                when 3 => Column3 <= col_vec;
                when 4 => Column4 <= col_vec;
                when 5 => Column5 <= col_vec;
                when 6 => Column6 <= col_vec;
                when 7 => Column7 <= col_vec;
                when others => Column8 <= col_vec;
            end case;
        end loop;
    end process;

end architecture behavioral;
