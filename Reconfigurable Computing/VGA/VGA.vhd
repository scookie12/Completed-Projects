library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is 
  port(
    clk        : in  std_logic;
    rst_l      : in  std_logic;
    but_press  : in  std_logic;          -- debounced externally
    Hsync      : out std_logic; 
    Vsync      : out std_logic;
    Red_out    : out unsigned(3 downto 0);
    Blue_out   : out unsigned(3 downto 0);
    Green_out  : out unsigned(3 downto 0)
  );
end entity VGA;

architecture behavioral of VGA is
  -- ========== 640x480@60 timing window inside 800x525 ==========
  constant H_FP_END    : unsigned(9 downto 0) := to_unsigned( 15,10);  --  16 (0..15)
  constant H_SYNC_END  : unsigned(9 downto 0) := to_unsigned(111,10);  --  96
  constant H_BP_END    : unsigned(9 downto 0) := to_unsigned(159,10);  --  48
  constant H_LINE_END  : unsigned(9 downto 0) := to_unsigned(799,10);  -- 640 (159..799)

  constant V_FP_END    : unsigned(9 downto 0) := to_unsigned(  9,10);  -- 10 (0..9)
  constant V_SYNC_BEG  : unsigned(9 downto 0) := to_unsigned( 10,10);  -- 10..11 low
  constant V_SYNC_END  : unsigned(9 downto 0) := to_unsigned( 11,10);
  constant V_ACTIVE_BEG: unsigned(9 downto 0) := to_unsigned( 46,10);  -- 46..524 visible
  constant V_FRAME_END : unsigned(9 downto 0) := to_unsigned(524,10);

  -- ========== State/counters ==========
  type state_type is (FRONT_PORCH, H_SYNC, BACK_PORCH, PIXEL_DATA);
  signal current_state, next_state : state_type;

  signal pixel_count : unsigned(9 downto 0) := (others => '0'); -- 0..799
  signal v_count     : unsigned(9 downto 0) := (others => '0'); -- 0..524

  -- Flags: user-visible 1..12 (wraps to 1). Internal fi = Flags-1 (0..11)
  signal Flags       : unsigned(3 downto 0) := to_unsigned(1,4);

  -- RGB (4-bit each) — registered
  signal Red,   Green,   Blue   : unsigned(3 downto 0) := (others => '0');
  -- next values (combinational)
  signal Red_n, Green_n, Blue_n : unsigned(3 downto 0) := (others => '0');

  -- ===== 4-bit color nibbles
  constant N0 : unsigned(3 downto 0) := to_unsigned( 0,4);
  constant N8 : unsigned(3 downto 0) := to_unsigned( 8,4);
  constant NA : unsigned(3 downto 0) := to_unsigned(10,4);
  constant NF : unsigned(3 downto 0) := to_unsigned(15,4);

  -- 12-bit colors R[11:8] & G[7:4] & B[3:0]
  constant COL_BLACK  : unsigned(11 downto 0) := N0 & N0 & N0;
  constant COL_WHITE  : unsigned(11 downto 0) := NF & NF & NF;
  constant COL_RED    : unsigned(11 downto 0) := NF & N0 & N0;
  constant COL_GREEN  : unsigned(11 downto 0) := N0 & NF & N0;
  constant COL_BLUE   : unsigned(11 downto 0) := N0 & N0 & NF;
  constant COL_YELLOW : unsigned(11 downto 0) := NF & NF & N0;
  constant COL_ORANGE : unsigned(11 downto 0) := NF & NA & N0;
  constant COL_NAVY   : unsigned(11 downto 0) := N0 & N0 & N8;

  -- button edge-detect (debounced externally)
  signal but_prev : std_logic := '0';

  signal green_count : integer := 685;
  signal yellow_count : integer := 845;

  -- helper
  function in_range(x, lo, hi : integer) return boolean is
  begin
    return (x >= lo) and (x <= hi);
  end function;

begin
  -- DACs (registered outputs)
  Red_out   <= Red;
  Green_out <= Green;
  Blue_out  <= Blue;

  -- Syncs
  Hsync <= '0' when current_state = H_SYNC else '1';
  Vsync <= '0' when (v_count >= V_SYNC_BEG and v_count <= V_SYNC_END) else '1';

  -- Next-state logic
  process(current_state, pixel_count)
  begin
    case current_state is
      when FRONT_PORCH =>
        if pixel_count = H_FP_END   then next_state <= H_SYNC;
        else                             next_state <= FRONT_PORCH; end if;
      when H_SYNC =>
        if pixel_count = H_SYNC_END then next_state <= BACK_PORCH;
        else                             next_state <= H_SYNC;      end if;
      when BACK_PORCH =>
        if pixel_count = H_BP_END   then next_state <= PIXEL_DATA;
        else                             next_state <= BACK_PORCH;  end if;
      when PIXEL_DATA =>
        if pixel_count = H_LINE_END then next_state <= FRONT_PORCH;
        else                             next_state <= PIXEL_DATA;  end if;
    end case;
  end process;

  -- Color logic (drive *_n only — single combinational driver)
  process (Flags, current_state, pixel_count, v_count)
    procedure set_rgb_n(col : unsigned(11 downto 0)) is
    begin
      Red_n   <= col(11 downto 8);
      Green_n <= col(7  downto 4);
      Blue_n  <= col(3  downto 0);
    end procedure;
    variable px, vy : integer;   -- absolute counters
    variable xa, ya : integer;   -- active-window coords (0..639, 0..479)
    variable d      : integer;   -- x - y for 45° stripe
    variable fi     : integer;   -- 0..11
  begin
    -- default background
    set_rgb_n(COL_BLACK);

    px  := to_integer(pixel_count);
    vy  := to_integer(v_count);
    fi  := to_integer(Flags) - 1;

    if current_state = PIXEL_DATA then
      -- global vertical blanking in pixel state
      if (vy <= 9) or (vy = 10) or (vy = 11) or (vy >= 525) then
        set_rgb_n(COL_BLACK);
      else
        case fi is
          -- fi=0  (Flag 1): 159..372 Blue, 373..586 White, 587..799 Red
          when 0 =>
            if    in_range(px,159,372) then set_rgb_n(COL_BLUE);
            elsif in_range(px,373,586) then set_rgb_n(COL_WHITE);
            elsif in_range(px,587,799) then set_rgb_n(COL_RED);
            else                           set_rgb_n(COL_BLACK);
            end if;

          -- fi=1  (Flag 2)
          when 1 =>
            if    in_range(px,159,372) then set_rgb_n(COL_GREEN);
            elsif in_range(px,373,586) then set_rgb_n(COL_WHITE);
            elsif in_range(px,587,799) then set_rgb_n(COL_RED);
            else                           set_rgb_n(COL_BLACK);
            end if;

          -- fi=2  (Flag 3)
          when 2 =>
            if    in_range(px,159,372) then set_rgb_n(COL_GREEN);
            elsif in_range(px,373,586) then set_rgb_n(COL_WHITE);
            elsif in_range(px,587,799) then set_rgb_n(COL_ORANGE);
            else                           set_rgb_n(COL_BLACK);
            end if;

          -- fi=3  (Flag 4)
          when 3 =>
            if    in_range(px,159,372) then set_rgb_n(COL_BLACK);
            elsif in_range(px,373,586) then set_rgb_n(COL_YELLOW);
            elsif in_range(px,587,799) then set_rgb_n(COL_RED);
            else                           set_rgb_n(COL_BLACK);
            end if;

          -- fi=4  (Flag 5)
          when 4 =>
            if    in_range(px,159,372) then set_rgb_n(COL_GREEN);
            elsif in_range(px,373,586) then set_rgb_n(COL_YELLOW);
            elsif in_range(px,587,799) then set_rgb_n(COL_RED);
            else                           set_rgb_n(COL_BLACK);
            end if;

          -- fi=5  (Flag 6)
          when 5 =>
            if    in_range(px,159,372) then set_rgb_n(COL_NAVY);
            elsif in_range(px,373,586) then set_rgb_n(COL_YELLOW);
            elsif in_range(px,587,799) then set_rgb_n(COL_RED);
            else                           set_rgb_n(COL_BLACK);
            end if;

          -- fi=6  (Flag 7)
          when 6 =>
            if    in_range(px,159,372) then set_rgb_n(COL_GREEN);
            elsif in_range(px,373,586) then set_rgb_n(COL_WHITE);
            elsif in_range(px,587,799) then set_rgb_n(COL_GREEN);
            else                           set_rgb_n(COL_BLACK);
            end if;

          -- fi=7  (Flag 8)
          when 7 =>
            if    in_range(px,159,372) then set_rgb_n(COL_ORANGE);
            elsif in_range(px,373,586) then set_rgb_n(COL_WHITE);
            elsif in_range(px,587,799) then set_rgb_n(COL_GREEN);
            else                           set_rgb_n(COL_BLACK);
            end if;

          -- fi=8  (Flag 9): horizontal bands
          when 8 =>
            if    in_range(vy,46,285) then set_rgb_n(COL_WHITE);
            elsif in_range(vy,286,524) then set_rgb_n(COL_RED);
            else                          set_rgb_n(COL_BLACK);
            end if;

          -- fi=9  (Flag 10)
          when 9 =>
            if    in_range(vy,46,204)  then set_rgb_n(COL_BLACK);
            elsif in_range(vy,205,364) then set_rgb_n(COL_RED);
            elsif in_range(vy,365,524) then set_rgb_n(COL_YELLOW);
            else                          set_rgb_n(COL_BLACK);
            end if;

          -- fi=10 (Flag 11)
          when 10 =>
            if    in_range(vy,46,204)  then set_rgb_n(COL_RED);
            elsif in_range(vy,205,364) then set_rgb_n(COL_WHITE);
            elsif in_range(vy,365,524) then set_rgb_n(COL_RED);
            else                          set_rgb_n(COL_BLACK);
            end if;

          -- fi=11 (Flag 12): Republic of the Congo (diagonal stripe)
          when 11 =>

            if pixel_count < green_count then set_rgb_n(COL_GREEN);
            elsif pixel_count < yellow_count then set_rgb_n(COL_YELLOW);
            else set_rgb_n(COL_RED);
            end if;

          when others =>
            set_rgb_n(COL_BLACK);
        end case;
      end if;
    end if;
  end process;

  -- Sequential: counters, state, button, and register RGB
  process (clk)
  begin
    if rising_edge(clk) then
      if rst_l = '0' then
        current_state <= FRONT_PORCH;
        pixel_count   <= (others => '0');
        v_count       <= (others => '0');
        Flags         <= to_unsigned(0,4);  -- start at Flag 1
        but_prev      <= '0';
        Red           <= (others => '0');
        Green         <= (others => '0');
        Blue          <= (others => '0');
      else
        -- state advance
        current_state <= next_state;

        -- pixel counter 0..799
        if (current_state = PIXEL_DATA) and (pixel_count = H_LINE_END) then
          pixel_count <= (others => '0');
        else
          pixel_count <= pixel_count + 1;
        end if;

        -- v_count 0..524 (advance at end of each line)
        if (current_state = PIXEL_DATA) and (pixel_count = H_LINE_END) then
          if v_count = V_FRAME_END then
            v_count <= (others => '0');
            green_count <= 685;
            yellow_count <= 845;
          else
            v_count <= v_count + 1;
            green_count <= green_count -1;
            yellow_count <= yellow_count -1;
          end if;
        end if;

        -- button: cycle 1..12 -> 1
        if (but_prev = '0') and (but_press = '1') then
          if to_integer(Flags) = 12 then
            Flags <= to_unsigned(1,4);
          else
            Flags <= to_unsigned(to_integer(Flags)+1, Flags'length);
          end if;
        end if;
        but_prev <= but_press;

        -- register the combinational next values (single driver for RGB)
        Red   <= Red_n;
        Green <= Green_n;
        Blue  <= Blue_n;
      end if;
    end if;
  end process;

end architecture;
