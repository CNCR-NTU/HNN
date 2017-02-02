LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

ENTITY receive232 IS

PORT(	clk					: IN STD_LOGIC; -- 100 MHz
		clock_1_8432MHz	: IN	STD_LOGIC;
		reset					: IN	STD_LOGIC;
		RX232					: IN	STD_LOGIC;
		data_ready			: OUT std_logic;
		result				: OUT	STD_LOGIC_VECTOR (7 downto 0)
		); 
		
END receive232;

ARCHITECTURE Behavior OF receive232 IS
	constant n 			: natural := 16;
	constant DELAY 	: natural := 56; -- using a reference clock of 50MHz
	signal count 		: std_logic_vector(7 downto 0) := "00000000";
	signal fifo			: std_logic_vector(7 downto 0) := "00000000";
	signal i				: natural := 0;
	signal delta		: natural := 0;
	signal check		: natural := 0;
	signal draux		: STD_LOGIC := '0';
	signal txFlag		: STD_LOGIC := '0';
	signal delayCount	: natural :=0;
	
BEGIN
Rx : process (clock_1_8432MHz, reset)
	BEGIN
		if rising_edge(clock_1_8432MHz) then
			if (reset='1') then
				i<=0;
				fifo<="00000000";
				count<="00000000";
				check<=0;
				delta<=0;
				txFlag<='0';
			else
			--////////////// GET VALUES /////////////////////
			-- 1 Start bit | 8 bits | 1 Stop bit
			-- f0=115.200 Khz, fs=16*f0
				if RX232='0' and count = 0 then
					count<=count+1;
					txFlag<='0';
				
				elsif count > 0 and count < 7 then
					count<=count+1;

				elsif RX232='0' and count = 7 then
					count<=count+1;
					check<=check+1;
				
				elsif RX232='1' and count = 7 then
					count<=count+1;
				
				elsif count > 7 and count < 9 then
					count<=count+1;
				
				elsif RX232='0' and count = 9 then
					count<=count+1;
					check<=check+1;
				elsif RX232='1' and count = 9 then
					count<=count+1;
				
				elsif count > 9 and count < 11 then
					count<=count+1;
				
				elsif RX232='0' and count = 11 then
					count<=count+1;
					check<=check+1;
				elsif RX232='1' and count = 11 then
					count<=count+1;
				
				elsif count = 12 then
					count<=count+1;
					if check=1 or check=2 then 
						delta<=0;
						check<=0;
					else
						delta<=2;
						check<=0;
					end if;
				
				elsif count > 12 and count < ((n)+delta) and (i=0) then
					count<=count+1;
				
				elsif count=(n+delta) then
					count<=count+1;
					fifo(i)<=RX232;
					i<=i+1;
				
				elsif count > ((i)*(n)+delta) and count < ((i+1)*(n)+delta) and  (i<9) then
					count<=count+1;
				
				elsif count = ((i+1)*(n)+delta) and  (i<8) then
					fifo(i) <=RX232;
					count<=count+1;
					i<=i+1;
				
				elsif count = ((i+1)*(n)+delta) and (i=8) then
					txFlag<='1';
					count<=count+1;
					i<=i+1;
				
				elsif count = (i*(n)+delta+1) and (i=9) then
					txFlag<='0';
					count<="00000000";
					i<=0;
					delta<=0;
					--fifo<="00000000";
				else
				end if;
			end if;
			result <= fifo;
		else
			-- nothing happens
		end if;
	end process;

	
Tx : process (clk, reset, txFlag)
	begin
		if rising_edge(clk) then
			if reset='1' then
				draux<='0';
				delayCount<=0;
			else
				if txFlag='1' and delayCount=0 then
					draux<='1';
					delayCount<=DELAY;
				else
					-- nothing happens
				end if;
					
			end if;
			
			if delayCount>0 then
				delayCount<=delayCount-1;
				draux<='0';
			else
				-- nothing happens
			end if;
			data_ready <= draux;
		else
			-- nothing happens
		end if;
	end process;
END Behavior;