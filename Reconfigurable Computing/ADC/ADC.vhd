library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADC is 
    port (
        sys_clk              : in std_logic;
        pll_clk              : in std_logic;
        locked               : in std_logic; 
        HEX0, HEX1, HEX2     : out std_logic_vector(7 downto 0);
        rst_l                : in std_logic
    );

end entity ADC;

architecture behavioral of ADC is
     
    signal adc_valid        : std_logic;
    signal adc_data         : std_logic_vector (11 downto 0);
    signal nib0, nib1, nib2 : std_logic_vector (3 downto 0);
    signal count            : integer range 0 to 15000000;

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

    component my_ADC is
        port (
            adc_pll_clock_clk      : in  std_logic;                               --  adc_pll_clock.clk
            adc_pll_locked_export  : in  std_logic;                               -- adc_pll_locked.export
            clock_clk              : in  std_logic;                               --          clock.clk
            command_valid          : in  std_logic;                               --        command.valid
            command_channel        : in  std_logic_vector(4 downto 0) ;           --               .channel
            command_startofpacket  : in  std_logic;                               --               .startofpacket
            command_endofpacket    : in  std_logic;                               --               .endofpacket
            command_ready          : out std_logic;                               --               .ready
            reset_sink_reset_n     : in  std_logic;                               --     reset_sink.reset_n
            response_valid         : out std_logic;                               --       response.valid
            response_channel       : out std_logic_vector(4 downto 0);            --               .channel
            response_data          : out std_logic_vector(11 downto 0);           --               .data
            response_startofpacket : out std_logic;                               --               .startofpacket
            response_endofpacket   : out std_logic            
        );
    end component;

    


begin

    u0 : my_ADC 
        port map(
            adc_pll_clock_clk       =>     pll_clk,         --  adc_pll_clock.clk
            adc_pll_locked_export   =>     locked,          --  adc_pll_locked.export
            clock_clk               =>     sys_clk,         --  clock.clk
            command_valid           =>     '1',             --  command.valid
            command_channel         =>     "00001",         --  .channel
            command_startofpacket   =>     '1',             --  .startofpacket
            command_endofpacket     =>     '1',             --  .endofpacket
            command_ready           =>     open,            --  .ready
            reset_sink_reset_n      =>     rst_l,           --  reset_sink.reset_n
            response_valid          =>     adc_valid,       --  response.valid
            response_channel        =>     open,            --  .channel
            response_data           =>     adc_data,        --  .data
            response_startofpacket  =>     open,            --  .startofpacket
            response_endofpacket    =>     open
        );



    process (sys_clk)

    begin
        if rising_edge(sys_clk) then
            if rst_l ='0' then
                count <=0;
                nib0 <= (others => '0');
                nib1 <= (others => '0');
                nib2 <= (others => '0');
            else      
                if count =  integer(100000) then
                    if adc_valid = '1' then
                        nib0 <= adc_data(3 downto 0);
                        nib1 <= adc_data(7 downto 4);
                        nib2 <= adc_data(11 downto 8);
                    end if;
                    count <=0;
                else 
                    count <= count + 1;
                end if;
            end if;
        end if;
        

    end process;

    HEX0 <= LUT(to_integer(unsigned(nib0)));
    HEX1 <= LUT(to_integer(unsigned(nib1)));
    HEX2 <= LUT(to_integer(unsigned(nib2)));


end architecture;
