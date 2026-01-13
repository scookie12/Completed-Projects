ibrary ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Debounce_TB is
end Debounce_TB;


architecture behavioral of Debounce_TB is

    component debouncer
        port(
            clk: in std_logic;
            b_in : in std_logic;
            real_press : out std_logic
        );

    end component; 

    constant CLK_PERIOD : time := 20 ns;


    begin

        uut : Debouncer
            port map (
                clk => clk,
                b_in => b_in,
                real_press => real_press
            );

        clk_process : process
        begin
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period/2;
        end process;
            

        stm_process : process
        begin
            b_in <= '1';
            wait for clk_period * 10;
            b_in <= '0';
            wait for clk_period * 50;
            b_in <= '1';
            wait for clk_period * 10;
            b_in <='0';
            wait for clk_period *50000;
            b_in <='1'
        end process;

end architecture behavioral;