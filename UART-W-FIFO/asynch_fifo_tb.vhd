library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_async_fifo is
end entity;

architecture Behavioral of tb_async_fifo is

    constant DATA_WIDTH : integer := 8;	
    constant ADDR_WIDTH : integer := 4;    

    signal wr_clk   : std_logic := '0';											
    signal rd_clk   : std_logic := '0';
    signal reset    : std_logic := '0';
    signal wr_en    : std_logic := '0';
    signal rd_en    : std_logic := '0';
    signal data_in  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal full     : std_logic;
    signal empty    : std_logic;
	
    component asynch_FIFO
        generic (
            DATA_WIDTH : integer := 8;	-- Data width of the FIFO
            ADDR_WIDTH : integer := 4        -- Address width, determines FIFO depth (2^ADDR_WIDTH)
        );
        port (
            wr_clk   : in  std_logic;									-- Write clock signal
            rd_clk   : in  std_logic;                                                                        -- Read clock signal
            reset    : in  std_logic;                                                                        -- Reset signal to clear FIFO
            wr_en    : in  std_logic;                                                                        -- Write enable signal
            rd_en    : in  std_logic;                                                                        -- Read enable signal
            data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);       -- Data input for writing to FIFO
            data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);      -- Data output for reading from FIFO
            full     : out std_logic;                                                                        -- Indicates FIFO is full
            empty    : out std_logic                                                                         -- Indicates FIFO is empty
        );
    end component;
	
-- Define clock periods for write and read clocks
    constant WR_CLK_PERIOD : time := 16 ns; -- Write clock period
    constant RD_CLK_PERIOD : time := 20 ns;  -- Read clock period

begin

-- Generate write clock (wr_clk)
    process
    begin
        wr_clk <= '0';
        wait for WR_CLK_PERIOD / 2;
        wr_clk <= '1';
        wait for WR_CLK_PERIOD / 2;
    end process;

-- Generate read clock (rd_clk)
    process
    begin
        rd_clk <= '0';
        wait for RD_CLK_PERIOD / 2;
        rd_clk <= '1';
        wait for RD_CLK_PERIOD / 2;
    end process;

-- Instantiate the DUT (Device Under Test) "asynch_FIFO"
    uut: asynch_FIFO
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            wr_clk   => wr_clk,
            rd_clk   => rd_clk,
            reset    => reset,
            wr_en    => wr_en,
            rd_en    => rd_en,
            data_in  => data_in,
            data_out => data_out,
            full     => full,
            empty    => empty
        );

-- Stimulus process to provide test inputs to the DUT
    process
    begin
	
-- Apply reset signal to initialize the FIFO
        reset <= '1';
        wait for 100 ns;	-- Wait for 100 ns to ensure reset
        reset <= '0';

-- Test case 1: Write a value to the FIFO
			wr_en <= '1';
			data_in <= std_logic_vector(to_unsigned(5, DATA_WIDTH)); -- Write value 5
			wait for WR_CLK_PERIOD;	-- Wait for one write clock cycle
			wr_en <= '0';			-- De-assert write enable
-- Test case 2: Read the value from the FIFO
			rd_en <= '1';
			wait for RD_CLK_PERIOD;	-- Wait for one read clock cycle
-- Test case 3: Write another value to the FIFO
			wr_en <= '1';			
			data_in <= std_logic_vector(to_unsigned(6, DATA_WIDTH));-- Write value 6
			wait for WR_CLK_PERIOD;	-- Wait for one write clock cycle
			wr_en <= '0';			-- De-assert write enable
			wait for WR_CLK_PERIOD;
			-- Additional read cycles to check FIFO behavior
			wait for RD_CLK_PERIOD;	
			wait for RD_CLK_PERIOD;	
			rd_en <= '0';	-- De-assert read enable
-- Add more test cases as needed by uncommenting below lines

	-- 		wait for RD_CLK_PERIOD;
	-- 		data_in <= std_logic_vector(to_unsigned(7, DATA_WIDTH));
         --   	wait for WR_CLK_PERIOD;
	--		data_in <= std_logic_vector(to_unsigned(8, DATA_WIDTH));
         --   	wait for WR_CLK_PERIOD;
	--		data_in <= std_logic_vector(to_unsigned(9, DATA_WIDTH));
         --   	wait for WR_CLK_PERIOD;
	--		data_in <= std_logic_vector(to_unsigned(10, DATA_WIDTH));
         --   	wait for WR_CLK_PERIOD;
	-- 		wait for RD_CLK_PERIOD;
	--  	wait for RD_CLK_PERIOD;
	--   	wait for RD_CLK_PERIOD;
	--    	wait for RD_CLK_PERIOD;
        --		wr_en <= '0';
	--	 	ait for RD_CLK_PERIOD;
	--	  	wait for RD_CLK_PERIOD;
	--	   	wait for RD_CLK_PERIOD;
	--		rd_en <= '0';
	
-- End simulation after 100 ns
        wait for 100 ns;
        assert false report "Simulation finished" severity note;
        wait;
    end process;

end architecture Behavioral;