library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_formal is
    -- On définit des génériques fixes pour la preuve formelle
    -- 10 Hz et 500 ms = 5 cycles d'horloge. C'est suffisant pour prouver la logique.
    generic (
        g_clk_freq : natural := 10;
        g_delay    : time    := 500 ms
    );
    port (
        clk_i   : in std_logic;
        arst_i  : in std_logic;
        start_i : in std_logic;
        done_o  : out std_logic
    );
end entity;

architecture formal of timer_formal is
    
    -- Constante locale correspondant au calcul interne du DUT
    -- 10 Hz * 0.5s = 5 cycles
    constant C_CYCLES : natural := 5; 

begin

    -- Instanciation du Design Under Test (DUT)
    -- On mappe les génériques pour forcer une petite valeur de comptage
    i_dut : entity work.timer
        generic map (
            clk_freq_hz_g => g_clk_freq,
            delay_g       => g_delay
        )
        port map (
            clk_i   => clk_i,
            arst_i  => arst_i,
            start_i => start_i,
            done_o  => done_o
        );

    -- =========================================================
    -- PROPRIÉTÉS PSL (Property Specification Language)
    -- =========================================================
    -- psl default clock is rising_edge(clk_i);

    -- 1. RESET CHECK
    -- Si Reset est actif, done_o doit être à '1' (Idle) immédiatement
    -- psl assert always (arst_i = '1' -> done_o = '1');

    -- 2. START BEHAVIOR
    -- Si on est Idle (done_o=1), pas de reset, et qu'on reçoit Start :
    -- Au cycle suivant, done_o doit passer à '0' (Busy).
    -- psl assert always (start_i = '1' and done_o = '1' and arst_i = '0' -> next done_o = '0');

    -- 3. DURATION CHECK (Le cœur de la preuve)
    -- Si on démarre, done_o doit rester à '0' pendant exactement C_CYCLES.
    -- La syntaxe [*5] signifie "répété 5 fois".
    -- psl assert always (
    --     (start_i = '1' and done_o = '1' and arst_i = '0') -> 
    --     next (done_o = '0' [*5])
    -- );

    -- 4. COMPLETION CHECK
    -- Après C_CYCLES d'activité, le timer doit revenir à '1'.
    -- next[A](B) signifie "dans A cycles, B doit être vrai".
    -- On ajoute 1 car le done_o remonte au cycle APRES la fin du comptage.
    -- psl assert always (
    --     (start_i = '1' and done_o = '1' and arst_i = '0') -> 
    --     next[6] (done_o = '1')
    -- );

    -- 5. STABILITY (Ignorer Start pendant le comptage)
    -- Si on est déjà occupé (done_o=0), un start ne doit rien changer (le compteur ne reset pas).
    -- C'est implicitement couvert par la propriété de durée, mais on peut vérifier que done_o ne remonte pas trop tôt.
    -- psl assert always (
    --     (done_o = '0' and arst_i = '0') -> next done_o = '0' until! count_finished
    -- );

end architecture;