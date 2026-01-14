library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity timer is
    generic (
        clk_freq_hz_g : natural; -- Clock frequency in Hz
        delay_g       : time     -- Delay duration, e.g., 100 ms
    );
    port (
        clk_i   : in  std_ulogic;
        arst_i  : in  std_ulogic;
        start_i : in  std_ulogic; -- No effect if not done_o
        done_o  : out std_ulogic  -- '1' when not counting ("not busy")
    );
end entity timer;

architecture rtl of timer is
    -- Calculate the cycle limit
    -- Convert delay to nanoseconds, multiply by frequency, then divide by 1e9
    -- This gives us the number of clock cycles needed
    function calc_max_count return natural is
        variable delay_ns : real;
        variable cycles   : real;
    begin
        if delay_g = 0 ns then
            return 0; -- Special case: zero delay
        end if;
        
        -- Convert time to nanoseconds (as real number)
        delay_ns := real(delay_g / 1 ns);
        
        -- Calculate cycles: (frequency * delay_in_seconds)
        -- delay_ns / 1e9 converts ns to seconds
        cycles := real(clk_freq_hz_g) * (delay_ns / 1.0e9);
        
        -- Round to nearest integer
        return integer(round(cycles));
    end function;
    
    constant MAX_COUNT : natural := calc_max_count;
    
    -- Counter register
    signal count_reg : natural range 0 to MAX_COUNT := 0;
    signal done_reg  : std_ulogic := '1';
    
begin
    -- Assertions for parameter validation
    assert clk_freq_hz_g > 0 
        report "Frequency must be greater than zero!" 
        severity failure;

    assert delay_g >= 0 ns 
        report "Delay cannot be negative!" 
        severity failure;
    
    -- Output assignment
    done_o <= done_reg;
    
    process(clk_i, arst_i)
    begin
        if arst_i = '1' then
            -- Asynchronous reset: return to idle state
            count_reg <= 0;
            done_reg  <= '1'; 
            
        elsif rising_edge(clk_i) then
            if done_reg = '1' then
                -- Idle state: waiting for the start pulse
                if start_i = '1' then
                    if MAX_COUNT = 0 then
                        -- Special case: zero delay means done immediately
                        done_reg  <= '1';
                        count_reg <= 0;
                    else
                        -- Start counting
                        done_reg  <= '0';
                        count_reg <= 1; -- Start at 1, we've already used one cycle
                    end if;
                end if;
            else
                -- Active state: incrementing the counter
                if count_reg < MAX_COUNT then
                    count_reg <= count_reg + 1;
                else
                    -- Target reached: return to idle
                    count_reg <= 0;
                    done_reg  <= '1'; 
                end if;
            end if;
        end if;
    end process;

end architecture rtl;