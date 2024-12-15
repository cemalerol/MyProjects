library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity TOP_UART_W_FIFO is
generic(
	c_rx_clkfreq			: integer := 62_500_000;	-- Clock frequency for RX modu
	c_tx_clkfreq			: integer := 50_000_000;    -- Clock frequency for TX modu
	c_rx_baudrate		: integer := 9600;                         -- Baud rate for RX module
	c_tx_baudrate		: integer := 115_200;                   -- Baud rate for TX module
	c_stopbit			: integer := 1;                                -- Number of stop bits for TX 
         parity_type 			: std_logic := '1';                       -- Parity type: '0' for even, 
	DATA_WIDTH 			: integer := 8;                                -- Data width for FIFO
        ADDR_WIDTH 			: integer := 4                                  -- FIFO depth as 2^ADDR_WIDTH
);
port(
	rx_clk 		: in std_logic;	-- Clock signal for RX module
	tx_clk 		: in std_logic;     -- Clock signal for TX module
	reset 		: in std_logic;     -- Reset signal
	rx_i		: in std_logic;     -- Input signal for RX module
	tx_o		: out std_logic     -- Output signal from TX module
);
end TOP_UART_W_FIFO;

architecture Behavioral of TOP_UART_W_FIFO is

component rx_w_parity is
generic(
	c_clkfreq 	: integer := 62_500_000;				-- System clock frequency	
	baudrate 	: integer := 9600;                                           -- UART communication baud rate
         parity_type 	: std_logic := '1'                                           -- '0' for even parity, '1' for odd parity
);                                                                                                            
port (                                                                                                     
	clk 			: in std_logic ;                                               -- Clock input
	reset		: in std_logic ;                                               -- Asynchronous reset
	rx_data_in	: in std_logic;                                                -- Incoming data
	rx_data_out	: out std_logic_vector ( 7 downto 0 );    -- Output data
	rx_done_tick: out std_logic;                                              -- Signal indicating reception completion
	rx_error	: out std_logic                                                -- Signal indicating a reception error
);
end component;

component tx is
generic ( 
	c_clkfreq 	: integer := 50_000_000;	-- Clock frequency
	baudrate	: integer := 115_200;       	-- UART baud rate
	stopbit    	: integer := 1;                    	-- Number of stop bits.
	parity_type 	: std_logic := '1'             	-- '0' for even parity, '1' for odd parity
);
port (
	clk 				: in std_logic ;						-- Clock signal input.
	reset			: in std_logic ;                                               -- Reset signal input
	tx_data_in		: in std_logic_vector ( 7 downto 0 );      -- Data to be transmitted
	tx_enable		: in std_logic;                                                --Enable signal to start transmission.
	tx_done_tick	: out std_logic;                                              -- Signal indicating transmission completion.
	tx_data_out 		: out std_logic	                                            -- UART serial output.
);
end component;

component asynch_FIFO is
 generic (
        DATA_WIDTH : integer := 8;   -- Data width of the FIFO
        ADDR_WIDTH : integer := 4     -- Address width, determines FIFO depth (2^ADDR_WIDTH)
    );
port(
	wr_clk   : in  std_logic;                                					-- Write clock signal
        rd_clk   : in  std_logic;                                                                            -- Read clock signal
        reset    : in  std_logic;                                                                            -- Reset signal to clear FIFO
        wr_en    : in  std_logic;                                                                            -- Write enable signal
        rd_en    : in  std_logic;                                                                            -- Read enable signal
        data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);           -- Data input for writing to FIFO
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);          -- Data output for reading from FIFO
        full     : out std_logic;                                                                            -- Indicates FIFO is full
        empty    : out std_logic                                                                             -- Indicates FIFO is empty
	);
end component;

-- RX signals
signal rx_data_out_s : std_logic_vector ( 7 downto 0) := (others => '0');
signal rx_done_tick_s : std_logic := '0';
signal rx_error_s : std_logic ;
signal tx_enable_s     : std_logic := '0';

-- TX signals
signal tx_done_tick_s : std_logic := '0';

-- FIFO signals
signal full_s 	: std_logic :=  '0';
signal empty_s 	: std_logic :=  '0';
signal fifo_data_out : std_logic_vector(7 downto 0);

-- FIFO write and read enable signals
    signal fifo_wr_en    : std_logic := '0';
    signal fifo_rd_en    : std_logic := '0';

begin

insta_rx : rx_w_parity
generic map(
	c_clkfreq 	=> c_rx_clkfreq,
	baudrate 	=> c_rx_baudrate,
         parity_type 	=> parity_type
)		
port map(
	clk 				=> rx_clk,			
	reset			=> reset	,	
	rx_data_in		=> rx_i,				-- Connect RX input data
	rx_data_out		=> rx_data_out_s,
	rx_done_tick	=> rx_done_tick_s,
	rx_error		=> rx_error_s
);

insta_tx : tx
generic map ( 
	c_clkfreq 	=> c_tx_clkfreq,
	baudrate	=> c_tx_baudrate,
	stopbit    	=> c_stopbit,
	parity_type 	=> parity_type
)
port map (
	clk 				=> tx_clk,
	reset			=> reset	,	
	tx_data_in		=> fifo_data_out,	-- Connect FIFO output data to TX input	
	tx_enable		=> tx_enable_s	,
	tx_done_tick	=> tx_done_tick_s,
	tx_data_out 		=> tx_o	
);

insta_fifo : asynch_FIFO
generic map (
        DATA_WIDTH => DATA_WIDTH,
        ADDR_WIDTH => ADDR_WIDTH
    )
port map(
	wr_clk   		=>	rx_clk,   			-- Connect write clock to RX clock	
        rd_clk   		=>	tx_clk,   			-- Connect read clock to TX clock
        reset   		=>	reset,   	
        wr_en   		=>	fifo_wr_en,   	
        rd_en    		=>	fifo_rd_en ,   	
        data_in 		=>	rx_data_out_s , 		-- Connect RX output data to FIFO input
        data_out		=>	fifo_data_out ,		-- Connect FIFO output data
        full     		=>	full_s,    	
        empty    		=>	empty_s   	
);

-- Process to control FIFO write operation
process(rx_clk, reset)
    begin
        if reset = '1' then
            fifo_wr_en <= '0';		-- Disable write on reset
        elsif rising_edge(rx_clk) then
            if rx_done_tick_s = '1' and full_s = '0' and  rx_error_s = '0' then
                fifo_wr_en <= '1';	-- Enable write when RX is done, FIFO is not full, and no errors
            else
                fifo_wr_en <= '0';	-- Otherwise, disable write
            end if;
        end if;
    end process;

  -- Process to control FIFO read and TX enable operation
    process(tx_clk, reset)
    begin
        if reset = '1' then
            tx_enable_s <= '0';		-- Disable TX on reset
            fifo_rd_en <= '0';		-- Disable FIFO read on reset
        elsif rising_edge(tx_clk) then
            if empty_s = '0' then
                fifo_rd_en <= '1';	-- Enable read when FIFO is not empty
                tx_enable_s <= '1';	-- Enable TX
            else
                fifo_rd_en <= '0';	-- Otherwise, disable read
                tx_enable_s <= '0';	-- Disable TX
            end if;
        end if;
    end process;

end Behavioral;

