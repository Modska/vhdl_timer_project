# run.py - Version améliorée avec plus de edge cases

from vunit import VUnit
from vunit.sim_if.ghdl import GHDLInterface

def forced_determine_backend(prefix): return "mcode"
GHDLInterface.determine_backend = staticmethod(forced_determine_backend)

vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/*.vhd")

tb = lib.test_bench("tb_timer")

# Tests standards
for freq in [50_000_000, 100_000_000]:
    for delay_ns in [100_000, 50_000]:  # 100us and 50us
        delay_name = f"{delay_ns//1000}us"
        tb.add_config(
            name=f"F{freq}_D{delay_name}", 
            generics=dict(clk_freq_hz_g=freq, delay_ns_g=delay_ns)
        )

# Edge case: délai zéro
tb.add_config(
    name="Special_Zero", 
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=0)
)

# Edge case: très petit délai (< 1 période d'horloge)
# Pour 50 MHz (période = 20 ns), tester 10 ns
tb.add_config(
    name="Edge_SubClock_10ns",
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=10)
)

# Edge case: exactement 1 période d'horloge
tb.add_config(
    name="Edge_OneClock_20ns",
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=20)
)

# Edge case: délai très long (10 ms)
tb.add_config(
    name="Edge_LongDelay_10ms",
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=10_000_000)
)

# Edge case: fréquence basse
tb.add_config(
    name="Edge_LowFreq_1kHz",
    generics=dict(clk_freq_hz_g=1_000, delay_ns_g=10_000_000)  # 10ms à 1kHz
)

vu.main()