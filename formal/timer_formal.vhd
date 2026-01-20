library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_formal is
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
    constant C_CYCLES : natural := 5; 
begin

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
    -- psl assert always (arst_i = '1' -> done_o = '1');

    -- 2. START BEHAVIOR
    -- psl assert always (start_i = '1' and done_o = '1' and arst_i = '0' -> next done_o = '0');

    -- 3. DURATION CHECK
    -- psl assert always ((start_i = '1' and done_o = '1' and arst_i = '0') -> next (done_o = '0' [*5]));

    -- 4. COMPLETION CHECK
    -- psl assert always ((start_i = '1' and done_o = '1' and arst_i = '0') -> next[6] (done_o = '1'));

    -- =========================================================
    -- AJOUT POUR LE MODE COVER
    -- =========================================================
    -- Cette ligne cherche un scénario où le timer démarre (start) puis finit (done)
    -- psl c_timer_complete : cover {start_i = '1'; done_o = '0'[*1 to 10]; done_o = '1'};

end architecture;