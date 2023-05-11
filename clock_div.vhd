library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_div is
    Port (clk, rst : in STD_LOGIC; -- 125 MHz clock & reset
          clk_div : out STD_LOGIC); -- 31.25 MHz
end clock_div;

architecture Behavioral of clock_div is

    signal temp : STD_LOGIC; 

begin
    process(clk, rst)
        variable counter : integer range 0 to 1;
    begin
        if (rst = '1') then
            counter := 0;
            temp <= '0';
            elsif (rising_edge(clk)) then
                if (counter = 1) then
                    temp <= not temp;
                    counter := 0;
                else
                    counter := counter + 1;
                end if;
            end if;
        end process;
    clk_div <= temp;
end Behavioral;
