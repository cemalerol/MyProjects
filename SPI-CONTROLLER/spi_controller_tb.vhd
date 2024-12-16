library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity spi_controller_tb is
generic ( 
	c_clkfreq 	: integer 	:= 10_000_000; 	-- 10 MHz clock frequency
	c_sclkfreq 	: integer 	:= 1_000_000;  	-- 1 MHz SPI clock frequency
	c_pol 		: std_logic := '0';         		-- SPI clock polarity
	c_pha 		: std_logic := '0'         		-- SPI clock phase
);
end spi_controller_tb;

architecture Behavioral of spi_controller_tb is
signal  clk      		: STD_LOGIC;              				-- 10 MHz clock signal
signal  reset    		: STD_LOGIC;              				-- Active-high reset signal
signal  data_in  		: STD_LOGIC_VECTOR(31 downto 0); 	-- 32-bit input data to SPI controller
signal  data_out 		:  STD_LOGIC_VECTOR(31 downto 0); 	-- 32-bit output data from SPI controller
signal  ready    		:  STD_LOGIC;              				-- If the last operation is completed meaning that DATA_OUT is valid
signal sdio      		: std_logic := 'Z';        			-- SPI data in/out signal (tri-state)
signal  sclk_o    		:   STD_LOGIC;             				-- SPI clock output (1 MHz)
signal  csb      		:   STD_LOGIC;             				-- Chip select (active low)

constant c_clk_period : time := 100ns; 		 			-- Clock period for 10 MHz

signal spiWrite  	: std_logic := '0';         				-- Control signal to start SPI write operation
signal spiWriteDone	: std_logic := '0';         			-- Signal to indicate SPI write operation is complete
signal SPISIGNAL 	: std_logic_vector (31 downto 0) := (others => '0');  -- 32-bit data signal for SPI transfer

-- Component instantiation for the SPI controller
component spi_controller is
generic ( 
	c_clkfreq 	: integer 	:= 10_000_000; 		 	-- Clock frequency for the SPI controller
	c_sclkfreq 	: integer 	:= 1_000_000;  			-- SPI clock frequency
	c_pol 		: std_logic := '0';         				-- SPI clock polarity
	c_pha 		: std_logic := '0'          				-- SPI clock phase
);
Port (
        clk      		: in  STD_LOGIC;          					-- Input clock (10 MHz)
        reset    		: in  STD_LOGIC;          					-- Active-high reset signal
        data_in  		: in  STD_LOGIC_VECTOR(31 downto 0); 	-- 32-bit input data
        data_out 	: out STD_LOGIC_VECTOR(31 downto 0); 	-- 32-bit output data
        ready    		: out STD_LOGIC;          					-- Ready signal indicating SPI transaction is complete
        sdio     		: inout  STD_LOGIC;       				-- SPI data in/out
        sclk_o    		: out  STD_LOGIC;         					-- SPI clock output (1 MHz)
        csb      		: out  STD_LOGIC          					-- Chip select (active low)
    );
end component;

begin

-- Instantiate the SPI controller module
UUT :  spi_controller
generic map ( 
	c_clkfreq 	=> c_clkfreq 	,  	-- Map clock frequency
	c_sclkfreq 	=> c_sclkfreq ,    		-- Map SPI clock frequency
	c_pol 		=> c_pol	,       		-- Map clock polarity
	c_pha 		=> c_pha            		-- Map clock phase
)
Port map (
        clk      		=>  clk      	,  		-- Connect clock signal
        reset    		=>  reset    	,  		-- Connect reset signal
        data_in  		=>  data_in  	,  		-- Connect input data
        data_out 	=>  data_out  ,  		 -- Connect output data
        ready    		=>  ready    	,  		-- Connect ready signal
        sdio     		=>  sdio     	,  		-- Connect SPI data signal
        sclk_o    		=>  sclk_o     	,  		-- Connect SPI clock output
        csb      		=>  csb         			-- Connect chip select signal
);

-- Clock generation process (10 MHz clock)
clk_process : process
begin
clk <= '0' ;                      			-- Set clock low
wait for c_clk_period/2;             	-- Wait for half of the clock period
clk <= '1';                        			-- Set clock high
wait for c_clk_period/2;             	-- Wait for half of the clock period
end process clk_process;

-- SPI write process to transfer data over SPI
SPIWRITE_P : process begin
	wait until rising_edge (spiWrite);   	-- Wait for the signal to start SPI write

	sdio<= SPISIGNAL(31);                		-- Assign first bit of SPI signal to SDIO
	wait until falling_edge(sclk_o);     	-- Wait for falling edge of SPI clock
		sdio<= SPISIGNAL(30);            		-- Assign next bit to SDIO
	wait until falling_edge(sclk_o);     	-- Repeat the process for all bits
		sdio<= SPISIGNAL(29);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(28);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(27);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(26);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(25);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(24);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(23);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(22);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(21);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(20);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(19);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(18);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(17);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(16);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(15);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(14);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(13);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(12);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(11);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(10);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(9);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(8);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(7);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(6);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(5);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(4);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(3);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(2);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(1);
	wait until falling_edge(sclk_o);
		sdio<= SPISIGNAL(0);            		-- Send the last bit

	wait until rising_edge(sclk_o);     	-- Wait for rising edge of SPI clock
		sdio <= 'Z';                   				-- Set SDIO to high impedance (tri-state)

	spiWriteDone <= '1';                			-- Indicate that the SPI write is done
	wait for 1ps;
	spiWriteDone <= '0';                			-- Reset the done signal
	
end process;

-- Stimulus process for test vectors
stim_proc: process
begin
         -- Activate reset signal
         reset <= '1';                      
         wait for c_clk_period * 10;           	-- Hold reset for 10 clock periods
         reset <= '0';                       			-- Release reset
         wait for c_clk_period * 10;
	
	--WRITE OPERATION - Failed because the control bit is low.
	data_in <= "00100101001001001010100001010100";  		-- Load input data (32-bit)
	wait for 32.2 us;

	--WRITE OPERATION
	data_in <= "00100101001001001010100001010101";  		-- Load input data (32-bit)
	wait until rising_edge(ready);    						-- Wait for SPI ready signal
	
	--READ OPERATION
	data_in <= "10000000010001000000100000000101";  		-- Load new input data
	wait until falling_edge(csb);           					-- Wait for chip select to go low
	SPISIGNAL <= "10101001010101001100100100100101";  	-- Set data to be sent via SPI
	spiWrite <= '1';                       							-- Trigger SPI write
	wait until rising_edge(spiWriteDone);   				-- Wait until SPI write is done
	spiWrite <= '0';                       							-- Reset SPI write trigger
	wait until rising_edge(ready);          					-- Wait for SPI ready signal
	
	--READ OPERATION - Failed because the control bit is low.
	data_in <= "10000000010001000000100000000100";  		-- Load new input data
	wait for 31.7 us;
	
	--WRITE OPERATION
	data_in <= "00100101001001001010100001010101";  		-- Load another input data
	wait until rising_edge(ready);       					-- Wait for SPI ready signal
	
	--READ OPERATION
	data_in <= "10011100010001001110100000000101";  		-- Load new input data
	wait until falling_edge(csb);						-- Wait for chip select to go low
	SPISIGNAL <= "00001101000101001000110100100101";		-- Set data to be sent via SPI
	spiWrite <= '1';										-- Trigger SPI write
         wait until rising_edge(spiWriteDone);				-- Wait until SPI write is done
         spiWrite <= '0';										-- Reset SPI write trigger
	
	--READ OPERATION
	wait until rising_edge(ready);						-- Wait for SPI ready signal
	data_in <= "10000000010001000000100000000101";   		-- Load new input data
	wait until falling_edge(sclk_o);						-- Wait for the falling edge of the SPI clock signal
	SPISIGNAL <= "10101001010101001100100100100101";		-- Set data to be sent via SPI
	spiWrite <= '1';										-- Trigger SPI write
	wait until rising_edge(spiWriteDone);				-- Wait until SPI write is done
	spiWrite <= '0';	 									-- Reset SPI write trigger
	
	--WRITE OPERATION
	wait until rising_edge(ready);						-- Wait for SPI ready signal
	data_in <= "01110110100001001010100001010101";                -- Load another input data
	wait until rising_edge(ready);                                                  -- Wait for SPI ready signal
	
	--WRITE OPERATION													
	data_in <= "00000010101001001010100001010101";  		-- Load another input data		
	wait until rising_edge(ready);                                                  -- Wait for SPI ready signal
	                                                                                                                                  
	wait for 40 us;
        assert false	-- Force the simulation to stop (simulation ends here)
	report "Test Completed" -- Output the message
	severity failure;
end process;

end Behavioral;

