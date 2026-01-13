library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accumulator is
    port (
        clk      : in std_logic;
        rst_l    : in std_logic;
        add_btn  : in std_logic;                  -- "Add" button
        sw       : in std_logic_vector(9 downto 0); -- 10-bit input
        led      : out std_logic_vector(9 downto 0); -- mirror switches
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0)
    );
end entity accumulator;

architecture behavioral of accumulator is

    -------------------------------------------------------------------
    -- 7-Segment Display Lookup Table (Your preferred LUT)
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
    -- FSM States
    -------------------------------------------------------------------
    type state_type is (IDLE, ADD, WAIT_RELEASE);
    signal current_state, next_state : state_type;

    -------------------------------------------------------------------
    -- Internal Signals
    -------------------------------------------------------------------
    signal accumulator_reg : std_logic_vector(23 downto 0);
    signal nib0, nib1, nib2, nib3, nib4, nib5 : std_logic_vector(3 downto 0);
	signal holdtime : integer range 0 to 100000000; --Make big, but debounce is like 1ms of button press

begin

    -------------------------------------------------------------------
    -- State Register
    -------------------------------------------------------------------
    process(clk)
	 variable sw_ext : unsigned(23 downto 0);  -- use a variable (new value same cycle)
    begin
        if rising_edge(clk) then
            if rst_l = '0' then
                current_state   <= IDLE;
                accumulator_reg <= (others => '0');
				holdtime <= 0;
            else
                current_state <= next_state;
				
				 -- holdtime update (registered)
                if current_state = WAIT_RELEASE and add_btn = '1' then
                    if holdtime < 100000000 then
                        holdtime <= holdtime + 1;
                    end if;
                else
                    holdtime <= 0;
                end if;
				
				if current_state = ADD then
                    -- zero-extend sw (10 -> 24 bits) then add
                    sw_ext := resize(unsigned(sw), 24); -- zero-extend 10->24
                    accumulator_reg <= std_logic_vector(unsigned(accumulator_reg) + sw_ext);
                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------
    -- Next State and Output Logic
    -------------------------------------------------------------------
    process(current_state, add_btn, holdtime)
    begin
        next_state <= current_state;

        case current_state is

            when IDLE =>
                if add_btn = '0' then               -- button pressed
                    next_state <= ADD;
                else
                    next_state <= IDLE;
                end if;

            when ADD =>
                -- Perform addition
				next_state <= WAIT_RELEASE;
            when WAIT_RELEASE =>
                if add_btn = '1' and holdtime >= 100000 then              -- button released
                    next_state <= IDLE;
                else
                    next_state <= WAIT_RELEASE;
                end if;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

    -------------------------------------------------------------------
    -- LED outputs mirror switches
    -------------------------------------------------------------------
    led <= sw;

    -------------------------------------------------------------------
    -- Display accumulator on six 7-segment displays
    -------------------------------------------------------------------
    nib0 <= accumulator_reg(3 downto 0);
    nib1 <= accumulator_reg(7 downto 4);
    nib2 <= accumulator_reg(11 downto 8);
    nib3 <= accumulator_reg(15 downto 12);
    nib4 <= accumulator_reg(19 downto 16);
    nib5 <= accumulator_reg(23 downto 20);

    HEX0 <= LUT(to_integer(unsigned(nib0)));
    HEX1 <= LUT(to_integer(unsigned(nib1)));
    HEX2 <= LUT(to_integer(unsigned(nib2)));
    HEX3 <= LUT(to_integer(unsigned(nib3)));
    HEX4 <= LUT(to_integer(unsigned(nib4)));
    HEX5 <= LUT(to_integer(unsigned(nib5)));

end architecture behavioral;
