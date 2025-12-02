## Xilinx Design Constraints (XDC) for Basys 3 Board
## FPGA Sensing Accelerator - STM32+FPGA Hybrid System
## Target: Digilent Basys 3 (Xilinx Artix-7 XC7A35T-CPG236)

## Clock Signal (100 MHz on-board oscillator)
## Note: We divide this to 50 MHz in RTL
create_clock -period 10.000 -name clk_100mhz -waveform {0.000 5.000} [get_ports clk_50mhz]
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]

## Reset Button (active low)
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports rst_n]

##############################################################################
## Comparator Inputs (from LM339)
## Connected via Pmod header JA or JXADC
##############################################################################

## Comparator Input Channel 0 (DC Bus 1)
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {comp_in[0]}]

## Comparator Input Channel 1 (DC Bus 2)
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {comp_in[1]}]

## Comparator Input Channel 2 (AC Voltage)
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {comp_in[2]}]

## Comparator Input Channel 3 (AC Current)
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {comp_in[3]}]

##############################################################################
## 1-bit DAC Outputs (to RC Filters)
## Connected via Pmod header JB
##############################################################################

## DAC Output Channel 0
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {dac_out[0]}]

## DAC Output Channel 1
set_property -dict {PACKAGE_PIN W12 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {dac_out[1]}]

## DAC Output Channel 2
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {dac_out[2]}]

## DAC Output Channel 3
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {dac_out[3]}]

##############################################################################
## SPI Interface (to STM32F401RE)
## Connected via Pmod header JC
##############################################################################

## SPI Clock (input from STM32)
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports spi_sck]

## SPI MOSI (Master Out Slave In, input from STM32)
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports spi_mosi]

## SPI MISO (Master In Slave Out, output to STM32)
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports spi_miso]

## SPI Chip Select (active low, input from STM32)
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports spi_cs_n]

##############################################################################
## Status LEDs (on-board Basys 3 LEDs)
##############################################################################

## LED 0 - Power indicator (always on when FPGA configured)
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led[0]}]

## LED 1 - ADC data ready (pulses at 10 kHz)
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]

## LED 2 - SPI active (on when CS low)
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[2]}]

## LED 3 - Data read strobe (pulses when STM32 reads data)
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

##############################################################################
## Timing Constraints
##############################################################################

## Input delays for comparator inputs (relative to internal 50 MHz clock)
## Assume comparator has ~50ns delay
set_input_delay -clock clk_100mhz -min 2.000 [get_ports {comp_in[*]}]
set_input_delay -clock clk_100mhz -max 5.000 [get_ports {comp_in[*]}]

## Output delays for DAC outputs
## Fast slew rate for 1 MHz toggle
set_output_delay -clock clk_100mhz -min 1.000 [get_ports {dac_out[*]}]
set_output_delay -clock clk_100mhz -max 3.000 [get_ports {dac_out[*]}]

## SPI timing constraints
## SPI clock is asynchronous (from external STM32)
set_input_delay -clock clk_100mhz -min 2.000 [get_ports spi_sck]
set_input_delay -clock clk_100mhz -max 8.000 [get_ports spi_sck]
set_input_delay -clock clk_100mhz -min 2.000 [get_ports spi_mosi]
set_input_delay -clock clk_100mhz -max 8.000 [get_ports spi_mosi]
set_input_delay -clock clk_100mhz -min 2.000 [get_ports spi_cs_n]
set_input_delay -clock clk_100mhz -max 8.000 [get_ports spi_cs_n]

## SPI MISO output timing
set_output_delay -clock clk_100mhz -min 1.000 [get_ports spi_miso]
set_output_delay -clock clk_100mhz -max 5.000 [get_ports spi_miso]

##############################################################################
## Configuration Settings
##############################################################################

## Configuration voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Bitstream options
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
