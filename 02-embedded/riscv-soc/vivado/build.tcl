# ==============================================================================
# build.tcl
# Vivado TCL Script to Build RISC-V SoC (Synthesis + Implementation + Bitstream)
#
# Usage:
#   vivado -mode batch -source build.tcl
#
# This script:
#   1. Opens the project
#   2. Runs synthesis
#   3. Runs implementation (place & route)
#   4. Generates bitstream
#   5. Reports timing, utilization, and power
# ==============================================================================

set project_name "riscv_soc"
set project_dir "../build"
set project_file "$project_dir/$project_name.xpr"

# ==============================================================================
# Check project exists
# ==============================================================================

if {![file exists $project_file]} {
    puts "ERROR: Project file not found: $project_file"
    puts "       Run create_project.tcl first"
    exit 1
}

# ==============================================================================
# Open project
# ==============================================================================

puts "INFO: Opening project $project_file"
open_project $project_file

# Update compile order
update_compile_order -fileset sources_1

# ==============================================================================
# Check prerequisites
# ==============================================================================

puts "INFO: Checking prerequisites..."

# Check for VexRiscv core
set vexriscv_found false
foreach file [get_files -filter {NAME =~ *VexRiscv*.v}] {
    set vexriscv_found true
    puts "INFO: Found VexRiscv core: $file"
}

if {!$vexriscv_found} {
    puts "WARNING: VexRiscv core not found!"
    puts "         The design will use stub implementation"
    puts "         See rtl/cpu/README.md for instructions"
}

# Check for firmware
set firmware_found false
foreach file [get_files -filter {NAME =~ *firmware.hex}] {
    set firmware_found true
    puts "INFO: Found firmware: $file"
}

if {!$firmware_found} {
    puts "WARNING: Firmware hex file not found!"
    puts "         ROM will be initialized with zeros"
    puts "         See firmware/README.md for compilation instructions"
}

# Check for constraints
set constraints_found false
foreach file [get_files -filter {FILE_TYPE == XDC}] {
    set constraints_found true
    puts "INFO: Found constraints: $file"
}

if {!$constraints_found} {
    puts "ERROR: No constraints file found!"
    puts "       Add basys3.xdc to project before building"
    exit 1
}

# ==============================================================================
# Run Synthesis
# ==============================================================================

puts "=============================================================================="
puts "Starting synthesis..."
puts "=============================================================================="

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis status
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

if {[get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} {
    puts "ERROR: Synthesis did not complete successfully"
    exit 1
}

puts "INFO: Synthesis completed successfully"

# ==============================================================================
# Synthesis Reports
# ==============================================================================

open_run synth_1 -name synth_1

puts "\n=============================================================================="
puts "Synthesis Utilization Report"
puts "=============================================================================="

report_utilization -file $project_dir/reports/post_synth_utilization.txt
report_utilization

puts "\n=============================================================================="
puts "Synthesis Timing Summary"
puts "=============================================================================="

report_timing_summary -file $project_dir/reports/post_synth_timing.txt
report_timing_summary -max_paths 10

# ==============================================================================
# Run Implementation
# ==============================================================================

puts "\n=============================================================================="
puts "Starting implementation (place & route)..."
puts "=============================================================================="

reset_run impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check implementation status
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

if {[get_property STATUS [get_runs impl_1]] != "route_design Complete!"} {
    puts "ERROR: Implementation did not complete successfully"
    exit 1
}

puts "INFO: Implementation completed successfully"

# ==============================================================================
# Implementation Reports
# ==============================================================================

open_run impl_1

puts "\n=============================================================================="
puts "Implementation Utilization Report"
puts "=============================================================================="

report_utilization -file $project_dir/reports/post_impl_utilization.txt
report_utilization

puts "\n=============================================================================="
puts "Implementation Timing Summary"
puts "=============================================================================="

report_timing_summary -file $project_dir/reports/post_impl_timing.txt
report_timing_summary -max_paths 10 -warn_on_violation

# Check timing
set timing_met [get_property SLACK [get_timing_paths]]
if {$timing_met < 0} {
    puts "WARNING: Timing constraints NOT met!"
    puts "         Slack: $timing_met ns"
    puts "         Design may not function correctly at target frequency"
} else {
    puts "INFO: Timing constraints MET"
    puts "      Slack: $timing_met ns"
}

puts "\n=============================================================================="
puts "Power Report"
puts "=============================================================================="

report_power -file $project_dir/reports/power.txt
report_power

# ==============================================================================
# Generate Bitstream
# ==============================================================================

puts "\n=============================================================================="
puts "Generating bitstream..."
puts "=============================================================================="

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Bitstream generation failed!"
    exit 1
}

puts "INFO: Bitstream generated successfully"

# ==============================================================================
# Copy output files
# ==============================================================================

set bit_file "$project_dir/$project_name.runs/impl_1/soc_top.bit"
set output_dir "../bitstreams"

file mkdir $output_dir

if {[file exists $bit_file]} {
    file copy -force $bit_file $output_dir/soc_top.bit
    puts "INFO: Bitstream copied to $output_dir/soc_top.bit"
} else {
    puts "WARNING: Bitstream file not found at expected location"
}

# ==============================================================================
# Final Summary
# ==============================================================================

puts "\n=============================================================================="
puts "BUILD COMPLETE!"
puts "=============================================================================="
puts ""
puts "Bitstream: $output_dir/soc_top.bit"
puts "Reports:   $project_dir/reports/"
puts ""
puts "Resource Utilization Summary:"

set util_report [report_utilization -return_string]
puts $util_report

puts "\nNext steps:"
puts "  1. Review timing reports to ensure constraints are met"
puts "  2. Program FPGA: vivado -mode batch -source program.tcl"
puts "  3. Connect UART terminal (115200 baud) for debug output"
puts "=============================================================================="

close_project
