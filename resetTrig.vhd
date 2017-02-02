LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY resetTrig IS
PORT(	clk	: IN STD_LOGIC;
		resetTri				: IN STD_LOGIC;
		resetBut				: IN STD_LOGIC;
		reset					: OUT STD_LOGIC
		);		
END resetTrig;

ARCHITECTURE Behavior OF resetTrig IS
	signal count	: natural 								:= 0;

BEGIN
	
process
	begin
			wait until clk'event and clk = '1';
			if (resetTri='1' or resetBut= '1') and count=0 then
				count<=count+1;
			elsif count>0 and count < 10 then 
				count<=count+1;
			elsif count=10 then 
				count <= count +1;
				reset<='1';
			elsif count>10 and count < 1747 then 
				count <= count +1;
			elsif count=1747 then
				reset<='0';
				count<=0;	
			else
			end if;
	END PROCESS;	
END Behavior;