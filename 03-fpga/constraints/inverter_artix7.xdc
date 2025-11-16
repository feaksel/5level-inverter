## Xilinx Design Constraints (XDC) file for 5-Level Inverter
## Target: Xilinx Artix-7 FPGA (XC7A35T or similar)
##
## This file defines:
## - Clock constraints
## - Pin mappings for PWM outputs
## - I/O standards
## - Timing constraints
##
## Author: 5-Level Inverter Project
## Date: 2025-11-15

#######################################
# Clock Constraints
#######################################

# System clock: 100 MHz
create_clock -period 10.000 -name sys_clk [get_ports clk]

# Input delay constraints (for synchronous inputs)
set_input_delay -clock sys_clk -max 2.000 [get_ports rst_n]
set_input_delay -clock sys_clk -max 2.000 [get_ports enable]
set_input_delay -clock sys_clk -max 2.000 [get_ports freq_50hz*]
set_input_delay -clock sys_clk -max 2.000 [get_ports modulation_index*]
set_input_delay -clock sys_clk -max 2.000 [get_ports deadtime_cycles*]
set_input_delay -clock sys_clk -max 2.000 [get_ports carrier_freq_div*]

# Output delay constraints
set_output_delay -clock sys_clk -max 5.000 [get_ports pwm1_*]
set_output_delay -clock sys_clk -max 5.000 [get_ports pwm2_*]
set_output_delay -clock sys_clk -max 5.000 [get_ports sync_pulse]
set_output_delay -clock sys_clk -max 5.000 [get_ports fault]

#######################################
# Pin Assignments (Example for Artix-7)
#######################################
# NOTE: Update these for your specific FPGA board

# System Clock (100 MHz oscillator)
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]

# Reset (active-low, button)
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports rst_n]

# Enable (switch)
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports enable]

#######################################
# H-Bridge 1 PWM Outputs (S1-S4)
#######################################

# S1: High-side switch 1 (PA8 equivalent)
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports pwm1_ch1_high]

# S2: Low-side switch 1 (PB13 equivalent)
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports pwm1_ch1_low]

# S3: High-side switch 2 (PA9 equivalent)
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports pwm1_ch2_high]

# S4: Low-side switch 2 (PB14 equivalent)
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports pwm1_ch2_low]

#######################################
# H-Bridge 2 PWM Outputs (S5-S8)
#######################################

# S5: High-side switch 3 (PC6 equivalent)
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports pwm2_ch1_high]

# S6: Low-side switch 3 (PC10 equivalent)
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports pwm2_ch1_low]

# S7: High-side switch 4 (PC7 equivalent)
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports pwm2_ch2_high]

# S8: Low-side switch 4 (PC11 equivalent)
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports pwm2_ch2_low]

#######################################
# Status Outputs
#######################################

# Synchronization pulse (for debugging/scope trigger)
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports sync_pulse]

# Fault output (LED indicator)
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports fault]

#######################################
# Configuration Inputs
#######################################
# These can be connected to switches, rotary encoders, or external microcontroller

# Frequency increment (32-bit)
# Using DIP switches or external SPI/I2C interface
# Example: Lower 8 bits on switches
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports freq_50hz[0]]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports freq_50hz[1]]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports freq_50hz[2]]
set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports freq_50hz[3]]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports freq_50hz[4]]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports freq_50hz[5]]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports freq_50hz[6]]
set_property -dict {PACKAGE_PIN R13 IOSTANDARD LVCMOS33} [get_ports freq_50hz[7]]
# Additional bits would require more pins or external interface

# Modulation index (16-bit)
# Example: Lower 8 bits
set_property -dict {PACKAGE_PIN T8 IOSTANDARD LVCMOS33} [get_ports modulation_index[0]]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports modulation_index[1]]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports modulation_index[2]]
set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports modulation_index[3]]
set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports modulation_index[4]]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports modulation_index[5]]
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports modulation_index[6]]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports modulation_index[7]]

# Dead-time cycles (8-bit)
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports deadtime_cycles[0]]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports deadtime_cycles[1]]
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports deadtime_cycles[2]]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports deadtime_cycles[3]]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports deadtime_cycles[4]]
set_property -dict {PACKAGE_PIN T17 IOSTANDARD LVCMOS33} [get_ports deadtime_cycles[5]]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports deadtime_cycles[6]]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports deadtime_cycles[7]]

# Carrier frequency divider (16-bit)
# Example: Lower 8 bits
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports carrier_freq_div[0]]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports carrier_freq_div[1]]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports carrier_freq_div[2]]
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports carrier_freq_div[3]]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports carrier_freq_div[4]]
set_property -dict {PACKAGE_PIN T2 IOSTANDARD LVCMOS33} [get_ports carrier_freq_div[5]]
set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports carrier_freq_div[6]]
set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS33} [get_ports carrier_freq_div[7]]

#######################################
# Timing Exceptions
#######################################

# False paths for asynchronous reset
set_false_path -from [get_ports rst_n]

# Multicycle paths for configuration inputs (change slowly)
set_multicycle_path -setup 4 -from [get_ports freq_50hz*]
set_multicycle_path -setup 4 -from [get_ports modulation_index*]
set_multicycle_path -setup 4 -from [get_ports deadtime_cycles*]
set_multicycle_path -setup 4 -from [get_ports carrier_freq_div*]

#######################################
# Design Rule Checks
#######################################

# Maximum fanout
set_max_fanout 20 [current_design]

# Notes:
# 1. Pin assignments are examples - update for your specific FPGA board
# 2. For actual hardware, use isolated gate drivers (e.g., Si8271)
# 3. Add level shifters if FPGA I/O voltage differs from gate driver logic
# 4. Consider fiber optic isolation for high-voltage applications
# 5. PWM outputs should go to optocouplers or isolated gate drivers
