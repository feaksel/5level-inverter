# ==============================================================================
# Vivado Simulation Script for RISC-V SoC
# ==============================================================================
#
# Usage:
#   vivado -mode batch -source sim.tcl -tclargs <testbench>
#
# Where <testbench> is one of:
#   - soc_top_tb          (default - full SoC)
#   - pwm_accelerator_tb  (PWM peripheral)
#   - uart_tb             (UART peripheral)
#   - protection_tb       (Protection peripheral)
#   - timer_tb            (Timer peripheral)
#   - adc_interface_tb    (ADC peripheral)
#

# ==============================================================================
# Configuration
# ==============================================================================

set project_name "riscv_soc"
set project_dir "../build"
set sim_dir "../sim"

# Get testbench name from command line args (default: soc_top_tb)
if {$argc > 0} {
    set testbench_name [lindex $argv 0]
} else {
    set testbench_name "soc_top_tb"
}

puts ""
puts "========================================"
puts "Vivado Simulation"
puts "========================================"
puts "Testbench: $testbench_name"
puts "Project: $project_dir/$project_name.xpr"
puts ""

# ==============================================================================
# Create/Open Project
# ==============================================================================

# Check if project exists
if {[file exists "$project_dir/$project_name.xpr"]} {
    puts "Opening existing project..."
    open_project "$project_dir/$project_name.xpr"
} else {
    puts "ERROR: Project not found!"
    puts "Please run 'make vivado-project' first"
    exit 1
}

# ==============================================================================
# Add Testbench Files to Simulation Set
# ==============================================================================

# Remove old simulation files (if any)
set sim_fileset [get_filesets sim_1]
if {[llength [get_files -of_objects $sim_fileset *.v -filter {FILE_TYPE == "Verilog"}]] > 0} {
    puts "Removing old simulation files..."
    remove_files -fileset sim_1 [get_files -of_objects $sim_fileset *_tb.v]
}

# Add testbench file
set tb_file "../tb/${testbench_name}.v"
if {[file exists $tb_file]} {
    puts "Adding testbench: $tb_file"
    add_files -fileset sim_1 -norecurse $tb_file
    update_compile_order -fileset sim_1
} else {
    puts "ERROR: Testbench file not found: $tb_file"
    puts ""
    puts "Available testbenches:"
    puts "  - soc_top_tb"
    puts "  - pwm_accelerator_tb"
    puts "  - uart_tb"
    puts "  - protection_tb"
    puts "  - timer_tb"
    puts "  - adc_interface_tb"
    puts ""
    exit 1
}

# Set top module for simulation
set_property top $testbench_name [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# ==============================================================================
# Simulation Settings
# ==============================================================================

# Set simulation runtime
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]

# Waveform settings
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.wdb} -value {${testbench_name}.wdb} -objects [get_filesets sim_1]

# Simulator options
set_property xsim.simulate.xsim.more_options {-testplusarg VERBOSE=1} [get_filesets sim_1]

# ==============================================================================
# Run Simulation
# ==============================================================================

puts ""
puts "========================================"
puts "Running Simulation"
puts "========================================"

# Launch simulation
launch_simulation -mode behavioral

# Wait for simulation to complete
# (Will run until $finish or timeout in testbench)

puts ""
puts "========================================"
puts "Simulation Complete"
puts "========================================"

# Save waveform
if {[current_sim] != ""} {
    puts "Saving waveform..."
    save_wave_config "${testbench_name}_wave.wcfg"

    # Export waveform data
    puts "Exporting waveform to VCD..."
    # VCD export is handled by testbench $dumpfile/$dumpvars
}

puts ""
puts "Waveform file: ${project_dir}/${project_name}.sim/sim_1/behav/xsim/${testbench_name}.wdb"
puts "To view waveform:"
puts "  vivado -mode gui ${project_dir}/${project_name}.xpr"
puts "  Then: Flow Navigator → Simulation → Open Waveform Database"
puts ""

# Close simulation
close_sim -force

# ==============================================================================
# Summary
# ==============================================================================

puts ""
puts "========================================"
puts "Simulation Summary"
puts "========================================"
puts "Testbench: $testbench_name"
puts "Status: Completed"
puts ""
puts "Check the transcript above for test results"
puts "========================================"
puts ""

# Close project
close_project
