library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MAXSONAR_PMOD is
    Port (clk, rst : in STD_LOGIC; -- 125MHz clock & reset
          Data : out STD_LOGIC_VECTOR(23 downto 0); -- (Received data bytes - 3*8 = 24)
          Data_Ready : out STD_LOGIC; -- Data is ready to be sent
          RX : in STD_LOGIC; -- Receive Data (Date byte from UART module)
          TX : out STD_LOGIC); -- Transmit Data
end MAXSONAR_PMOD;

architecture Behavioral of MAXSONAR_PMOD is

-- UART Module instantiation    
component UART is 
    Port (clk, rst : in STD_LOGIC;
          RX : in STD_LOGIC;
          Byte : out STD_LOGIC;
          Dout : out STD_LOGIC_VECTOR(7 downto 0));
end component;
    
    constant start : STD_LOGIC_VECTOR(7 downto 0) := x"52"; -- Start bit "R"
    constant stop : STD_LOGIC_VECTOR(7 downto 0) := x"0D"; -- Carriage Return Character "13"
    
    signal RX_Data : STD_LOGIC_VECTOR(23 downto 0); -- Store received data bytes
    signal Byte_Received : STD_LOGIC; -- Indicates when a byte has been received from UART module
    signal RX_Received : STD_LOGIC_VECTOR(7 downto 0); -- Byte received from UART module
    signal Data_Received : STD_LOGIC; -- Indicates when data has been received
    signal start_detect : STD_LOGIC; -- Indicates when the start bit has been detected
   
begin

    RX_UART: UART port map (clk, rst, RX, Byte_Received, RX_Received);

-- Checks to see if the start byte has been received from the UART module
    process(clk, rst)
    begin
        if (rst = '1') then
            start_detect <= '0'; -- No start byte has been received
        elsif (rising_edge(clk)) then
            if (Byte_Received = '1') then -- if a byte has been received from the UART module
                if (RX_Received = start) then -- Checks to see if Byte received = to the start bit value "R"
                    start_detect <= '1'; -- Start bit has been detected
                end if;
            elsif (Data_Received = '1') then -- If the start byte information has been received
                start_detect <= '0'; -- Give start_detect value of 0 indicating all bytes have received
            end if;
        end if;
    end process;
 
-- Checks to see if the data bits have been received from the UART module
    process(clk, rst)
        variable counter : integer range 0 to 3; -- Counts received bytes
    begin
        if (rst = '1') then
            counter := 0;  -- counter = 0
            RX_Data <= (others => '0'); -- In all cases RX_Data is assigned a value of 0 
            Data_Received <= '0'; -- No bytes have been received
        elsif (rising_edge(clk)) then 
            if (Byte_Received = '1') AND (start_detect = '1') then
                if (counter <= 2) then 
                    RX_Data(8*counter+7 downto 8*counter) <= RX_Received; -- stores the received byte into RX_Data at the appropirate position based on the count value
                    counter := counter + 1; -- the counter keeps counting 
                    Data_Received <= '0'; -- Data received it set to 0 indicating more data is expected
                else    
                    counter := 0; -- counter resets to 0
                    Data_Received <= '1'; -- Indicates all data bytes have been received
                end if;
            else
                Data_Received <= '0'; -- if neither conditions are met then data_received is set to 0 indicating data has not been received
            end if;
        end if;
    end process;
    
    -- Assigning signals
    
    Data(7 downto 0) <= RX_Data(23 downto 16); -- MSB is transmitted first
    Data(15 downto 8) <= RX_Data(15 downto 8);
    Data(23 downto 16) <= RX_Data(7 downto 0);
    
    Data_Ready <= Data_Received; 
    
    TX <= '1'; -- TX is set to a constant of 1 to constantly transmit readings 
    
end Behavioral;
