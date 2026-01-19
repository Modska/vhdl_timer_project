#!/bin/bash
# Script to run formal verification with SymbiYosys

set -e

echo "=========================================="
echo "Formal Verification of Timer Module"
echo "=========================================="

# Check if sby is installed
if ! command -v sby &> /dev/null; then
    echo "ERROR: SymbiYosys (sby) is not installed"
    echo "Install OSS CAD Suite from: https://github.com/YosysHQ/oss-cad-suite-build"
    exit 1
fi

# Check if ghdl-yosys plugin is available
if ! command -v ghdl &> /dev/null; then
    echo "ERROR: GHDL is not installed"
    exit 1
fi

echo ""
echo "Running Bounded Model Checking (BMC)..."
sby -f timer.sby bmc

echo ""
echo "Running Inductive Proof..."
sby -f timer.sby prove

echo ""
echo "Running Cover Property Check..."
sby -f timer.sby cover

echo ""
echo "=========================================="
echo "Formal Verification Complete!"
echo "=========================================="
echo ""
echo "Results:"
echo "  - BMC:   Check timer_bmc/logfile.txt"
echo "  - Prove: Check timer_prove/logfile.txt"
echo "  - Cover: Check timer_cover/logfile.txt"