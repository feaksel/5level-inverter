# ==============================================================================
# Vivado Project Creation Script for RISC-V SoC
# ==============================================================================
#
# This script automates the creation of the Vivado project for the 5-level
# inverter RISC-V SoC with VexRiscv CPU core.
#
# Usage (from Windows Command Prompt or PowerShell):
#   cd \\wsl$\Ubuntu\home\<username>\5level-inverter\02-embedded\riscv-soc
#   vivado -mode batch -source create_vivado_project.tcl
#
# Or from Vivado TCL Console:
#   source create_vivado_project.tcl
#
# ==============================================================================

# Project configuration
set proj_name "riscv_soc"
set proj_dir "./vivado_project"
set rtl_dir "./rtl"
set constraints_dir "./constraints"
set firmware_dir "./firmware"

# Target FPGA (Basys 3)
set part "xc7a35tcpg236-1"

puts ""
puts "===================================="
puts "Creating RISC-V SoC Vivado Project"
puts "===================================="
puts ""

# Create project directory
file mkdir $proj_dir

# Create new project
create_project $proj_name $proj_dir -part $part -force

puts "✓ Project created: $proj_name"

# ==============================================================================
# Add RTL Source Files
# ==============================================================================

puts ""
puts "Adding RTL source files..."

# Top level
add_files [glob $rtl_dir/soc_top.v]

# CPU
add_files [glob $rtl_dir/cpu/VexRiscv.v]
add_files [glob $rtl_dir/cpu/vexriscv_wrapper.v]

# Bus
add_files [glob $rtl_dir/bus/wishbone_interconnect.v]

# Memory
add_files [glob $rtl_dir/memory/rom_32kb.v]
add_files [glob $rtl_dir/memory/ram_64kb.v]

# Peripherals
add_files [glob $rtl_dir/peripherals/pwm_accelerator.v]
add_files [glob $rtl_dir/peripherals/adc_interface.v]
add_files [glob $rtl_dir/peripherals/protection.v]
add_files [glob $rtl_dir/peripherals/timer.v]
add_files [glob $rtl_dir/peripherals/gpio.v]
add_files [glob $rtl_dir/peripherals/uart.v]

# Utilities
add_files [glob $rtl_dir/utils/pwm_comparator.v]
add_files [glob $rtl_dir/utils/carrier_generator.v]
add_files [glob $rtl_dir/utils/sine_generator.v]

puts "✓ Added RTL files"

# ==============================================================================
# Add Constraints
# ==============================================================================

puts ""
puts "Adding constraints..."

if {[file exists $constraints_dir/basys3_pins.xdc]} {
    add_files -fileset constrs_1 [glob $constraints_dir/basys3_pins.xdc]
    puts "✓ Added constraints: basys3_pins.xdc"
} else {
    puts "⚠ Warning: Constraints file not found: $constraints_dir/basys3_pins.xdc"
    puts "  You can add it later or create one manually"
}

# ==============================================================================
# Add Firmware (for simulation and ROM initialization)
# ==============================================================================

puts ""
puts "Adding firmware files..."

if {[file exists $firmware_dir/firmware.hex]} {
    # Add as data file (for simulation)
    add_files -fileset sim_1 [glob $firmware_dir/firmware.hex]
    # Also add to sources (so ROM can find it)
    add_files [glob $firmware_dir/firmware.hex]
    set_property file_type "Memory File" [get_files firmware.hex]
    puts "✓ Added firmware: firmware.hex"
} else {
    puts "⚠ Warning: Firmware not found: $firmware_dir/firmware.hex"
    puts "  Build firmware first: cd firmware && make"
}

# ==============================================================================
# Set Top Module
# ==============================================================================

puts ""
puts "Setting top module..."

set_property top soc_top [current_fileset]
update_compile_order -fileset sources_1

puts "✓ Top module set: soc_top"

# ==============================================================================
# Project Settings
# ==============================================================================

puts ""
puts "Configuring project settings..."

# Set target language to Verilog
set_property target_language Verilog [current_project]

# Enable generation of simulation scripts
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

# Set synthesis strategy
set_property strategy {Flow_PerfOptimized_high} [get_runs synth_1]

# Set implementation strategy
set_property strategy {Performance_ExplorePostRoutePhysOpt} [get_runs impl_1]

puts "✓ Project configured"

# ==============================================================================
# Summary
# ==============================================================================

puts ""
puts "===================================="
puts "Project Creation Complete!"
puts "===================================="
puts ""
puts "Project: $proj_name"
puts "Location: $proj_dir/$proj_name.xpr"
puts "Part: $part (Basys 3)"
puts ""
puts "Next steps:"
puts "  1. Open project: vivado $proj_dir/$proj_name.xpr"
puts "  2. Run synthesis: launch_runs synth_1"
puts "  3. Run implementation: launch_runs impl_1"
puts "  4. Generate bitstream: launch_runs impl_1 -to_step write_bitstream"
puts ""
puts "Or run full build:"
puts "  vivado -mode batch -source build.tcl"
puts ""
