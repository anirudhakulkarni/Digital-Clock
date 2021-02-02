--2019CS50421
--Anirudha Kulkarni
-- --frequency reducer V2
--converts 10mhz to 1hz
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
entity freq_divider is
port (
	reset: in std_logic;
	clock10MHz: in std_logic;
	clock_1s: out std_logic
	);
END freq_divider;
architecture freq_divider_ar of freq_divider is
SIGNAL counter: integer:=1; 
SIGNAL temp : std_logic := "0";
BEGIN
 	process(clock10MHz,reset)
	BEGIN
		IF(reset="1")THEN
			counter<=1;
			temp<="0";
		elsIF(rising_edge(clock10MHz)) THEN
			counter <= counter +1;
			IF(counter=10000000) THEN--when 10**7 is over it becomes 1 sec period and hence it toggle for other pulse
				temp<=not temp;
				counter <= 1; --start again from 1
			END IF;
		END IF;
	clock_1s <= temp; 
	END process;
	
END freq_divider_ar;

--fsm corresponding to changing position of cursor with respect to change in K3
ENTITY arbiter IS--find corresponding state transition diagram in pdf attached
	PORT (
		reset: IN STD_LOGIC;
		edit_mode: IN STD_LOGIC;
		K3: IN STD_LOGIC;
		cursor: OUT std_logic_vector(2 downto 0)
		);
END arbiter;
ARCHITECTURE FSM OF arbiter IS
	--TYPE state_type IS (Idle,S0, H1, TH1H0, H0, TH0M1, M1, TM1M0, M0 , TM0S1, S1, TS1S0, S0, TS0H1);
	TYPE state_type IS (H1, H0, M1, M0 , S1, S0);--state denotes current position of cursor
	SIGNAL state : state_type;
BEGIN
	PROCESS(K3,reset,edit_mode)
	BEGIN
		IF(reset='1')THEN
			state <= H1;
		END IF;
		IF(edit_mode='1')THEN--operational only when it is edit mode
			IF(RISING_EDGE(K3)) THEN--rising edge of k3 is chosen in order to capture pushing of push button
				CASE state IS
					WHEN S1 =>
						IF K3 = "1" THEN state <= S0; END IF;
					WHEN S0 =>
						IF K3 = "1" THEN state <= H1; END IF;
					WHEN H0 =>
						IF K3 = "1" THEN state <= M1; END IF;
					WHEN M1 =>
						IF K3 = "1" THEN state <= M0; END IF;
					WHEN M0 =>
						IF K3 = "1" THEN state <= S1; END IF;

					WHEN H1 =>
						IF K3 = "1" THEN state <= H0; END IF; 
				END CASE;
			END IF;
		END IF;
	END PROCESS;
	WITH state SELECT
		cursor <= "000" WHEN S0 ,
		“001“ WHEN S1 ,
		"010" WHEN M0 ,
		"011" WHEN M1,
		"100" WHEN H0,
		"101" WHEN H1;
END FSM;
--generates edit mode and display modes
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY BUTTONS IS
PORT (
	K1 : IN std_logic;
	K2 : IN std_logic;
	K3 : IN std_logic;
	K4 : IN std_logic;
	reset: IN std_logic;
	edit_mode: OUT STD_LOGIC:=0;
	display_mode: OUT STD_LOGIC:=0
	);
END BUTTONS;
ARCHITECTURE BUTTONS_AR of BUTTONS IS
    BEGIN
	PROCESS(K2,reset) BEGIN--sensitive to rising edge of k2 in order to stay in the state when pushed and released
		IF(reset='1')THEN--initialized as false
			edit_mode=0;
		ELSIF(RISING_EDGE(K2)) THEN
			edit_mode<=not edit_mode;--toggles when k3 pushed and released
		END IF;
	END PROCESS;
	PROCESS(K1,reset) BEGIN
		IF(reset='1')THEN--initialized as HH:MM
			display_mode=0;
		ELSIF(RISING_EDGE(K1)) THEN
			display_mode<=not display_mode;--display mode=0 is case of HH:MM	
		END IF;
	END PROCESS;
END BUTTONS_AR;


library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY counter IS
PORT (
	clock_1s: IN std_logic; 
	reset: IN std_logic; 
	edit_mode: IN std_logic;
	K4: IN std_logic;
	cursor: IN std_logic_vector(2 downto 0); 
	H1_out: OUT std_logic_vector(3 downto 0);
 	H0_out: OUT std_logic_vector(3 downto 0);
 	M1_out: OUT std_logic_vector(3 downto 0);
	M0_out: OUT std_logic_vector(3 downto 0);
	S1_out: OUT std_logic_vector(3 downto 0);
	S0_out: OUT std_logic_vector(3 downto 0)
	);
END counter;
ARCHITECTURE counter_ar of counter IS
	SIGNAL H1,H0,M1,M0,S1,S0: STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
	PROCESS(clock_1s,reset)
	BEGIN
	IF(RESET='1')THEN--initialize
		H1<="0";H0<="0";M1<="0";M0<="0";S1<="0";S0<="0";
    ELSIF (rising_edge(clock_1s)) THEN--increment at rising edge
		IF (S0 = "1001") THEN--this checks from left to right and removes boundary condition. the innermost if statement checks worst condition when its 23:59:59. similarly..
			IF (S1 = "0101") THEN
				S0 <= "0000"; S1 <= "0000";
				IF (M0 = "1001") THEN
					IF (M1 = "0101") THEN
						M0 <= "0000"; M1 <= "0000";
						IF (H1 = "0010") THEN
							IF (H0 = "0011") THEN
								H1 <= "0000"; H1 <= "0000";
							ELSE H0 <= H0 + "0001"; END IF;
						ELSE
							IF (H0 = "1001") THEN H1 <= H1 +"0001"; H0 <= "0000";
							ELSE H0 <= H0 + "001"; END IF; 
						END IF;
					ELSE  M1 <= M1 + "001"; M0 <= "0000"; END IF;
				ELSE M0 <= M0 + "001"; END IF;
			ELSE  S1 <= S1 + "001"; S0 <= "0000"; END IF;
		ELSE S0 <= S0 + "001"; END IF;
    END IF;
  END PROCESS;
  PROCESS(K4)BEGIN--increment operation sensitive to risinng edge of k4 so as to work only when pressed once
	IF(edit_mode="1")THEN---only in edit mode
		IF(RISING_EDGE(K4))THEN
			IF(cursor="000") THEN--checks cursor location and increments the number by checking corner cases. if 59 and 1 is added in s0 only s0 changes to 0 no effect on s1. gives 50.
				IF(S0="1001")THEN--idealistic as user want to set each digit independent of other
					S0<="0000";
				ELSE
					S0<=S0+"0001";
				END IF;
			END IF;
			IF(cursor="001") THEN
				IF(S1="0101")THEN
					S1<="0000";
				ELSE
					S1<=S1+"0001";
				END IF;
			END IF;
			IF(cursor="010") THEN
				IF(M0<="1001")THEN
					M0<="0000";
				ELSE
					M0<=M0+"0001";
				END IF;
			END IF;
			IF(cursor="011") THEN
				IF(M1<="0101")THEN
					M1<="0000";
				ELSE
					M1<=M1+"0101";
				END IF;
			END IF;
			IF(cursor="101") THEN
				IF(H1<="0010")THEN
					H1<="0000";
				ELSE
					H1<=H1+"0001";
				END IF;
			END IF;
			IF(cursor="100") THEN
				IF(H1="0010")THEN
					IF(H0>="0011")THEN
						H0<="0000";
					ELSE
						H0<=H0+"0001";
					END IF;
				ELSE
					IF(H0="1001")THEN
						H0<="0000";
					ELSE
						H0<=H0+"0001";
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
	END PROCESS;	
  H1_out <= H1;
  H0_out <= H0;
  M1_out <= M1;
  M0_out <= M0;
  S1_out <= S1;
  S0_out <= S0;

END counter_ar;

-- selects 1 vector to be displayed from 4 as per refresh rate
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY display_driver IS
PORT (
	A: in std_logic_vector(3 downto 0);
	B: in std_logic_vector(3 downto 0);
	C: in std_logic_vector(3 downto 0);
	D: in std_logic_vector(3 downto 0);
	selector: IN std_logic_vector(1 downto 0);
	selected_out: OUT std_logic_vector(6 downto 0)
	);
END display_driver;
ARCHITECTURE display_driver_ar of display_driver IS
BEGIN
	PROCESS(selector,A,B,C,D)
	BEGIN
		case(selector) IS
		WHEN "00" =>  selected_out <= A; --0--
		WHEN "01" =>  selected_out <= B; --1--
		WHEN "10" =>  selected_out <= C; --2--
		WHEN "11" =>  selected_out <= D; --3--
		END case;
	END PROCESS;
END display_driver_ar;



--decides which 4 among all six numbers to display
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY display_mode IS
PORT (
	H1_out: in std_logic_vector(4 downto 0);
	H0_out: in std_logic_vector(4 downto 0);
	M1_out: in std_logic_vector(4 downto 0);
    M0_out: in std_logic_vector(4 downto 0);
    S1_out: in std_logic_vector(4 downto 0);
	S0_out: in std_logic_vector(4 downto 0);
	A: out std_logic_vector(3 downto 0);
	B: out std_logic_vector(3 downto 0);
	C: out std_logic_vector(3 downto 0);
	D: out std_logic_vector(3 downto 0);
	display_mode: IN std_logic
	);
END display_mode;
ARCHITECTURE display_mode_ar of display_mode IS
BEGIN
	PROCESS(display_mode,S_out0,S_out1,M_out0,M_out1,H_out1,H_out0)--sensitive all as a number might change without change in mode
	BEGIN
		case(display_mode) IS--2 modes. HH:MM and MM:SS
		WHEN "0" =>  A <= H1_out ;
			B<= H0_out ;
			C<= M1_out;
			D<= M0_out;
		WHEN "1" => A <= M1_out;
		B<= M0_out;
		C<= S1_out;
		D<= S0_out;
		END case;
	END PROCESS;
END display_mode_ar;



--converts given 4 bit vector to corresponding 7 segment diplay
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
entity bcd_to_7segment is
	Port ( selected_out : in STD_LOGIC_VECTOR (3 downto 0);
		display_mode: IN STD_LOGIC;--this corresponds to HH:MM to indicate working or not
		cathodes : out STD_LOGIC_VECTOR (7 downto 0));
END bcd_to_7segment; 
architecture bcd_to_7segment_ar of bcd_to_7segment is
BEGIN 
	process(selected_out,display_mode)
	BEGIN 
		IF(display_mode="0") THEN--please see pdf for relevant logic with explanation
			case selected_out is
				when "0000" =>
				cathodes <= "00000011"; --0
				when "0001" =>
					cathodes <= "10011111"; --1
				when "0010" =>
					cathodes <= "00100101"; --2
				when "0011" =>
					cathodes <= "00001101"; --3
				when "0100" =>
					cathodes <= "10011001"; --4
				when "0101" =>
					cathodes <= "01001001"; --5
				when "0110" =>
					cathodes <= "01000001"; --6
				when "0111" =>
					cathodes <= "00011111"; --7
				when "1000" =>
					cathodes <= "00000001"; --8
				when "1001" =>
					cathodes <= "00001001"; --9
				when others =>
					cathodes <= "11111111"; --null
			END case;
		ELSE
			case selected_out is
				when "0000" =>
				cathodes <= "00000010"; --0
				when "0001" =>
					cathodes <= "10011110"; --1
				when "0010" =>
					cathodes <= "00100100"; --2
				when "0011" =>
					cathodes <= "00001100"; --3
				when "0100" =>
					cathodes <= "10011000"; --4
				when "0101" =>
					cathodes <= "01001000"; --5
				when "0110" =>
					cathodes <= "01000000"; --6
				when "0111" =>
					cathodes <= "00011110"; --7
				when "1000" =>
					cathodes <= "00000000"; --8
				when "1001" =>
					cathodes <= "00001000"; --9
				when others =>
					cathodes <= "11111110"; --null
			END case;
		END IF;
			
	END process;
END bcd_to_7segment_ar;



-- generates selector based on refresh rate which decides blinking of dot refresh rate and edit mode
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY selector_gen IS
PORT (
	clock10MHz: IN std_logic;
	reset: IN std_logic;
	cursor: IN std_logic_vector(2 downto 0);
	selector: OUT std_logic_vector(1 downto 0);
	anodes: OUT std_logic_vector(3 downto 0)
	);
END selector_gen;
ARCHITECTURE selector_gen_ar of selector_gen IS
	SIGNAL rcountsofar: STD_LOGIC_VECTOR (19 downto 0);
BEGIN
	PROCESS(clock10MHz,reset)
	BEGIN
		IF(reset="1") THEN
			rcountsofar<="00000000000000000000";
		ELSIF(RISING_EDGE(clock10MHz)) THEN
			IF(rcountsofar="100110001001011001111111") THEN
				rcountsofar<="00000000000000000000";
			ELSE
				rcountersofar<=rcountersofar+"00000000000000000001";
			END IF;
		END IF;
		selector<=rcountersofar(19 downto 18);--when refresh period is taken as 10.5 last 18 bits from 20 bit counter shows period correspondding to 10.5/4 refresh period 
    	CASE selector IS
	    	WHEN "00"=>
		    	anodes<="0111";--turning off first anode and reversing others
		    WHEN "01"=>
		    	anodes<="1011";
		    WHEN "10"=>
		    	anodes<="1101";
		    WHEN "11"=>
		    	anodes<="1110";
	    END CASE;
	END PROCESS;
	
		
END selector_gen_ar;




library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
ENTITY main IS
PORT ( 
 	clock10MHz: IN std_logic; 
 	-- clock 10 MHz
 	reset: IN std_logic; 
	K1: IN STD_LOGIC;
	K2: IN STD_LOGIC;
	K3: IN STD_LOGIC;
	K4: IN STD_LOGIC;

	anodes: OUT std_logic_vector(3 downto 0);
 	cathodes: OUT std_logic_vector(7 downto 0)
	);

END main;
ARCHITECTURE mainar of main IS
component freq_divider
port (
	reset: in std_logic;
	clock10MHz: in std_logic;
	clock_1s: out std_logic
	);
END component;
component counter
PORT (
	clock_1s: IN std_logic; 
	reset: IN std_logic; 
	edit_mode: IN std_logic;
	K4: IN std_logic;
	cursor: IN std_logic_vector(2 downto 0); 
	H1_out: OUT std_logic_vector(3 downto 0);
 	H0_out: OUT std_logic_vector(3 downto 0);
 	M1_out: OUT std_logic_vector(3 downto 0);
	M0_out: OUT std_logic_vector(3 downto 0);
	S1_out: OUT std_logic_vector(3 downto 0);
	S0_out: OUT std_logic_vector(3 downto 0)
	);
END component;
component BUTTONS
PORT (
	K1 : IN std_logic;
	K2 : IN std_logic;
	K3 : IN std_logic;
	K4 : IN std_logic;
	reset: IN std_logic;
	edit_mode: OUT STD_LOGIC:=0;
	display_mode: OUT STD_LOGIC:=0
	);
END component;
component selector_gen 
PORT (
	clock10MHz: IN std_logic;
	reset: IN std_logic;
	cursor: IN std_logic_vector(2 downto 0);
	selector: OUT std_logic_vector(1 downto 0);
	anodes: OUT std_logic_vector(3 downto 0)
	);
END component;
component display_driver
PORT (
	A: in std_logic_vector(3 downto 0);
	B: in std_logic_vector(3 downto 0);
	C: in std_logic_vector(3 downto 0);
	D: in std_logic_vector(3 downto 0);
	selector: IN std_logic_vector(1 downto 0);
	selected_out: OUT std_logic_vector(6 downto 0)
	);
END component;
component bcd_to_7segment 
	Port ( selected_out : in STD_LOGIC_VECTOR (3 downto 0);
		display_mode: IN STD_LOGIC;
		cathodes : out STD_LOGIC_VECTOR (7 downto 0));
END component; 
component display_mode
PORT (
	H1_out: in std_logic_vector(4 downto 0);
	H0_out: in std_logic_vector(4 downto 0);
	M1_out: in std_logic_vector(4 downto 0);
    M0_out: in std_logic_vector(4 downto 0);
    S1_out: in std_logic_vector(4 downto 0);
	S0_out: in std_logic_vector(4 downto 0);
	A: out std_logic_vector(3 downto 0);
	B: out std_logic_vector(3 downto 0);
	C: out std_logic_vector(3 downto 0);
	D: out std_logic_vector(3 downto 0);
	display_mode: IN std_logic
	);
END component;
component arbiter
	PORT (
		reset: IN STD_LOGIC;
		edit_mode: IN STD_LOGIC;
		K3: IN STD_LOGIC;
		cursor: OUT std_logic_vector(2 downto 0)
		);
END component;
signal clock_1s: std_logic;--initailizing intermidiate signals
signal H1_out: std_logic_vector(3 downto 0);
signal H0_out: std_logic_vector(3 downto 0);
signal M1_out: std_logic_vector(3 downto 0);
signal M0_out: std_logic_vector(3 downto 0);
signal S1_out: std_logic_vector(3 downto 0);
signal S0_out: std_logic_vector(3 downto 0);
signal display_mode: STD_LOGIC;
signal edit_mode: STD_LOGIC;
signal selected_out: std_logic_vector(6 downto 0);
signal cathodes: STD_LOGIC_VECTOR (7 downto 0));
signal cursor: std_logic_vector(2 downto 0);
signal clock10MHz: std_logic;
signal anodes: std_logic_vector(3 downto 0);
signal selector: std_logic_vector(1 downto 0);
signal A: std_logic_vector(3 downto 0);
signal B: std_logic_vector(3 downto 0);
signal C: std_logic_vector(3 downto 0);
signal D: std_logic_vector(3 downto 0);


begin 
map1: freq_divider PORT MAP (clock10MHz=>clock10MHz,reset=>reset,clock_1s=>clock_1s);--mapping to respective ports
map2: counter PORT MAP (clock_1s=>clock_1s,reset=>reset,edit_mode=>edit_mode,K4=>K4,cursor=>cursor,H1_out=H1_out,H0_out=>H0_out,M1_out=>M1_out,M0_out=>M0_out,S1_out=>S1_out,S0_out=>S0_out);
map3: BUTTONS PORT MAP (K1=>K1,K2=>K2,K3=>K3,K4=>K4,reset=>reset,edit_mode=>edit_mode,display_mode=>display_mode);
map4: bcd_to_7segment PORT MAP(selected_out=>selected_out,display_mode=>display_mode,cathodes=>cathodes);
map5: arbiter PORT MAP(K3=>K3,reset=>reset,edit_mode=>edit_mode,cursor=>cursor);
map6: selector_gen PORT MAP(reset=>reset,clock10MHz=>clock10MHz,cursor=>cursor,selector=>selector,anodes=>anodes);
map7: display_mode PORT MAP(H1_out=H1_out,H0_out=>H0_out,M1_out=>M1_out,M0_out=>M0_out,S1_out=>S1_out,S0_out=>S0_out,A=>A,B=>B,C=>C,D=>D,display_mode=>display_mode);
map8: display_driver PORT MAP(A=>A,B=>B,C=>C,D=>D,selector=>selector,selected_out=>selected_out);
END mainar;

-------gave some error on vivaldo but couldnt find it. If possible please provide feedback
-- --frequency reducer v1
-- library IEEE;
-- USE IEEE.STD_LOGIC_1164.ALL;
-- USE IEEE.STD_LOGIC_UNSIGNED.ALL;
-- entity freq_divider is
-- port (
-- 	clock10MHz: in std_logic;
-- 	clock_1s: out std_logic
-- 	);
-- END freq_divider;
-- architecture freq_divider_ar of freq_divider is
-- SIGNAL counter: std_logic_vector(23 downto 0):=(others =>"0"); --2**24 bit required for
-- BEGIN
--  	process(clock10MHz)
-- 	BEGIN
-- 		IF(rising_edge(clock10MHz)) THEN
-- 			counter <= counter + "000000000000000000000001";
-- 			IF(counter>="100110001001011010000000") THEN--when 10**7 is over
-- 				counter <= "000000000000000000000000";
-- 			END IF;
-- 		END IF;
-- 	END process;
-- 	clock_1s <= "0" when counter = "010011000100101101000000" ELSE "1";--till its 5*10**6
-- END freq_divider_ar;



----with integers to store count but couldnt go further
-- main counter which keeps counting and depENDs on mode to go in edit mode 
-- library IEEE;
-- USE IEEE.STD_LOGIC_1164.ALL;
-- ENTITY counter IS
-- PORT (
-- 	clock_1s: IN std_logic; 
-- 	reset: IN std_logic; 
-- 	edit_mode: IN std_logic;
-- 	K4: IN std_logic;
-- 	cursor: IN std_logic_vector(2 downto 0); 
-- 	H_out1: OUT std_logic_vector(6 downto 0);
--  	H_out0: OUT std_logic_vector(6 downto 0);
--  	M_out1: OUT std_logic_vector(6 downto 0);
-- 	M_out0: OUT std_logic_vector(6 downto 0);
-- 	S_out1: OUT std_logic_vector(6 downto 0);
-- 	S_out0: OUT std_logic_vector(6 downto 0)
-- 	);
-- END counter;
-- ARCHITECTURE counter_ar of counter IS
-- 	SIGNAL counter_hour, counter_minute, counter_second: integer;
-- BEGIN
-- 	PROCESS(clock_1s,reset) BEGIN
-- 		IF(reset="1")THEN
-- 			counter_hour <= 0;
-- 			counter_minute <= 0;
-- 			counter_second <= 0;
-- 		elsIF(rising_edge(clock_1s))  THEN
-- 			counter_second <= counter_second + 1;
-- 			IF(counter_second >=59) THEN -- second > 59 THEN minute increases
-- 				counter_minute <= counter_minute + 1;
-- 				counter_second <= 0;
-- 				IF(counter_minute >=59) THEN -- minute > 59 THEN hour increases
-- 					counter_minute <= 0;
-- 					counter_hour <= counter_hour + 1;
-- 					IF(counter_hour >= 24) THEN -- hour > 24 THEN set hour to 0
-- 						counter_hour <= 0;
-- 					END IF;
-- 				END IF;
-- 			END IF;
-- 		END IF;
-- 	END PROCESS;
-- 	IF(edit_mode="1")THEN
-- 		process(K4) BEGIN
-- 			IF(rising_edge(K4)) THEN
-- 				IF(cursor="00")THEN
-- 					IF(counter_second%10=)
--
-- END counter_ar;

--2019CS50421
--Anirudha Kulkarni
