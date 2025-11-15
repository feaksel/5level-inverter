# Makefile for 5-Level Inverter FPGA Development
# Supports Icarus Verilog for simulation and Vivado for synthesis

# Project settings
PROJECT = inverter_5level
TOP_MODULE = inverter_5level_top

# Directories
RTL_DIR = rtl
TB_DIR = tb
SIM_DIR = sim
CONSTR_DIR = constraints

# Source files
RTL_SOURCES = \
	$(RTL_DIR)/carrier_generator.v \
	$(RTL_DIR)/pwm_comparator.v \
	$(RTL_DIR)/sine_generator.v \
	$(RTL_DIR)/$(TOP_MODULE).v

# Testbench files
TB_SOURCES = \
	$(TB_DIR)/carrier_generator_tb.v \
	$(TB_DIR)/inverter_5level_top_tb.v

# Simulation tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Synthesis tools
VIVADO = vivado

#######################################
# Simulation targets
#######################################

.PHONY: all clean sim_carrier sim_top view_carrier view_top

all: sim_top

# Simulate carrier generator
sim_carrier: $(SIM_DIR)/carrier_generator_tb.vvp
	@echo "Running carrier generator simulation..."
	$(VVP) $(SIM_DIR)/carrier_generator_tb.vvp
	@echo "Simulation complete. Waveform: $(SIM_DIR)/carrier_generator_tb.vcd"

$(SIM_DIR)/carrier_generator_tb.vvp: $(RTL_DIR)/carrier_generator.v $(TB_DIR)/carrier_generator_tb.v | $(SIM_DIR)
	$(IVERILOG) -o $@ $(RTL_DIR)/carrier_generator.v $(TB_DIR)/carrier_generator_tb.v

# Simulate top-level inverter
sim_top: $(SIM_DIR)/inverter_5level_top_tb.vvp
	@echo "Running top-level inverter simulation..."
	$(VVP) $(SIM_DIR)/inverter_5level_top_tb.vvp
	@echo "Simulation complete. Waveform: $(SIM_DIR)/inverter_5level_top_tb.vcd"

$(SIM_DIR)/inverter_5level_top_tb.vvp: $(RTL_SOURCES) $(TB_DIR)/inverter_5level_top_tb.v | $(SIM_DIR)
	$(IVERILOG) -o $@ $(RTL_SOURCES) $(TB_DIR)/inverter_5level_top_tb.v

# View waveforms with GTKWave
view_carrier: sim_carrier
	$(GTKWAVE) $(SIM_DIR)/carrier_generator_tb.vcd &

view_top: sim_top
	$(GTKWAVE) $(SIM_DIR)/inverter_5level_top_tb.vcd &

#######################################
# Synthesis targets (Vivado)
#######################################

.PHONY: synth impl bitstream program

# Synthesize design
synth:
	@echo "Running Vivado synthesis..."
	$(VIVADO) -mode batch -source scripts/synth.tcl

# Implementation
impl:
	@echo "Running Vivado implementation..."
	$(VIVADO) -mode batch -source scripts/impl.tcl

# Generate bitstream
bitstream:
	@echo "Generating bitstream..."
	$(VIVADO) -mode batch -source scripts/bitstream.tcl

# Program FPGA
program:
	@echo "Programming FPGA..."
	$(VIVADO) -mode batch -source scripts/program.tcl

#######################################
# Utility targets
#######################################

# Create simulation directory
$(SIM_DIR):
	mkdir -p $(SIM_DIR)

# Clean build artifacts
clean:
	rm -rf $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd
	rm -rf .Xil
	rm -rf *.jou *.log
	@echo "Clean complete"

# Help
help:
	@echo "5-Level Inverter FPGA Makefile"
	@echo ""
	@echo "Simulation targets:"
	@echo "  make sim_carrier    - Simulate carrier generator"
	@echo "  make sim_top        - Simulate complete inverter (default)"
	@echo "  make view_carrier   - View carrier waveforms in GTKWave"
	@echo "  make view_top       - View inverter waveforms in GTKWave"
	@echo ""
	@echo "Synthesis targets (requires Vivado):"
	@echo "  make synth          - Run synthesis"
	@echo "  make impl           - Run implementation"
	@echo "  make bitstream      - Generate bitstream"
	@echo "  make program        - Program FPGA"
	@echo ""
	@echo "Utility targets:"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make help           - Show this help"
	@echo ""
	@echo "Requirements:"
	@echo "  - Icarus Verilog (for simulation)"
	@echo "  - GTKWave (for waveform viewing)"
	@echo "  - Vivado (for synthesis, optional)"
