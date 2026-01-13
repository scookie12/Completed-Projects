library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_delay is
    port (
        iRSTN : in  std_logic;  -- active-low reset
        iCLK  : in  std_logic;
        oRST  : out std_logic   -- goes high after delay
    );
end entity reset_delay;

architecture rtl of reset_delay is
    signal Cont : unsigned(19 downto 0) := (others => '0');
begin
    process(iCLK, iRSTN)
    begin
        if iRSTN = '0' then
            Cont <= (others => '0');
            oRST <= '0';
        elsif rising_edge(iCLK) then
            if Cont(19) = '0' then
                Cont <= Cont + 1;
                oRST <= '0';
            else
                oRST <= '1';
            end if;
        end if;
    end process;
end architecture rtl;
