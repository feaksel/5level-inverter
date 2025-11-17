# ==============================================================================
# Quick UART Verification - Vivado Simulation
# ==============================================================================
#
# This script runs a standalone UART simulation without needing a full project.
# Perfect for quick verification of the UART tx_empty race condition fix.
#
# Usage:
#   cd 02-embedded/riscv-soc
#   vivado -mode batch -source vivado/sim_uart_quick.tcl
#
# Or in GUI mode to view waveforms:
#   vivado -mode gui -source vivado/sim_uart_quick.tcl
#

puts ""
puts "========================================"
puts "UART Quick Verification"
puts "========================================"
puts "Testing UART module in standalone mode"
puts ""

# Create temporary simulation directory
set sim_dir "sim_uart_quick"
file mkdir $sim_dir
cd $sim_dir

puts "Setting up simulation..."

# Compile UART module
puts "  Compiling uart.v..."
exec xvlog ../rtl/peripherals/uart.v

# Compile testbench
puts "  Compiling uart_vivado_test.v..."
exec xvlog ../tb/uart_vivado_test.v

# Elaborate design
puts "  Elaborating design..."
exec xelab uart_vivado_test -debug all -s uart_sim

# Run simulation
puts ""
puts "========================================"
puts "Running Simulation"
puts "========================================"
puts ""

# Run in batch mode
exec xsim uart_sim -runall -log uart_test.log -tclbatch ../vivado/xsim_run.tcl

puts ""
puts "========================================"
puts "Simulation Complete"
puts "========================================"
puts ""
puts "Results saved to: $sim_dir/uart_test.log"
puts "Waveform saved to: $sim_dir/uart_vivado_test.wdb"
puts ""
puts "To view waveform:"
puts "  cd $sim_dir"
puts "  xsim --gui uart_vivado_test.wdb"
puts ""
puts "========================================"
puts ""

# Print log file
if {[file exists "uart_test.log"]} {
    puts "Test Output:"
    puts "========================================"
    set fp [open "uart_test.log" r]
    set file_data [read $fp]
    close $fp
    puts $file_data
    puts "========================================"
}

cd ..
