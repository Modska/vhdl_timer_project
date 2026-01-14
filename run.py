from vunit import VUnit
from vunit.sim_if.ghdl import GHDLInterface

# Force mcode backend for GHDL compatibility
def forced_determine_backend(prefix):
    return "mcode"
GHDLInterface.determine_backend = staticmethod(forced_determine_backend)

vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/*.vhd")

tb = lib.test_bench("tb_timer")

# --- 1. Standard Scenarios ---
for freq in [50_000_000, 100_000_000]:
    for delay in ["100us", "50us"]:
        tb.add_config(
            name=f"Standard_F{freq}_D{delay}",
            generics=dict(clk_freq_hz_g=freq, delay_g=delay)
        )

# --- 2. Edge Case (Long Delay) ---
tb.add_config(
    name="Edge_SlowClock_LongDelay",
    generics=dict(clk_freq_hz_g=1000, delay_g="1sec")
)

vu.main()