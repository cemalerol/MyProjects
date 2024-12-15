library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rx_w_parity is
generic(
	c_clkfreq 	: integer := 62_500_000;				-- System clock frequency
	baudrate 	: integer := 9600;					-- UART communication baud rate
         parity_type 	: std_logic := '1' 					-- '0' for even parity, '1' for odd parity
);		
port (
	clk 			: in std_logic ;						-- Clock input
	reset		: in std_logic ;						-- Asynchronous reset
	rx_data_in	: in std_logic;						-- Incoming data
	rx_data_out	: out std_logic_vector ( 7 downto 0 );	-- Output data
	rx_done_tick: out std_logic;						-- Signal indicating reception completion
	rx_error	: out std_logic						-- Signal indicating a reception error
);
end rx_w_parity;

architecture Behavioral of rx_w_parity is

constant c_bittimerlim 	 : integer := c_clkfreq/baudrate ;				-- Calculate the bit timer limit based on clock frequency and baud rate

type t_state is ( idle_state , data_state, error_state);				-- State machine states
signal state : t_state := idle_state;									-- Current state of the FSM

signal rx_data_reg : std_logic_vector ( 10 downto 0) := (others => '0');	-- Register to store incoming data (start, data, parity, and stop bits)
signal rx_done_tick_s : std_logic := '0';								-- Internal signal for rx_done_tick
signal rx_parity_bit : std_logic_vector ( 8 downto 0) := (others => '0');	-- Signal to calculate parity bit
signal parity_error : std_logic ;										-- Signal indicating parity error
signal rx_error_s : std_logic ;										-- Internal signal for rx_error

signal bitcounter : integer range 0 to 255 := 0;							-- Counter for received bits
signal bittimer : integer range 0 to c_bittimerlim := 0;					-- Timer for bit duration


begin

process (clk,reset)

begin	
	if ( reset = '1' ) then					-- Reset logic
		state <= idle_state;				-- Return to idle state
		bitcounter 	<= 0;				-- Reset bit counter
		bittimer 	<= 0;				-- Reset bit timer
		rx_done_tick_s	<= '0';			-- Reset rx_done_tick
		rx_data_reg <= (others => '0');	-- Clear data register
		rx_error_s <= '0';				-- Clear error signal
		
		
	elsif (rising_edge(clk)) then-- On clock rising edge
		case state is 
			when idle_state =>
				rx_error_s 	<= '0' ;											-- Clear error signal
				rx_done_tick_s	<= '0';										-- Clear done tick signal
				
				if(	rx_data_in = '0') then									-- Start bit detected
					
					if(bittimer >= (c_bittimerlim/2)-1)  then 					-- Sample in the middle of the bit duration
						bittimer <= 0;										-- Reset timer
						rx_data_reg <= rx_data_in & rx_data_reg( 10 downto 1);	-- Shift start bit into register. Start bit is set to MSB
						state <= data_state;									-- Move to data reception state
					else 	
						bittimer <= bittimer +1;								-- Increment timer
					end if;
				
				
				else
					if(bittimer >= (c_bittimerlim)-1)  then					-- No start bit detected.
					-- If the start bit does not come as 0 but as 1, it is certain that there will be an error. Will save the value and continue to receive data
						bittimer <= 0;										-- Reset timer
						state <= idle_state;									-- Stay in idle state
						bitcounter <= bitcounter + 1;							-- Increment bit counter
						rx_data_reg <= rx_data_in & rx_data_reg( 10 downto 1);	-- Shift data into register		
					else 	
						bittimer <= bittimer +1;								-- Increment timer
					end if;		
				end if;

			
			when data_state => -- Data reception, including parity and stop bits			
				
				if(bittimer = c_bittimerlim-1) then					
					bittimer <= 0;										-- Reset timer
					rx_data_reg <= rx_data_in & rx_data_reg( 10 downto 1);  	-- Shift incoming bit into register.
					--It assigns the received data to MSB in order and shifts the data to the right. Thus, the first received appears in the LSB at the last stage.
					if (bitcounter < 9) then								-- If more bits to receive
						bitcounter <= bitcounter + 1;						-- Increment bit counter
						state <= data_state;								-- Stay in data state
					else
						bitcounter <= 0;									-- Reset bit counter
						bittimer <= 0;									-- Reset timer
						state <= error_state;							-- Move to error state							
					end if;
					
				else
					bittimer <= bittimer + 1;								-- Increment timer
					state <= data_state;									-- Stay in data state
				end if;
			
			when error_state => 													-- Error detection state.
			--Data transfer does not occur in this state. It only checks if there is an error.
				if(bittimer = (c_bittimerlim/2)-1) then	
					bittimer <=  0;												-- Reset timer
					rx_error_s <= parity_error or rx_data_reg(0) or not rx_data_in;	-- Check for errors in parity, start, or stop bits
					state <= idle_state;											-- Return to idle state
					rx_done_tick_s <= '1';										-- Set done tick signal
				else
					bittimer <= bittimer + 1;										-- Increment timer
				end if;
				
		end case;	
	end if;						 
end process;

-- Calculate parity bit
rx_parity_bit(0) <= parity_type; 									-- Initialize with the chosen parity type
GENERATE_parity  : for k in 0 to 7 generate
	rx_parity_bit(k+1) <= rx_parity_bit(k) xor rx_data_reg(k+1);	-- XOR to calculate parity
end generate;

-- Check for parity error
parity_error <= rx_parity_bit (8) xor rx_data_reg (9); 				-- Compare calculated and received parity bits.

-- Assign output signals
rx_error <= rx_error_s; 											-- Error signal
rx_data_out	 <= rx_data_reg( 8 downto 1); 							-- Data output
rx_done_tick <= rx_done_tick_s;									-- Done tick output
end Behavioral;


