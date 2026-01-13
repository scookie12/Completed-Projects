library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accumulator is
    port (
        clk5      : in std_logic;
        clk12      : in std_logic;
        rst_l    : in std_logic;
        add_btn  : in std_logic;                  -- "Add" button
        sw       : in std_logic_vector(9 downto 0); -- 10-bit input
        led      : out std_logic_vector(9 downto 0); -- mirror switches
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0);
        write_enable : out std_logic;
        rdusedw : in std_logic_vector(2 downto 0);
        full : in std_logic;
        data_in : out unsigned(9 downto 0);
        read_enable : out std_logic;
        data_out : in unsigned(9 downto 0);
        empty : in std_logic
    );
end entity accumulator;

architecture behavioral of accumulator is
    -------------------------------------------------------------------
    -- 7-Segment Display Lookup Table
    -------------------------------------------------------------------
    type MY_MEM is array (0 to 15) of std_logic_vector(7 downto 0);
    constant LUT : MY_MEM := (
        X"C0", -- 0
        X"F9", -- 1
        X"A4", -- 2
        X"B0", -- 3
        X"99", -- 4
        X"92", -- 5
        X"82", -- 6
        X"F8", -- 7
        X"80", -- 8
        X"98", -- 9
        X"88", -- A
        X"83", -- B
        X"C6", -- C
        X"A1", -- D
        X"86", -- E
        X"8E"  -- F
    );

    -------------------------------------------------------------------
    -- FSM state encodings
    -------------------------------------------------------------------
    -- clk5 write-domain FSM
    type state_type1 is (IDLE1, WAIT_RELEASE, PUSH_FIFO);
    signal current_state1, next_state1 : state_type1;

    -- clk12 read-domain FSM
    type state_type2 is (WAIT_BURST, POP_STREAM);
    signal current_state2, next_state2 : state_type2;

    -------------------------------------------------------------------
    -- Internal registers / signals
    -------------------------------------------------------------------
    -- debouncer counter in clk5 domain
    signal holdtime : integer range 0 to 50000 := 0;

    -- read side bookkeeping
    signal count          : unsigned(2 downto 0) := (others => '0'); -- how many left to consume this burst
    signal accumulator_reg: unsigned(23 downto 0) := (others => '0'); -- running sum
    signal total_reg      : unsigned(23 downto 0) := (others => '0'); -- latched value shown on HEX

    -- rdreq pipeline helper
    signal read_enable_int : std_logic := '0';  -- internal rdreq
    signal wait_valid      : std_logic := '0';  -- delayed "data_out is valid now"

    -- HEX display nibbles
    signal nib0, nib1, nib2, nib3, nib4, nib5 : std_logic_vector(3 downto 0);

begin
    -------------------------------------------------------------------
    -- LED outputs mirror switches
    -------------------------------------------------------------------
    led <= sw;

    -------------------------------------------------------------------
    -- ================= clk5 DOMAIN (WRITE SIDE) =================
    -- Debounce, wait for release, push one word into FIFO
    -------------------------------------------------------------------
    process(clk5)
    begin
        if rising_edge(clk5) then
            if rst_l = '0' then
                current_state1 <= IDLE1;
                holdtime       <= 0;
                write_enable   <= '0';
                data_in        <= (others => '0');
            else
                -- advance state
                current_state1 <= next_state1;

                -- default each clk5
                write_enable <= '0';

                -- debounce timing / holdtime
                if (current_state1 = WAIT_RELEASE) and (next_state1 = WAIT_RELEASE) then
                    -- still waiting in WAIT_RELEASE
                    if (add_btn = '1') and (holdtime < 5000) then
                        holdtime <= holdtime + 1;
                    else
                        -- either button still low or we've hit 5000; holdtime stays as-is
                        holdtime <= holdtime;
                    end if;
                else
                    -- leaving WAIT_RELEASE or not in it
                    holdtime <= 0;
                end if;

                -- PUSH_FIFO: generate 1-cycle write pulse and capture switches
                if current_state1 = PUSH_FIFO then
                    write_enable <= '1';
                    data_in      <= unsigned(sw);
                end if;
            end if;
        end if;
    end process;

    -- next-state logic for clk5 FSM
    process(current_state1, add_btn, holdtime, full)
    begin
        next_state1 <= current_state1;

        case current_state1 is
            when IDLE1 =>
                if add_btn = '0' then        -- button pressed (active low)
                    next_state1 <= WAIT_RELEASE;
                else
                    next_state1 <= IDLE1;
                end if;

            when WAIT_RELEASE =>
                if (add_btn = '0') or (holdtime < 5000) then
                    -- still holding or not debounced long enough
                    next_state1 <= WAIT_RELEASE;
                elsif (add_btn = '1') and (holdtime >= 5000) and (full = '0') then
                    -- good release, fifo not full -> push
                    next_state1 <= PUSH_FIFO;
                else
                    -- either released but fifo full, or weird edge
                    next_state1 <= IDLE1;
                end if;

            when PUSH_FIFO =>
                -- 1-cycle strobe, then go chill
                next_state1 <= IDLE1;

            when others =>
                next_state1 <= IDLE1;
        end case;
    end process;


    -------------------------------------------------------------------
    -- ================= clk12 DOMAIN (READ SIDE) =================
    -------------------------------------------------------------------
    process(clk12)
        variable data_ext : unsigned(23 downto 0);
        variable depth    : unsigned(2 downto 0);
        variable will_finish_now : std_logic;
    begin
        if rising_edge(clk12) then
            if rst_l = '0' then
                current_state2   <= WAIT_BURST;
                read_enable_int  <= '0';
                wait_valid       <= '0';
                count            <= (others => '0');
                accumulator_reg  <= (others => '0');
                total_reg        <= (others => '0');
            else
                --------------------------------------------------------
                -- advance state
                --------------------------------------------------------
                current_state2 <= next_state2;

                --------------------------------------------------------
                -- defaults each cycle
                --------------------------------------------------------
                read_enable_int <= '0';

                -- sample fifo depth (safe in read clock domain)
                depth := unsigned(rdusedw);

                --------------------------------------------------------
                -- WAIT_BURST state
                --------------------------------------------------------
                if current_state2 = WAIT_BURST then
                    -- not actively reading
                    read_enable_int <= '0';

                    -- if we're about to leave WAIT_BURST -> POP_STREAM,
                    -- preload count with 5
                    if next_state2 = POP_STREAM then
                        count <= to_unsigned(5,3);
                        -- we are doing running accumulation, so we KEEP accumulator_reg
                        -- (if you wanted per-burst sum instead, you'd clear it here)
                    end if;
                end if;

                --------------------------------------------------------
                -- POP_STREAM state
                --------------------------------------------------------
                if current_state2 = POP_STREAM then
                    -- Figure out if this cycle will consume the LAST word
                    -- We "finish now" if: (a) FIFO has presented valid data this cycle
                    -- AND (b) that data is the last remaining one (count = 1 before decrement)
                    will_finish_now := '0';
                    if (wait_valid = '1') and (count = to_unsigned(1,3)) then
                        will_finish_now := '1';
                    end if;

                    -- Consume valid data_out from LAST cycle's read request
                    if wait_valid = '1' then
                        data_ext := resize(data_out, 24); -- widen 10->24
                        accumulator_reg <= accumulator_reg + data_ext;

                        -- decrement remaining count
                        count <= count - 1;
                    end if;

                    -- If we're NOT finishing this burst yet,
                    -- keep asking for more data. This is the key fix.
                    if will_finish_now = '0' then
                        read_enable_int <= '1';  -- request next word
                    else
                        read_enable_int <= '0';  -- DO NOT request another word,
                                                  -- prevents "extra" read leaking into next burst
                        total_reg <= accumulator_reg + resize(data_out,24);
                        -- note: we used accumulator_reg + data_ext above,
                        -- but data_ext is only valid when wait_valid='1'.
                        -- In the will_finish_now='1' branch, wait_valid='1', so this matches.
                    end if;
                end if;

                --------------------------------------------------------
                -- pipeline wait_valid for next cycle
                -- wait_valid='1' means "data_out right now is from last cycle's rdreq"
                --------------------------------------------------------
                wait_valid <= read_enable_int;
            end if;
        end if;
    end process;


    -------------------------------------------------------------------
    -- next-state logic for clk12 FSM
    -------------------------------------------------------------------
    process(current_state2, rdusedw, count, wait_valid)
        variable depth : unsigned(2 downto 0);
    begin
        depth := unsigned(rdusedw);
        next_state2 <= current_state2;

        case current_state2 is

            when WAIT_BURST =>
                if depth >= to_unsigned(5,3) then
                    next_state2 <= POP_STREAM;
                else
                    next_state2 <= WAIT_BURST;
                end if;

            when POP_STREAM =>
                -- We leave POP_STREAM after we've just consumed the last word.
                -- That's exactly when wait_valid='1' (meaning we consumed something this cycle)
                -- AND count = 1 (meaning that "something" was the last remaining one).
                if (wait_valid = '1') and (count = to_unsigned(1,3)) then
                    next_state2 <= WAIT_BURST;
                else
                    next_state2 <= POP_STREAM;
                end if;

            when others =>
                next_state2 <= WAIT_BURST;
        end case;
    end process;

    -------------------------------------------------------------------
    -- drive entity output
    -------------------------------------------------------------------
    read_enable <= read_enable_int;


    -------------------------------------------------------------------
    -- Drive HEX displays from total_reg (24 bits hex across 6 digits)
    -------------------------------------------------------------------
    nib0 <= std_logic_vector(total_reg(3  downto 0));
    nib1 <= std_logic_vector(total_reg(7  downto 4));
    nib2 <= std_logic_vector(total_reg(11 downto 8));
    nib3 <= std_logic_vector(total_reg(15 downto 12));
    nib4 <= std_logic_vector(total_reg(19 downto 16));
    nib5 <= std_logic_vector(total_reg(23 downto 20));

    HEX0 <= LUT(to_integer(unsigned(nib0)));
    HEX1 <= LUT(to_integer(unsigned(nib1)));
    HEX2 <= LUT(to_integer(unsigned(nib2)));
    HEX3 <= LUT(to_integer(unsigned(nib3)));
    HEX4 <= LUT(to_integer(unsigned(nib4)));
    HEX5 <= LUT(to_integer(unsigned(nib5)));

end architecture behavioral;
