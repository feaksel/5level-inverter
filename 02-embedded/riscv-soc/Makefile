# ==============================================================================
# Top-level Makefile for RISC-V SoC Project
# ==============================================================================

# Project directories
FIRMWARE_DIR = firmware
VIVADO_DIR = vivado
BUILD_DIR = build
BITSTREAM_DIR = bitstreams

# Vivado executable (adjust if needed)
VIVADO = vivado

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
# Simulation (optional)
# ==============================================================================

sim:
	@echo "Running Vivado simulation..."
	cd $(VIVADO_DIR) && $(VIVADO) -mode batch -source sim.tcl

# ==============================================================================
# Complete clean
# ==============================================================================

clean: firmware-clean vivado-clean
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
	@echo "Utility targets:"
	@echo "  uart-monitor     - Connect to UART (115200 baud)"
	@echo "  sim              - Run simulation"
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
