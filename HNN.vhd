-- Copyright (C) 1991-2016 Altera Corporation. All rights reserved.
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, the Altera Quartus Prime License Agreement,
-- the Altera MegaCore Function License Agreement, or other 
-- applicable license agreement, including, without limitation, 
-- that your use is for the sole purpose of programming logic 
-- devices manufactured by Altera and sold by Altera or its 
-- authorized distributors.  Please refer to the applicable 
-- agreement for further details.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 15.1.2 Build 193 02/01/2016 SJ Standard Edition"
-- CREATED		"Thu Sep  8 14:56:02 2016"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY HNN IS 
	PORT
	(
		RX232 :  IN  STD_LOGIC;
		CLK50 :  IN  STD_LOGIC;
		PB :  IN  STD_LOGIC_VECTOR(0 TO 0);
		sbIn :  IN  STD_LOGIC_VECTOR(19 DOWNTO 0);
		sbOut :  OUT  STD_LOGIC;
		TX232 :  OUT  STD_LOGIC;
		LED :  OUT  STD_LOGIC_VECTOR(0 TO 0)
	);
END HNN;

ARCHITECTURE bdf_type OF HNN IS 

COMPONENT clk_div
	PORT(clock_1_8432MHz : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 clk_out : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT mc
GENERIC (BID : STD_LOGIC_VECTOR(3 DOWNTO 0);
			CONTROLBUS : INTEGER;
			ID : STD_LOGIC_VECTOR(3 DOWNTO 0);
			READBACKBUS : INTEGER;
			RESERVEDC : INTEGER;
			RESERVEDR : INTEGER;
			SIS : INTEGER
			);
	PORT(clk : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 spiIn_ready : IN STD_LOGIC;
		 spiBusy : IN STD_LOGIC;
		 sendSpike : IN STD_LOGIC;
		 busy : IN STD_LOGIC;
		 q : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 readBckBus : IN STD_LOGIC_VECTOR(30031 DOWNTO 0);
		 sbIn : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
		 spiIn : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 spiOutReady : OUT STD_LOGIC;
		 sbOut : OUT STD_LOGIC;
		 resetTri : OUT STD_LOGIC;
		 we : OUT STD_LOGIC;
		 runStep : OUT STD_LOGIC;
		 restoreState : OUT STD_LOGIC;
		 contBus : OUT STD_LOGIC_VECTOR(151423 DOWNTO 0);
		 data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 raddr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 spiOut : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 waddr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT receive232
	PORT(clk : IN STD_LOGIC;
		 clock_1_8432MHz : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 RX232 : IN STD_LOGIC;
		 data_ready : OUT STD_LOGIC;
		 result : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT resettrig
	PORT(clk : IN STD_LOGIC;
		 resetTri : IN STD_LOGIC;
		 reset : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT single_clock_ram
	PORT(clk : IN STD_LOGIC;
		 we : IN STD_LOGIC;
		 data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 raddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 waddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 q : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT transmit232
	PORT(clk : IN STD_LOGIC;
		 clock_115_2KHz : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 datar232 : IN STD_LOGIC;
		 data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 TX232 : OUT STD_LOGIC;
		 busy232 : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT pll
	PORT(refclk : IN STD_LOGIC;
		 rst : IN STD_LOGIC;
		 outclk_0 : OUT STD_LOGIC;
		 outclk_1 : OUT STD_LOGIC
	);
END COMPONENT;

SIGNAL	data :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	q :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	raddr :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	resut :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	spiOut :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	waddr :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_20 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_21 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_22 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_23 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_8 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_15 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_17 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_19 :  STD_LOGIC;


BEGIN 



b2v_inst : clk_div
PORT MAP(clock_1_8432MHz => SYNTHESIZED_WIRE_20,
		 reset => SYNTHESIZED_WIRE_21,
		 clk_out => SYNTHESIZED_WIRE_17);


SYNTHESIZED_WIRE_22 <= SYNTHESIZED_WIRE_2 OR SYNTHESIZED_WIRE_3;


LED <= NOT(SYNTHESIZED_WIRE_22);



SYNTHESIZED_WIRE_3 <= NOT(PB);



b2v_inst2 : mc
GENERIC MAP(BID => "0000",
			CONTROLBUS => 151008,
			ID => "0001",
			READBACKBUS => 30016,
			RESERVEDC => 112,
			RESERVEDR => 16,
			SIS => 304
			)
PORT MAP(clk => SYNTHESIZED_WIRE_23,
		 reset => SYNTHESIZED_WIRE_21,
		 spiIn_ready => SYNTHESIZED_WIRE_7,
		 spiBusy => SYNTHESIZED_WIRE_8,
		 q => q,
		 sbIn => sbIn,
		 spiIn => resut,
		 spiOutReady => SYNTHESIZED_WIRE_19,
		 sbOut => sbOut,
		 resetTri => SYNTHESIZED_WIRE_2,
		 we => SYNTHESIZED_WIRE_15,
		 data => data,
		 raddr => raddr,
		 spiOut => spiOut,
		 waddr => waddr);


b2v_inst3 : receive232
PORT MAP(clk => SYNTHESIZED_WIRE_23,
		 clock_1_8432MHz => SYNTHESIZED_WIRE_20,
		 reset => SYNTHESIZED_WIRE_21,
		 RX232 => RX232,
		 data_ready => SYNTHESIZED_WIRE_7,
		 result => resut);


b2v_inst4 : resettrig
PORT MAP(clk => SYNTHESIZED_WIRE_23,
		 resetTri => SYNTHESIZED_WIRE_22,
		 reset => SYNTHESIZED_WIRE_21);


b2v_inst5 : single_clock_ram
PORT MAP(clk => SYNTHESIZED_WIRE_23,
		 we => SYNTHESIZED_WIRE_15,
		 data => data,
		 raddr => raddr,
		 waddr => waddr,
		 q => q);


b2v_inst6 : transmit232
PORT MAP(clk => SYNTHESIZED_WIRE_23,
		 clock_115_2KHz => SYNTHESIZED_WIRE_17,
		 reset => SYNTHESIZED_WIRE_21,
		 datar232 => SYNTHESIZED_WIRE_19,
		 data => spiOut,
		 TX232 => TX232,
		 busy232 => SYNTHESIZED_WIRE_8);


b2v_inst7 : pll
PORT MAP(refclk => CLK50,
		 outclk_0 => SYNTHESIZED_WIRE_23,
		 outclk_1 => SYNTHESIZED_WIRE_20);


END bdf_type;