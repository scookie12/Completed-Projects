library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--This is for a 50MHz clock input
entity Debouncer is
	port (
		clk: in std_logic;
		b_in: in std_logic;
		real_press : out std_logic
	);
	
architecture behavioral of Debouncer is 

type state_type is (IDLE, PRESSED);
signal current_state, next_state : state_type;


signal holdtime : integer range 0 to 500000;

begin

process (clk)


	if rising_edge(clk) then
		current_state <= next_state;
		if b_in = '0' then
			holdtime = holdtime+1;					
		else 
			holdtime = 0;
		end if;
	end if;
end process;
	
		
process (b_in, current_state, holdtime)
	begin 
		case current_state is 
			when IDLE
				holdtime = 0;
				if b_in = '0' then
					next_state <= PRESSED;
				else
					next_state <= IDLE;
				end if;
			
			when PRESSED
				if b_in = '0' then
						next_state <= PRESSED;
						if holdtime >= 50000 then
							real_pressed = '0';
						else
							real_pressed = '1';
						end if;
				else if b_in = '1'
						next_state <= IDLE;
						real_pressed = '1';
				end if;
			when others
end process;


end architecture behavioral;

		