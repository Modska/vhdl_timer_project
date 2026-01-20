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
    function calc_cycles_to_count return natural is
        variable delay_ns : real;
        variable cycles   : real;
    begin
        if delay_g = 0 ns then -- test if the delay is nul
            return 0;
        end if;
        
        delay_ns := real(delay_g / 1 ns); -- Divide by 1 ns to get the scaling factor as a real
        cycles := real(clk_freq_hz_g) * (delay_ns / 1.0e9); -- Convertion from freq used and time desired to number of clocks needed
        
        return integer(round(cycles));
    end function;
    
    constant CYCLES_TO_COUNT : natural := calc_cycles_to_count; --stocking in a constant the number of cycle needed to reach the timing needed
    
    signal count : natural := 0;
    signal counting : boolean := false;
    
begin
    assert clk_freq_hz_g > 0 --tests if values are usable
        report "Frequency must be greater than zero!" 
        severity failure;

    assert delay_g >= 0 ns 
        report "Delay cannot be negative!" 
        severity failure;
        -- Informational assertion for very long delays
    assert CYCLES_TO_COUNT < 2**30
        report "Warning: Very long delay may cause overflow issues"
        severity warning;
    
    -- Output logic
    done_o <= '0' when counting else '1';
    
    process(clk_i, arst_i)
    begin
        if arst_i = '1' then --Reset to restart the timer
            count    <= 0;
            counting <= false;
            
        elsif rising_edge(clk_i) then
            if not counting then
                -- Idle state
                if start_i = '1' and CYCLES_TO_COUNT > 0 then
                    -- Start counting from 0
                    count    <= 0;
                    counting <= true;
                end if;
            else
                -- Counting state
                if count = CYCLES_TO_COUNT - 1 then
                    -- Finished counting
                    count    <= 0;
                    counting <= false;
                else
                    -- Continue counting
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
