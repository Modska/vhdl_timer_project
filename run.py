from vunit import VUnit
from vunit.sim_if.ghdl import GHDLInterface
import os

# --- THE FIX ---
# We manually override the backend detection because VUnit fails 
# to parse "mcode JIT code generator"
def forced_determine_backend(prefix):
    return "mcode"

GHDLInterface.determine_backend = staticmethod(forced_determine_backend)
# ---------------

# Initialize VUnit
vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()

# Library and files setup
lib = vu.add_library("lib")
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/*.vhd")

# Run
vu.main()