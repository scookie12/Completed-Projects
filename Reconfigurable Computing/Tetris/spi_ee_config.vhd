library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spi_param.all;

entity spi_ee_config is
    port (
        -- Host side
        iRSTN        : in    std_logic;  -- active low reset
        iSPI_CLK     : in    std_logic;
        iSPI_CLK_OUT : in    std_logic;
        iG_INT2      : in    std_logic;  -- unused in this simplified version

        oDATA_L      : out   std_logic_vector(SO_DataL downto 0);
        oDATA_H      : out   std_logic_vector(SO_DataL downto 0);

        -- SPI side
        SPI_SDIO     : inout std_logic;
        oSPI_CSN     : out   std_logic;
        oSPI_CLK     : out   std_logic;

        -- debug to LEDs
        dbg_ini_index : out std_logic_vector(3 downto 0);
        dbg_spi_go    : out std_logic;
        dbg_spi_state : out std_logic
    );
end entity spi_ee_config;

architecture rtl of spi_ee_config is

    ----------------------------------------------------------------
    -- Types / signals
    ----------------------------------------------------------------
    type state_type is (
        ST_RESET,
        ST_INIT_LOAD,
        ST_INIT_GO,
        ST_INIT_WAIT,
        ST_READ_LB_LOAD,
        ST_READ_LB_GO,
        ST_READ_LB_WAIT,
        ST_READ_HB_LOAD,
        ST_READ_HB_GO,
        ST_READ_HB_WAIT
    );

    signal state      : state_type := ST_RESET;

    signal ini_index  : integer range 0 to 15 := 0;

    signal p2s_data   : std_logic_vector(SI_DataL downto 0) := (others => '0');
    signal spi_go     : std_logic := '0';
    signal spi_end    : std_logic;
    signal s2p_data   : std_logic_vector(SO_DataL downto 0);

    signal dataL_reg  : std_logic_vector(SO_DataL downto 0) := (others => '0');
    signal dataH_reg  : std_logic_vector(SO_DataL downto 0) := (others => '0');

    -- init write_data (2+6+8 = 16 bits total)
    -- addr[5:0] & data[7:0]
    signal write_data : std_logic_vector(SI_DataL-2 downto 0);

begin

    ----------------------------------------------------------------
    -- Instantiate spi_controller
    ----------------------------------------------------------------
    u_spi_controller : entity work.spi_controller
        port map (
            iRSTN        => iRSTN,
            iSPI_CLK     => iSPI_CLK,
            iSPI_CLK_OUT => iSPI_CLK_OUT,
            iP2S_DATA    => p2s_data,
            iSPI_GO      => spi_go,
            oSPI_END     => spi_end,
            oS2P_DATA    => s2p_data,
            SPI_SDIO     => SPI_SDIO,
            oSPI_CSN     => oSPI_CSN,
            oSPI_CLK     => oSPI_CLK
        );

    -- Drive outputs
    oDATA_L <= dataL_reg;
    oDATA_H <= dataH_reg;

    dbg_ini_index <= std_logic_vector(to_unsigned(ini_index, 4));
    dbg_spi_go    <= spi_go;
    -- simple encoding: 1 when actively shifting
    dbg_spi_state <= '1' when (state = ST_INIT_GO or
                               state = ST_INIT_WAIT or
                               state = ST_READ_LB_GO or
                               state = ST_READ_LB_WAIT or
                               state = ST_READ_HB_GO or
                               state = ST_READ_HB_WAIT)
                     else '0';

    ----------------------------------------------------------------
    -- Init table (combinational)
    ----------------------------------------------------------------
    process(ini_index)
    begin
        case ini_index is
            when 0  => write_data <= THRESH_ACT    & x"20";
            when 1  => write_data <= THRESH_INACT  & x"03";
            when 2  => write_data <= TIME_INACT    & x"01";
            when 3  => write_data <= ACT_INACT_CTL & x"7F";
            when 4  => write_data <= THRESH_FF     & x"09";
            when 5  => write_data <= TIME_FF       & x"46";
            when 6  => write_data <= BW_RATE       & x"09"; -- 50 Hz
            when 7  => write_data <= INT_ENABLE    & x"10";
            when 8  => write_data <= INT_MAP       & x"10";
            when 9  => write_data <= DATA_FORMAT   & x"40";
            when others =>
                write_data <= POWER_CONTROL & x"08";
        end case;
    end process;

    ----------------------------------------------------------------
    -- Main FSM
    ----------------------------------------------------------------
    process(iSPI_CLK, iRSTN)
    begin
        if iRSTN = '0' then
            state     <= ST_RESET;
            ini_index <= 0;
            spi_go    <= '0';
            p2s_data  <= (others => '0');
            dataL_reg <= (others => '0');
            dataH_reg <= (others => '0');
        elsif rising_edge(iSPI_CLK) then

            case state is

                ----------------------------------------------------
                -- Reset / go to first init write
                ----------------------------------------------------
                when ST_RESET =>
                    ini_index <= 0;
                    spi_go    <= '0';
                    state     <= ST_INIT_LOAD;

                ----------------------------------------------------
                -- INIT: load next write
                ----------------------------------------------------
                when ST_INIT_LOAD =>
                    if ini_index < INI_NUMBER then
                        -- p2s_data = {SPI_WRITE_MODE, addr[5:0], data[7:0]}
                        p2s_data <= SPI_WRITE_MODE & write_data;
                        spi_go   <= '1';
                        state    <= ST_INIT_GO;
                    else
                        -- all init writes done, move to read loop
                        state <= ST_READ_LB_LOAD;
                    end if;

                ----------------------------------------------------
                -- INIT: assert GO until spi_end
                ----------------------------------------------------
                when ST_INIT_GO =>
                    if spi_end = '1' then
                        spi_go    <= '0';
                        ini_index <= ini_index + 1;
                        state     <= ST_INIT_LOAD;
                    end if;

                ----------------------------------------------------
                -- READ LOOP: read X_LB (low byte)
                ----------------------------------------------------
                when ST_READ_LB_LOAD =>
                    -- command: READ + X_LB + dummy data
                    p2s_data <= SPI_READ_MODE & X_LB & x"00";
                    spi_go   <= '1';
                    state    <= ST_READ_LB_GO;

                when ST_READ_LB_GO =>
                    if spi_end = '1' then
                        spi_go <= '0';

                        -- Only keep the real data byte (last 8 bits shifted in)
                        dataL_reg(7 downto 0)        <= s2p_data(7 downto 0);
                        dataL_reg(SO_DataL downto 8) <= (others => '0');

                        state  <= ST_READ_HB_LOAD;
                    end if;

                ----------------------------------------------------
                -- READ LOOP: read X_HB (high byte)
                ----------------------------------------------------
                when ST_READ_HB_LOAD =>
                    p2s_data <= SPI_READ_MODE & X_HB & x"00";
                    spi_go   <= '1';
                    state    <= ST_READ_HB_GO;

                when ST_READ_HB_GO =>
                    if spi_end = '1' then
                        spi_go <= '0';

                        -- Only keep the real data byte (last 8 bits shifted in)
                        dataH_reg(7 downto 0)        <= s2p_data(7 downto 0);
                        dataH_reg(SO_DataL downto 8) <= (others => '0');

                        -- go back to low-byte read
                        state  <= ST_READ_LB_LOAD;
                    end if;

                when others =>
                    state <= ST_RESET;
            end case;

        end if;
    end process;

end architecture rtl;
