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
            
            -- Runs for all standard configs (if delay > 0)
            if run("Test_Timer_Accuracy") and delay_g > 0 ns then
                rst <= '1'; wait for 100 ns; rst <= '0';
                wait until rising_edge(clk);
                start <= '1'; wait until rising_edge(clk); start <= '0';
                wait until done = '0';
                start_time := now;
                wait until done = '1';
                check_equal(now - start_time, delay_g, "Accuracy failed");

            -- Runs for all standard configs
            elsif run("Test_Reset_During_Counting") and delay_g > 10 us then
                rst <= '1'; wait for 100 ns; rst <= '0';
                wait until rising_edge(clk);
                start <= '1'; wait until rising_edge(clk); start <= '0';
                wait for delay_g / 2;
                rst <= '1'; wait for 100 ns;
                check(done = '1', "Reset failed to stop timer");
                rst <= '0';

            -- Runs ONLY for the 'Special_ZeroDelay' config
            elsif run("Test_Zero_Delay") and delay_g = 0 ns then
                rst <= '1'; wait for 100 ns; rst <= '0';
                wait until rising_edge(clk);
                start <= '1'; wait until rising_edge(clk); start <= '0';
                wait until done = '1' for 2 * CLK_PERIOD;
                check(done = '1', "Zero delay failed");
            end if;

        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;