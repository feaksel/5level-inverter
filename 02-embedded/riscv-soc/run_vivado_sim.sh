#!/bin/bash
# Script to run Vivado simulation with proper PATH setup

# Common Vivado installation paths
VIVADO_PATHS=(
    "/c/Xilinx/Vivado/2023.2/bin"
    "/c/Xilinx/Vivado/2023.1/bin"
    "/c/Xilinx/Vivado/2022.2/bin"
    "/c/Xilinx/Vivado/2022.1/bin"
    "/c/Xilinx/Vivado/2021.2/bin"
    "/c/Xilinx/Vivado/2021.1/bin"
    "/c/Xilinx/Vivado/2020.2/bin"
    "/c/Program Files/Xilinx/Vivado/2023.2/bin"
    "/c/Program Files/Xilinx/Vivado/2023.1/bin"
)

# Find Vivado installation
VIVADO_BIN=""
for path in "${VIVADO_PATHS[@]}"; do
    if [ -f "$path/vivado.bat" ]; then
        VIVADO_BIN="$path"
        echo "Found Vivado at: $VIVADO_BIN"
        break
    fi
done

if [ -z "$VIVADO_BIN" ]; then
    echo "ERROR: Could not find Vivado installation!"
    echo "Please install Vivado or update the VIVADO_PATHS in this script"
    exit 1
fi

# Add Vivado to PATH
export PATH="$VIVADO_BIN:$PATH"

# Navigate to project directory
cd "$(dirname "$0")/vivado_project" || exit 1

# Run simulation
echo "Running Vivado simulation..."
vivado -mode batch -source ../run_sim.tcl 2>&1 | tee sim_output.log

echo ""
echo "Simulation complete. Check sim_output.log for details."
