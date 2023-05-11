library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Top_TB is
--  Port ( );
end Top_TB;

architecture Behavioral of Top_TB is

component Top is 
    Port(clk, rst : in STD_LOGIC;
         DS : out STD_LOGIC;
         AN : out STD_LOGIC_VECTOR(6 downto 0);
         RD : in STD_LOGIC;
         TD : out STD_LOGIC);
end component;

    signal clk_tb, rst_tb : STD_LOGIC := '0';
    signal DS_tb, RD_tb, TD_tb : STD_LOGIC;
    signal AN_tb : STD_LOGIC_VECTOR(6 downto 0);

begin
    
    U1: Top port map(clk_tb, rst_tb, DS_tb, AN_tb, RD_tb, TD_tb);
    
    process
    begin
        while now < 5000 ns loop
            clk_tb <= '0';
            wait for 10 ns;
            clk_tb <= '1';
            wait for 10 ns;
        end loop;
        wait;
    end process; 
    
    process
    begin
        rst_tb <= '1';
        wait for 20 ns;
        rst_tb <= '0';
        wait;
    end process;
    
    process
    begin
        RD_tb <= '1';
        wait for 50 ns;
        RD_tb <= '0';
        wait for 50 ns;
    end process;
    
end Behavioral;
