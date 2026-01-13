library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ScoreToDigits is
    port (
        score_in : in  unsigned(19 downto 0);  -- 0..999999
        d5       : out unsigned(3 downto 0);   -- hundred-thousands
        d4       : out unsigned(3 downto 0);   -- ten-thousands
        d3       : out unsigned(3 downto 0);   -- thousands
        d2       : out unsigned(3 downto 0);   -- hundreds
        d1       : out unsigned(3 downto 0);   -- tens
        d0       : out unsigned(3 downto 0)    -- ones
    );
end entity ScoreToDigits;

architecture rtl of ScoreToDigits is
    -- decimal place constants as unsigned(19 downto 0)
    constant C100000 : unsigned(19 downto 0) := to_unsigned(100000, 20);
    constant C10000  : unsigned(19 downto 0) := to_unsigned(10000,  20);
    constant C1000   : unsigned(19 downto 0) := to_unsigned(1000,   20);
    constant C100    : unsigned(19 downto 0) := to_unsigned(100,    20);
    constant C10     : unsigned(19 downto 0) := to_unsigned(10,     20);
    constant C1      : unsigned(19 downto 0) := to_unsigned(1,      20);
begin

    -- Pure combinational: split score_in into 6 decimal digits
    process(score_in)
        variable remain  : unsigned(19 downto 0);
        variable v_d5 : unsigned(3 downto 0);
        variable v_d4 : unsigned(3 downto 0);
        variable v_d3 : unsigned(3 downto 0);
        variable v_d2 : unsigned(3 downto 0);
        variable v_d1 : unsigned(3 downto 0);
        variable v_d0 : unsigned(3 downto 0);
    begin
        -- start with full score as remainainder
        remain  := score_in;

        -- default all digits to 0
        v_d5 := (others => '0');
        v_d4 := (others => '0');
        v_d3 := (others => '0');
        v_d2 := (others => '0');
        v_d1 := (others => '0');
        v_d0 := (others => '0');

        --------------------------------------------------------------------
        -- Digit 5: hundred-thousands place (0..9)
        --------------------------------------------------------------------
        for i in 0 to 9 loop
            if remain >= C100000 then
                remain  := remain - C100000;
                v_d5 := v_d5 + 1;
            end if;
        end loop;

        --------------------------------------------------------------------
        -- Digit 4: ten-thousands place (0..9)
        --------------------------------------------------------------------
        for i in 0 to 9 loop
            if remain >= C10000 then
                remain  := remain - C10000;
                v_d4 := v_d4 + 1;
            end if;
        end loop;

        --------------------------------------------------------------------
        -- Digit 3: thousands place (0..9)
        --------------------------------------------------------------------
        for i in 0 to 9 loop
            if remain >= C1000 then
                remain  := remain - C1000;
                v_d3 := v_d3 + 1;
            end if;
        end loop;

        --------------------------------------------------------------------
        -- Digit 2: hundreds place (0..9)
        --------------------------------------------------------------------
        for i in 0 to 9 loop
            if remain >= C100 then
                remain  := remain - C100;
                v_d2 := v_d2 + 1;
            end if;
        end loop;

        --------------------------------------------------------------------
        -- Digit 1: tens place (0..9)
        --------------------------------------------------------------------
        for i in 0 to 9 loop
            if remain >= C10 then
                remain  := remain - C10;
                v_d1 := v_d1 + 1;
            end if;
        end loop;

        --------------------------------------------------------------------
        -- Digit 0: ones place (whatever is left, 0..9)
        --------------------------------------------------------------------
        for i in 0 to 9 loop
            if remain >= C1 then
                remain  := remain - C1;
                v_d0 := v_d0 + 1;
            end if;
        end loop;

        -- drive outputs
        d5 <= v_d5;
        d4 <= v_d4;
        d3 <= v_d3;
        d2 <= v_d2;
        d1 <= v_d1;
        d0 <= v_d0;
    end process;

end architecture rtl;
