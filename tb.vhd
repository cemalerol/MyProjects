library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_module is
generic(
	c_rx_clkfreq			: integer := 62_500_000;
	c_tx_clkfreq			: integer := 50_000_000;
	c_rx_baudrate		: integer := 9600;
	c_tx_baudrate		: integer := 115_200;
	c_stopbit			: integer := 1;
         parity_type 			: std_logic := '1';
	DATA_WIDTH 			: integer := 8;  
        ADDR_WIDTH 			: integer := 4   
);
end tb_top_module;

architecture Behavioral of tb_top_module is

    -- Sinyaller
    signal rx_clk      : std_logic := '0';
    signal tx_clk      : std_logic := '0';
    signal reset       : std_logic := '0';
    signal rx_i  : std_logic := '1';
    signal tx_o : std_logic;
	signal input_data  : std_logic_vector(10 downto 0) := (others => '0');


 -- Clock period constants for RX and TX clocks
constant clk_period_rx : time := 16 ns;    -- RX clock period (62.5 MHz)
constant clk_period_tx : time := 20 ns;    -- TX clock period (50 MHz)

-- Baud rate timing constant for 9600 baud	
constant c_baud9600 : time:= 104.17 us;	-- Baud rate for 9600 (104.17 microseconds)
constant c_hex43 : std_logic_vector (10 downto 0) := '1' & '0' & x"43"  & '0' ;	-- Data: 0x43
constant c_hexA5 : std_logic_vector (10 downto 0) := '1' & '1' & x"A5"  & '0' ;	-- Data: 0xA5
constant c_hex24 : std_logic_vector (10 downto 0) := '1' & '1' & x"24"  & '0' ;	-- Data: 0x24
constant c_hexC5 : std_logic_vector (10 downto 0) := '1' & '1' & x"C5"  & '0' ;	-- Data: 0xC5
constant c_hexB2 : std_logic_vector (10 downto 0) := '1' & '1' & x"B2"  & '0' ;	-- Data: 0xB2
constant c_hexD9 : std_logic_vector (10 downto 0) := '1' & '0' & x"D9"  & '0' ;	-- Data: 0xD9

    
    -- Component declaration for the UART with FIFO top module
component TOP_UART_W_FIFO is
generic(
	c_rx_clkfreq			: integer := 62_500_000;	-- Clock frequency for RX modu
	c_tx_clkfreq			: integer := 50_000_000;     -- Clock frequency for TX modu
	c_rx_baudrate		: integer := 9600;                         -- Baud rate for RX module
	c_tx_baudrate		: integer := 115_200;                    -- Baud rate for TX module
	c_stopbit			: integer := 1;                                 -- Number of stop bits for TX 
         parity_type 			: std_logic := '1';                       -- Parity type: '0' for even, 
	DATA_WIDTH 			: integer := 8;                                 -- Data width for FIFO
        ADDR_WIDTH 			: integer := 4                                  -- FIFO depth as 2^ADDR_WIDTH
);
port(
	rx_clk 		: in std_logic;	-- Clock signal for RX module
	tx_clk 		: in std_logic;      -- Clock signal for TX module
	reset 		: in std_logic;      -- Reset signal
	rx_i		: in std_logic;      -- Input signal for RX module
	tx_o		: out std_logic      -- Output signal from TX module
);
end component;

begin

-- RX clock generation process
    process
    begin
          rx_clk <= '0';
        wait for clk_period_rx / 2;
	rx_clk <= '1';
        wait for clk_period_rx / 2;
    end process;

  -- TX clock generation process
   process
    begin
          tx_clk <= '0';
        wait for clk_period_tx / 2;
	tx_clk <= '1';
        wait for clk_period_tx / 2;
    end process;

-- Instantiate the TOP_UART_W_FIFO component (UART with FIFO)
    uut: TOP_UART_W_FIFO
    port map(
        rx_clk      => rx_clk,
        tx_clk      => tx_clk,
        reset       => reset,
        rx_i  => rx_i,
        tx_o => tx_o
    );

-- Test process to apply test cases
    process
    begin
        -- Initialize Inputs
        reset <= '1';		-- Assert reset
        wait for 50 ns;
        reset <= '0';
        wait for 50 ns;	-- Deassert reset

-- Test Case 1: Send data through RX and check FIFO write
-- Loop through each data value and transmit on RX
for i in 0 to 10 loop
	rx_i <= c_hex43(i);	-- Send data 0x43
	wait for c_baud9600;	-- Wait for baud rate time
end loop;

-- Repeat the process with different data values
for i in 0 to 10 loop
	rx_i <= c_hexA5(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hex24(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hexC5(i);
	wait for c_baud9600;
end loop;

   for i in 0 to 10 loop
	rx_i <= c_hex43(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hexA5(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hex24(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hexC5(i);
	wait for c_baud9600;
end loop;

   for i in 0 to 10 loop
	rx_i <= c_hex43(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hexA5(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hex24(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hexC5(i);
	wait for c_baud9600;
end loop;

   for i in 0 to 10 loop
	rx_i <= c_hex43(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hexA5(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hex24(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hexC5(i);
	wait for c_baud9600;
end loop;

   for i in 0 to 10 loop
	rx_i <= c_hexB2(i);
	wait for c_baud9600;
end loop;

for i in 0 to 10 loop
	rx_i <= c_hexD9(i);
	wait for c_baud9600;
end loop;

-- End of simulation
assert false
report "SIM done." 
severity failure;
    end process;

end Behavioral;
