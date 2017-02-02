
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity mc is

generic 
	(
		CONTROLBUS 	: natural := 1576;	-- Control BUS width
		TXDELAY		: natural := 869;
		RESERVEDC	: natural := 112;	-- Control BUS Reserved bits 
		SIS 			: natural := 304;	-- Synaptic inputs
		READBACKBUS	: natural := 32	-- Readback BUS width
	);

port (	
	clk				: IN std_logic; -- 50 MHz clock
	reset				: IN std_logic; -- sync reset
	spiInReady		: IN std_logic; -- SPI
	spiIn				: IN std_logic_vector (7 downto 0); -- SPI
	sbIn				: IN std_logic_vector (19 downto 0); -- SB input
	spiBusy			: IN std_logic;
	q					: IN std_logic_vector(7 downto 0);
	sendSpike		: IN std_logic;
	readBckBus		: IN std_logic_vector (READBACKBUS-1 downto 0); -- N/M model
	busy				: IN std_logic; -- N/M model
	spiOutReady		: OUT std_logic; -- SPI
	spiOut			: OUT std_logic_vector (7 downto 0); -- SPI
	resetTri			: OUT std_logic;
	raddr				: OUT std_logic_vector(15 downto 0);
	waddr				: OUT std_logic_vector(15 downto 0);
	data				: OUT std_logic_vector(7 downto 0);
	we					: OUT std_logic;
	runStep			: OUT std_logic; -- N/M model
	restoreState	: OUT std_logic; -- N/M model
	contBus			: OUT std_logic_vector (CONTROLBUS+RESERVEDC+SIS-1 downto 0) -- N/M model
	);
end mc;

-- architecture body --
architecture mc_arch of mc is
	constant	id					: std_logic_vector(3 downto 0) := "0001";	
	signal instruction 		: std_logic_vector(7 downto 0) := (others => '0');
	signal writeOp				: std_logic_vector(95 downto 0) := (others => '0');
	signal protWriteOp		: std_logic_vector(111 downto 0) := (others => '0');
	signal spikeTrain			: std_logic_vector(303 downto 0) := (others => '0');
	signal mapSB				: std_logic_vector(303 downto 0) := (others => '0');
	signal netTopology		: std_logic_vector(303 downto 0) := (others => '0');
	signal err					: std_logic_vector(7 downto 0) := (others => '0');
	signal err_flag			: std_logic :='0';
	signal resetTrigger_aux	: std_logic :='0';
	signal restoreState_aux	: std_logic :='0';
	signal conf_flags			: std_logic_vector(7 downto 0) := (others => '0');
	signal runStep_aux		: std_logic :='0';
	signal writeType			: std_logic :='0';
	signal payload				: natural;
	signal timestamp			: std_logic_vector(63 downto 0) := (others => '0');
	signal contBus_aux		: std_logic_vector (CONTROLBUS-1 downto 0); -- N/M model
	signal readBuffer			: std_logic_vector(39 downto 0) := (others => '0');
	signal read_flag			: std_logic :='0';
	signal readOp				: std_logic_vector(63 downto 0) := (others => '0');
	signal readType			: std_logic :='0';
	signal queueProc			: integer :=0;
	signal busy_flag			: std_logic := '0';
	signal ct					: natural :=0;
	signal waddr_aux			: std_logic_vector(15 downto 0) := (others => '0');
	signal raddr_aux			: std_logic_vector(15 downto 0) := (others => '0');
	signal we_aux				: std_logic := '0';
	signal spiOut_aux			: std_logic_vector(7 downto 0) := (others => '0');
	signal spiOutReady_aux	: std_logic := '0';
	signal data_aux			: std_logic_vector(7 downto 0):= (others => '0');
	signal payload_flag		: std_logic := '0';
	signal spk_flag			: std_logic :='1';
	signal spkBuff				: std_logic_vector(7 downto 0) := (others => '0');
	signal counter				: natural :=0;
	signal count 				: natural :=0;
	signal baseAdd				: natural range 0 to CONTROLBUS-1 :=0;
	signal size					: natural range 0 to 31 :=0;

BEGIN


wrapper: process(clk, reset, read_flag, readBuffer)
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			waddr_aux<= (others => '0');
			data<= (others => '0');
			we_aux <='0';
			busy_flag<='0';
			ct<=0;
			spk_flag<='0';
			spkBuff<=(others => '0');
			data_aux<=(others => '0');
		else
			if busy='1' and busy_flag='0' then
				busy_flag<='1';
			elsif busy='0' and busy_flag='1' then
				busy_flag<='0';
				spkBuff<="011"&id&sendSpike;
				spk_flag<='1';
			else
				-- nothing happens
			end if;
			if read_flag='1' and ct=0 and we_aux='0' and spk_flag='0' then
				data_aux<=readBuffer (39 downto 32);
				ct<=ct+1;
				we_aux<='1';
			elsif ct>0 and ct<5 and read_flag='1' and spk_flag='0' then
				if to_integer(unsigned(waddr_aux))+1>511 then
					waddr_aux<=(others =>'0');
				else
					waddr_aux<=waddr_aux+1;
				end if;
				data_aux<=readBuffer(39 - (ct-1)*8 downto 32-(ct-1)*8);
				ct<=ct+1;
				
			elsif ct = 5 then
				ct<=0;
				we_aux<='0';

			else
				-- nothing happens
			end if;
			
			if spk_flag = '1' and we_aux='0' and read_flag='0' and ct=0 then
				data_aux<=spkBuff;
				we_aux<='1';
				ct<=ct+1;
			elsif ct=1 and read_flag='0' and spk_flag='1'then
				we_aux<='0';
				spk_flag<='0';
				if to_integer(unsigned(waddr_aux))+1>511 then
					waddr_aux<=(others =>'0');
				else
					waddr_aux<=waddr_aux+1;
				end if;
				ct<=0;
			else
				-- nothing happens
			end if;
		end if;
	-- write data to ports
	data<=data_aux;
	we<=we_aux;
	waddr<=waddr_aux;
	else
		--nothing happens
	end if;
end process;

dispatcher: process(clk, reset, waddr_aux)
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			raddr_aux<= (others => '0');
			queueProc<=0;
			counter<=0;
			spiOut_aux<=(others =>'0');
			spiOutReady_aux<='0';
		else
			if raddr_aux<waddr_aux then
				queueProc<= to_integer(unsigned(waddr_aux-raddr_aux));
			elsif raddr_aux>waddr_aux then
				queueProc<= 512-to_integer(unsigned(raddr_aux-waddr_aux));
			else
				queueProc<=0;
			end if;
			
			if counter=0 and raddr_aux/=waddr_aux and spiBusy='0' then
				spiOut_aux<=q;
				spiOutReady_aux<='1';
				counter<=counter+1;
			elsif counter=1 then
				if raddr_aux<511 and raddr_aux/=waddr_aux then 
					raddr_aux<=raddr_aux+1;
				else
					raddr_aux<=(others =>'0');
				end if;
				spiOutReady_aux<='0';
				counter<=counter+1;
			elsif counter>1 and counter<TXDELAY*20 then
				counter<=counter+1;
			elsif counter=TXDELAY*20 then
				counter<=0;
			else
				-- nothing happens
			end if;
		end if;
		-- write to output ports
		raddr<=raddr_aux;
		spiOut<=spiOut_aux;
		spiOutReady<=spiOutReady_aux;
	else
		--nothing happens
	end if;
end process;

spiController: process(clk, reset, queueProc)
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			count<=0;
			instruction<=(others => '0');
			resetTrigger_aux	<='0';
			restoreState_aux<='0';
			conf_flags<=(others =>'0');
			err<=(others => '0');
			spikeTrain<=(others => '0');
			err_flag<='0';
			runStep_aux<='0';
			payload<=0;
			writeOp<=(others => '0');
			protWriteOp<=(others =>'0');
			writeType<='0';
			readOp<=(others => '0');
			readType<='0';
			contBus_aux<=(others => '0');
			readBuffer<=(others =>'0');
			read_flag<='0';
			payload_flag<='0';
			baseAdd<=0;
			size<=0;
			conf_flags<=(others => '0');
		else
			
			if spiInReady='1' and count=0 and spiIn(4 downto 1)=id then
				count<=count+1;
				if spiIn(7 downto 5) = "000" then -- resetFPGA
					instruction(0)<='1';
					payload<=0;
					payload_flag<='1';
				elsif spiIn(7 downto 5) = "001" then -- restoreState
					instruction(1)<='1';
					payload<=0;
					payload_flag<='1';
				elsif spiIn(7 downto 5) = "010" then -- runStep
						instruction(2)<='1';
						payload<=37;
						payload_flag<='0';
				elsif spiIn(7 downto 5) = "110" then -- write
					instruction(5)<='1';
					if spiIn(0)='1' then
						writeType<='1';
						payload<=13;
						payload_flag<='0';
					else
						writeType<='0';
						payload<=11;
						payload_flag<='0';
					end if;
				elsif spiIn(7 downto 5) = "111" then -- read
					instruction(6)<='1';
					payload<=7;
					payload_flag<='0';
				else -- others
						instruction(7)<='1';
						payload<=0;
						payload_flag<='1';
				end if;
			else
				-- nothing happens
			end if;
			
			if spiInReady='1' and count>0 and payload_flag='0' then
				if payload>0 then
					payload<=payload-1;
				else
					payload_flag<='1';
					if instruction(5)='1' and writeType='0' then -- write
						baseAdd<=to_integer(unsigned(writeOp(95 downto 64)));
						size<=to_integer(unsigned(writeOp(63 downto 32)))-to_integer(unsigned(writeOp(95 downto 64)));
						conf_flags(4)<='1';
					elsif instruction(6)='1' and readType='0' then -- read
						baseAdd<= to_integer(unsigned(readOp(63 downto 32)));
						size<= to_integer(unsigned(readOp(31 downto 8)&spiIn))-to_integer(unsigned(readOp(63 downto 32)));
					else
						-- nothing happens
					end if;
				end if;
				if instruction(2)='1' then -- runStep
					spikeTrain(((payload*8)+7) downto (payload*8))<=spiIn;
				
				elsif instruction(5)='1' then -- write
					if writeType='0' then
						writeOp(((payload*8)+7) downto (payload*8))<=spiIn;
					else
						protWriteOp(((payload*8)+7) downto (payload*8))<=spiIn;
					end if;
				
				elsif instruction(6)='1' then -- read
					readOp(((payload*8)+7) downto (payload*8))<=spiIn;
				else
					-- generate error!
				end if;
				
			elsif count>0 and payload_flag='1' and payload=0 then
				if instruction(0)='1' then -- resetFPGA
					resetTrigger_aux<='1';
				elsif instruction(1)='1' then -- restoreState
					if conf_flags(4)='1' and conf_flags(3)='1' then
						conf_flags(0)<='1';
						restoreState_aux<='1';
					else
						err_flag<='1';
						err<=x"01"; -- Error cannot restore a state before configuring
					end if;
				elsif instruction(2)='1' and queueProc<490 then -- runStep
					if conf_flags(4)='1' and conf_flags(3)='1' and conf_flags(0)='1'  then
						runStep_aux<='1';
						timestamp<=timestamp+1;
						conf_flags(1)<='1';
					else
--						err_flag<='1';
--						err<=x"03"; -- Error a run step can only be processed after configuring the simulation
					end if;
				elsif instruction(5)='1' then -- write
					if writeType='1' then
						timestamp<=protWriteOp(63 downto 0);
						writeType<='0';
						conf_flags(3)<='1';
					else
						--Item input BUS address LSB: XX-XX-XX-XX //size of 32 bits
						--Item input BUS address MSB: XX-XX-XX-XX //size of 32 bits
						if baseAdd<CONTROLBUS and baseAdd+size<CONTROLBUS then
							if size=7 then
								contBus_aux(baseAdd+7 downto baseAdd)<= writeOp (7 downto 0);
								conf_flags(4)<='1';
--								iterator:=iterator+size+1;
							elsif size=15 then
								contBus_aux(baseAdd+15 downto baseAdd)<= writeOp (15 downto 0);
								conf_flags(4)<='1';
--								iterator:=iterator+size+1;
							elsif size=23 then
								contBus_aux(baseAdd+23 downto baseAdd)<= writeOp (23 downto 0);
								conf_flags(4)<='1';
--								iterator:=iterator+size+1;
							elsif size=31 then
								contBus_aux(baseAdd+31 downto baseAdd)<= writeOp (31 downto 0);
								conf_flags(4)<='1';
--								iterator:=iterator+size+1;
							else
								err_flag<='1';
								err<=x"04"; -- Error incorrect data size
							end if;
						else
							err_flag<='1';
							err<=x"09"; -- Error invalid address
						end if;
						
					end if;
				elsif instruction(6)='1' then -- read
					--Item input BUS address LSB: XX-XX-XX-XX //size of 32 bits
					--Item input BUS address MSB: XX-XX-XX-XX //size of 32 bits
					if baseAdd<READBACKBUS and baseAdd+size<READBACKBUS then
						if size=7 then
							readBuffer(7 downto 0)<=readBckBus(baseAdd+7 downto baseAdd);
							readBuffer(31 downto 8)<= (others =>'0');
							readBuffer(39 downto 32)<= "111"&id&'0';
							read_flag<='1';
						elsif size=15 then
							readBuffer(15 downto 0)<=readBckBus(baseAdd+15 downto baseAdd);
							readBuffer(31 downto 16)<= (others =>'0');
							readBuffer(39 downto 32)<= "111"&id&'0';
							read_flag<='1';
						elsif size=23 then
							readBuffer(23 downto 0)<=readBckBus(baseAdd+23 downto baseAdd);
							readBuffer(31 downto 24)<= (others =>'0');
							readBuffer(39 downto 32)<= "111"&id&'0';
							read_flag<='1';
						elsif size=31 then
							readBuffer(31 downto 0)<=readBckBus(baseAdd+31 downto baseAdd);
							readBuffer(39 downto 32)<= "111"&id&'0';
							read_flag<='1';
						else
							err_flag<='1';
							err<=x"04"; -- Error incorrect data size
						end if;
					else
						err_flag<='1';
						err<=x"09"; -- Error invalid address
					end if;
				elsif instruction(7)='1' then -- others
					err_flag<='1';
					err<=x"FF"; -- Error cannot receive a sendSpike command from the MCS
				else
					-- last state
				end if;
				instruction<=(others =>'0');
				count<=0;
			else
				-- TO DO
			end if;
			if resetTrigger_aux='1' then
				resetTrigger_aux<='0';
			else
				-- nothing happens
			end if;
			if restoreState_aux='1' then
				restoreState_aux<='0';
			else
				-- nothing happens
			end if;
			if runStep_aux='1' then
				runStep_aux<='0';
				conf_flags(1)<='0';
			else
				--nothing happens
			end if;
			if read_flag='1' then
				read_flag<='0';
			else
				--nothing happens
			end if;
		end if;
		-- write to output ports
		restoreState<=restoreState_aux;
		resetTri<=resetTrigger_aux;
		runStep<=runStep_aux;
		contBus(SIS-1 downto 0)<=spikeTrain;
		contBus(SIS+RESERVEDC-1 downto SIS)<=protWriteOp(111 downto 64)&timestamp;
		contBus(SIS+RESERVEDC+CONTROLBUS-1 downto SIS+RESERVEDC) <=contBus_aux;
	else
		--nothing happens
	end if;
end process;
end mc_arch;
