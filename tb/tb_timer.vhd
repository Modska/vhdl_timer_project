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
        variable duration   : time; 
        variable margin     : time;
        variable is_accurate : boolean; -- To store our comparison result
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
                    -- Rounding to 1ns and 500 ps added to solve rounding issues
                    if  abs((now - start_time) - DELAY_TIME) < (CLK_PERIOD / 2) or 
                        abs((now - start_time) - (DELAY_TIME + CLK_PERIOD)) < (CLK_PERIOD / 2) then
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
            -- EDGE CASE: Continuous Start (Back-to-back)
            elsif run("Test_Continuous_Start") then
                if DELAY_TIME > 0 ns then
                -- 1. Setup
                rst <= '1'; wait for 100 ns; rst <= '0';
                wait until rising_edge(clk);
        
                -- 2. Maintain START high
                start <= '1'; 
                wait until done = '0'; -- Wait for 1st cycle to start
                wait until done = '1'; -- Wait for 1st cycle to end
        
                -- 3. Check for immediate restart
                -- We wait for the rising edge where the timer evaluates START
                wait until rising_edge(clk); 
                -- Then we wait for the falling edge to be sure logic has propagated
                wait until falling_edge(clk); 
        
        check(done = '0', "Timer should have restarted immediately with continuous start");
        start <= '0'; 
    end if;
            -- EDGE CASE: Very Short Delay (Minimum cycles)
            elsif run("Test_Minimum_Non_Zero_Delay") then
            -- This test is specifically relevant when DELAY_TIME is very small
            if DELAY_TIME > 0 ns and DELAY_TIME <= CLK_PERIOD then
                info("Testing minimal response time with delay: " & to_string(DELAY_TIME));
        
                -- 1. Reset the system
                rst <= '1'; wait for 100 ns; rst <= '0';
                wait until rising_edge(clk);
        
                -- 2. Trigger the timer
                start <= '1'; wait until rising_edge(clk); start <= '0';
        
                -- 3. Measurement with a strict timeout
                -- A 1-cycle timer should be done within a couple of clock cycles
                wait until done = '1' for 3 * CLK_PERIOD;
        
                -- 4. Validation
                check(done = '1', "Timer took too long or failed to finish for a minimal delay!");
            else
                info("Skipping Minimal_Delay test: DELAY_TIME is too large for this specific edge case.");
            end if;
        end if;
            

        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;