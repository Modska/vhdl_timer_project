library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- VUnit libraries for test automation
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
    generic (
        runner_cfg    : string;
        -- Generics injected by VUnit run.py
        clk_freq_hz_g : positive := 50_000_000; 
        delay_ns_g    : natural  := 100_000  -- Target delay in nanoseconds
    );
end entity;

architecture sim of tb_timer is
    -- Internal constant to convert numeric nanoseconds to VHDL time type
    constant DELAY_TIME : time := delay_ns_g * 1 ns;
    
    -- Interface signals for the Unit Under Test (UUT)
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '0';
    signal done  : std_logic;

    -- Clock period calculation based on the frequency injected by the runner
    constant CLK_PERIOD : time := 1 sec / clk_freq_hz_g;
begin

    -- Clock Generation: Oscillates at the calculated period
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

    -- Main Test Process
    main : process
        variable start_time  : time;
        variable is_accurate : boolean; 
    begin
        test_runner_setup(runner, runner_cfg);

        -- Iterate through all configurations defined in run.py
        while test_suite loop
            
            -- SCENARIO 1: Basic timing accuracy for standard operation
            if run("Test_Timer_Accuracy") then
                if DELAY_TIME > 0 ns then
                    -- Initial system reset
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    -- Trigger pulse (one clock cycle wide)
                    start <= '1'; wait until rising_edge(clk); start <= '0'; 
                    
                    -- Measurement start: triggered when done_o falls (Busy state)
                    wait until done = '0';
                    start_time := now; 
                    
                    -- Measurement end: triggered when done_o rises (Idle state)
                    wait until done = '1';
                    
                    -- Validation logic using an adaptive margin (0.75 * Clock Period)
                    -- Accounts for discrete sampling jitter: duration must be Target OR Target + 1 Cycle
                    if abs((now - start_time) - DELAY_TIME) < (CLK_PERIOD * 3 / 4) or 
                       abs((now - start_time) - (DELAY_TIME + CLK_PERIOD)) < (CLK_PERIOD * 3 / 4) then
                        is_accurate := true;
                    else
                        is_accurate := false;
                    end if;

                    check(is_accurate, 
                          "Timing accuracy failure! Measured duration: " & to_string(now - start_time) & 
                          " | Expected target: " & to_string(DELAY_TIME));
                else
                    info("Skipping Accuracy test: Not applicable for 0ns delay");
                end if;

            -- SCENARIO 2: Asynchronous reset mid-operation
            elsif run("Test_Reset_During_Counting") then
                if DELAY_TIME > 20 ns then 
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    wait until done = '0';
                    
                    -- Abort the process halfway through the requested delay
                    wait for DELAY_TIME / 2;
                    rst <= '1'; wait for 100 ns;
                    
                    check(done = '1', "Safety failure: Done signal must return to Idle state immediately during reset");
                    rst <= '0';
                else
                    info("Skipping Reset test: Delay is too short for mid-cycle interruption");
                end if;

            -- SCENARIO 3: Zero delay configuration handling
            elsif run("Test_Zero_Delay") then
                if DELAY_TIME = 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    
                    -- Logic must process zero delay without freezing (Watchdog: 4 clock cycles)
                    wait until done = '1' for 4 * CLK_PERIOD;
                    check(done = '1', "Robustness failure: Timer failed to exit busy state for 0ns configuration");
                else
                    info("Skipping Zero_Delay test: Current config uses positive delay");
                end if;

            -- EDGE CASE: Continuous 'start' signal (should auto-restart)
            elsif run("Test_Continuous_Start") then
                if DELAY_TIME > 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
            
                    start <= '1'; -- Hold signal high permanently
                    wait until done = '0'; -- Verify first trigger
                    wait until done = '1'; -- Verify first completion
            
                    -- Allow logic to re-evaluate the high 'start' signal on the next cycle
                    wait until rising_edge(clk); 
                    wait until falling_edge(clk); 
            
                    check(done = '0', "Logic error: Timer failed to re-trigger despite continuous start signal");
                    start <= '0'; 
                end if;

            -- EDGE CASE: Delay requested is smaller than one clock period
            elsif run("Test_Minimum_Non_Zero_Delay") then
                if DELAY_TIME > 0 ns and DELAY_TIME <= CLK_PERIOD then
                    info("Verifying minimal pulse handling for delay: " & to_string(DELAY_TIME));
            
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
            
                    start <= '1'; wait until rising_edge(clk); start <= '0';
            
                    -- Timer must finish within a deterministic time (Watchdog: 3 cycles)
                    wait until done = '1' for 3 * CLK_PERIOD;
            
                    check(done = '1', "Performance failure: Timer did not complete minimal delay within expected cycles");
                else
                    info("Skipping Minimal_Delay test: DELAY_TIME exceeds minimal period threshold");
                end if;
            
            -- EDGE CASE: Verify that spurious START pulses during countdown are ignored
            elsif run("Test_Timer_Ignore_Extra_Start") then
                if DELAY_TIME > 50 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
            
                    -- Initial trigger
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    start_time := now; 
                    wait until done = '0'; 
            
                    -- Inject a parasite START pulse during active countdown
                    wait for DELAY_TIME / 4;
                    start <= '1'; wait until rising_edge(clk); start <= '0';
            
                    -- Watchdog to detect infinite loops or logic stalls
                    wait until done = '1' for DELAY_TIME * 2;
            
                    check(done = '1', "Stall detected: Timer locked up after receiving extra start pulse during operation");
            
                    -- Validate that the duration remained the same (parasite pulse was ignored)
                    if abs((now - start_time) - DELAY_TIME) < (CLK_PERIOD * 3 / 4) or 
                       abs((now - start_time) - (DELAY_TIME + CLK_PERIOD)) < (CLK_PERIOD * 3 / 4) then
                        is_accurate := true;
                    else
                        is_accurate := false;
                    end if;

                    check(is_accurate, "Jitter failure: Timer duration was shifted or restarted by a parasite pulse");
                end if;
            end if;

        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
