from vunit import VUnit
import os

# Create VUnit instance with deprecated warnings fixed
vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()

# Create a library named 'lib'
lib = vu.add_library("lib")

# Add all VHDL files from src and tb folders
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/*.vhd")

# Run the simulation
vu.main()