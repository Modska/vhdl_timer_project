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

# 1. Standard configurations
for freq in [50_000_000, 100_000_000]:
    for delay in ["100us", "50us"]:
        tb.add_config(name=f"F{freq}_D{delay}", generics=dict(clk_freq_hz_g=freq, delay_g=delay))

# 2. Specific case for Zero delay
tb.add_config(name="Special_ZeroDelay", generics=dict(clk_freq_hz_g=50_000_000, delay_g="0ns"))

vu.main()