library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration of SPI controller
entity spi_controller is
generic ( 
	c_clkfreq 	: integer 	:= 10_000_000; 			-- Clock frequency of the system (10 MHz)
	c_sclkfreq 	: integer 	:= 1_000_000; 			-- SPI clock frequency (1 MHz)
	c_pol 		: std_logic := '0'; 					-- Clock polarity (idle state of clock)
	c_pha 		: std_logic := '0'					-- Clock phase (sampling edge)
);
Port (
        clk      		: in  STD_LOGIC;              				-- 10 MHz system clock input
        reset    		: in  STD_LOGIC;              				-- Active-high reset signal
        data_in  		: in  STD_LOGIC_VECTOR(31 downto 0); 	-- 32-bit data input to SPI controller
        data_out 	: out STD_LOGIC_VECTOR(31 downto 0); 	-- 32-bit data output from SPI controller to the logic signal
        ready    		: out  STD_LOGIC;              				-- If the last operation is completed meaning that DATA_OUT is valid
        sdio     		: inout  STD_LOGIC;           				-- SPI data input/output (tri-state)
        sclk_o     	: out  STD_LOGIC;             				-- SPI clock output (SCLK)
        csb      		: out  STD_LOGIC              				-- Chip select output (active-low)
    );
end spi_controller;

architecture Behavioral of spi_controller is
-- Constants
constant c_edgecntrtimelimit : integer := c_clkfreq/(c_sclkfreq*2); -- Time limit to generate SCLK based on clock ratio

-- Signals
signal edgecntr : integer range 0 to c_edgecntrtimelimit := 0; 			-- Counter for SCLK generation
signal prev_data_in : STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); 	-- Previous data input signal for comparison
signal new_data : std_logic := '0'; 									 -- Signal to track if new data is available

-- SPI signals and control signals
signal bit_count : integer := 0;     									-- Counter for transmitted/received bits
signal shift_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');  -- Shift register for data transfer

signal sclk_en : std_logic := '0'; 		-- SCLK enable signal
signal sclk : std_logic := '0'; 		-- SPI clock signal
signal sclk_prev: std_logic := '0'; 	-- Previous value of SCLK for edge detection
signal sclk_rise : std_logic := '0'; 	-- Signal indicating rising edge of SCLK
signal sclk_fall: std_logic := '0'; 	-- Signal indicating falling edge of SCLK
signal pol_phase : std_logic_vector ( 1 downto 0 ) := (others => '0'); -- Combined polarity and phase signals 
signal mosi_en : std_logic := '0'; 		-- Enable signal for MOSI (Sampling write mode)
signal miso_en : std_logic := '0'; 		-- Enable signal for MISO (Sampling read mode)
signal sdio_out    : std_logic := 'Z';     -- Helper signal for SDIO output
signal sdio_in     : std_logic := '0';      -- Helper signal for SDIO input

-- State declarations for the FSM
type state_type is (S_IDLE, S_WRITE, S_READ, S_WRITE_FINISH, S_READ_FINISH); -- SPI states
signal state : state_type := S_IDLE;   										  -- Initial state is idle

begin
-- SDIO control logic (handles inout direction)
sdio <= sdio_out when (state = S_WRITE) else 'Z';  	-- SDIO behaves as output during write, otherwise high impedance
sdio_in <= sdio when (state = S_READ) else 'Z';    	-- SDIO behaves as input during read, otherwise high impedance
-- Combine polarity and phase into one signal for easy control
pol_phase <= c_pol & c_pha; 						-- For SPI modes. In this code we use Mod 0(CPOL=0, CPHA=0).

-- Sampling enable process based on polarity and phase
P_SAMPLE_EN : process (pol_phase, sclk_fall, sclk_rise) begin
	case pol_phase is
		when "00" =>
			mosi_en <= sclk_fall; -- MOSI samples on falling edge
			miso_en <= sclk_rise; -- MISO samples on rising edge
		when "01" =>
			mosi_en <= sclk_rise; -- MOSI samples on rising edge
			miso_en <= sclk_fall; -- MISO samples on falling edge
		when "10" =>
			mosi_en <= sclk_rise; -- MOSI samples on rising edge
			miso_en <= sclk_fall; -- MISO samples on falling edge
		when "11" =>
			mosi_en <= sclk_fall; -- MOSI samples on falling edge
			miso_en <= sclk_rise; -- MISO samples on rising edge
		when others =>
	end case;
end process P_SAMPLE_EN;

-- Edge detection process for SCLK
P_RISEFALL_DETECT : process (sclk, sclk_prev) begin
	if(sclk = '1' and sclk_prev = '0' ) then
		sclk_rise <= '1';  -- Detect rising edge of SCLK
	else
		sclk_rise <= '0';  -- No rising edge
	end if;
	
	if(sclk = '0' and sclk_prev = '1' ) then
		sclk_fall <= '1';  -- Detect falling edge of SCLK
	else
		sclk_fall <= '0';  -- No falling edge
	end if;
end process P_RISEFALL_DETECT;

-- SCLK generation process
P_SCLK_GEN : process (clk) begin
	if(rising_edge(clk)) then
		if(sclk_en = '1') then
			if (edgecntr = c_edgecntrtimelimit-1) then
				sclk <= not sclk;  		-- Toggle SCLK when counter reaches the limit
				edgecntr <= 0;     			-- Reset the counter
			else
				edgecntr <= edgecntr + 1; 	-- Increment the counter
			end if;
		else
			edgecntr <= 0; 				-- Reset counter if SCLK is disabled
			if(c_pol = '0') then
				sclk <= '0'; 				-- Set SCLK to idle state based on polarity
			else
				sclk <= '1'; 				-- Set SCLK to idle state based on polarity
			end if;
		end if;
	end if;
end process P_SCLK_GEN;

-- Check for new data
process(clk, reset)
begin
	if (reset = '1') then
		prev_data_in <= (others => '0');
		new_data <= '0';
	elsif rising_edge(clk) then
		if (data_in /= prev_data_in) then   -- Compare data_in with previous value
			prev_data_in <= data_in;        	-- Update previous data with current one
			new_data <= '1';                		-- Mark new data detected
		else
			new_data <= '0';                		-- No new data
		end if;
	end if;
end process;

-- Main FSM process
process(clk, reset)
begin
	if (reset = '1')then
            -- Reset state
		state <= S_IDLE;  			-- Return to idle state
		sclk_prev <= '0'; 			-- Reset previous clock value
		data_out <= (others => '0'); 	-- Clear output data
		sclk_o <= '0';    				-- Reset SPI clock
		sdio_out <= 'Z';  			-- Set SDIO to high impedance
		bit_count <= 0;   				-- Reset bit counter
		shift_reg <= (others => '0'); 	-- Clear shift register
		ready <= '0';     				-- Set ready signal low
		csb <= '1';       				-- Deactivate chip select (active low)
		sclk_en <= '0';   				-- Disable SCLK generation
	elsif rising_edge(clk) then
		sclk_prev <= sclk; 			-- Update previous SCLK value for edge detection
		case state is
			when S_IDLE =>
				ready <= '1';   		-- Indicate that controller is not busy
				csb <= '1';     		-- Chip select is deactivated
				sclk_en <= '0'; 		-- Disable SCLK generation
				bit_count <= 0; 		-- Reset bit counter
				if(c_pol = '0') then
					sclk_o <= '0'; 	-- Set SCLK to idle state based on polarity
				else
					sclk_o <= '1'; 	-- Set SCLK to idle state based on polarity
				end if;
				
				if (data_in(0) = '1' and new_data = '1') then  	-- Check if control bit is set
					ready <= '0';         				  	-- Set ready signal low (start transmission)
					sclk_en <= '1';       				  	-- Enable SCLK generation
					shift_reg <= data_in(31 downto 0);  	-- Load input data into shift register
					bit_count <= 31;      				  	-- Set bit counter to 31 for 32-bit transfer
					if (data_in(31) = '1') then   		  	-- Check R/W bit (1 = read, 0 = write)
						state <= S_READ;  					-- Transition to read state
						csb <= '0';       					-- Activate chip select (active low)
					else
						state <= S_WRITE; 				-- Transition to write state
						csb <= '0';       					-- Activate chip select (active low)
					end if;
				else
					shift_reg <= (others => '0'); 			-- Clear shift register
					state <= S_IDLE;   					-- Remain in idle state
				end if;
				

			when S_WRITE =>
				if (bit_count >= 0)then	 
					sclk_o <= sclk;							-- Output SCLK signal
					if(mosi_en = '1') then        				-- If MOSI is enabled
						sdio_out <= shift_reg(bit_count);	-- Output data bit to SDIO
						bit_count <= bit_count - 1;			-- Decrement bit counter
					end if;
				else
					sdio_out <= 'Z';		-- Set the `sdio_out` signal to high-impedance state ('Z') to effectively disconnect it from the output (tri-state behavior)
					csb <= '1';   			-- Deactivate chip select (active low)
					ready <= '1'; 		-- Indicate that transmission is complete
					state <= S_IDLE;   	-- Transition back to idle state
				end if;
				
			
			when S_READ =>
				if (bit_count >= 0)then	
					sclk_o <= sclk;						-- Output SCLK signal
					if(miso_en = '1') then 				-- If MISO is enabled
						shift_reg(bit_count) <= sdio_in;	-- Read data bit from SDIO
						bit_count <= bit_count - 1;		-- Decrement bit counter
					end if;
				else
					data_out <= shift_reg;	-- Load received data into output register
					csb <= '1';    				-- Deactivate chip select (active low)
					ready <= '1'; 			-- Indicate that read operation is complete
					state <= S_IDLE;   		-- Transition back to idle state	
				end if;	
			
			when others =>
				state <= S_IDLE;	-- Default case: return to idle state
			
		end case;
	end if;
end process;
end Behavioral;
