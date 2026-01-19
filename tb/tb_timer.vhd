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
    -- Convert nanoseconds to time
    constant DELAY_TIME : time := delay_ns_g * 1 ns;
    
    -- Signals to connect to the timer
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
        variable start_time : time;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            
            -- Runs ONLY for positive delays (Standard tests)
            if run("Test_Timer_Accuracy") then
                if DELAY_TIME > 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    start <= '1'; wait until rising_edge(clk); start <= '0'; --starting the timer
                    wait until done = '0';
                    start_time := now; 
                    wait until done = '1';
                    check_equal(now - start_time, DELAY_TIME, "Accuracy mismatch"); --Comparaison between the test time and the simulated time
                else
                    info("Skipping Accuracy test for 0ns delay");
                end if;

            -- Runs for standard delays to test reset
            elsif run("Test_Reset_During_Counting") then
                if DELAY_TIME > 20 ns then -- Need some time to actually be counting
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    wait until done = '0';
                    wait for DELAY_TIME / 2;
                    rst <= '1'; wait for 100 ns;
                    check(done = '1', "Done should be high after reset");
                    rst <= '0';
                else
                    info("Skipping Reset test for very short delay");
                end if;

            -- Runs ONLY for the 0ns configuration
            elsif run("Test_Zero_Delay") then
                if DELAY_TIME = 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    -- Should be done almost immediately because the is no waiting 
                    wait until done = '1' for 4 * CLK_PERIOD;
                    check(done = '1', "Timer failed to handle 0ns delay");
                else
                    info("Skipping Zero_Delay test for positive delay config");
                end if;
            -- EDGE CASE: Start signal ignored while already counting
            elsif run("Test_Ignore_Start_During_Counting") then
                if DELAY_TIME > 50 ns then
                    -- 1. System initialization
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    -- 2. First valid start pulse
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    -- Wait for the timer to acknowledge by dropping the done signal
                    wait until done = '0';
                    start_time := now; -- Start measuring time here
                    -- 3. Attempt to disturb the timer with a second start pulse
                    -- Wait for 25% of the duration before sending the glitch/extra pulse
                    wait for DELAY_TIME / 4;
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    
                    -- 4. Wait for the natural completion of the timer
                    wait until done = '1';
                    wait until done = '1';
                    
                    -- 5. Final validation
                    -- If the timer ignored the second start, total time will match DELAY_TIME.
                    -- If it incorrectly restarted, total time would be (DELAY_TIME + DELAY_TIME/4).
                    check_equal(now - start_time, DELAY_TIME, 
                        "Error: Timer restarted or shifted its end time upon receiving an extra start pulse!");
                end if;
            end if;
            

        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;