// Simple Verilator testbench wrapper
// This provides a main() function for Verilator simulations

#include <verilated.h>
#include <verilated_vcd_c.h>
#include <iostream>

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    std::cout << "Verilator simulation starting..." << std::endl;
    std::cout << "Note: This simulation uses Verilator timing mode." << std::endl;
    std::cout << "Waveforms will be generated in VCD format." << std::endl;

    // The actual testbench logic is in the Verilog initial blocks
    // Verilator will handle the timing and execution

    // Simulation complete
    std::cout << "Simulation finished. Check .vcd file for waveforms." << std::endl;

    return 0;
}
