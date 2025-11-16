# ==============================================================================
# program.tcl
# Vivado TCL Script to Program Basys 3 FPGA
#
# Usage:
#   vivado -mode batch -source program.tcl
#
# This script:
#   1. Detects connected Basys 3 board
#   2. Programs the FPGA with generated bitstream
# ==============================================================================

set bitstream_file "../bitstreams/soc_top.bit"

# ==============================================================================
# Check bitstream exists
# ==============================================================================

if {![file exists $bitstream_file]} {
    puts "ERROR: Bitstream file not found: $bitstream_file"
    puts "       Run build.tcl first to generate bitstream"
    exit 1
}

puts "INFO: Found bitstream: $bitstream_file"

# ==============================================================================
# Connect to hardware
# ==============================================================================

puts "INFO: Connecting to hardware server..."

open_hw_manager
connect_hw_server -allow_non_jtag

# Get list of hardware targets
set targets [get_hw_targets]

if {[llength $targets] == 0} {
    puts "ERROR: No hardware targets found!"
    puts "       Make sure Basys 3 is connected via USB"
    close_hw_manager
    exit 1
}

puts "INFO: Found [llength $targets] hardware target(s)"

# Open first target (usually the connected board)
set target [lindex $targets 0]
puts "INFO: Opening target: $target"

current_hw_target $target
open_hw_target

# ==============================================================================
# Get FPGA device
# ==============================================================================

set devices [get_hw_devices]

if {[llength $devices] == 0} {
    puts "ERROR: No FPGA devices found on target!"
    close_hw_target
    close_hw_manager
    exit 1
}

# Basys 3 should have one device (XC7A35T)
set device [lindex $devices 0]
puts "INFO: Found device: [get_property PART $device]"

# Verify it's the correct FPGA
set part [get_property PART $device]
if {![string match "*xc7a35t*" [string tolower $part]]} {
    puts "WARNING: Expected Artix-7 XC7A35T, found: $part"
    puts "         Continuing anyway..."
}

current_hw_device $device
refresh_hw_device $device

# ==============================================================================
# Program FPGA
# ==============================================================================

puts "\n=============================================================================="
puts "Programming FPGA..."
puts "=============================================================================="

# Set bitstream file
set_property PROGRAM.FILE $bitstream_file $device

# Program the device
puts "INFO: Programming device with $bitstream_file"
program_hw_devices $device

# Wait for programming to complete
after 1000

# Verify programming
if {[get_property PROGRAM.DONE [get_hw_devices]] == 1} {
    puts "SUCCESS: FPGA programmed successfully!"
} else {
    puts "ERROR: FPGA programming failed!"
    close_hw_target
    close_hw_manager
    exit 1
}

# ==============================================================================
# Cleanup
# ==============================================================================

puts "\n=============================================================================="
puts "PROGRAMMING COMPLETE!"
puts "=============================================================================="
puts ""
puts "The FPGA is now running the RISC-V SoC firmware."
puts ""
puts "Next steps:"
puts "  1. Connect UART terminal (115200 baud, 8N1)"
puts "     - Linux: screen /dev/ttyUSB0 115200"
puts "     - Windows: PuTTY or Tera Term"
puts "  2. Observe status LEDs on Basys 3:"
puts "     - LED0: Power indicator (should be ON)"
puts "     - LED1: Fault indicator (should be OFF)"
puts "     - LED2: UART TX activity"
puts "     - LED3: Interrupt activity"
puts "  3. Monitor debug output via UART"
puts "  4. Test PWM outputs with oscilloscope"
puts ""
puts "Safety reminder:"
puts "  - Do NOT connect to high voltage without proper isolation"
puts "  - Test PWM signals at low voltage first"
puts "  - Verify all protection circuits before connecting inverter"
puts "=============================================================================="

close_hw_target
close_hw_manager
