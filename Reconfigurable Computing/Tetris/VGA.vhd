library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is 
  port(
    clk        : in  std_logic;
    rst_l      : in  std_logic;
    score      : in unsigned(19 downto 0);  -- 0..999999
    Column0    : in unsigned(41 downto 0);
    Column1    : in unsigned(41 downto 0);
    Column2    : in unsigned(41 downto 0);
    Column3    : in unsigned(41 downto 0);
    Column4    : in unsigned(41 downto 0);
    Column5    : in unsigned(41 downto 0);
    Column6    : in unsigned(41 downto 0);
    Column7    : in unsigned(41 downto 0);
    Column8    : in unsigned(41 downto 0);
    Hsync      : out std_logic; 
    Vsync      : out std_logic;
    Red_out    : out unsigned(3 downto 0);
    Blue_out   : out unsigned(3 downto 0);
    Green_out  : out unsigned(3 downto 0)
  );
end entity VGA;

architecture behavioral of VGA is

  component ScoreToDigits
    port(
        score_in : in  unsigned(19 downto 0);  -- 0..999999
        d5       : out unsigned(3 downto 0);   -- hundred-thousands
        d4       : out unsigned(3 downto 0);   -- ten-thousands
        d3       : out unsigned(3 downto 0);   -- thousands
        d2       : out unsigned(3 downto 0);   -- hundreds
        d1       : out unsigned(3 downto 0);   -- tens
        d0       : out unsigned(3 downto 0)    -- ones
    );
  end component;

  -- ========== 640x480@60 timing window inside 800x525 ==========
  constant H_FP_END    : unsigned(9 downto 0) := to_unsigned( 15,10);  --  16 (0..15)
  constant H_SYNC_END  : unsigned(9 downto 0) := to_unsigned(111,10);  --  96
  constant H_BP_END    : unsigned(9 downto 0) := to_unsigned(159,10);  --  48
  constant H_LINE_END  : unsigned(9 downto 0) := to_unsigned(799,10);  -- 640 (159..799)

  constant V_FP_END     : unsigned(9 downto 0) := to_unsigned(  9,10);  -- 10 (0..9)
  constant V_SYNC_BEG   : unsigned(9 downto 0) := to_unsigned( 10,10);  -- 10..11 low
  constant V_SYNC_END   : unsigned(9 downto 0) := to_unsigned( 11,10);
  constant V_ACTIVE_BEG : unsigned(9 downto 0) := to_unsigned( 46,10);  -- 46..524 visible
  constant V_FRAME_END  : unsigned(9 downto 0) := to_unsigned(524,10);

  -- ========== State/counters ==========
  type state_type is (FRONT_PORCH, H_SYNC, BACK_PORCH, PIXEL_DATA);
  signal current_state, next_state : state_type;

  signal pixel_count : unsigned(9 downto 0) := (others => '0'); -- 0..799
  signal v_count     : unsigned(9 downto 0) := (others => '0'); -- 0..524

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

  -- score digit layout (6 columns, but we’ll use 5..1 for now)
  constant DIGIT_WIDTH       : unsigned(9 downto 0) := to_unsigned(10,10);
  constant SCORE_COL_START5  : unsigned(9 downto 0) := to_unsigned(644,10);
  constant SCORE_COL_START4  : unsigned(9 downto 0) := to_unsigned(658,10);
  constant SCORE_COL_START3  : unsigned(9 downto 0) := to_unsigned(672,10);
  constant SCORE_COL_START2  : unsigned(9 downto 0) := to_unsigned(686,10);
  constant SCORE_COL_START1  : unsigned(9 downto 0) := to_unsigned(700,10);
  constant SCORE_COL_START0  : unsigned(9 downto 0) := to_unsigned(714,10);

  constant SCORE_ROW_1       : unsigned(9 downto 0) := to_unsigned(469,10);
  constant SCORE_ROW_2       : unsigned(9 downto 0) := to_unsigned(479,10);
  constant SCORE_ROW_3       : unsigned(9 downto 0) := to_unsigned(489,10);

  -- board columns (9 columns × 32 pixels = 288)
  constant COL_START_8       : unsigned(9 downto 0) := to_unsigned(336,10);
  constant COL_START_7       : unsigned(9 downto 0) := to_unsigned(368,10);
  constant COL_START_6       : unsigned(9 downto 0) := to_unsigned(400,10);
  constant COL_START_5       : unsigned(9 downto 0) := to_unsigned(432,10);
  constant COL_START_4       : unsigned(9 downto 0) := to_unsigned(464,10);
  constant COL_START_3       : unsigned(9 downto 0) := to_unsigned(496,10);
  constant COL_START_2       : unsigned(9 downto 0) := to_unsigned(528,10); -- fixed spacing
  constant COL_START_1       : unsigned(9 downto 0) := to_unsigned(560,10);
  constant COL_START_0       : unsigned(9 downto 0) := to_unsigned(592,10);

  signal d5  : unsigned(3 downto 0);
  signal d4  : unsigned(3 downto 0);
  signal d3  : unsigned(3 downto 0);
  signal d2  : unsigned(3 downto 0);
  signal d1  : unsigned(3 downto 0);
  signal d0  : unsigned(3 downto 0);

begin

  u0_Score: ScoreToDigits
    port map(
        score_in => score,
        d5       => d5,
        d4       => d4,
        d3       => d3,
        d2       => d2,
        d1       => d1,
        d0       => d0 
    );

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

  ---------------------------------------------------------------------------
  -- Color / score + Tetris drawing logic
  ---------------------------------------------------------------------------
  process (current_state, pixel_count, v_count,
           Column0, Column1, Column2, Column3, Column4,
           Column5, Column6, Column7, Column8,
           d0, d1, d2, d3, d4, d5)
    -- helper to set RGB
    procedure set_rgb_n(col : unsigned(11 downto 0)) is
    begin
      Red_n   <= col(11 downto 8);
      Green_n <= col(7  downto 4);
      Blue_n  <= col(3  downto 0);
    end procedure;

    -- 7-segment style digit drawer
    procedure draw_digit(
      digit     : in integer;                   -- 0..9
      col_start : in unsigned(9 downto 0);      -- left column of digit
      px        : in unsigned(9 downto 0);      -- current pixel x
      vy        : in unsigned(9 downto 0);      -- current pixel y
      hit       : inout std_logic               -- set to '1' if this digit lights this pixel
    ) is
      -- segment “hit” for current pixel
      variable seg_a, seg_b, seg_c : boolean;
      variable seg_d, seg_e, seg_f : boolean;
      variable seg_g               : boolean;
      -- which segments are ON for this digit
      variable on_a, on_b, on_c : boolean;
      variable on_d, on_e, on_f : boolean;
      variable on_g             : boolean;
      -- shorthand for right edge
      variable right_col : unsigned(9 downto 0);
    begin
      right_col := col_start + DIGIT_WIDTH;

      -- horizontal segments
      seg_a := (px >= col_start) and (px <= right_col) and (vy = SCORE_ROW_1);
      seg_g := (px >= col_start) and (px <= right_col) and (vy = SCORE_ROW_2);
      seg_d := (px >= col_start) and (px <= right_col) and (vy = SCORE_ROW_3);

      -- vertical segments
      seg_f := (px = col_start)   and (vy >= SCORE_ROW_1) and (vy <= SCORE_ROW_2); -- left top
      seg_e := (px = col_start)   and (vy >= SCORE_ROW_2) and (vy <= SCORE_ROW_3); -- left bottom
      seg_b := (px = right_col)   and (vy >= SCORE_ROW_1) and (vy <= SCORE_ROW_2); -- right top
      seg_c := (px = right_col)   and (vy >= SCORE_ROW_2) and (vy <= SCORE_ROW_3); -- right bottom

      -- default: all off
      on_a := false; on_b := false; on_c := false;
      on_d := false; on_e := false; on_f := false; on_g := false;

      -- which segments are lit for each digit
      case digit is
        when 0 =>
          on_a := true; on_b := true; on_c := true;
          on_d := true; on_e := true; on_f := true;
        when 1 =>
          on_b := true; on_c := true;
        when 2 =>
          on_a := true; on_b := true; on_g := true;
          on_e := true; on_d := true;
        when 3 =>
          on_a := true; on_b := true; on_g := true;
          on_c := true; on_d := true;
        when 4 =>
          on_f := true; on_g := true;
          on_b := true; on_c := true;
        when 5 =>
          on_a := true; on_f := true; on_g := true;
          on_c := true; on_d := true;
        when 6 =>
          on_a := true; on_f := true; on_g := true;
          on_c := true; on_d := true; on_e := true;
        when 7 =>
          on_a := true; on_b := true; on_c := true;
        when 8 =>
          on_a := true; on_b := true; on_c := true;
          on_d := true; on_e := true; on_f := true; on_g := true;
        when 9 =>
          on_a := true; on_b := true; on_c := true;
          on_d := true; on_f := true; on_g := true;
        when others =>
          null;
      end case;

      -- if this pixel is on any lit segment, mark hit
      if    (seg_a and on_a) or (seg_b and on_b) or (seg_c and on_c)
         or (seg_d and on_d) or (seg_e and on_e) or (seg_f and on_f)
         or (seg_g and on_g) then
        hit := '1';
      end if;
    end procedure;

    procedure draw_column(
      Column   : in unsigned(41 downto 0);
      col_start: in unsigned(9 downto 0);      -- left edge of this Tetris column on screen
      px       : in unsigned(9 downto 0);      -- current pixel x
      vy       : in unsigned(9 downto 0)       -- current pixel y
    ) is
      -- geometry
      constant CELL_WIDTH  : integer := 32;    -- pixels per Tetris column (x)
      constant CELL_HEIGHT : integer := 32;    -- pixels per Tetris row (y)
      constant BOARD_TOP   : integer := 62;    -- y of the top of row 13

      variable px_i   : integer;
      variable vy_i   : integer;
      variable col_x0 : integer;
      variable col_x1 : integer;

      variable row_top : integer;
      variable base    : integer;              -- base bit index for this row's 3-bit cell
      variable present : std_logic;
      variable clr     : std_logic_vector(1 downto 0);
    begin
      px_i   := to_integer(px);
      vy_i   := to_integer(vy);
      col_x0 := to_integer(col_start);
      col_x1 := col_x0 + CELL_WIDTH - 1;

      -- Only care about pixels within this Tetris column stripe
      if (px_i >= col_x0) and (px_i <= col_x1) then

        -- Walk through 14 rows (0 = bottom, 13 = top)
        for r in 0 to 13 loop
          row_top := BOARD_TOP + (13 - r) * CELL_HEIGHT;

          if (vy_i >= row_top) and (vy_i < row_top + CELL_HEIGHT) then
            -- This pixel is inside row r of this column.
            base    := r * 3;  -- bits [base+2 .. base] = [present, color1, color0]
            present := Column(base+2);
            clr     := std_logic_vector(Column(base+1 downto base));

            if present = '1' then
              -- Choose color by 2-bit code:
              -- 00 blue, 01 red, 10 green, 11 yellow
              case clr is
                when "00" => set_rgb_n(COL_BLUE);
                when "01" => set_rgb_n(COL_RED);
                when "10" => set_rgb_n(COL_GREEN);
                when others =>  -- "11"
                  set_rgb_n(COL_YELLOW);
              end case;
            end if;
            exit;  -- found our row
          end if;
        end loop;
      end if;
    end procedure;

    -- local copies of coordinates
    variable px_u, vy_u : unsigned(9 downto 0);
    variable digit_hit  : std_logic;
  begin
    -- default background
    set_rgb_n(COL_BLACK);

    px_u := pixel_count;
    vy_u := v_count;

    if current_state = PIXEL_DATA then

      -- outside active vertical area → black
      if (vy_u < V_ACTIVE_BEG) or (vy_u > V_FRAME_END) then
        set_rgb_n(COL_BLACK);

      else
        ------------------------------------------------------------------
        -- Board outline
        ------------------------------------------------------------------
        if (to_integer(px_u) = 335) and (to_integer(vy_u) > 61) and (to_integer(vy_u) < 510) then
          set_rgb_n(COL_WHITE);                        -- left line

        elsif (to_integer(px_u) = 624) and (to_integer(vy_u) > 61) and (to_integer(vy_u) < 510) then
          set_rgb_n(COL_WHITE);                        -- right line

        elsif (to_integer(px_u) >= 335) and (to_integer(px_u) <= 624)
              and (to_integer(vy_u) = 509) then
          set_rgb_n(COL_WHITE);                        -- bottom line

        else
          ----------------------------------------------------------------
          -- Score digits + Tetris columns
          ----------------------------------------------------------------
          digit_hit := '0';

          -- score
          draw_digit(to_integer(d5), SCORE_COL_START5, px_u, vy_u, digit_hit);
          draw_digit(to_integer(d4), SCORE_COL_START4, px_u, vy_u, digit_hit);
          draw_digit(to_integer(d3), SCORE_COL_START3, px_u, vy_u, digit_hit);
          draw_digit(to_integer(d2), SCORE_COL_START2, px_u, vy_u, digit_hit);
          draw_digit(to_integer(d1), SCORE_COL_START1, px_u, vy_u, digit_hit);
          draw_digit(to_integer(d0), SCORE_COL_START0, px_u, vy_u, digit_hit);

          -- Tetris board
          draw_column(Column0, COL_START_0, px_u, vy_u);
          draw_column(Column1, COL_START_1, px_u, vy_u);
          draw_column(Column2, COL_START_2, px_u, vy_u);
          draw_column(Column3, COL_START_3, px_u, vy_u);
          draw_column(Column4, COL_START_4, px_u, vy_u);
          draw_column(Column5, COL_START_5, px_u, vy_u);
          draw_column(Column6, COL_START_6, px_u, vy_u);
          draw_column(Column7, COL_START_7, px_u, vy_u);
          draw_column(Column8, COL_START_8, px_u, vy_u);

          -- Only override with white if a digit hits.
          -- NO "else set_rgb_n(COL_BLACK)" here, or it erases the blocks.
          if digit_hit = '1' then
            set_rgb_n(COL_WHITE);
          end if;

        end if;  -- board vs score

      end if;    -- active area
    end if;      -- PIXEL_DATA state
  end process;

  ---------------------------------------------------------------------------
  -- Sequential: counters, state, and RGB registers
  ---------------------------------------------------------------------------
  process (clk)
  begin
    if rising_edge(clk) then
      if rst_l = '0' then
        current_state <= FRONT_PORCH;
        pixel_count   <= (others => '0');
        v_count       <= (others => '0');
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
          else
            v_count <= v_count + 1;
          end if;
        end if;

        -- register the combinational next values (single driver for RGB)
        Red   <= Red_n;
        Green <= Green_n;
        Blue  <= Blue_n;
      end if;
    end if;
  end process;

end architecture behavioral;
