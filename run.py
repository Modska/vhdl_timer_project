from vunit import VUnit

# Create VUnit instance
vu = VUnit.from_argv()

# Create a library named 'lib'
lib = vu.add_library("lib")

# Add all VHDL files from src and tb folders
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/*.vhd")

# Run the simulation
vu.main()