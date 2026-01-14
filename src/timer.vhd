library ieee ;
use ieee . std_logic_1164 . all ;
use ieee . numeric_std . all ;
use ieee . math_real .all ;

entity timer is
 generic (
 clk_freq_hz_g : natural ; -- Clock frequency in Hz
 delay_g : time -- Delay duration , e.g. , 100 ms
 ) ;
 port (
 clk_i : in std_ulogic ;
 arst_i : in std_ulogic ;
 start_i : in std_ulogic ; -- No effect if not done_o
 done_o : out std_ulogic -- ’1 ’ when not counting (" not busy ")
 ) ;
 end entity timer ;

architecture rtl of timer is
    -- Calculate the cycle limit 
    -- Assumption: clk_freq * delay fits within a 31-bit positive integer (VHDL natural limit)
    constant MAX_COUNT : natural := clk_freq_hz_g * (delay_g / 1 sec);
    
    -- Counter register
    signal count_reg : natural range 0 to MAX_COUNT := 0;
    
begin

    process(clk_i, arst_i)
    begin
        if arst_i = '1' then
            -- Asynchronous reset: return to idle state
            count_reg <= 0;
            done_o    <= '1'; 
            
        elsif rising_edge(clk_i) then
            if done_o = '1' then
                -- Idle state: waiting for the start pulse
                if start_i = '1' then
                    done_o    <= '0'; -- Switch to busy mode
                    count_reg <= 0;
                end if;
            else
                -- Active state: incrementing the counter
                if count_reg < MAX_COUNT - 1 then
                    count_reg <= count_reg + 1;
                else
                    -- Target reached: reset counter and return to idle
                    count_reg <= 0;
                    done_o    <= '1'; 
                end if;
            end if;
        end if;
    end process;

end architecture rtl;