#!/bin/bash
# ==============================================================================
# UART Verification Test Runner
# ==============================================================================
#
# This script runs the UART verification test using either:
#   1. Icarus Verilog (open-source, fast)
#   2. Vivado XSim (commercial, full-featured)
#
# Usage:
#   ./run_uart_test.sh [iverilog|vivado]
#
# If no argument is provided, it will auto-detect available tools.
#

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "========================================"
echo "  UART Verification Test Runner"
echo "========================================"
echo ""

# Determine which simulator to use
SIMULATOR=${1:-auto}

if [ "$SIMULATOR" = "auto" ]; then
    echo "Auto-detecting simulation tools..."
    if command -v iverilog &> /dev/null; then
        SIMULATOR="iverilog"
        echo -e "${GREEN}✓ Found: Icarus Verilog${NC}"
    elif command -v xvlog &> /dev/null; then
        SIMULATOR="vivado"
        echo -e "${GREEN}✓ Found: Vivado XSim${NC}"
    else
        echo -e "${RED}✗ Error: No simulation tools found!${NC}"
        echo ""
        echo "Please install one of:"
        echo "  - Icarus Verilog: sudo apt-get install iverilog"
        echo "  - Vivado (Xilinx)"
        echo ""
        exit 1
    fi
fi

echo "Using simulator: $SIMULATOR"
echo ""

# Create simulation directory
SIM_DIR="sim"
mkdir -p $SIM_DIR

# ==============================================================================
# Icarus Verilog Simulation
# ==============================================================================

if [ "$SIMULATOR" = "iverilog" ]; then
    echo "========================================"
    echo " Running with Icarus Verilog"
    echo "========================================"
    echo ""

    echo "Compiling design..."
    iverilog -g2012 \
        -o $SIM_DIR/uart_test.vvp \
        rtl/peripherals/uart.v \
        tb/uart_vivado_test.v

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Compilation successful${NC}"
    else
        echo -e "${RED}✗ Compilation failed${NC}"
        exit 1
    fi

    echo ""
    echo "Running simulation..."
    echo "========================================"
    vvp $SIM_DIR/uart_test.vvp | tee $SIM_DIR/uart_test.log

    echo ""
    echo "========================================"
    echo "Simulation complete!"
    echo "========================================"
    echo "Log file: $SIM_DIR/uart_test.log"
    echo "Waveform: $SIM_DIR/uart_vivado_test.vcd"
    echo ""
    echo "To view waveform:"
    echo "  gtkwave $SIM_DIR/uart_vivado_test.vcd"
    echo ""

# ==============================================================================
# Vivado XSim Simulation
# ==============================================================================

elif [ "$SIMULATOR" = "vivado" ]; then
    echo "========================================"
    echo " Running with Vivado XSim"
    echo "========================================"
    echo ""

    cd $SIM_DIR

    echo "Compiling UART module..."
    xvlog ../rtl/peripherals/uart.v

    echo "Compiling testbench..."
    xvlog ../tb/uart_vivado_test.v

    echo "Elaborating design..."
    xelab uart_vivado_test -debug typical -s uart_sim

    echo ""
    echo "Running simulation..."
    echo "========================================"
    xsim uart_sim -runall -log uart_test.log

    cd ..

    echo ""
    echo "========================================"
    echo "Simulation complete!"
    echo "========================================"
    echo "Log file: $SIM_DIR/uart_test.log"
    echo "Waveform: $SIM_DIR/uart_vivado_test.wdb"
    echo ""
    echo "To view waveform:"
    echo "  cd $SIM_DIR"
    echo "  xsim --gui uart_sim"
    echo ""

else
    echo -e "${RED}Error: Unknown simulator '$SIMULATOR'${NC}"
    echo "Valid options: iverilog, vivado, auto"
    exit 1
fi

# ==============================================================================
# Check results
# ==============================================================================

echo ""
echo "========================================"
echo " Test Results Summary"
echo "========================================"

if grep -q "ALL TESTS PASSED" $SIM_DIR/uart_test.log; then
    echo -e "${GREEN}"
    echo "  ✓✓✓ ALL TESTS PASSED! ✓✓✓"
    echo ""
    echo "  ✓ UART module is working correctly"
    echo "  ✓ tx_empty race condition is FIXED"
    echo "  ✓ Ready for use in SoC"
    echo -e "${NC}"
    exit 0
elif grep -q "SOME TESTS FAILED" $SIM_DIR/uart_test.log; then
    echo -e "${RED}"
    echo "  ✗ SOME TESTS FAILED"
    echo ""
    echo "  Review the log file for details:"
    echo "    $SIM_DIR/uart_test.log"
    echo -e "${NC}"
    exit 1
else
    echo -e "${YELLOW}"
    echo "  ? Unable to determine test result"
    echo ""
    echo "  Check the log file:"
    echo "    $SIM_DIR/uart_test.log"
    echo -e "${NC}"
    exit 1
fi
