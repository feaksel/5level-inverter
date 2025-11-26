## ==============================================================================
## basys3.xdc
## Xilinx Design Constraints for Basys 3 Board
##
## Board: Digilent Basys 3
## FPGA: Xilinx Artix-7 XC7A35T-1CPG236C
## ==============================================================================

## ==============================================================================
## Clock and Reset
## ==============================================================================

## 100 MHz System Clock (from onboard oscillator)
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_100mhz]

## Reset Button (active low, BTNC - center button)
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports rst_n]

## ==============================================================================
## UART (USB-UART Bridge on Basys 3)
## ==============================================================================

## UART TX (FPGA output to PC)
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports uart_tx]

## UART RX (FPGA input from PC)
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports uart_rx]

## ==============================================================================
## PWM Outputs (8 channels to PMOD JB and JC)
## ==============================================================================

## PMOD JB (PWM channels 0-3)
## JB1-JB4: pwm_out[0:3]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports {pwm_out[0]}]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {pwm_out[1]}]
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports {pwm_out[2]}]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports {pwm_out[3]}]

## PMOD JC (PWM channels 4-7)
## JC1-JC4: pwm_out[4:7]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports {pwm_out[4]}]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports {pwm_out[5]}]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {pwm_out[6]}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {pwm_out[7]}]

## ==============================================================================
## ADC SPI Interface (PMOD JA)
## ==============================================================================

## JA1: SPI Clock
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports adc_sck]

## JA2: SPI MOSI (Master Out Slave In)
set_property -dict {PACKAGE_PIN L2 IOSTANDARD LVCMOS33} [get_ports adc_mosi]

## JA3: SPI MISO (Master In Slave Out)
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports adc_miso]

## JA4: SPI Chip Select (active low)
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports adc_cs_n]

## ==============================================================================
## Protection Inputs (Switches)
## ==============================================================================

## SW0: Overcurrent Protection (OCP) fault input (active high)
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports fault_ocp]

## SW1: Overvoltage Protection (OVP) fault input (active high)
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports fault_ovp]

## SW2: Emergency Stop (E-stop, active low when switch is ON)
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports estop_n]

## ==============================================================================
## GPIO (Remaining Switches and PMOD JD)
## ==============================================================================

## Switches SW3-SW15 (GPIO input)
set_property -dict {PACKAGE_PIN W17 IOSTANDARD LVCMOS33} [get_ports {gpio[0]}]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports {gpio[1]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {gpio[2]}]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {gpio[3]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {gpio[4]}]
set_property -dict {PACKAGE_PIN V2  IOSTANDARD LVCMOS33} [get_ports {gpio[5]}]
set_property -dict {PACKAGE_PIN T3  IOSTANDARD LVCMOS33} [get_ports {gpio[6]}]
set_property -dict {PACKAGE_PIN T2  IOSTANDARD LVCMOS33} [get_ports {gpio[7]}]
set_property -dict {PACKAGE_PIN R3  IOSTANDARD LVCMOS33} [get_ports {gpio[8]}]
set_property -dict {PACKAGE_PIN W2  IOSTANDARD LVCMOS33} [get_ports {gpio[9]}]
set_property -dict {PACKAGE_PIN U1  IOSTANDARD LVCMOS33} [get_ports {gpio[10]}]
set_property -dict {PACKAGE_PIN T1  IOSTANDARD LVCMOS33} [get_ports {gpio[11]}]
set_property -dict {PACKAGE_PIN R2  IOSTANDARD LVCMOS33} [get_ports {gpio[12]}]

## PMOD JD (GPIO bidirectional, gpio[13:15])
set_property -dict {PACKAGE_PIN D4  IOSTANDARD LVCMOS33} [get_ports {gpio[13]}]
set_property -dict {PACKAGE_PIN D3  IOSTANDARD LVCMOS33} [get_ports {gpio[14]}]
set_property -dict {PACKAGE_PIN F4  IOSTANDARD LVCMOS33} [get_ports {gpio[15]}]

## ==============================================================================
## Status LEDs
## ==============================================================================

## LED0: Power/Reset indicator
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led[0]}]

## LED1: Fault indicator
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]

## LED2: UART TX activity
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[2]}]

## LED3: Interrupt activity
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## ==============================================================================
## Configuration and Bitstream Settings
## ==============================================================================

## Configuration voltage
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Bitstream compression
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

## Unused pin configuration (for ASIC migration, minimize leakage)
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLDOWN [current_design]

## ==============================================================================
## Timing Constraints
## ==============================================================================

## Input delay constraints (approximate for external signals)
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.000 [get_ports uart_rx]
set_input_delay -clock [get_clocks sys_clk_pin] -max 5.000 [get_ports uart_rx]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.000 [get_ports adc_miso]
set_input_delay -clock [get_clocks sys_clk_pin] -max 5.000 [get_ports adc_miso]

## Output delay constraints (approximate for external signals)
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.000 [get_ports uart_tx]
set_output_delay -clock [get_clocks sys_clk_pin] -max 5.000 [get_ports uart_tx]
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.000 [get_ports {pwm_out[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 5.000 [get_ports {pwm_out[*]}]

## False paths for asynchronous inputs (buttons, switches)
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports fault_ocp]
set_false_path -from [get_ports fault_ovp]
set_false_path -from [get_ports estop_n]
set_false_path -from [get_ports {gpio[*]}]

## False paths for LEDs (not timing critical)
set_false_path -to [get_ports {led[*]}]

## ==============================================================================
## Physical Constraints (for better placement)
## ==============================================================================

## Group critical paths for better placement
## (These are examples, adjust based on actual utilization)

## Keep memory blocks close
# set_property LOC RAMB36_X0Y0 [get_cells -hierarchical -filter {NAME =~ *rom_memory*}]
# set_property LOC RAMB36_X0Y1 [get_cells -hierarchical -filter {NAME =~ *ram_memory*}]

## ==============================================================================
## Notes for ASIC Migration
## ==============================================================================

## When migrating to ASIC:
## 1. Remove FPGA-specific properties (PACKAGE_PIN, IOSTANDARD)
## 2. Replace with pad cell instantiations
## 3. Update timing constraints based on actual pad delays
## 4. Add power domain constraints if using multiple voltage domains
## 5. Ensure all clocks are properly defined
## 6. Add scan chain constraints for DFT

## ==============================================================================
## End of Constraints File
## ==============================================================================
