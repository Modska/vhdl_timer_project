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
    -- Calculate how many cycles the timer should count
    -- Handles edge cases: zero delay, sub-clock delays, very long delays
    function calc_cycles_to_count return natural is
        variable delay_ns : real;
        variable cycles   : real;
        variable result   : natural;
    begin
        -- Special case: zero delay means no counting at all
        if delay_g = 0 ns then
            return 0;
        end if;
        
        -- Convert time to nanoseconds
        delay_ns := real(delay_g / 1 ns);
        
        -- Calculate number of cycles: frequency * time_in_seconds
        cycles := real(clk_freq_hz_g) * (delay_ns / 1.0e9);
        
        -- Round to nearest integer
        result := integer(round(cycles));
        
        -- Critical: For sub-clock period delays, ensure at least 1 cycle
        -- A synchronous counter cannot count less than one clock period
        if result = 0 and delay_g > 0 ns then
            result := 1;
        end if;
        
        return result;
    end function;
    
    constant CYCLES_TO_COUNT : natural := calc_cycles_to_count;
    
    signal count    : natural := 0;
    signal counting : boolean := false;
    
begin
    -- Parameter validation
    assert clk_freq_hz_g > 0 
        report "Clock frequency must be greater than zero!" 
        severity failure;

    assert delay_g >= 0 ns 
        report "Delay cannot be negative!" 
        severity failure;
    
    -- Informational warnings
    assert CYCLES_TO_COUNT < 2**30
        report "Warning: Very long delay may cause overflow issues"
        severity warning;
    
    -- Info message for sub-clock period delays
    assert (delay_g = 0 ns) or (CYCLES_TO_COUNT > 0)
        report "Note: Delay " & time'image(delay_g) & 
               " will be implemented with " & integer'image(CYCLES_TO_COUNT) & 
               " clock cycles"
        severity note;
    
    process(clk_i, arst_i)
    begin
        if arst_i = '1' then
            count    <= 0;
            counting <= false;
            done_o   <= '1';  -- Asynchronous reset sets done immediately
            
        elsif rising_edge(clk_i) then
            if not counting then
                -- Idle state: waiting for start pulse
                done_o <= '1';
                if start_i = '1' and CYCLES_TO_COUNT > 0 then
                    count    <= 0;
                    counting <= true;
                    done_o   <= '0';  -- Start counting, set done low
                end if;
                
            else
                -- Counting state
                done_o <= '0';
                if count = CYCLES_TO_COUNT - 1 then
                    -- Finished counting: return to idle
                    count    <= 0;
                    counting <= false;
                    done_o   <= '1';  -- Set done high when finished
                else
                    -- Continue counting
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;