library ieee ;
use ieee . std_logic_1164 . all ;
use ieee . numeric_std . all ;
use ieee . math_real .all ;

entity timer is
 generic (
 clk_freq_hz_g : natural ; -- Clock frequency in Hz
 delay_g : time -- Delay duration , e.g. , 100 ms
 ) ;
 port (
 clk_i : in std_ulogic ;
 arst_i : in std_ulogic ;
 start_i : in std_ulogic ; -- No effect if not done_o
 done_o : out std_ulogic -- ’1 ’ when not counting (" not busy ")
 ) ;
 end entity timer ;

architecture rtl of timer is
    -- Calcul de la limite (Hypothèse : le résultat doit tenir dans un entier 32 bits)
    constant MAX_COUNT : natural := clk_freq_hz_g * (delay_g / 1 sec);
    
    -- Registre du compteur
    signal count_reg : natural range 0 to MAX_COUNT := 0;
    
    -- Signal interne pour savoir si on est en train de compter
    signal busy : std_ulogic := '0';
begin

    process(clk_i, arst_i)
    begin
        if arst_i = '1' then
            count_reg <= 0;
            busy      <= '0';
            done_o    <= '1';
        elsif rising_edge(clk_i) then
            if busy = '0' then
                -- État de repos : on attend le start
                if start_i = '1' then
                    busy    <= '1';
                    count_reg <= 0;
                    done_o  <= '0';
                else
                    done_o  <= '1';
                end if;
            else
                -- État actif : on compte les cycles
                if count_reg < MAX_COUNT - 1 then
                    count_reg <= count_reg + 1;
                else
                    -- Terminé !
                    count_reg <= 0;
                    busy      <= '0';
                    done_o    <= '1';
                end if;
            end if;
            
        end if;
    end process;

end architecture rtl;