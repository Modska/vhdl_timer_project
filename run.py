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

# Regular tests - pass delay in nanoseconds
for freq in [50_000_000, 100_000_000, 68_000_000]: #50 Mhz, 100 Mhz, 68 Mhz
    for delay_ns in [100_000, 50_000, 150_000]:  # 100us and 50us and 150us in nanoseconds
        delay_name = f"{delay_ns//1000}us"
        tb.add_config(
            name=f"F{freq}_D{delay_name}", 
            generics=dict(clk_freq_hz_g=freq, delay_ns_g=delay_ns)
        )

# Zero case
tb.add_config(
    name="Special_Zero", 
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=0)
)

vu.main()