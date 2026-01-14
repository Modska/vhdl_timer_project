library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
    generic (
        runner_cfg    : string;
        clk_freq_hz_g : positive := 50_000_000; 
        delay_ns_g    : natural  := 100_000
    );
end entity;

architecture sim of tb_timer is
    constant DELAY_TIME : time := delay_ns_g * 1 ns;
    constant CLK_PERIOD : time := 1 sec / clk_freq_hz_g;
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '0';
    signal done  : std_logic;

begin
    clk <= not clk after CLK_PERIOD / 2;

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
        variable measured_delay : time;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            
            -- Test 1: Timer accuracy
            if run("Test_Timer_Accuracy") then
                if DELAY_TIME > 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    -- Start timer
                    start <= '1'; 
                    wait until rising_edge(clk); 
                    start <= '0';
                    
                    -- Measure delay
                    wait until done = '0';
                    start_time := now;
                    wait until done = '1';
                    measured_delay := now - start_time;
                    
                    -- Check accuracy
                    check_equal(measured_delay, DELAY_TIME, "Accuracy mismatch");
                    info("Measured delay: " & time'image(measured_delay));
                else
                    info("Skipping Accuracy test for 0ns delay");
                end if;

            -- Test 2: Reset during counting
            elsif run("Test_Reset_During_Counting") then
                if DELAY_TIME > 20 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    start <= '1'; 
                    wait until rising_edge(clk); 
                    start <= '0';
                    wait until done = '0';
                    
                    -- Reset in the middle
                    wait for DELAY_TIME / 2;
                    rst <= '1'; 
                    wait for 100 ns;
                    check(done = '1', "Done should be high after reset");
                    rst <= '0';
                else
                    info("Skipping Reset test for very short delay");
                end if;

            -- Test 3: Zero delay handling
            elsif run("Test_Zero_Delay") then
                if DELAY_TIME = 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    start <= '1'; 
                    wait until rising_edge(clk); 
                    start <= '0';
                    
                    -- Should remain done
                    wait for 4 * CLK_PERIOD;
                    check(done = '1', "Timer should stay done for 0ns delay");
                else
                    info("Skipping Zero_Delay test for positive delay");
                end if;
            
            -- Test 4: Multiple start pulses (start_i stays high)
            elsif run("Test_Multiple_Start_Pulses") then
                if DELAY_TIME > 10 * CLK_PERIOD then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    -- Keep start high for multiple cycles
                    start <= '1';
                    wait for 5 * CLK_PERIOD;
                    start <= '0';
                    
                    -- Timer should only start once
                    wait until done = '0';
                    start_time := now;
                    wait until done = '1';
                    measured_delay := now - start_time;
                    
                    check_equal(measured_delay, DELAY_TIME, 
                               "Multi-pulse should give same delay");
                else
                    info("Skipping Multiple_Start test for short delay");
                end if;
            
            -- Test 5: Start pulse while busy (should be ignored)
            elsif run("Test_Start_While_Busy") then
                if DELAY_TIME > 20 * CLK_PERIOD then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    -- Start timer
                    start <= '1'; 
                    wait until rising_edge(clk); 
                    start <= '0';
                    wait until done = '0';
                    
                    -- Try to start again while busy
                    wait for DELAY_TIME / 4;
                    start <= '1';
                    wait for 3 * CLK_PERIOD;
                    start <= '0';
                    
                    -- Measure total time - should be unchanged
                    start_time := now - (DELAY_TIME / 4) - (3 * CLK_PERIOD);
                    wait until done = '1';
                    measured_delay := now - start_time;
                    
                    check_equal(measured_delay, DELAY_TIME, 
                               "Start while busy should be ignored");
                else
                    info("Skipping Start_While_Busy test for short delay");
                end if;
            
            -- Test 6: Back-to-back timers
            elsif run("Test_Back_To_Back") then
                if DELAY_TIME > 0 ns and DELAY_TIME < 1 ms then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    
                    -- Run timer twice in a row
                    for i in 1 to 2 loop
                        wait until rising_edge(clk);
                        start <= '1'; 
                        wait until rising_edge(clk); 
                        start <= '0';
                        
                        wait until done = '0';
                        start_time := now;
                        wait until done = '1';
                        measured_delay := now - start_time;
                        
                        check_equal(measured_delay, DELAY_TIME, 
                                   "Back-to-back run " & integer'image(i));
                    end loop;
                else
                    info("Skipping Back_To_Back test");
                end if;

            end if;
        end loop;

        test_runner_cleanup(runner);
    end process;
end architecture;