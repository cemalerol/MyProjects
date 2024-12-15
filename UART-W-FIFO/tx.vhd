library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tx is
generic ( 
	c_clkfreq 	: integer := 50_000_000;	-- Clock frequency
	baudrate	: integer := 115_200;		-- UART baud rate
	stopbit    	: integer := 1;			-- Number of stop bits.
	parity_type 	: std_logic := '1'		-- '0' for even parity, '1' for odd parity
);
port (
	clk 				: in std_logic ;						-- Clock signal input.
	reset			: in std_logic ;						-- Reset signal input
	tx_data_in		: in std_logic_vector ( 7 downto 0 );	-- Data to be transmitted
	tx_enable		: in std_logic;						--Enable signal to start transmission.
	tx_done_tick	: out std_logic;						-- Signal indicating transmission completion.
	tx_data_out 		: out std_logic						-- UART serial output.
);
end tx;

architecture Behavioral of tx is
constant c_bittimerlim 	: integer := c_clkfreq/baudrate ;				-- Calculate the bit timer limit based on clock frequency and baud rate
constant c_stopbitlim 	: integer := (c_clkfreq/baudrate)*stopbit;	-- Calculate the stop bit timer limit

signal bittimer : integer range 0 to c_stopbitlim := 0;	-- Timer for bit duration
signal bitcounter : integer range 0 to 255 := 0;			-- Counter for tracking the number of bits transmitted.

signal tx_reg 			: std_logic_vector ( 8 downto 0) := (others => '0');	-- Register to hold the data and parity bit for transmission.
signal tx_parity_bit		: std_logic_vector ( 8 downto 0) := (others => '0');	-- Signal to calculate and hold the parity bit.

type t_state is ( idle_state, load_state, transition_state, start_state, data_state, parity_state, stop_state);-- State machine states
signal state : t_state := idle_state; -- Current state of the FSM


begin
process(clk,reset)
begin	
	if ( reset = '1' ) then				-- Reset all signals to initial values when reset is active.
		tx_data_out <= '1';			-- UART line is idle (high) when not transmitting.
		tx_done_tick <= '0';			-- Clear the done signal.
		bitcounter <= 0 ;
		bittimer <= 0;
		tx_reg <= (others => '0');   	-- Clear the transmission register.
		state <= idle_state;			-- Set the state to idle.
	
	elsif(rising_edge(clk)) then
			case state is
			
				when idle_state => 			-- Idle state: Wait for the enable signal to start transmission.
					tx_data_out <= '1';		-- Keep the UART line idle.
					tx_done_tick <= '0';		-- Ensure the done signal is low.
					bitcounter <= 0 ;			-- Clear the bit counter.
					if(tx_enable = '1' ) then	-- Check if transmission is enabled.
						state <= load_state;	-- Move to the load state.
						tx_data_out <= '0';	-- Send the start bit (low level).					
					else
						state <= idle_state;	-- Remain in idle state if not enabled.
					end if;
				
				when load_state =>					-- Load the input data into the transmission register.
					tx_reg(7 downto 0)<= tx_data_in ;	-- Load the input data.
					state <= transition_state;		-- Move to the transition state.
					
				when transition_state =>				--Prepare the parity bit.
					tx_reg(8) <=  tx_parity_bit(8);	-- Add the parity bit to the register.
					state <= start_state;			-- Move to the start state.
								
				when start_state =>						-- Transmit the start bit and initialize timing.
					if(bittimer = c_bittimerlim-1) then
						state <= data_state;				-- Move to the data state.
						tx_data_out <= tx_reg(0);		-- Transmit the first data bit.
						tx_reg(8) <= tx_reg(0);			-- Shift data bits.
						tx_reg(7 downto 0) <= tx_reg(8 downto 1);
						bittimer <= 0;					-- Reset the bit timer.
					else
						bittimer <= bittimer + 1;			-- Increment the bit timer.
					end if;

				when data_state =>						-- Transmit the data bits one by one.
					if(bitcounter=7)then				-- All data bits transmitted, move to parity state.
						if(bittimer = c_bittimerlim-1) then
							state <= parity_state;		-- Move to parity state.
							bittimer <= 0;				-- Reset the bit timer.
							tx_data_out <= tx_reg(0);	-- Output the last data bit.
							bitcounter <= bitcounter + 1;
						else
							bittimer <= bittimer + 1;		-- Increment the bit timer.
						end if;
					else
					-- Continue transmitting data bits.
						if(bittimer = c_bittimerlim-1) then
							tx_reg(8) <= tx_reg(0);				-- Shift data bits.
							tx_reg(7 downto 0) <= tx_reg(8 downto 1);
							tx_data_out <= tx_reg(0);			-- Output the next data bit.
							bitcounter <= bitcounter + 1;			-- Increment the bit counter.
							bittimer <= 0;						-- Reset the bit timer.
						else
							bittimer <= bittimer + 1;				-- Increment the bit timer.
						end if;
					end if;
				
				when parity_state =>
				-- Transmit the parity bit.
					if(bittimer = c_bittimerlim-1) then
						tx_data_out <= '1';		-- UART line idle after parity bit.
						bitcounter <= 0;			-- Reset the bit counter.
						state <= stop_state;		-- Move to the stop state.
						bittimer <= 0;			-- Reset the bit timer.
					else
						bittimer <= bittimer + 1;	-- Increment the bit timer.
					end if;
				
				when stop_state =>					-- Transmit the stop bit(s).
					if(bittimer = c_stopbitlim-1) then
						state <= idle_state;			-- Return to idle state.
						tx_done_tick <= '1';			-- Indicate transmission completion.
						tx_reg <= (others => '0');	-- Clear the transmission register.
						bittimer <= 0;				-- Reset the bit timer.
					else
						bittimer <= bittimer + 1;		-- Increment the bit timer.
					end if;								
		end case;

	end if;						 
end process;						
					
-- Parity calculation logic.				
tx_parity_bit(0) <= parity_type; 	-- Initialize the parity bit based on the selected parity type.
GENERATE_parity  : for k in 0 to 7 generate
	tx_parity_bit(k+1) <= tx_parity_bit(k) xor tx_reg(k);	-- XOR operation to calculate the parity bit.
end generate;

end Behavioral;					

