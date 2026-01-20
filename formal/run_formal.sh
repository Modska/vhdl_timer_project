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

# Check if ghdl is available
if ! command -v ghdl &> /dev/null; then
    echo "ERROR: GHDL is not installed"
    exit 1
fi

echo ""
echo "Running Bounded Model Checking (BMC)..."
timeout 300 sby -f timer.sby bmc || echo "BMC completed with exit code $?"

echo ""
echo "Running Cover Property Check..."
timeout 300 sby -f timer.sby cover || echo "Cover completed with exit code $?"

echo ""
echo "=========================================="
echo "Formal Verification Complete!"
echo "=========================================="
echo ""
echo "Results:"
if [ -f timer_bmc/status ]; then
    echo "  - BMC:   $(cat timer_bmc/status)"
fi
if [ -f timer_cover/status ]; then
    echo "  - Cover: $(cat timer_cover/status)"
fi
echo ""
echo "Detailed logs:"
echo "  - BMC:   timer_bmc/logfile.txt"
echo "  - Cover: timer_cover/logfile.txt"