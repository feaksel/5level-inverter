# RISC-V Implementation - Stage 4

**Status:** Planning Phase
**Target Platform:** Custom RISC-V Soft-Core on FPGA
**Date:** 2025-12-03

---

## Overview

This directory will contain the **Stage 4 implementation** of the 5-level inverter control system using a **custom RISC-V soft-core processor**. This stage demonstrates the transition from commercial microcontroller (STM32) to custom silicon, preparing for eventual ASIC implementation.

### Goals

1. **Educational**: Design a complete processor from scratch for power electronics
2. **Performance**: Optimize for real-time control at 10 kHz
3. **Customization**: Add domain-specific instructions for inverter control
4. **ASIC Preparation**: Create architecture suitable for future ASIC tape-out

---

## Current Status

🚧 **PLANNING PHASE** - Not yet implemented

**What's Ready:**
- ✅ Requirements documentation (see `docs/CUSTOM_CORE_REQUIREMENTS.md`)
- ✅ ISA selection (RV32IMC + custom Zpec extension)
- ✅ Peripheral architecture defined
- ✅ Memory map specified

**Next Steps:**
1. Choose implementation approach (custom core vs. modified existing)
2. Set up RISC-V development environment
3. Begin core development or integration

---

## Architecture Overview

### Core Specifications

```
ISA:              RV32IMC + Zpec (custom extension)
Pipeline:         3-stage (Fetch, Decode/Execute, Writeback)
Clock Frequency:  100 MHz (target)
Memory:           Harvard architecture
                  - 64 KB instruction memory (BRAM)
                  - 64 KB data memory (BRAM)
Bus:              Wishbone B4
```

### Custom Instructions (Zpec Extension)

```assembly
pr.step   rd, rs1, rs2    # PR controller iteration
dt.comp   rd, rs1, rs2    # Dead-time compensation
pwm.set   rd, rs1, rs2    # Atomic PWM update
qadd      rd, rs1, rs2    # Saturating add (Q15)
qsub      rd, rs1, rs2    # Saturating subtract (Q15)
fault.chk rd, rs1         # Parallel fault check
```

### Peripherals

```
- PWM Timer 0 (H-Bridge 1: S1-S4)
- PWM Timer 1 (H-Bridge 2: S5-S8)
- ADC Interface (4 channels, 10 kHz)
- UART (debug)
- GPIO (status LEDs, fault signals)
- Interrupt Controller (vectored, 5 priority levels)
```

---

## Directory Structure (Planned)

```
riscv/
├── README.md                    # This file
├── docs/                        # Documentation
│   ├── CUSTOM_CORE_REQUIREMENTS.md   # Detailed requirements ✅
│   ├── architecture.md          # Micro-architecture details (TODO)
│   ├── isa_extension.md         # Zpec ISA specification (TODO)
│   └── peripheral_spec.md       # Peripheral specifications (TODO)
├── rtl/                         # HDL source files
│   ├── core/                    # RISC-V core
│   │   ├── riscv_core.v         # Top-level core
│   │   ├── fetch.v              # Fetch stage
│   │   ├── decode.v             # Decode stage
│   │   ├── execute.v            # Execute stage
│   │   ├── alu.v                # ALU
│   │   ├── regfile.v            # Register file
│   │   └── mult_div.v           # M extension multiplier/divider
│   ├── peripherals/             # Peripheral modules
│   │   ├── pwm_timer.v          # PWM generation with dead-time
│   │   ├── adc_interface.v      # ADC controller
│   │   ├── uart.v               # UART module
│   │   ├── gpio.v               # GPIO controller
│   │   └── interrupt_ctrl.v     # Interrupt controller
│   ├── bus/                     # Bus infrastructure
│   │   ├── wishbone_interconnect.v
│   │   └── wishbone_arbiter.v
│   └── soc/                     # System-on-Chip integration
│       ├── inverter_soc.v       # Top-level SoC
│       └── memory.v             # Memory blocks
├── software/                    # Embedded software
│   ├── startup/                 # Startup code
│   │   ├── startup.S            # Assembly startup
│   │   └── linker.ld            # Linker script
│   ├── hal/                     # Hardware Abstraction Layer
│   │   ├── hal_pwm.c/h          # PWM HAL
│   │   ├── hal_adc.c/h          # ADC HAL
│   │   ├── hal_gpio.c/h         # GPIO HAL
│   │   └── hal_uart.c/h         # UART HAL
│   ├── drivers/                 # Low-level drivers
│   ├── control/                 # Control algorithms
│   │   ├── pr_controller.c/h    # PR current controller
│   │   ├── pi_controller.c/h    # PI voltage controller
│   │   └── modulation.c/h       # PWM modulation
│   ├── safety/                  # Safety and fault handling
│   └── main.c                   # Main application
├── sim/                         # Simulation environment
│   ├── testbenches/             # Verilog testbenches
│   ├── verilator/               # Verilator simulation
│   └── wave_configs/            # Waveform configurations
├── verification/                # Verification suite
│   ├── riscv_tests/             # RISC-V compliance tests
│   ├── unit_tests/              # Unit tests for modules
│   └── integration_tests/       # Full system tests
├── fpga/                        # FPGA-specific files
│   ├── xilinx/                  # Xilinx Vivado projects
│   │   ├── constraints/         # Timing and pin constraints
│   │   └── scripts/             # TCL build scripts
│   └── intel/                   # Intel Quartus (alternative)
└── tools/                       # Build and analysis tools
    ├── Makefile                 # Build system
    ├── generate_hex.py          # Convert ELF to hex
    └── performance_analyzer.py  # Analyze timing
```

---

## Getting Started (When Implementation Begins)

### Prerequisites

1. **RISC-V GNU Toolchain**
   ```bash
   # Install from source (recommended) or package manager
   git clone https://github.com/riscv/riscv-gnu-toolchain
   cd riscv-gnu-toolchain
   ./configure --prefix=/opt/riscv --with-arch=rv32imc --with-abi=ilp32
   make
   export PATH=/opt/riscv/bin:$PATH
   ```

2. **HDL Simulator**
   - Verilator (open-source, recommended)
   - ModelSim/QuestaSim (commercial)
   - Icarus Verilog (simple, free)

3. **FPGA Tools**
   - Xilinx Vivado (for Artix-7 or similar)
   - Intel Quartus (alternative)

4. **RISC-V ISA Simulator (for testing)**
   ```bash
   git clone https://github.com/riscv/riscv-isa-sim
   cd riscv-isa-sim
   mkdir build && cd build
   ../configure --prefix=/opt/riscv
   make && make install
   ```

### Build Flow (Future)

```bash
# 1. Build software
cd software
make clean all
# Output: inverter.elf, inverter.hex

# 2. Run RTL simulation
cd ../sim/verilator
make sim
# Loads inverter.hex into simulated memory

# 3. Synthesize for FPGA
cd ../../fpga/xilinx
vivado -mode batch -source build.tcl
# Output: bitstream for FPGA

# 4. Program FPGA
make program
```

---

## Key Documentation

### Must Read Before Starting

1. **[CUSTOM_CORE_REQUIREMENTS.md](docs/CUSTOM_CORE_REQUIREMENTS.md)**
   - Comprehensive requirements document
   - ISA selection rationale
   - Custom instruction specifications
   - Memory architecture
   - Peripheral details
   - Performance requirements
   - Implementation options

2. **[CLAUDE.md](../../CLAUDE.md)** (Project root)
   - Overall project structure
   - Development workflows
   - Coding standards
   - Safety requirements

3. **STM32 Implementation** (for reference)
   - See `../stm32/` for the working implementation to port

---

## Implementation Options

### Option 1: Custom Core from Scratch ⭐ **Recommended for Learning**

**Pros:**
- Maximum educational value
- Complete understanding of every component
- Full control over optimizations

**Cons:**
- Longer development time (6-8 weeks)
- More verification required

### Option 2: Modify Existing Core (PicoRV32)

**Pros:**
- Faster development (3-4 weeks)
- Pre-verified base core
- Add custom instructions to proven design

**Cons:**
- Less "from scratch" experience
- Need to understand existing codebase

### Option 3: Use VexRiscv Generator

**Pros:**
- Fastest (2-3 weeks)
- Highly configurable
- Good performance

**Cons:**
- Requires learning SpinalHDL
- Less insight into micro-architecture

---

## Performance Targets

### Real-Time Requirements

| Parameter | Target | Notes |
|-----------|--------|-------|
| Control Loop Frequency | 10 kHz | 100 μs period |
| ISR Execution Time | < 50 μs | 50% duty cycle |
| Interrupt Latency | < 500 ns | 50 clock cycles @ 100 MHz |
| PWM Update | < 3 μs | All 8 channels |
| ADC Read | < 2 μs | 4 channels |

### With Custom Instructions

| Operation | Without Zpec | With Zpec | Speedup |
|-----------|--------------|-----------|---------|
| PR Controller Step | ~350 ns | ~50 ns | 7× |
| Dead-time Comp | ~200 ns | ~30 ns | 6.7× |
| PWM Update | ~3 μs | ~0.5 μs | 6× |
| Fault Check | ~500 ns | ~100 ns | 5× |

**Result:** Custom instructions reduce ISR time from ~50 μs to ~25 μs!

---

## Migration from STM32

The control algorithms and software structure from Stage 2 (STM32) will be ported to this RISC-V implementation.

### Key Changes

1. **Hardware Abstraction Layer**
   - Unified API across STM32 and RISC-V
   - Platform-specific implementations in separate files

2. **Fixed-Point Arithmetic**
   - STM32 uses hardware FPU (float)
   - RISC-V uses Q15 fixed-point (int16_t)
   - Validation against MATLAB reference required

3. **Peripheral Registers**
   - STM32: Use HAL library
   - RISC-V: Direct register access via memory-mapped I/O

4. **Interrupt Handling**
   - Different vector table structure
   - Custom CSR (Control and Status Register) usage

---

## Testing Strategy

### 1. Unit Testing (Module Level)

- Test each Verilog module in isolation
- Use cocotb (Python) or SystemVerilog testbenches
- Verify against RISC-V ISA spec

### 2. ISA Compliance Testing

```bash
# Run official RISC-V compliance tests
cd verification/riscv_tests
make test
# Should pass all RV32IMC tests
```

### 3. Software-in-Loop (Simulation)

- Run control algorithm in Verilator
- Compare with MATLAB reference
- Validate timing requirements

### 4. Hardware-in-Loop (FPGA)

- Deploy to FPGA board
- Connect to power stage (with safety precautions!)
- Compare with STM32 implementation

---

## Resources and References

### RISC-V Learning
- [RISC-V ISA Manual](https://riscv.org/technical/specifications/)
- [RISC-V Bytes Blog](https://danielmangum.com/categories/risc-v-bytes/)
- "Computer Organization and Design: RISC-V Edition" (Patterson & Hennessy)

### Open-Source Cores
- [PicoRV32](https://github.com/YosysHQ/picorv32) - Simple, educational
- [VexRiscv](https://github.com/SpinalHDL/VexRiscv) - Configurable, high-performance
- [SERV](https://github.com/olofk/serv) - Bit-serial, ultra-small

### Tools
- [RISC-V GNU Toolchain](https://github.com/riscv/riscv-gnu-toolchain)
- [Verilator](https://www.veripool.org/verilator/) - Fast Verilog simulator
- [GTKWave](http://gtkwave.sourceforge.net/) - Waveform viewer

### Power Electronics + FPGA
- Xilinx Application Notes on motor control
- "FPGA-based Implementation of Multilevel Inverters" (research papers)

---

## FAQ

### Q: Why RISC-V instead of ARM Cortex-M?

**A:** RISC-V is:
- Open-source (no licensing fees for ASIC)
- Extensible (can add custom instructions)
- Educational (can design from scratch)
- Future-proof (growing ecosystem)

### Q: Why custom instructions?

**A:** Control algorithms have repetitive operations (multiply-accumulate, saturating arithmetic) that benefit from hardware acceleration. Custom instructions can provide 5-10× speedup for specific operations while only adding ~5% to core area.

### Q: Can this run on any FPGA?

**A:** Yes! Recommended targets:
- Xilinx Artix-7 (XC7A35T or larger)
- Intel Cyclone IV/V
- Lattice ECP5

The design uses ~5,000 LUTs and 4 BRAMs, so most mid-range FPGAs work.

### Q: How does this compare to STM32 performance?

**A:**
- **Without custom instructions:** Comparable (both ~50% CPU usage)
- **With custom instructions:** ~2× better (25% CPU usage)
- **Power consumption:** FPGA uses less power at idle but more under load

### Q: What about debugging?

**A:** We'll implement:
- UART-based debug prints
- JTAG interface (future)
- Waveform analysis (RTL simulation)
- Instruction trace (in simulation)

---

## Timeline (Estimated)

Assuming 10-15 hours/week of development:

```
Week 1-2:   Environment setup, choose implementation approach
Week 3-6:   Core development (or integration)
Week 7-8:   Peripheral development
Week 9-10:  Software porting (HAL, control algorithms)
Week 11:    Simulation and verification
Week 12-13: FPGA deployment and testing
Week 14-15: Optimization and validation
Week 16:    Documentation and comparison with STM32
```

**Total: ~16 weeks** (4 months)

---

## Contributing

When working on this implementation:

1. **Follow CLAUDE.md guidelines** - Safety first, document thoroughly
2. **Use HAL for portability** - Keep hardware-specific code isolated
3. **Validate against MATLAB** - All algorithms must match reference
4. **Write testbenches** - Every module needs verification
5. **Update documentation** - Keep this README and docs/ current

---

## License

TBD - Same as parent project

---

## Contact / Questions

Refer to main project README for contact information.

---

**Last Updated:** 2025-12-03
**Status:** 📋 Planning Phase - Ready to begin implementation
**Next Milestone:** Choose implementation approach and set up development environment
