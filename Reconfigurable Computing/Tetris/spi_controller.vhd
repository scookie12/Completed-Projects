library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spi_param.all;

entity spi_controller is
    port (
        -- Host side
        iRSTN        : in    std_logic;  -- active-low reset
        iSPI_CLK     : in    std_logic;
        iSPI_CLK_OUT : in    std_logic;
        iP2S_DATA    : in    std_logic_vector(SI_DataL downto 0);
        iSPI_GO      : in    std_logic;
        oSPI_END     : out   std_logic;
        oS2P_DATA    : out   std_logic_vector(SO_DataL downto 0);

        -- SPI side
        SPI_SDIO     : inout std_logic;
        oSPI_CSN     : out   std_logic;
        oSPI_CLK     : out   std_logic
    );
end entity spi_controller;

architecture rtl of spi_controller is

    signal read_mode     : std_logic;
    signal write_address : std_logic;
    signal spi_count_en  : std_logic := '0';
    signal spi_count     : unsigned(3 downto 0) := (others => '1');  -- 4'hF
    signal s2p_reg       : std_logic_vector(SO_DataL downto 0) := (others => '0');
    signal spi_end_i     : std_logic;

begin
    ----------------------------------------------------------------
    -- Combinational logic
    ----------------------------------------------------------------
    read_mode     <= iP2S_DATA(SI_DataL);           -- MSB
    write_address <= std_logic(spi_count(3));       -- high nibble vs low nibble

    spi_end_i <= '1' when spi_count = "0000" else '0';
    oSPI_END  <= spi_end_i;

    oSPI_CSN <= not iSPI_GO;
    oSPI_CLK <= iSPI_CLK_OUT when spi_count_en = '1' else '1';

    SPI_SDIO <= iP2S_DATA(to_integer(spi_count))
                when (spi_count_en = '1') and
                     ((read_mode = '0') or (write_address = '1'))
                else 'Z';

    oS2P_DATA <= s2p_reg;

    ----------------------------------------------------------------
    -- Sequential logic
    ----------------------------------------------------------------
    process(iSPI_CLK, iRSTN)
    begin
        if iRSTN = '0' then
            spi_count_en <= '0';
            spi_count    <= (others => '1');
            s2p_reg      <= (others => '0');
        elsif rising_edge(iSPI_CLK) then

            -- enable/disable counter
            if spi_end_i = '1' then
                spi_count_en <= '0';
            elsif iSPI_GO = '1' then
                spi_count_en <= '1';
            end if;

            -- spi_count
            if spi_count_en = '0' then
                spi_count <= (others => '1');       -- 4'hF
            else
                spi_count <= spi_count - 1;
            end if;

            -- readback shift register (only during read, low nibble)
            if (read_mode = '1') and (write_address = '0') then
                s2p_reg <= s2p_reg(SO_DataL-1 downto 0) & SPI_SDIO;
            end if;
        end if;
    end process;

end architecture rtl;
