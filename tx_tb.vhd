library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tx_tb is
generic ( 
	c_clkfreq 	: integer := 50_000_000;
	baudrate	: integer := 115_200;
	stopbit    	: integer := 1;
	parity_type 	: std_logic := '1' 
);
end tx_tb;

architecture Behavioral of tx_tb is

component tx is
generic ( 
	c_clkfreq 	: integer := 50_000_000;	-- Clock frequency
	baudrate	: integer := 115_200;          -- UART baud rate
	stopbit    	: integer := 1;                       -- Number of stop bits.
	parity_type 	: std_logic := '1'                 -- '0' for even parity, '1' for odd parity
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

signal	clk 				:  std_logic ;
signal	reset			:  std_logic ;
signal	tx_data_in		:  std_logic_vector ( 7 downto 0 );
signal	tx_enable		:  std_logic;
signal	tx_done_tick	:  std_logic;
signal	tx_data_out 		:  std_logic;

-- Constant for the simulation clock period
constant c_clkperiod : time := 20ns;	-- Clock period (50 MHz frequency)

begin
-- Instantiating the DUT "tx"
DUT : tx
generic map ( 
	c_clkfreq 	=> c_clkfreq,	
	baudrate	=> baudrate,	
	stopbit    	=> stopbit ,   	
	parity_type 	=> parity_type 	
)
port map(
	clk 				=> clk 	,		
	reset			=> reset	,	
	tx_data_in		=> tx_data_in	,
	tx_enable		=> tx_enable	,
	tx_done_tick	=> tx_done_tick,
	tx_data_out 		=> tx_data_out 	
);
-- Clock generation process
P_CLKGEN: process begin 
	
	clk <= '0' ;
	wait for c_clkperiod/2;
	clk <= '1' ;
	wait for c_clkperiod/2;
	end process P_CLKGEN;
	
-- Stimulus process to provide test inputs to the DUT	
P_STIMULI : process begin
-- Assert reset for one clock cycle
reset <= '1';
wait for c_clkperiod;
reset <= '0';

-- First test case: Transmit data 0xA5 without enabling transmission
tx_data_in <= x"A5";
tx_enable <= '0';

wait for c_clkperiod*10;	-- Wait for a few clock cycles

-- Second test case: Transmit data 0x51 with enable signal
tx_data_in <= x"51";
tx_enable <= '1';		-- Enable transmission
wait for  c_clkperiod;
tx_enable <= '0';		-- Disable transmission
wait for  95.510 us;		-- Wait for transmission to complete

-- Third test case: Transmit data 0xA3
tx_data_in <= x"A3";
tx_enable <= '1';
wait for  c_clkperiod;
tx_enable <= '0';
wait for  95.510 us;		-- Wait for transmission to complete

-- Fourth test case: Transmit data 0xB8
tx_data_in <= x"B8";
tx_enable <= '1';
wait for  c_clkperiod;
tx_enable <= '0';

-- Wait until the transmission is done
wait until (rising_edge(tx_done_tick));	-- Wait for transmission completion
wait for 1 us;

-- End simulation with an assertion
assert false
report "SIM done." 
severity failure;
end process P_STIMULI;
end Behavioral;
