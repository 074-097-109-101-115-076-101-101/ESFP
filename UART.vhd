library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART is 
    Port (clk, rst : in STD_LOGIC; -- 125 MHz clock & reset
          RX : in STD_LOGIC; -- Receive Data
          Byte : out STD_LOGIC; -- Refers to distance data (8 data bits = Byte)
          Dout : out STD_LOGIC_VECTOR(7 downto 0)); -- Transmit Data
end UART;

architecture Behavioral of UART is
    
    -- Finite State Machine   
    type FSM is (idle, start, data, stop); 
    
    constant clk_freq : integer := 31250000; -- 31.25 MHz clock frequency
    constant baud_rate : integer := 9600; -- 9600 baud rate (Rate data is transmitted in bits per second)
    
    signal system_state : FSM; -- Refers to the current state of the system
    
    signal RD : STD_LOGIC; -- Synchronized version of RX input signal and used to sample input data
     
    signal Byte_Received : STD_LOGIC; -- Indicates when distance data has been received (Byte)
    
    signal RD_Byte : STD_LOGIC_VECTOR(7 downto 0); -- Indicates the distance data that has been received in bits (8 bits = 1 Byte)
    
    signal DD_Received : STD_LOGIC_VECTOR(7 downto 0); -- Stores the value of distance data

begin

-- Synchronize RX with the clock   
    process(clk, rst)
        variable store : STD_LOGIC; -- Used to store the synchronized value of RX
    begin
        if (rst = '1') then 
            store := '1';
            RD <= '1';
        elsif (rising_edge(clk)) then
            RD <= store; -- update RD with store  
            store := RX; 
        end if;
    end process;
    
    
    -- clk_freq / baud_rate = cycles 
    
    process(clk, rst)
        variable counter : integer range 0 to 3255; -- cycles per bit
        variable index : integer; -- bit index of a received byte
    begin
        if (rst = '1') then
            system_state <= idle; 
            counter := 0;
            index := 0;
        elsif (rising_edge(clk)) then
            Byte_Received <= '0';
            
            case system_state is -- determine current and next state
                
                -- Idle State
                when idle => 
                    counter := 0; 
                    index := 0;
                    if (RD = '0') then -- Start bit is received
                        system_state <= start;
                    else
                        system_state <= idle;
                    end if;
                
                -- Start state
                when start => 
                    if (counter = (3255)/2) then -- Counts half a clock cycle and checks to see if a valid start bit is present
                        if (RD = '0') then 
                            system_state <= data;
                            counter := 0;
                        else
                            system_state <= idle;
                        end if;
                    else
                        counter := counter + 1;
                        system_state <= start;
                    end if;
                
                -- Data state
                when data => 
                    if (counter < 3255) then 
                        counter := counter + 1;
                        system_state <= data;
                    else
                        counter := 0; -- Counter resets to 0 
          
                        RD_Byte(index) <= RD; -- The synchronized signal is assigned to the bit position of the data received
                        
                        if (index = 7) then -- Last bit position
                            index := 0; -- Distance data (Byte) has been received
                            system_state <= stop;                        
                        else
                            index := index + 1;
                            system_state <= data;
                        end if;
                    end if;
                
                -- Stop state
                when stop => 
                    DD_Received <= RD_Byte;
                    if (counter < 3255) then
                        counter := counter + 1;
                        system_state <= stop;
                    else
                        Byte_Received <= '1';
                        counter := 0;
                        system_state <= idle;
                    end if;
                 
                when others =>
                
            end case;
        end if;
    end process;
     
    -- Assign signals 
    Byte <= Byte_Received;
    Dout <= DD_Received;

end Behavioral;
