library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RLE_encoder is
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        start           : in  std_logic;
        data_in         : in  std_logic_vector(7 downto 0);
        data_out        : out std_logic_vector(15 downto 0);
        done            : out std_logic;
        reduced_length  : out unsigned(7 downto 0)
    );
end entity;

architecture arch of RLE_encoder is
    ----------------------------------------------------------------
    -- Matrix storage
    ----------------------------------------------------------------
    type mem_t is array (0 to 63) of std_logic_vector(7 downto 0);
    signal mem : mem_t;
    
    ----------------------------------------------------------------
    -- Zigzag order for 8 x 8 matrix
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
    -- RLE Buffer
    ----------------------------------------------------------------
    type rle_t is array (0 to 63) of std_logic_vector(15 downto 0);
    signal rle_buffer : rle_t;    
    
    
    --state and signal declarations
    type state_t is (idle, fill_inputs, initialize, compress, output);
    signal state : state_t;    
    signal fill_count       : integer range 0 to 64;
    signal zigzag_index     : integer range 0 to 64;
    signal rle_write_index  : integer range 0 to 63;
	 signal symbol_count        : unsigned(7 downto 0);
	 signal rle_length       : unsigned(7 downto 0);
	 signal current_symbol   : std_logic_vector(7 downto 0);
    signal output_count     : integer range 0 to 64;    
    
    
begin
    
    process(clk, reset)
        variable next_symbol : std_logic_vector(7 downto 0);
    begin
        if reset = '1' then
            state           <= idle;
            fill_count    <= 0;
            zigzag_index    <= 0;
            rle_write_index <= 0;
            output_count  <= 0;
            current_symbol  <= (others => '0');
            symbol_count       <= (others => '0');
            rle_length      <= (others => '0');
            done            <= '0';
            reduced_length  <= (others => '0');
            data_out        <= (others => '0');
            
        elsif rising_edge(clk) then
            case state is
                
                
                -- idle: once start=1 capture the first data point and move to fill_inputs state
                
                when idle =>
                    done            <= '0';
                    fill_count    <= 0;
                    zigzag_index    <= 0;
                    rle_write_index <= 0;
                    output_count  <= 0;
                    symbol_count       <= (others => '0');
                    rle_length      <= (others => '0');
                    
                    if start = '1' then
                        -- capute first data immediately
                        mem(0) <= data_in;
                        fill_count <= 1;
                        state <= fill_inputs;
                    end if;
                
                
                -- fill_inputs: Store the rest of the 63 input symbols
                
                when fill_inputs =>
					 
						  --fill every clk till the length reaches 64 (index reachess 63)
                    if fill_count < 64 then
                        mem(fill_count) <= data_in;
                        fill_count <= fill_count + 1;
                    end if;

						  						  
                    if fill_count = 63 then
                        state <= initialize;
                    end if;
                
                
                -- initialize: initialise the first symbol in the input matrix to being compression procecss
                
                when initialize =>
                    current_symbol  <= mem(zigzag_order(0));
                    symbol_count       <= to_unsigned(1, 8);	--that symbol has appeared once for now
                    zigzag_index    <= 1;	-- the second zigziag_index according as per the array
                    rle_write_index <= 0;
                    state           <= compress;
                
                
                -- compress: traverse in zigzag order and compute the reduced length
                
                when compress =>
                    if zigzag_index < 64 then
                        -- obtain the next symbol as per zigzag order and check whether same or new symbol
                        next_symbol := mem(zigzag_order(zigzag_index));
                        
                        if next_symbol = current_symbol then
                            -- if same symbol incremement the count and zigzag index
                            symbol_count    <= symbol_count + 1;
                            zigzag_index <= zigzag_index + 1;
                        else
                            -- if different symbol, store the run count and the corresponding symbol
                            rle_buffer(rle_write_index) <= std_logic_vector(symbol_count) & current_symbol;
                            rle_write_index <= rle_write_index + 1;
                            
                            -- then make the new symbol as current symbol, intialise symbol_count as 1 again, update the zigzag_index
                            current_symbol <= next_symbol;
                            symbol_count      <= to_unsigned(1, 8);
                            zigzag_index   <= zigzag_index + 1;
                        end if;
								-- this process repeats every clock until all 64 elements have been traversed in the zigzag order
                        
                    else
                        -- all elements traversed, write the last count and element too
                        rle_buffer(rle_write_index) <= std_logic_vector(symbol_count) & current_symbol;
                        rle_length      <= to_unsigned(rle_write_index + 1, 8);	--length is index+1
                        output_count  <= 0;
                        state           <= output;
                    end if;
                
                
                -- output - send the compressed data through data_out one by one
                
                when output =>
                    if output_count = 0 then
                        -- First cycle: set done and output first element
                        done           <= '1';
                        reduced_length <= rle_length;
                        data_out       <= rle_buffer(0);
                        output_count <= 1;
                    elsif output_count < to_integer(rle_length) then
                        -- Continue outputting remaining elements
                        data_out       <= rle_buffer(output_count);
                        output_count <= output_count + 1;
                    
                    end if;
                    
            end case;
        end if;
    end process;
    
end architecture;