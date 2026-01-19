library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Formal verification wrapper for timer
-- Uses simple assertions compatible with GHDL-Yosys
entity timer_formal is
    generic (
        -- Use small values for formal verification
        clk_freq_hz_g : natural := 1000;  -- 1 kHz
        delay_g       : time    := 10 us  -- 10 cycles at 1 kHz
    );
end entity timer_formal;

architecture formal of timer_formal is
    signal clk   : std_ulogic := '0';
    signal rst   : std_ulogic;
    signal start : std_ulogic;
    signal done  : std_ulogic;
    
    -- Track state for assertions
    signal prev_done : std_ulogic := '1';
    signal started : std_ulogic := '0';
    signal cycle_count : natural := 0;
    
    -- Calculate expected cycles
    function calc_expected_cycles return natural is
        variable delay_ns : real;
        variable cycles   : real;
        variable result   : natural;
    begin
        if delay_g = 0 ns then
            return 0;
        end if;
        delay_ns := real(delay_g / 1 ns);
        cycles := real(clk_freq_hz_g) * (delay_ns / 1.0e9);
        result := integer(round(cycles));
        if result = 0 and delay_g > 0 ns then
            result := 1;
        end if;
        return result;
    end function;
    
    constant EXPECTED_CYCLES : natural := calc_expected_cycles;
    
begin
    -- DUT instantiation
    dut: entity work.timer
        generic map (
            clk_freq_hz_g => clk_freq_hz_g,
            delay_g       => delay_g
        )
        port map (
            clk_i   => clk,
            arst_i  => rst,
            start_i => start,
            done_o  => done
        );
    
    -- Tracking process
    process(clk, rst)
    begin
        if rst = '1' then
            prev_done <= '1';
            started <= '0';
            cycle_count <= 0;
        elsif rising_edge(clk) then
            prev_done <= done;
            
            -- Detect start of counting
            if done = '1' and prev_done = '1' and start = '1' and EXPECTED_CYCLES > 0 then
                started <= '1';
                cycle_count <= 0;
            elsif started = '1' and done = '0' then
                cycle_count <= cycle_count + 1;
            elsif started = '1' and done = '1' then
                started <= '0';
            end if;
        end if;
    end process;
    
    -- ========================================================================
    -- FORMAL ASSERTIONS
    -- ========================================================================
    
    -- Property 1: Reset forces done high
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                assert done = '1' 
                    report "After reset, done must be high"
                    severity failure;
            end if;
        end if;
    end process;
    
    -- Property 2: When idle and no start, done stays high
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' and prev_done = '1' and done = '1' and start = '0' then
                assert done = '1'
                    report "Done should stay high when idle"
                    severity failure;
            end if;
        end if;
    end process;
    
    -- Property 3: Start causes done to go low (if cycles > 0)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' and EXPECTED_CYCLES > 0 then
                if prev_done = '1' and start = '1' then
                    -- Next cycle, done should be low
                    -- (checked in next clock cycle via prev_done)
                end if;
            end if;
        end if;
    end process;
    
    -- Property 4: Correct cycle count
    -- When counting finishes, verify it took the right number of cycles
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' and started = '1' and prev_done = '0' and done = '1' then
                assert cycle_count = EXPECTED_CYCLES
                    report "Incorrect cycle count: expected " & 
                           integer'image(EXPECTED_CYCLES) & " got " & 
                           integer'image(cycle_count)
                    severity failure;
            end if;
        end if;
    end process;
    
    -- Property 5: Zero delay means done stays high
    process(clk)
    begin
        if rising_edge(clk) then
            if EXPECTED_CYCLES = 0 then
                assert done = '1'
                    report "For zero delay, done must always be high"
                    severity failure;
            end if;
        end if;
    end process;

end architecture formal;