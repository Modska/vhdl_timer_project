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
    -- Calculate how many cycles to count
    -- The duration while done='0' should be exactly delay_g
    function calc_cycles_to_count return natural is
        variable delay_ns : real;
        variable cycles   : real;
    begin
        if delay_g = 0 ns then
            return 0;
        end if;
        
        delay_ns := real(delay_g / 1 ns);
        cycles := real(clk_freq_hz_g) * (delay_ns / 1.0e9);
        
        return integer(round(cycles));
    end function;
    
    constant CYCLES_TO_COUNT : natural := calc_cycles_to_count;
    
    signal count : natural := 0;
    
begin
    assert clk_freq_hz_g > 0 
        report "Frequency must be greater than zero!" 
        severity failure;

    assert delay_g >= 0 ns 
        report "Delay cannot be negative!" 
        severity failure;
    
    process(clk_i, arst_i)
    begin
        if arst_i = '1' then
            count  <= 0;
            done_o <= '1'; 
            
        elsif rising_edge(clk_i) then
            if count = 0 then
                -- Idle: not counting
                done_o <= '1';
                if start_i = '1' and CYCLES_TO_COUNT > 0 then
                    -- Start counting
                    count  <= CYCLES_TO_COUNT;
                    done_o <= '0';
                end if;
            else
                -- Counting down
                done_o <= '0';
                count  <= count - 1;
            end if;
        end if;
    end process;

end architecture rtl;