library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RLE_decoder is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        data_in        : in  std_logic_vector(15 downto 0);
        start          : in  std_logic;
        reduced_length : in  unsigned(7 downto 0);
        data_out       : out std_logic_vector(7 downto 0);
        done           : out std_logic
    );
end entity;

architecture rtl of RLE_decoder is
    ----------------------------------------------------------------
    -- Matrix storage
    ----------------------------------------------------------------
    type mem_t is array (0 to 63) of std_logic_vector(7 downto 0);
    signal mem : mem_t;
    
    ----------------------------------------------------------------
    -- RLE buffer
    ----------------------------------------------------------------
    type rle_t is array (0 to 255) of std_logic_vector(15 downto 0);
    signal rle_buffer : rle_t;
    
    ----------------------------------------------------------------
    -- Zigzag LUT (same as encoder)
    ----------------------------------------------------------------
    type zigzag_t is array (0 to 63) of integer range 0 to 63;
    constant zigzag_order : zigzag_t := (
        0,  1,  8,
        16, 9,  2,
        3,  10, 17, 24,
        32, 25, 18, 11, 4,
        5,  12, 19, 26, 33, 40,
        48, 41, 34, 27, 20, 13, 6,
        7,  14, 21, 28, 35, 42, 49, 56,
        57, 50, 43, 36, 29, 22, 15,
        23, 30, 37, 44, 51, 58,
        59, 52, 45, 38, 31,
        39, 46, 53, 60,
        61, 54, 47,
        55, 62,
        63
    );
    
    ----------------------------------------------------------------
    -- State and signal declarations
    ----------------------------------------------------------------
    type state_t is (idle, fill_rle_buffer, expand_rle, output_data);
    signal state : state_t;
    
    signal rle_read_count   : integer range 0 to 256;
    signal rle_read_index   : integer range 0 to 256;
    signal zigzag_write_idx : integer range 0 to 64;
    signal output_index     : integer range 0 to 64;
    signal expand_count     : unsigned(7 downto 0);
    signal current_symbol   : std_logic_vector(7 downto 0);
    signal current_count    : unsigned(7 downto 0);
    
begin

    process(clk, reset)
    begin
        if reset = '1' then
            state             <= idle;
            rle_read_count    <= 0;
            rle_read_index    <= 0;
            zigzag_write_idx  <= 0;
            output_index      <= 0;
            expand_count      <= (others => '0');
            current_symbol    <= (others => '0');
            current_count     <= (others => '0');
            done              <= '0';
            data_out          <= (others => '0');
            
        elsif rising_edge(clk) then
            case state is
                
                -- idle: wait for start to become 1 otherwise set everything to 0
                when idle =>
                    done             <= '0';
                    rle_read_count   <= 0;
                    rle_read_index   <= 0;
                    zigzag_write_idx <= 0;
                    output_index     <= 0;
                    expand_count     <= (others => '0');
                    
                    if start = '1' then
                        -- capture the first pair immediately
                        rle_buffer(0) <= data_in;
                        rle_read_count <= 1;
                        state <= fill_rle_buffer;
                    end if;
                
                
                -- fill_rle_buffer: read all the remaining pairs
                when fill_rle_buffer =>
                    if rle_read_count < to_integer(reduced_length) then
                        rle_buffer(rle_read_count) <= data_in;
                        rle_read_count <= rle_read_count + 1;
                    end if;
                    
                    if rle_read_count = to_integer(reduced_length) - 1 then
                        -- all rle pairs captured, now set variables for expansion process
                        rle_read_index   <= 0;
                        zigzag_write_idx <= 0;
                        current_count    <= unsigned(rle_buffer(0)(15 downto 8));
                        current_symbol   <= rle_buffer(0)(7 downto 0);
                        expand_count     <= to_unsigned(0, 8);
                        state            <= expand_rle;
                    end if;
                
                
                -- expand_rle: expand and fill in zigzag order
                when expand_rle =>
                    if zigzag_write_idx < 64 then
                        -- write the current symbol into matrix at zigzag positions
                        mem(zigzag_order(zigzag_write_idx)) <= current_symbol;
                        zigzag_write_idx <= zigzag_write_idx + 1;
                        expand_count <= expand_count + 1;
                        
                        -- check if the current symbol has been written the count number of times
                        if expand_count = current_count - 1 then
                            -- select next rle pair
                            if rle_read_index < to_integer(reduced_length) - 1 then
                                rle_read_index <= rle_read_index + 1;
                                current_count  <= unsigned(rle_buffer(rle_read_index + 1)(15 downto 8));
                                current_symbol <= rle_buffer(rle_read_index + 1)(7 downto 0);
                                expand_count   <= to_unsigned(0, 8);
                            end if;
                        end if;
                    else
                        -- fully filled
                        output_index <= 0;
                        state        <= output_data;
                    end if;
                
                
                -- output_data: output the data from the matrix 
                when output_data =>
                    if output_index = 0 then
                        -- set done and output first element
                        done         <= '1';
                        data_out     <= mem(0);
                        output_index <= 1;
                    elsif output_index < 64 then
                        -- output the remaining elements
                        data_out     <= mem(output_index);
                        output_index <= output_index + 1;
                    else                        
                        done <= '1';
                    end if;
                    
            end case;
        end if;
    end process;
    
end architecture;