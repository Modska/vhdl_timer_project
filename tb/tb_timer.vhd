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
        delay_g       : time     := 100 us
    );
end entity;

architecture sim of tb_timer is
    -- Signals to connect to the timer
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '0';
    signal done  : std_logic;

    -- Calculate clock period based on injected frequency
    constant CLK_PERIOD : time := 1 sec / clk_freq_hz_g;
begin

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2;

    -- Unit Under Test (UUT) Instantiation
    uut: entity work.timer
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

main : process
        variable start_time : time;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            
            -- Runs ONLY for positive delays (Standard tests)
            if run("Test_Timer_Accuracy") then
                if delay_g > 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    wait until done = '0';
                    start_time := now;
                    wait until done = '1';
                    check_equal(now - start_time, delay_g, "Accuracy mismatch");
                else
                    info("Skipping Accuracy test for 0ns delay");
                end if;

            -- Runs for standard delays to test reset
            elsif run("Test_Reset_During_Counting") then
                if delay_g > 20 ns then -- Need some time to actually be counting
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    wait until done = '0';
                    wait for delay_g / 2;
                    rst <= '1'; wait for 100 ns;
                    check(done = '1', "Done should be high after reset");
                    rst <= '0';
                else
                    info("Skipping Reset test for very short delay");
                end if;

            -- Runs ONLY for the 0ns configuration
            elsif run("Test_Zero_Delay") then
                if delay_g = 0 ns then
                    rst <= '1'; wait for 100 ns; rst <= '0';
                    wait until rising_edge(clk);
                    start <= '1'; wait until rising_edge(clk); start <= '0';
                    -- Should be done almost immediately
                    wait until done = '1' for 4 * CLK_PERIOD;
                    check(done = '1', "Timer failed to handle 0ns delay");
                else
                    info("Skipping Zero_Delay test for positive delay config");
                end if;
            end if;

        end loop;

        test_runner_cleanup(runner);
    end process;
end architecture;