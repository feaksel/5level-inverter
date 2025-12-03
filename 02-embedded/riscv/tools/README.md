# RISC-V Core Build System

This directory contains the build system and tools for the RISC-V RV32IM custom core project.

## Quick Start

### 1. Check Environment

```bash
make env-check
```

This verifies that all required tools are installed.

### 2. Create a New Module

```bash
make new-module NAME=regfile
```

This creates:
- `../rtl/core/regfile.v` (module template)
- `../sim/testbenches/tb_regfile.v` (testbench template)

### 3. Run Tests

```bash
make test MODULE=regfile
```

This compiles and runs the testbench using Icarus Verilog (default).

### 4. View Waveforms

```bash
make waves MODULE=regfile
```

Opens GTKWave to view the simulation waveforms.

## Available Commands

### Simulation

```bash
make test MODULE=<name>          # Run testbench
make sim MODULE=<name>           # Same as test
make waves MODULE=<name>         # View waveforms
```

### Multiple Module Tests

```bash
make test-regfile                # Test register file
make test-alu                    # Test ALU
make test-decode                 # Test decoder
make test-core                   # Test full core
make test-all                    # Run all tests
```

### Program Compilation

```bash
# Assemble a RISC-V assembly program
make <program>.elf               # Compile
make <program>.hex               # Convert to hex

# Example:
make add_test.elf
make add_test.hex
```

### Cleanup

```bash
make clean                       # Remove build artifacts
make distclean                   # Deep clean
```

### Development Tools

```bash
make lint                        # Run Verilator linter
make synth-check                 # Run synthesis check (Yosys)
make info                        # Show project information
make env-check                   # Check tool installation
make quickstart                  # Show quick start guide
make help                        # Show available targets
```

## Simulator Selection

### Using Icarus Verilog (default)

```bash
make test MODULE=regfile
```

### Using Verilator

```bash
make test MODULE=regfile SIMULATOR=verilator
```

## File Structure

```
tools/
├── Makefile              # Main build system
└── README.md             # This file

Generated directories:
../sim/build/             # Build artifacts
../sim/waves/             # Waveform files (.vcd)
```

## Required Tools

### Simulation

- **Icarus Verilog** (`iverilog`, `vvp`)
  ```bash
  sudo apt-get install iverilog
  ```

- **GTKWave** (waveform viewer)
  ```bash
  sudo apt-get install gtkwave
  ```

- **Verilator** (optional, faster simulation)
  ```bash
  sudo apt-get install verilator
  ```

### RISC-V Toolchain

- **GCC for RISC-V**
  ```bash
  # Option 1: Install prebuilt
  sudo apt-get install gcc-riscv64-unknown-elf

  # Option 2: Build from source
  git clone https://github.com/riscv/riscv-gnu-toolchain
  cd riscv-gnu-toolchain
  ./configure --prefix=/opt/riscv --with-arch=rv32im --with-abi=ilp32
  make
  ```

- Set toolchain prefix (if needed):
  ```bash
  export RISCV_PREFIX=riscv32-unknown-elf-
  ```

### Optional Tools

- **Yosys** (synthesis check)
  ```bash
  sudo apt-get install yosys
  ```

## Example Workflow

### 1. Implement Register File

```bash
# Create module
make new-module NAME=regfile

# Edit implementation
vim ../rtl/core/regfile.v

# Edit testbench
vim ../sim/testbenches/tb_regfile.v

# Run simulation
make test MODULE=regfile

# View waveforms
make waves MODULE=regfile
```

### 2. Implement ALU

```bash
make new-module NAME=alu
# ... edit files ...
make test MODULE=alu
```

### 3. Run All Tests

```bash
make test-all
```

## Debugging Tips

### Viewing Signals

Edit your testbench to add signal monitoring:

```verilog
initial begin
    $monitor("Time=%0t clk=%b rst_n=%b data=%h",
             $time, clk, rst_n, data);
end
```

### Waveform Analysis

Use GTKWave to:
1. Add signals to waveform viewer
2. Use zoom and measurement tools
3. Search for specific values or transitions
4. Export screenshots

### Simulation Verbosity

Add to your testbench:

```verilog
initial begin
    $display("Starting test...");
    // ... tests ...
    $display("Test completed!");
end
```

## Troubleshooting

### "Module not found" error

Make sure your module file exists in `../rtl/core/<MODULE>.v`

### "Testbench not found" error

Create testbench: `make new-module NAME=<MODULE>`

### RISC-V toolchain not found

Install toolchain or set `RISCV_PREFIX` environment variable:

```bash
export RISCV_PREFIX=riscv32-unknown-elf-
```

### Waveform file not found

Run simulation first: `make test MODULE=<MODULE>`

## Tips for Development

1. **Start small**: Begin with simple modules (regfile, ALU)
2. **Test incrementally**: Test each module before integrating
3. **Use waveforms**: Visual debugging is powerful
4. **Write assertions**: Add checks in your testbenches
5. **Follow the roadmap**: See `docs/IMPLEMENTATION_ROADMAP.md`

## Additional Resources

- **Documentation**: `../docs/IMPLEMENTATION_ROADMAP.md`
- **Requirements**: `../docs/CUSTOM_CORE_REQUIREMENTS.md`
- **Main README**: `../README.md`
- **Project guidelines**: `../../CLAUDE.md`

## Contact

For questions or issues, refer to the main project documentation.

---

**Last Updated:** 2025-12-03
**Version:** 1.0
