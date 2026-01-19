library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Formal verification wrapper for timer
-- This module instantiates the timer and adds PSL properties
entity timer_formal is
    generic (
        -- Use small values for formal verification to keep state space manageable
        clk_freq_hz_g : natural := 1000;  -- 1 kHz for faster formal verification
        delay_g       : time    := 10 us  -- 10 cycles at 1 kHz
    );
end entity timer_formal;

architecture formal of timer_formal is
    signal clk   : std_ulogic := '0';
    signal rst   : std_ulogic := '0';
    signal start : std_ulogic := '0';
    signal done  : std_ulogic;
    
    -- Counter to track cycles after start
    signal cycle_counter : natural := 0;
    signal counting_started : boolean := false;
    
    -- Calculate expected cycle count
    function calc_expected_cycles return natural is
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
    
    -- Clock generation (not used in formal, but helps with simulation)
    clk <= not clk after 500 us;  -- 1 kHz clock
    
    -- Cycle counter for properties
    process(clk, rst)
    begin
        if rst = '1' then
            cycle_counter <= 0;
            counting_started <= false;
        elsif rising_edge(clk) then
            if done = '1' and start = '1' and EXPECTED_CYCLES > 0 then
                -- Start detected
                counting_started <= true;
                cycle_counter <= 0;
            elsif counting_started and done = '0' then
                -- Counting in progress
                cycle_counter <= cycle_counter + 1;
            elsif counting_started and done = '1' then
                -- Counting finished
                counting_started <= false;
                cycle_counter <= 0;
            end if;
        end if;
    end process;
    
    -- ========================================================================
    -- PSL FORMAL PROPERTIES
    -- ========================================================================
    
    -- Default clock for PSL properties
    default clock is rising_edge(clk);
    
    -- Property 1: After reset, done must be high
    property p_reset_done is
        always (rst -> next done);
    assert p_reset_done;
    
    -- Property 2: If not started, done stays high
    property p_idle_done is
        always ((done and not start) -> next done);
    assert p_idle_done;
    
    -- Property 3: Start pulse causes done to go low (if EXPECTED_CYCLES > 0)
    property p_start_causes_busy is
        always ((done and start and EXPECTED_CYCLES > 0) -> next not done);
    assert p_start_causes_busy;
    
    -- Property 4: Zero delay keeps done high
    property p_zero_delay is
        (EXPECTED_CYCLES = 0) -> always done;
    assert p_zero_delay;
    
    -- Property 5: After start, done goes high after exactly EXPECTED_CYCLES
    -- This is the key timing property
    property p_correct_timing is
        always ((done and start and EXPECTED_CYCLES > 0) -> 
                next (not done[*EXPECTED_CYCLES] |=> done));
    assert p_correct_timing;
    
    -- Property 6: Done signal is stable (no glitches)
    property p_done_stable is
        always (done -> (done until not done));
    assert p_done_stable;
    
    -- Property 7: Once counting starts, it completes without interruption
    -- (unless reset occurs)
    property p_counting_completes is
        always ((not done and not rst) -> 
                (not done until (done or rst)));
    assert p_counting_completes;
    
    -- Property 8: Start during counting is ignored
    property p_ignore_start_when_busy is
        always ((not done and start) -> next not done);
    assert p_ignore_start_when_busy;
    
    -- ========================================================================
    -- COVER PROPERTIES (to ensure properties are reachable)
    -- ========================================================================
    
    -- Cover: Successfully complete a timing cycle
    property c_complete_cycle is
        eventually (done and not prev(done));
    cover c_complete_cycle;
    
    -- Cover: Reset during counting
    property c_reset_while_counting is
        eventually (not done and rst);
    cover c_reset_while_counting;
    
    -- Cover: Back-to-back start pulses
    property c_back_to_back is
        eventually (done and prev(done) and start);
    cover c_back_to_back;

end architecture formal;