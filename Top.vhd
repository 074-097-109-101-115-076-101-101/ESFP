library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top is
    Port (clk, rst : in STD_LOGIC; -- 125 MHz clock & reset
    
          -- 7 Segment Display
          DS : out STD_LOGIC; -- Digit Selection 
          AN : out STD_LOGIC_VECTOR(6 downto 0); -- 7 Segment Display output
          
          -- UART
          RD : in STD_LOGIC; -- Receive data 
          TD : out STD_LOGIC); -- Transmit Data
end Top;

architecture Behavioral of Top is

-- Clock Divider instantiation 
component clock_div is
    Port(clk, rst : in STD_LOGIC; -- clock & reset
         clk_div : out STD_LOGIC); -- 62.5 MHz 
end component;

-- MAXSONAR instantiation
component MAXSONAR_PMOD is
    Port(clk, rst : in STD_LOGIC; -- clock & reset
         Data : out STD_LOGIC_VECTOR(23 downto 0); -- Received Data
         Data_Ready : out STD_LOGIC; 
         RX : in STD_LOGIC; -- Receiver
         TX : out STD_LOGIC); -- Transmitter
end component;
        
    -- 31.25 MHz clock & reset signal
    signal clock, reset : STD_LOGIC;
    
    -- MAXSONAR signals
    signal Sonar : STD_LOGIC_VECTOR(23 downto 0); -- Stores the raw distance data received from the MAXSONAR_PMOD
    signal Sonar_Data : STD_LOGIC_VECTOR(23 downto 0); -- Stores synchronized data with the clock signal  of "Sonar"
    
    -- 7 Segment Display signals
    signal select_digit : STD_LOGIC; -- selects between the two digits 
    signal Data_Ready : STD_LOGIC; -- Indicates whether the data received from MAXSONAR_PMOD is ready to be displayed on the SSD
    
    signal Distance_Data : STD_LOGIC_VECTOR(7 downto 0); -- Stores distance data in bytes received from Sonar_Data
    
    signal SSD : STD_LOGIC_VECTOR(6 downto 0); -- Stores the decoded value to be displayed on a single digit on the 7-Seg Display
    
    signal Dout : STD_LOGIC_VECTOR(6 downto 0); -- Outputs a single digit on the 7-Seg Display
    
    signal AN2, AN1, AN0 : STD_LOGIC_VECTOR(3 downto 0); -- Hundreds, tens, and ones place for Distance on 7-Seg Display respectively 
    signal enable : STD_LOGIC; -- enables or disables the output of digit data
    signal LED : STD_LOGIC; -- Control timing of the digit switching on the 7-Seg Display
    
begin
    
    MAXSONAR: MAXSONAR_PMOD port map(clock, reset, Sonar, Data_Ready, RD, TD);
    Clock_Divider: clock_div port map(clk, reset, clock);
  
  -- MAXSONAR 
    process(clock, reset)
    begin
        if (reset = '1') then
            Sonar_Data <= (others => '1');
        elsif (rising_edge(clock)) then
            if (Data_Ready = '1') then
                Sonar_Data <= Sonar;
            end if;
        end if;
    end process;

-- A portion of the synchronized distance data from sonar_data is stored into Distance_Data starting from the LSB up to 8 bits when
-- select_digit has a value of 0 and will take the next byte of distance data when select_digit has a value of 1.
    Distance_Data <= Sonar_Data(7 downto 0) when (select_digit = '0') else Sonar_Data(15 downto 8);

-- LUT for 7-Segment Display 
-- Decoder 
    process(clock, reset)
    begin
        if (rising_edge(clock)) then
            case (Distance_Data(3 downto 0)) is
                when "0000" => SSD <= "0111111"; -- 0
                when "0001" => SSD <= "0000110"; -- 1
                when "0010" => SSD <= "1011011"; -- 2
                when "0011" => SSD <= "1001111"; -- 3
                when "0100" => SSD <= "1100110"; -- 4
                when "0101" => SSD <= "1101101"; -- 5
                when "0110" => SSD <= "1111101"; -- 6
                when "0111" => SSD <= "0000111"; -- 7
                when "1000" => SSD <= "1111111"; -- 8
                when "1001" => SSD <= "1101111"; -- 9
                when others => SSD <= "0000000"; -- Blank when not a digit
            end case;
        end if;
    end process;
    
--  Disable display of a digit when the data value is 0     
    Dout <= "0000000" when ((select_digit = '1') AND (SSD = "0111111")) else SSD;

    
-- Switching for the 7 Segment Display 
-- 312499 / 31250000 = 10 ms or 100 Hz
    process(clock, reset)
        variable counter : integer range 0 to 312499; 
    begin
        if (reset = '1') then
            counter := 0;
            select_digit <= '0';
        elsif (rising_edge(clock)) then
            if (counter = 312499) then
                counter := 0;
                select_digit <= not select_digit;
            else
                counter := counter + 1;
            end if;
        end if;
    end process;
    
-- Counter to check if 3 bytes have been received
    process(clock, reset)
        variable counter : integer range 0 to 3;
    begin
        if (reset = '1') then
            counter := 0;
            enable <= '1';  -- Outputs a value of 0
        elsif (rising_edge(clock)) then
            if (Data_Ready = '1') then 
                counter := 0;
                enable <= '1';
            else
                if (LED = '1') then
                    if (counter = 3) then
                        enable <= '0';
                    else
                        counter := counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;  
        
    --Assigning signals
    AN2 <= Sonar_Data(19 downto 16); -- MSB 
    AN1 <= Sonar_Data(15 downto 12);
    AN0 <= Sonar_Data(11 downto 8);
    
    reset <= rst;
    DS <= select_digit;
    AN <= Dout  when (enable = '1') else "1111111";   
                    
end Behavioral;
