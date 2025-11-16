# ==============================================================================
# Vivado Build Script for RISC-V SoC
# ==============================================================================
#
# This script runs the complete FPGA build flow:
#   1. Synthesis
#   2. Implementation
#   3. Bitstream generation
#   4. Reports
#
# Usage (from Windows Command Prompt):
#   cd \\wsl$\Ubuntu\home\<username>\5level-inverter\02-embedded\riscv-soc\vivado_project
#   vivado -mode batch -source ../build.tcl
#
# Or from existing project:
#   source ../build.tcl
#
# ==============================================================================

set proj_name "riscv_soc"

puts ""
puts "===================================="
puts "RISC-V SoC Build Flow"
puts "===================================="
puts ""

# Open project if not already open
if {[catch {current_project}]} {
    puts "Opening project: $proj_name..."
    open_project ${proj_name}.xpr
    puts "✓ Project opened"
} else {
    puts "Project already open: [current_project]"
}

# ==============================================================================
# Synthesis
# ==============================================================================

puts ""
puts "===================================="
puts "Step 1: Synthesis"
puts "===================================="
puts ""

# Reset synthesis run if it exists
if {[get_runs synth_1 -quiet] != ""} {
    reset_run synth_1
}

# Launch synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check for errors
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "✗ ERROR: Synthesis failed!"
    exit 1
}

puts "✓ Synthesis completed successfully"

# Open synthesized design
open_run synth_1 -name synth_1

# Generate utilization report
puts ""
puts "Generating utilization report..."
report_utilization -file reports/post_synth_utilization.rpt
report_timing_summary -file reports/post_synth_timing.rpt

# Display quick summary
puts ""
puts "Resource Utilization (Post-Synthesis):"
puts "--------------------------------------"
report_utilization -return_string

# ==============================================================================
# Implementation
# ==============================================================================

puts ""
puts "===================================="
puts "Step 2: Implementation"
puts "===================================="
puts ""

# Reset implementation run if it exists
if {[get_runs impl_1 -quiet] != ""} {
    reset_run impl_1
}

# Launch implementation
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check for errors
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "✗ ERROR: Implementation failed!"
    exit 1
}

puts "✓ Implementation completed successfully"

# ==============================================================================
# Bitstream Generation
# ==============================================================================

puts ""
puts "===================================="
puts "Step 3: Bitstream Generation"
puts "===================================="
puts ""

# Launch bitstream generation
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check for errors
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "✗ ERROR: Bitstream generation failed!"
    exit 1
}

puts "✓ Bitstream generated successfully"

# Open implemented design
open_run impl_1

# ==============================================================================
# Reports
# ==============================================================================

puts ""
puts "===================================="
puts "Step 4: Generating Reports"
puts "===================================="
puts ""

# Create reports directory
file mkdir reports

# Generate reports
puts "Generating post-implementation reports..."
report_utilization -file reports/post_impl_utilization.rpt
report_timing_summary -file reports/post_impl_timing.rpt
report_power -file reports/post_impl_power.rpt
report_drc -file reports/post_impl_drc.rpt
report_io -file reports/post_impl_io.rpt
report_clock_utilization -file reports/clock_utilization.rpt

puts "✓ Reports generated in reports/ directory"

# ==============================================================================
# Summary
# ==============================================================================

puts ""
puts "===================================="
puts "Build Complete!"
puts "===================================="
puts ""

# Display quick summary
puts "Resource Utilization (Post-Implementation):"
puts "--------------------------------------------"
report_utilization -return_string

puts ""
puts "Timing Summary:"
puts "---------------"
report_timing_summary -return_string

puts ""
puts "Output Files:"
puts "-------------"
puts "Bitstream: [get_property DIRECTORY [current_run]]/[current_project].bit"
puts "Reports:   reports/*.rpt"
puts ""

puts "Next steps:"
puts "  1. Program FPGA:"
puts "     - Open Hardware Manager in Vivado"
puts "     - Connect to Basys 3 board"
puts "     - Program with bitstream"
puts ""
puts "  2. Monitor UART:"
puts "     - Connect to COM port (115200 baud)"
puts "     - View firmware debug output"
puts ""
