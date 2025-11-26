# ==============================================================================
# Top-level Makefile for RISC-V SoC Project
# ==============================================================================

# Project directories
FIRMWARE_DIR = firmware
VIVADO_DIR = vivado
BUILD_DIR = build
BITSTREAM_DIR = bitstreams
TB_DIR = tb
SIM_DIR = sim

# Vivado executable (adjust if needed)
VIVADO = vivado

# Iverilog executable (for open-source simulation)
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# ==============================================================================
# Targets
# ==============================================================================

.PHONY: all firmware vivado-project vivado-build vivado-program clean help

all: firmware vivado-build
	@echo ""
	@echo "====================================="
	@echo "Complete build finished!"
	@echo "====================================="

# ==============================================================================
# Firmware
# ==============================================================================

firmware:
	@echo "Building firmware..."
	$(MAKE) -C $(FIRMWARE_DIR) all

firmware-clean:
	@echo "Cleaning firmware..."
	$(MAKE) -C $(FIRMWARE_DIR) clean

firmware-info:
	$(MAKE) -C $(FIRMWARE_DIR) info

# ==============================================================================
# Vivado Project
# ==============================================================================

vivado-project:
	@echo "Creating Vivado project..."
	cd $(VIVADO_DIR) && $(VIVADO) -mode batch -source create_project.tcl

vivado-build: firmware
	@echo "Building Vivado project (synthesis + implementation + bitstream)..."
	cd $(VIVADO_DIR) && $(VIVADO) -mode batch -source build.tcl

vivado-program:
	@echo "Programming FPGA..."
	cd $(VIVADO_DIR) && $(VIVADO) -mode batch -source program.tcl

vivado-gui:
	@echo "Opening Vivado GUI..."
	cd $(VIVADO_DIR) && $(VIVADO) ../$(BUILD_DIR)/riscv_soc.xpr &

vivado-clean:
	@echo "Cleaning Vivado build..."
	rm -rf $(BUILD_DIR) $(BITSTREAM_DIR)
	rm -rf $(VIVADO_DIR)/.Xil

# ==============================================================================
# Simulation
# ==============================================================================

# Create simulation directory
$(SIM_DIR):
	mkdir -p $(SIM_DIR)

# Vivado simulations (batch mode)
sim: sim-soc
	@echo "Default simulation (SoC top-level) complete"

sim-soc: vivado-project $(SIM_DIR)
	@echo "Running SoC top-level simulation..."
	cd $(VIVADO_DIR) && $(VIVADO) -mode batch -source sim.tcl -tclargs soc_top_tb

sim-pwm: vivado-project $(SIM_DIR)
	@echo "Running PWM accelerator simulation..."
	cd $(VIVADO_DIR) && $(VIVADO) -mode batch -source sim.tcl -tclargs pwm_accelerator_tb

sim-uart: vivado-project $(SIM_DIR)
	@echo "Running UART simulation..."
	cd $(VIVADO_DIR) && $(VIVADO) -mode batch -source sim.tcl -tclargs uart_tb

sim-protection: vivado-project $(SIM_DIR)
	@echo "Running Protection peripheral simulation..."
	cd $(VIVADO_DIR) && $(VIVADO) -mode batch -source sim.tcl -tclargs protection_tb

sim-all: sim-soc sim-pwm sim-uart sim-protection
	@echo ""
	@echo "====================================="
	@echo "All simulations complete!"
	@echo "====================================="

# Iverilog simulations (open-source alternative)
sim-iverilog-soc: $(SIM_DIR)
	@echo "Running Icarus Verilog simulation (SoC)..."
	cd $(SIM_DIR) && $(IVERILOG) -g2012 -o soc_top_tb.vvp \
		-I../rtl \
		../rtl/soc_top.v \
		../rtl/bus/wishbone_interconnect.v \
		../rtl/memory/*.v \
		../rtl/peripherals/*.v \
		../rtl/utils/*.v \
		../rtl/cpu/vexriscv_wrapper.v \
		../tb/soc_top_tb.v
	cd $(SIM_DIR) && $(VVP) soc_top_tb.vvp

sim-iverilog-pwm: $(SIM_DIR)
	@echo "Running Icarus Verilog simulation (PWM)..."
	cd $(SIM_DIR) && $(IVERILOG) -g2012 -o pwm_accelerator_tb.vvp \
		-I../rtl \
		../rtl/peripherals/pwm_accelerator.v \
		../rtl/utils/*.v \
		../tb/pwm_accelerator_tb.v
	cd $(SIM_DIR) && $(VVP) pwm_accelerator_tb.vvp

# View waveforms (Iverilog)
view-wave-soc:
	cd $(SIM_DIR) && $(GTKWAVE) soc_top_tb.vcd &

view-wave-pwm:
	cd $(SIM_DIR) && $(GTKWAVE) pwm_accelerator_tb.vcd &

# Clean simulation files
sim-clean:
	@echo "Cleaning simulation files..."
	rm -rf $(SIM_DIR)/*.vcd
	rm -rf $(SIM_DIR)/*.vvp
	rm -rf $(SIM_DIR)/*.wdb

# ==============================================================================
# Complete clean
# ==============================================================================

clean: firmware-clean vivado-clean sim-clean
	@echo "Clean complete."

# ==============================================================================
# Quick commands
# ==============================================================================

# Quick build and program
flash: all vivado-program

# Quick firmware rebuild and FPGA reprogram
reflash: firmware-clean firmware vivado-build vivado-program

# ==============================================================================
# UART monitoring
# ==============================================================================

uart-monitor:
	@echo "Connecting to UART (115200 baud)..."
	@echo "Press Ctrl-A then K to exit."
	@if [ -e /dev/ttyUSB0 ]; then \
		screen /dev/ttyUSB0 115200; \
	elif [ -e /dev/ttyUSB1 ]; then \
		screen /dev/ttyUSB1 115200; \
	else \
		echo "Error: No USB serial device found."; \
		echo "Check that Basys 3 is connected."; \
	fi

# ==============================================================================
# Directory creation
# ==============================================================================

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BITSTREAM_DIR):
	mkdir -p $(BITSTREAM_DIR)

# ==============================================================================
# Help
# ==============================================================================

help:
	@echo "====================================="
	@echo "RISC-V SoC Build System"
	@echo "====================================="
	@echo ""
	@echo "Main targets:"
	@echo "  all              - Build firmware and FPGA bitstream"
	@echo "  flash            - Build and program FPGA"
	@echo "  reflash          - Rebuild firmware and reprogram FPGA"
	@echo "  clean            - Clean all build artifacts"
	@echo ""
	@echo "Firmware targets:"
	@echo "  firmware         - Build firmware only"
	@echo "  firmware-clean   - Clean firmware build"
	@echo "  firmware-info    - Show firmware size info"
	@echo ""
	@echo "Vivado targets:"
	@echo "  vivado-project   - Create Vivado project"
	@echo "  vivado-build     - Synthesize and generate bitstream"
	@echo "  vivado-program   - Program FPGA with bitstream"
	@echo "  vivado-gui       - Open project in Vivado GUI"
	@echo "  vivado-clean     - Clean Vivado build"
	@echo ""
	@echo "Simulation targets:"
	@echo "  sim              - Run default simulation (SoC top-level)"
	@echo "  sim-soc          - Simulate complete SoC"
	@echo "  sim-pwm          - Simulate PWM accelerator only"
	@echo "  sim-uart         - Simulate UART peripheral only"
	@echo "  sim-protection   - Simulate protection peripheral only"
	@echo "  sim-all          - Run all simulations"
	@echo "  sim-iverilog-soc - Simulate with Icarus Verilog (open-source)"
	@echo "  sim-iverilog-pwm - Simulate PWM with Icarus Verilog"
	@echo "  view-wave-soc    - View SoC waveform (GTKWave)"
	@echo "  view-wave-pwm    - View PWM waveform (GTKWave)"
	@echo "  sim-clean        - Clean simulation files"
	@echo ""
	@echo "Utility targets:"
	@echo "  uart-monitor     - Connect to UART (115200 baud)"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - RISC-V GCC toolchain (riscv32-unknown-elf-gcc)"
	@echo "  - Vivado 2020.2 or later"
	@echo "  - VexRiscv core (see rtl/cpu/README.md)"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make firmware        # Build firmware"
	@echo "  2. make vivado-project  # Create Vivado project"
	@echo "  3. make vivado-build    # Synthesize design"
	@echo "  4. make vivado-program  # Program FPGA"
	@echo "  5. make uart-monitor    # View debug output"
	@echo ""
	@echo "Or simply:"
	@echo "  make flash              # Do all of the above"
	@echo ""
