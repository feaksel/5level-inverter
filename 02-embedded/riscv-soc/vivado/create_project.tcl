# ==============================================================================
# create_project.tcl
# Vivado TCL Script to Create RISC-V SoC Project
#
# Usage:
#   vivado -mode batch -source create_project.tcl
#   OR
#   vivado -mode tcl -source create_project.tcl
#
# Target: Digilent Basys 3 (Xilinx Artix-7 XC7A35T-1CPG236C)
# ==============================================================================

# Project settings
set project_name "riscv_soc"
set project_dir "../build"
set rtl_dir "../rtl"

# FPGA part (Basys 3)
set fpga_part "xc7a35tcpg236-1"

# Create project directory
file mkdir $project_dir

# Create project
create_project $project_name $project_dir -part $fpga_part -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
set_property default_lib work [current_project]

puts "INFO: Created project $project_name for part $fpga_part"

# ==============================================================================
# Add source files
# ==============================================================================

puts "INFO: Adding RTL source files..."

# Top-level
add_files -norecurse $rtl_dir/soc_top.v

# CPU
add_files -norecurse $rtl_dir/cpu/vexriscv_wrapper.v
# NOTE: Add VexRiscv.v when available
# add_files -norecurse $rtl_dir/cpu/VexRiscv.v

# Memory
add_files -norecurse $rtl_dir/memory/rom_32kb.v
add_files -norecurse $rtl_dir/memory/ram_64kb.v

# Peripherals
add_files -norecurse $rtl_dir/peripherals/pwm_accelerator.v
add_files -norecurse $rtl_dir/peripherals/adc_interface.v
add_files -norecurse $rtl_dir/peripherals/protection.v
add_files -norecurse $rtl_dir/peripherals/timer.v
add_files -norecurse $rtl_dir/peripherals/gpio.v
add_files -norecurse $rtl_dir/peripherals/uart.v

# Bus
add_files -norecurse $rtl_dir/bus/wishbone_interconnect.v

# Utility modules (from Track 2)
add_files -norecurse $rtl_dir/utils/carrier_generator.v
add_files -norecurse $rtl_dir/utils/pwm_comparator.v
add_files -norecurse $rtl_dir/utils/sine_generator.v

# Set top module
set_property top soc_top [current_fileset]

puts "INFO: Added all RTL source files"

# ==============================================================================
# Add constraints
# ==============================================================================

puts "INFO: Adding constraints..."

# Check if constraints file exists
if {[file exists "../constraints/basys3.xdc"]} {
    add_files -fileset constrs_1 -norecurse ../constraints/basys3.xdc
    puts "INFO: Added Basys 3 constraints file"
} else {
    puts "WARNING: Constraints file not found at ../constraints/basys3.xdc"
    puts "         You will need to add it manually before synthesis"
}

# ==============================================================================
# Add firmware hex file
# ==============================================================================

puts "INFO: Configuring firmware..."

# Check if firmware hex file exists
if {[file exists "../firmware/firmware.hex"]} {
    add_files -norecurse ../firmware/firmware.hex
    set_property file_type {Memory Initialization Files} [get_files firmware.hex]
    puts "INFO: Added firmware hex file"
} else {
    puts "WARNING: Firmware file not found at ../firmware/firmware.hex"
    puts "         ROM will be initialized with zeros"
    puts "         Compile firmware before synthesis"
}

# ==============================================================================
# Set synthesis and implementation strategies
# ==============================================================================

puts "INFO: Configuring build strategies..."

# Synthesis strategy
set_property strategy {Vivado Synthesis Defaults} [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE Default [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING false [get_runs synth_1]

# Implementation strategy
set_property strategy {Vivado Implementation Defaults} [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Timing-driven implementation
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

puts "INFO: Build strategies configured"

# ==============================================================================
# Set project properties for better results
# ==============================================================================

# Enable timing closure
set_property strategy Performance_Explore [get_runs synth_1]

# Set target frequency (50 MHz = 20 ns period)
create_clock -period 20.000 -name sys_clk [get_ports clk_100mhz]

puts "INFO: Timing constraints set for 50 MHz operation"

# ==============================================================================
# Save and close
# ==============================================================================

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Save project
save_project_as $project_name $project_dir -force

puts "=============================================================================="
puts "SUCCESS: Project created successfully!"
puts ""
puts "Project location: $project_dir/$project_name.xpr"
puts ""
puts "Next steps:"
puts "  1. Obtain VexRiscv core (see rtl/cpu/README.md)"
puts "  2. Compile firmware (see firmware/README.md)"
puts "  3. Run synthesis: vivado -mode batch -source build.tcl"
puts "  4. Program FPGA: vivado -mode batch -source program.tcl"
puts ""
puts "Or open in GUI:"
puts "  vivado $project_dir/$project_name.xpr"
puts "=============================================================================="
