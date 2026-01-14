from vunit import VUnit
from vunit.sim_if.ghdl import GHDLInterface

# Fix for GHDL "Dunoon" version detection
def forced_determine_backend(prefix):
    return "mcode"
GHDLInterface.determine_backend = staticmethod(forced_determine_backend)

vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/*.vhd")

tb = lib.test_bench("tb_timer")

# --- Standard Scenarios ---
for freq in [50_000_000, 100_000_000]:
    for delay in ["100us", "50us"]:
        tb.add_config(
            name=f"Standard_F{freq}_D{delay}",
            generics=dict(clk_freq_hz_g=freq, delay_g=delay)
        )

# --- Edge Cases (Large Values) ---
tb.add_config(
    name="Edge_SlowClock_LongDelay",
    generics=dict(clk_freq_hz_g=1000, delay_g="1sec")
)

# --- Invalid Values (Fixed Syntax) ---
# We use attributes={'expect_fail': True} for modern VUnit versions
tb.add_config(
    name="Invalid_Zero_Frequency",
    generics=dict(clk_freq_hz_g=0, delay_g="100us"),
    attributes={'expect_fail': True} 
)

tb.add_config(
    name="Invalid_Negative_Delay",
    generics=dict(clk_freq_hz_g=50_000_000, delay_g="-10us"),
    attributes={'expect_fail': True}
)

vu.main()