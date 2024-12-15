library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity rx_tb is
generic(
	c_clkfreq 	: integer := 62_500_000;		
	baudrate 	: integer := 9600;
         parity_type 	: std_logic := '1'
);
end rx_tb;

architecture Behavioral of rx_tb is

component rx_w_parity is
generic(
	c_clkfreq 	: integer := 62_500_000;					-- System clock frequency
	baudrate 	: integer := 9600;                                                   -- UART communication baud rate
         parity_type 	: std_logic := '1'                                                   -- '0' for even parity, '1' for odd parity
);                                                                                                                     
port (                                                                                                              
	clk 			: in std_logic ;                                                        -- Clock input
	reset		: in std_logic ;                                                        -- Asynchronous reset
	rx_data_in	: in std_logic;                                                         -- Incoming data
	rx_data_out	: out std_logic_vector ( 7 downto 0 );             -- Output data
	rx_done_tick: out std_logic;                                                       -- Signal indicating reception completion
	rx_error	: out std_logic                                                         -- Signal indicating a reception error
);
end component;
signal clk 			:  std_logic ;
signal reset			:  std_logic ;
signal rx_data_in	:  std_logic;
signal rx_data_out	:  std_logic_vector ( 7 downto 0 );
signal rx_done_tick	:  std_logic;
signal rx_error		:  std_logic;

constant c_clkperiod : time := 16ns;	-- Clock period derived from system frequency
constant c_hex43 : std_logic_vector (10 downto 0) := '1' & '0' & x"43"  & '0' ;	-- Data packet for x43
constant c_hexA5 : std_logic_vector (10 downto 0) := '1' & '1' & x"A5"  & '1' ;	-- Data packet for xA5
constant c_hex24 : std_logic_vector (10 downto 0) := '1' & '1' & x"24"  & '1' ;	-- Data packet for x24
constant c_baud9600 : time:= 104.17 us;


begin
-- Instantiating the DUT (rx_w_parity)
DUT : rx_w_parity
generic map(
	c_clkfreq 	=> c_clkfreq 	,
	baudrate 	=> baudrate 	,	
         parity_type 	=> parity_type 
)
port map (
	clk 			 => clk 			,
	reset		 => reset		,
	rx_data_in	 => rx_data_in	,
	rx_data_out	 => rx_data_out	,
	rx_done_tick => rx_done_tick,
	rx_error	 => rx_error	
);
-- Clock generation process
P_CLKGEN: process begin 
	
	clk <= '0' ;
	wait for c_clkperiod/2;
	clk <= '1' ;
	wait for c_clkperiod/2;
	end process P_CLKGEN;

-- Stimulus process to provide test input to the DUT
P_STIMULI : process begin

-- Assert reset for one clock cycle
reset <= '1';
wait for c_clkperiod;
reset <= '0';

-- Send first test data packet bit by bit
for i in 0 to 10 loop
	rx_data_in <= c_hex43(i);
	wait for c_baud9600;
end loop;

-- Send second test data packet
for i in 0 to 10 loop
	rx_data_in <= c_hexA5(i);	-- Apply each bit to rx_data_in
	wait for c_baud9600;			-- Wait for one bit duration
end loop;

-- Send third test data packet
for i in 0 to 10 loop
	rx_data_in <= c_hex24(i);
	wait for c_baud9600;
end loop;

-- End simulation with an assertion
assert false
report "SIM done." 
severity failure;
end process P_STIMULI;
end Behavioral;
