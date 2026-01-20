# run.py - VHDL Simulation Runner
# Optimized with VUnit to include multiple edge cases and configurations

from vunit import VUnit
from vunit.sim_if.ghdl import GHDLInterface

# Workaround: Force GHDL to use the 'mcode' backend for compatibility with some environments
def forced_determine_backend(prefix): return "mcode"
GHDLInterface.determine_backend = staticmethod(forced_determine_backend)

# Initialize VUnit from command line arguments
vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()

# Create design library and add source/testbench files
lib = vu.add_library("lib")
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/*.vhd")

# Reference to the main testbench entity
tb = lib.test_bench("tb_timer")

# --- REGULAR TEST SCENARIOS ---
# Testing common frequency and delay combinations
# Frequencies: 50 MHz, 100 MHz, 68 MHz
# Delays: 100 us, 50 us, 150 us
for freq in [50_000_000, 100_000_000, 68_000_000]:
    for delay_ns in [100_000, 50_000, 150_000]:
        delay_name = f"{delay_ns//1000}us"
        tb.add_config(
            name=f"F{freq}_D{delay_name}", 
            generics=dict(clk_freq_hz_g=freq, delay_ns_g=delay_ns)
        )

# --- EDGE CASE SCENARIOS ---

# Case 1: Zero Delay
# Verifies system behavior when a timer is triggered with no delay requested
tb.add_config(
    name="Special_Zero", 
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=0)
)

# Case 2: Sub-Clock Period Delay
# At 50 MHz (T = 20 ns), testing a 10 ns delay to check quantization/rounding logic
tb.add_config(
    name="Edge_SubClock_10ns",
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=10)
)

# Case 3: Exact One-Clock Period Delay
# Verifies that the counter handles the minimum representable non-zero delay
tb.add_config(
    name="Edge_OneClock_20ns",
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=20)
)

# Case 4: Long Delay (10 ms)
# Tests for potential counter overflow and handling of larger numeric values
tb.add_config(
    name="Edge_LongDelay_10ms",
    generics=dict(clk_freq_hz_g=50_000_000, delay_ns_g=10_000_000)
)

# Case 5: Low Clock Frequency (1 kHz)
# Verifies timing logic with slower clock cycles (10 ms delay at 1 kHz)
tb.add_config(
    name="Edge_LowFreq_1kHz",
    generics=dict(clk_freq_hz_g=1_000, delay_ns_g=10_000_000)
)

# Execute the simulation suite
vu.main()
