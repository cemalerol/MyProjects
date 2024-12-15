library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity asynch_FIFO is
 generic (
        DATA_WIDTH : integer := 8;  -- Data width of the FIFO
        ADDR_WIDTH : integer := 4    -- Address width, determines FIFO depth (2^ADDR_WIDTH)
    );
port(
	wr_clk   : in  std_logic;                               					-- Write clock signal
        rd_clk   : in  std_logic;                                                                           -- Read clock signal
        reset    : in  std_logic;                                                                            -- Reset signal to clear FIFO
        wr_en    : in  std_logic;                                                                            -- Write enable signal
        rd_en    : in  std_logic;                                                                            -- Read enable signal
        data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);           -- Data input for writing to FIFO
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);         -- Data output for reading from FIFO
        full     : out std_logic;                                                                            -- Indicates FIFO is full
        empty    : out std_logic                                                                             -- Indicates FIFO is empty
	);
end asynch_FIFO;

architecture Behavioral of asynch_FIFO is

-- Memory array to store FIFO data
    type fifo_mem_type is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo_mem : fifo_mem_type := (others => (others => '0'));
	
-- Write and read pointers in binary and gray code
    signal wr_ptr_bin, rd_ptr_bin : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
    signal wr_ptr_gray, rd_ptr_gray : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
	
-- Synchronization signals for crossing clock domains
    signal wr_ptr_gray_sync1, wr_ptr_gray_sync2 : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
    signal rd_ptr_gray_sync1, rd_ptr_gray_sync2 : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
	
-- Signals for FIFO full and empty conditions
    signal fifo_full, fifo_empty : std_logic :=  '0';

begin
-- Assign internal full and empty signals to output ports
    full <= fifo_full;
    empty <= fifo_empty;

-- Write process: Writes data to FIFO memory when enabled and not full
    process(wr_clk)
    begin
        if rising_edge(wr_clk) then
            if reset = '1' then
                wr_ptr_bin <= (others => '0');				-- Reset write pointer to 0
            elsif wr_en = '1' and fifo_full = '0' then		-- Write data to memory at location indicated by write pointer
                fifo_mem(to_integer(unsigned(wr_ptr_bin(ADDR_WIDTH-1 downto 0)))) <= data_in;
                wr_ptr_bin <= std_logic_vector(unsigned(wr_ptr_bin) + 1); 	-- Increment write pointer

            end if;
        end if;
    end process;
	
-- Read process: Reads data from FIFO memory when enabled and not empty
    process(rd_clk)
    begin
        if rising_edge(rd_clk) then
            if reset = '1' then
                rd_ptr_bin <= (others => '0');		-- Reset read pointer to 0
            elsif rd_en = '1' and fifo_empty = '0' then
	-- Output data from memory at location indicated by read pointer	
                data_out <= fifo_mem(to_integer(unsigned(rd_ptr_bin(ADDR_WIDTH-1 downto 0))));
                rd_ptr_bin <= std_logic_vector(unsigned(rd_ptr_bin) + 1);	-- Increment read pointer

            end if;
        end if;
    end process;
	
-- Generate Gray-coded write pointer (Binary to Gray conversion)
    process(wr_ptr_bin)
    begin
        wr_ptr_gray(ADDR_WIDTH) <= wr_ptr_bin(ADDR_WIDTH);	-- MSB remains the same
        for i in ADDR_WIDTH-1 downto 0 loop
	-- XOR each bit with the next higher-order bit
            wr_ptr_gray(i) <= wr_ptr_bin(i+1) xor wr_ptr_bin(i);
        end loop;
    end process;
	
-- Generate Gray-coded read pointer (Binary to Gray conversion)
    process(rd_ptr_bin)
    begin
        rd_ptr_gray(ADDR_WIDTH) <= rd_ptr_bin(ADDR_WIDTH);	-- MSB remains the same
        for i in ADDR_WIDTH-1 downto 0 loop
	-- XOR each bit with the next higher-order bit
            rd_ptr_gray(i) <= rd_ptr_bin(i+1) xor rd_ptr_bin(i);
        end loop;
    end process;
	
-- Synchronize write pointer to read clock domain
    process(rd_clk)
    begin
        if rising_edge(rd_clk) then
            wr_ptr_gray_sync1 <= wr_ptr_gray;		-- First stage of synchronization
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;	-- Second stage of synchronization
        end if;
    end process;
	
-- Synchronize read pointer to write clock domain
    process(wr_clk)
    begin
        if rising_edge(wr_clk) then
            rd_ptr_gray_sync1 <= rd_ptr_gray;		-- First stage of synchronization
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;	-- Second stage of synchronization
        end if;
    end process;
	
-- Generate FIFO full signal based on pointer comparison
    process(wr_ptr_gray, rd_ptr_gray_sync2)
    begin
       if( (wr_ptr_gray(ADDR_WIDTH) /= rd_ptr_gray_sync2(ADDR_WIDTH)) and (wr_ptr_gray(ADDR_WIDTH-1 downto 0) = rd_ptr_gray_sync2(ADDR_WIDTH-1 downto 0))) then
	   -- FIFO is full when write pointer wraps around to match read pointer
		fifo_full <= '1';
	else
		fifo_full <= '0';-- Otherwise, FIFO is not full
	end if;
    end process;
	
-- Generate FIFO empty signal based on pointer comparison
    process(rd_ptr_gray, wr_ptr_gray_sync2) -- Temporarily misdetecting that the FIFO is empty is a normal result of this type of delay and is temporary.
    begin
        if ( rd_ptr_gray = wr_ptr_gray_sync2) then
		fifo_empty <= '1' ;	-- FIFO is empty when read pointer matches write pointer
	else
		fifo_empty <= '0'; 	-- Otherwise, FIFO is not empty
	end if;
    end process;
	


end Behavioral;
