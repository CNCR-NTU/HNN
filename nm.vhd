-- Libraries used --

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.fixed_float_types.all;
--!ieee_proposed for fixed point
use ieee.fixed_pkg.all;
--!ieee_proposed for floating point
use ieee.float_pkg.all;

use work.expdecay.all;


entity nm is

generic 
	(
		CONTROLBUS 	: natural := 1576;	-- Control BUS width
		RESERVEDC	: natural := 112;	-- Control BUS Reserved bits 
		SIS 			: natural := 304;	-- Synaptic inputs
		READBACKBUS	: natural := 32;	-- Readback BUS width
		SYNAPSES		: natural :=20
	);


port (clk			: IN std_logic;
		reset			: IN std_logic;
		runStep		: IN std_logic; -- N/M model
		restoreState: IN std_logic; -- N/M model
		contBus		: IN std_logic_vector (CONTROLBUS+RESERVEDC+SIS-1 downto 0); -- N/M model
		sendSpike	: OUT std_logic;
		readBckBus	: OUT std_logic_vector (READBACKBUS-1 downto 0); -- N/M model
		busy			: OUT std_logic -- N/M model
		);
end nm;

-- architecture body --
architecture nm_arch of nm is

-- declaration : constant and signals --

 
--constant v_th:				std_logic_vector (15 downto 0)	:=x"001E";		-- threshold voltage = 30 mV --
type synFloat is array (0 to SYNAPSES-1) of float32;
type synNatural is array (0 to SYNAPSES-1) of natural;
signal 	eSynMap:			std_logic_vector(39 downto 0);
signal	eSyn:				synFloat;
signal 	v_th:				float32;
signal	time_step: 		float32;		
signal	a:					float32;
signal 	b:					float32;
signal	c:					float32;
signal 	d:					float32;
signal	av:				float32;
signal	mr:				float32;	
signal	stimuli:			float32;	
signal	w:					synFloat;
signal	iSyn:				synFloat;
signal	dt:				synNatural;
signal	g_Syn:			synFloat;
signal	gSyn:				synFloat;
signal 	aux1:				float32;
signal 	aux2:				float32;
signal 	aux3:				float32;
signal 	aux4:				float32;
signal 	aux5:				float32;
signal 	aux7:				float32;
signal 	aux8:				float32;
signal 	aux6:				float32;
signal	spike:			std_logic 											:='0';
signal 	count:			natural												:=0;
signal 	syn:				std_logic_vector(19 downto 0)					:= (others => '0');
signal	flag:				std_logic 											:='0';
signal	sflag:			std_logic 											:='0';
signal	readBckBus_aux: std_logic_vector (READBACKBUS-1 downto 0):=(others =>'0');
signal	ct:				natural 												:=0;


begin
		--- process ---
	process 
		variable currentSum : float32;
	begin
		wait until clk'EVENT and clk = '1';
		if reset='1' then
		   -- (C) tonic bursting
			--  a=0.02, b=0.25, c=-50, d=2, v0=-70 w1=2, w2=2
			--testbench
			a<=to_float(0.0,a);
			b<=to_float(0.0,b);
			c<=to_float(0.0,c);
			d<=to_float(0.0,d);
			v_th<=to_float(0.0,aux6);
			stimuli<=to_float(0.0,stimuli);
			av<=to_float(0.0,av); 
			mr<=to_float(0.0,mr);
			ct<=0;
			for I in 0 to SYNAPSES-1 loop
				w(I)<=to_float(0.0,w(I));
				iSyn(I)<=to_float(0.0,iSyn(I));
				dt(I)<=0;
				gSyn(I)<=to_float(0.0,gSyn(I));
				g_Syn(I)<=to_float(0.0,g_Syn(I));
				eSyn(I)<=to_float(0.0,eSyn(I));
			end loop;
			time_step<=to_float(0.0,time_step);
			aux1<=to_float(0.0,aux1);
			aux2<=to_float(0.0,aux2);
			aux3<=to_float(0.0,aux3);
			aux4<=to_float(0.0,aux4);
			aux5<=to_float(0.0,aux5);
			aux6<=to_float(0.0,aux6);
			aux7<=to_float(0.0,aux7);
			aux8<=to_float(0.0,aux8);
			spike<='0';
			flag<='0';
			readBckBus_aux<=(others =>'0');
			syn<=(others => '0');
			sflag<='0';
			currentSum:=to_float(0.0,currentSum);
			esynMap<=(others =>'0');
		else
			
		if restoreState='1' then
			time_step<=to_float(contBus(SIS+95 downto SIS+64),time_step);
			v_th<=to_float(contBus(SIS+RESERVEDC+31 downto SIS+RESERVEDC),v_th);
			a<=to_float(contBus(SIS+RESERVEDC+63 downto SIS+RESERVEDC+32),a);
			b<=to_float(contBus(SIS+RESERVEDC+95 downto SIS+RESERVEDC+64),b);
			c<=to_float(contBus(SIS+RESERVEDC+127 downto SIS+RESERVEDC+96),c);
			d<=to_float(contBus(SIS+RESERVEDC+159 downto SIS+RESERVEDC+128),d);
			av<=to_float(contBus(SIS+RESERVEDC+191 downto SIS+RESERVEDC+160),av);
			mr<=to_float(contBus(SIS+RESERVEDC+223 downto SIS+RESERVEDC+192),mr);
			stimuli<=to_float(contBus(SIS+RESERVEDC+255 downto SIS+RESERVEDC+224),stimuli);
			esynMap<=contBus(SIS+RESERVEDC+295 downto SIS+RESERVEDC+256);
			for I in 0 to SYNAPSES-1 loop
				w(I)<=to_float(contBus(SIS+RESERVEDC+327+(I*32) downto SIS+RESERVEDC+296+(I*32)),w(I));
				g_Syn(I)<=to_float(contBus(SIS+RESERVEDC+967+(I*32) downto SIS+RESERVEDC+936+(I*32)),g_Syn(I));
				iSyn(I)<=to_float(0.0,iSyn(I));
				eSyn(I)<=to_float(0.0,eSyn(I));
				gSyn(I)<=to_float(0.0,gSyn(I));
				dt(I)<=0;
			end loop;
			ct<=0;
			busy<='0';
			sflag<='1';
			flag<='0';
			eSynMap<=(others => '0');
		else
			-- nothing happens
		end if;
		
		if sflag='1' then
			for I in 0 to SYNAPSES-1 loop
				if w(I)<to_float(0.0,w(I)) or w(I)>to_float(0.0,w(I))then
					syn(I)<='1';
				else
					syn(I)<='0';
				end if;
				if eSynMap(I*2+1 downto I*2) = "01" then
					eSyn(I)<=to_float(1.0,eSyn(I));
				elsif eSynMap(I*2+1 downto I*2) = "11" then
					eSyn(I)<=to_float(-1.0,eSyn(I));
				else
					eSyn(I)<=to_float(0.0,eSyn(I));
				end if;
			end loop;
			sflag<='0';
			flag<='1';
		else
			-- nothing happens
		end if;
		
			if count=0 and flag='1' and runStep='1' then
				if spike='1' then
					spike<='0';
				else
					--nothing happens
				end if;
				busy<='1';
				stimuli<=to_float(contBus(SIS+RESERVEDC+255 downto SIS+RESERVEDC+224),stimuli);
				currentSum:=to_float(0.0,currentSum);
				for I in 0 to SYNAPSES-1 loop
					if syn(I)='1' then
						if contBus(I)='1' then
							dt(I)<=0;
						else
							dt(I)<=dt(I)+1; 
						end if;
						
					else
						-- nothing happens
					end if;
				end loop;
				count<=count+1;

			elsif count=1 then
				if ct<SYNAPSES then
					if syn(ct)='1' then
						gSyn(ct)<=g_syn(ct)*CONDUCTANCE(dt(ct));
						iSyn(ct)<=aV*w(ct)-eSyn(ct)*w(ct);
					else
						gSyn(ct)<=to_float(0.0,gSyn(ct));
						iSyn(ct)<=to_float(0.0,iSyn(ct));
					end if;
					ct<=ct+1;
				else
					count<=count+1;
					ct<=0;
				end if;
			
			elsif count=2 then
				if ct<SYNAPSES then
					iSyn(ct)<=iSyn(ct)*gSyn(ct);
					ct<=ct+1;
				else
					count<=count+1;
					ct<=0;
				end if;
			
			elsif count=3 then
				for I in 0 to SYNAPSES-1 loop
					currentSum:=currentSum+iSyn(I);
				end loop;
				count<=count+1;
			
			elsif count=4 then
				aux1<=currentSum+stimuli; --I
				aux2<=time_step*to_float(0.04,aux2); --0.04*dt
				aux3<=av*to_float(5.0,aux3); --5.0*v
				aux4<=a*b; --a*b
				aux5<=a*mr; --a*u
				aux7<=time_step*to_float(140.0,aux7); --140.0*dt
				aux8<=av*av; -- v^2
				aux6<=mr*time_step; --u*dt
				count<=count+1;
			
			elsif count=5 then
				aux1<=time_step*aux1; --I*dt
				aux2<=aux2*aux8; --0.04*v^2*dt
				aux3<=time_step*aux3; --5.0*v*dt
				aux4<=av*aux4;--a*b*v
				count<=count+1;
				
			elsif count=6 then
				count<=count+1;
				av<=av+aux2+aux3+aux7-aux6+aux1; --v + 0.04*v^2*dt+5.0*v*dt+140.0*dt - u*dt+I*dt
			
			elsif count=7 then
				count<=count+1;
				av<=av+aux2+aux3+aux7-aux6+aux1; --v + 0.04*v^2*dt+5.0*v*dt+140.0*dt - u*dt+I*dt
				mr<=mr+aux4-aux5; --mr + a*b*v-a*u
			
			elsif count=8 then
				if av >= v_th then
					readBckBus_aux<=to_slv(v_th);
					av<=c;
					mr<=mr+d;
					spike<='1';
				else
					readBckBus_aux<=to_slv(aV);
				end if;
				count<=0;
				busy<='0';
			else
				-- nothing happens
			end if;
			sendSpike<=spike;
			readBckBus<=readBckBus_aux;
		end if;	
	end process;
end nm_arch;