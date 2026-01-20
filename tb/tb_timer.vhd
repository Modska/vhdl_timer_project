library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- VUnit libraries
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
    generic (
        runner_cfg    : string;
        -- Generics injected by VUnit run.py
        clk_freq_hz_g : positive := 50_000_000; 
        delay_ns_g    : natural  := 100_000  -- Delay in nanoseconds
    );
end entity;

architecture sim of tb_timer is
    -- Convert nanoseconds to time type
    constant DELAY_TIME : time := delay_ns_g * 1 ns;
    
    -- Signals to connect to the Unit Under Test (UUT)
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '0';
    signal done  : std_logic;

    -- Calculate clock period based on injected frequency
    constant CLK_PERIOD : time := 1 sec / clk_freq_hz_g;
begin

    -- Clock generation for simulation
    clk <= not clk after CLK_PERIOD / 2;

    -- Unit Under Test (UUT) Instantiation
    uut: entity work.timer
        generic map (
            clk_freq_hz_g => clk_freq_hz_g,
            delay_g       => DELAY_TIME
        )
        port map (
            clk_i   => clk,
            arst_i  => rst,
            start_i => start,
            done_o  => done
        );

    main : process
        variable start_time  : time;
        variable is_accurate : boolean; 
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            
            -- Test 1: Accuracy verification for standard delays
            if run("Test_Timer_Accuracy") then
                if DELAY_TIME > 0 ns then
                    -- Reset and initialization
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    -- Trigger the timer
                    start <= '1'; wait until rising_edge(clk); start <= '0'; 
                    
                    -- Capture start time when timer acknowledges
                    wait until done = '0';
                    start_time := now; 
                    
                    -- Wait for completion
                    wait until done = '1';
                    
                    -- Validation using adaptive margin (0.75 * Period)
                    -- Checks if measured duration is Target OR Target + 1 Cycle
                    if abs((now - start_time) - DELAY_TIME) < (CLK_PERIOD * 3 / 4) or 
                       abs((now - start_time) - (DELAY_TIME + CLK_PERIOD)) < (CLK_PERIOD * 3 / 4) then
                        is_accurate := true;
                    else
                        is_accurate := false;
                    end if;

                    check(is_accurate, 
                          "Accuracy mismatch! Measured: " & to_string(now - start_time) & 
                          " | Target: " & to_string(DELAY_TIME));
                else
                    info("Skipping Accuracy test for 0ns delay");
                end if;

            -- Test 2: Verify reset behavior during operation
            elsif run("Test_Reset_During_Counting") then
                if DELAY_TIME > 20 ns then 
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    wait until done = '0';
                    
                    -- Apply reset halfway through the countdown
                    wait for DELAY_TIME / 2;
                    rst <= '1'; wait for 100 ns;
                    
                    check(done = '1', "Done signal should be high (idle) during/after reset");
                    rst <= '0';
                else
                    info("Skipping Reset test for very short delay");
                end if;

            -- Test 3: Specific handling of 0ns delay configuration
            elsif run("Test_Zero_Delay") then
                if DELAY_TIME = 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    
                    -- Timer should be done almost immediately (within 4 cycles)
                    wait until done = '1' for 4 * CLK_PERIOD;
                    check(done = '1', "Timer failed to handle 0ns delay configuration");
                else
                    info("Skipping Zero_Delay test for positive delay config");
                end if;

            -- EDGE CASE: Check if timer restarts correctly if START is held high
            elsif run("Test_Continuous_Start") then
                if DELAY_TIME > 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
            
                    start <= '1'; -- Keep start high
                    wait until done = '0'; -- First run starts
                    wait until done = '1'; -- First run ends
            
                    -- Wait for the logic to evaluate the next cycle
                    wait until rising_edge(clk); 
                    wait until falling_edge(clk); 
            
                    check(done = '0', "Timer should have restarted immediately with continuous start signal");
                    start <= '0'; 
                end if;

            -- EDGE CASE: Verify response when delay is shorter than one clock cycle
            elsif run("Test_Minimum_Non_Zero_Delay") then
                if DELAY_TIME > 0 ns and DELAY_TIME <= CLK_PERIOD then
                    info("Testing minimal response time with delay: " & to_string(DELAY_TIME));
            
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
            
                    start <= '1'; wait until rising_edge(clk); start <= '0';
            
                    -- Protection: must finish within 3 cycles
                    wait until done = '1' for 3 * CLK_PERIOD;
            
                    check(done = '1', "Timer failed to finish for a minimal delay within expected time");
                else
                    info("Skipping Minimal_Delay test: DELAY_TIME is outside minimal range");
                end if;
            
            -- EDGE CASE: Verify that extra START pulses during counting are ignored
            elsif run("Test_Timer_Ignore_Extra_Start") then
                if DELAY_TIME > 50 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
            
                    -- Initial start
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    start_time := now; 
                    wait until done = '0'; 
            
                    -- Send a second "parasite" START pulse halfway through
                    wait for DELAY_TIME / 4;
                    start <= '1'; wait until rising_edge(clk); start <= '0';
            
                    -- Wait for completion with a timeout watchdog (prevents infinite loop)
                    wait until done = '1' for DELAY_TIME * 2;
            
                    check(done = '1', "Simulation Timeout: Timer got stuck after extra start pulse!");
            
                    -- If ignored, total time should remain ~DELAY_TIME
                    if abs((now - start_time) - DELAY_TIME) < (CLK_PERIOD * 3 / 4) or 
                       abs((now - start_time) - (DELAY_TIME + CLK_PERIOD)) < (CLK_PERIOD * 3 / 4) then
                        is_accurate := true;
                    else
                        is_accurate := false;
                    end if;

                    check(is_accurate, "Timer restarted or shifted incorrectly! Measured: " & to_string(now - start_time));
                end if;
            end if;

        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
