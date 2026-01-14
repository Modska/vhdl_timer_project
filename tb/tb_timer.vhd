library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
    generic (runner_cfg : string);
end entity;

architecture sim of tb_timer is
    -- Signals
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '0';
    signal done  : std_logic;

    -- Test parameters
    constant CLK_PERIOD : time := 20 ns; 
    constant DELAY_VAL  : time := 100 us;
begin

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2;

    -- UUT Instantiation
    uut: entity work.timer
        generic map (
            clk_freq_hz_g => 50_000_000,
            delay_g       => DELAY_VAL
        )
        port map (
            clk_i   => clk,
            arst_i  => rst,
            start_i => start,
            done_o  => done
        );

    -- Main Test Process
    main : process
        variable start_time : time;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            if run("Test_nominal_delay") then 
                -- Reset
                rst <= '1';
                wait for 100 ns;
                rst <= '0';
                wait until rising_edge(clk);

                -- Start
                start <= '1';
                wait until rising_edge(clk);
                start <= '0';
                
                -- Detect falling edge (start of counting)
                wait until done = '0';
                start_time := now;

                -- Detect rising edge (end of counting)
                wait until done = '1';
                
                -- Check result
                check_equal(now - start_time, DELAY_VAL, "Delay_Mismatch");
            end if;
        end loop;

        test_runner_cleanup(runner);
    end process;

end architecture;