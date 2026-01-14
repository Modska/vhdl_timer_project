library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Bibliothèques VUnit
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
    generic (runner_cfg : string); -- VUnit injecte la configuration ici
end entity;

architecture sim of tb_timer is
    -- Signaux pour relier au timer
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '0';
    signal done  : std_logic;

    -- Paramètres du test (ex: 50MHz, 100 microsecondes)
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz
    constant DELAY_VAL  : time := 100 us;
begin

    -- 1. Génération de l'horloge
    clk <= not clk after CLK_PERIOD / 2;

    -- 2. Instanciation du Timer (UUT : Unit Under Test)
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

    -- 3. Processus de test VUnit
    main : process
        variable start_time : time;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            if run("Test du délai nominal") then
                -- Initialisation
                rst <= '1';
                wait for 100 ns;
                rst <= '0';
                wait until rising_edge(clk);

                -- Lancement du timer
                start <= '1';
                wait until rising_edge(clk);
                start <= '0';
                
                -- On note quand ça commence (done passe à 0)
                wait until done = '0';
                start_time := now;

                -- On attend la fin (done repasse à 1)
                wait until done = '1';
                
                -- Vérification VUnit (Self-checking)
                check_equal(now - start_time, DELAY_VAL, "Erreur: Le délai ne correspond pas !");
            
            end if;
        end loop;

        test_runner_cleanup(runner);
    end process;

end architecture;