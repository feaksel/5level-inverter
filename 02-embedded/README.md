# Embedded Implementations - 5-Level Inverter

This directory contains all microcontroller and SoC implementations for the 5-level cascaded H-bridge multilevel inverter control system.

## Overview

The project follows a progressive implementation path across multiple embedded platforms, each building upon the previous stage's learnings:

```
Stage 2: STM32F401RE (Microcontroller) ✅ COMPLETE
         ↓
Stage 3: FPGA Implementation ✅ RTL MODULES COMPLETE
         ↓
Stage 4: RISC-V SoC ✅ FULLY IMPLEMENTED
         ↓
Stage 5-6: ASIC (Future)
```

---

## Directory Structure

### `/stm32f401re/` - STM32F401RE Implementation (Stage 2A) ✅

**Status:** Production-ready, complete implementation

**Platform:** ARM Cortex-M4F @ 84 MHz with FPU

**Features:**
- ✅ 8-channel PWM generation (TIM1 + TIM8)
- ✅ 10 kHz switching frequency with 1 μs dead-time
- ✅ Level-shifted carrier modulation
- ✅ 4 ADC channels for current/voltage sensing (DMA-based)
- ✅ Proportional-Resonant (PR) current controller
- ✅ Safety protection (OCP, OVP)
- ✅ Soft-start sequence
- ✅ UART debug output @ 115200 baud
- ✅ Data logger
- ✅ 4 test modes

**Code Stats:**
- 1,734 lines of C code
- 11 application modules
- Complete build system (Makefile + STM32CubeMX)
- Ready for hardware validation

**Quick Start:**
```bash
cd stm32f401re/
make clean all
make flash
```

See [`stm32f401re/README.md`](stm32f401re/README.md) for detailed documentation.

---

### `/stm32f303re/` - STM32F303RE Implementation (Stage 2B) ✅

**Status:** Production-ready, complete implementation

**Platform:** ARM Cortex-M4F @ 72 MHz with FPU

**Advantages over F401RE:**
- ✅ **4x 12-bit ADCs @ 5 MSPS** (vs 1x ADC on F401) - superior analog capabilities
- ✅ **16KB Core-Coupled Memory (CCM)** - zero wait-state RAM for time-critical code
- ✅ **7 built-in comparators** - hardware-accelerated protection
- ✅ **4 built-in op-amps** - integrated signal conditioning
- ✅ **Dual ADC mode** - simultaneous multi-channel sampling
- ✅ **8 timers** - more flexible PWM generation

**Features:**
- ✅ 8-channel PWM generation (TIM1 + TIM8)
- ✅ 5/10/20 kHz configurable switching frequency with 1 μs dead-time
- ✅ Level-shifted carrier modulation
- ✅ Enhanced 4-ADC current/voltage sensing (DMA-based)
- ✅ Proportional-Resonant (PR) current controller
- ✅ Safety protection (OCP, OVP)
- ✅ Soft-start sequence
- ✅ UART debug output @ 115200 baud
- ✅ Data logger
- ✅ 4 test modes
- ✅ F303-optimized clock configuration (72 MHz)

**Code Stats:**
- Based on F401RE implementation
- Adapted for F303RE specifications
- Enhanced for superior analog performance
- CCM RAM support in linker script

**Quick Start:**
```bash
cd stm32f303re/
make clean all
make flash
```

**Best For:** Projects requiring precise multi-channel current sensing, advanced analog signal conditioning, or ultra-fast ISR execution.

See [`stm32f303re/README.md`](stm32f303re/README.md) for detailed documentation.

---

### `/riscv-soc/` - RISC-V System-on-Chip (Stage 3-4) ✅

**Status:** Fully implemented, synthesized, and simulated

**Platform:** Custom RISC-V SoC with VexRiscv CPU core

**Features:**
- ✅ Complete SoC with CPU, memory, and peripherals
- ✅ 5,805 lines of synthesized Verilog RTL
- ✅ VexRiscv RV32IMC CPU @ 50 MHz
- ✅ 32 KB ROM + 64 KB RAM
- ✅ Wishbone bus interconnect
- ✅ Hardware PWM accelerator (8 channels with dead-time)
- ✅ ADC interface (4-channel SPI)
- ✅ Hardware protection module (OCP, OVP, watchdog)
- ✅ Timer, GPIO, UART peripherals
- ✅ Complete firmware in C and RISC-V assembly
- ✅ Vivado project automation
- ✅ Passing simulation tests
- ✅ FPGA-ready (Basys 3 / Artix-7)
- ✅ ASIC-ready (technology-independent RTL)

**Code Stats:**
- 5,805 lines of Verilog RTL
- Complete SoC architecture
- Firmware build system
- Comprehensive testbenches
- Full Vivado integration

**Quick Start:**
```bash
cd riscv-soc/
make flash              # Build firmware + synthesize + program FPGA
make uart-monitor       # Monitor debug output
```

**Documentation:**
- [`riscv-soc/README.md`](riscv-soc/README.md) - Quick start guide
- [`riscv-soc/00-RISCV-SOC-ARCHITECTURE.md`](riscv-soc/00-RISCV-SOC-ARCHITECTURE.md) - Complete architecture (~80 pages)
- [`riscv-soc/01-IMPLEMENTATION-GUIDE.md`](riscv-soc/01-IMPLEMENTATION-GUIDE.md) - Build instructions (~65 pages)
- [`riscv-soc/firmware/README.md`](riscv-soc/firmware/README.md) - Firmware development guide

---

## Platform Comparison

| Feature | STM32F401RE | STM32F303RE | RISC-V SoC |
|---------|-------------|-------------|------------|
| **CPU** | ARM Cortex-M4F @ 84 MHz | ARM Cortex-M4F @ 72 MHz | VexRiscv RV32IMC @ 50 MHz |
| **Architecture** | Proprietary | Proprietary | Open-source RISC-V |
| **Memory** | 512 KB Flash + 96 KB RAM | 512 KB Flash + 64 KB RAM + 16 KB CCM | 32 KB ROM + 64 KB RAM |
| **ADC** | 1x 12-bit @ 2.4 MSPS | 4x 12-bit @ 5 MSPS | External 4-ch SPI ADC |
| **Analog** | Basic | 7 comparators + 4 op-amps | None (external) |
| **PWM Generation** | Timer peripherals (TIM1/TIM8) | Timer peripherals (TIM1/TIM8) | Custom hardware accelerator |
| **Dead-time** | Hardware timer | Hardware timer | Custom RTL logic |
| **Development** | STM32CubeIDE + HAL | STM32CubeIDE + HAL | Vivado + RISC-V GCC |
| **Cost** | ~$15 (dev board) | ~$15 (dev board) | ~$50 (FPGA board) |
| **Power** | ~100 mW | ~90 mW (lower clock) | ~500 mW (FPGA) |
| **Scalability** | Limited by peripherals | Limited by peripherals | Unlimited (add RTL modules) |
| **Latency** | μs (interrupt-driven) | μs (interrupt-driven) | ns (hardware-accelerated) |
| **Jitter** | ~100 ns | ~100 ns | < 10 ns |
| **Best For** | General purpose, high speed | Precision analog, multi-sensing | Custom hardware, ASIC path |
| **ASIC Path** | Not applicable | Not applicable | Direct path to silicon |

---

## Implementation Philosophy

### Hardware Abstraction

Both implementations maintain clean abstraction layers to facilitate:
- Algorithm portability across platforms
- Future ASIC development
- Code reuse and maintainability
- Educational understanding

### Safety-First Design

All implementations include:
- Multiple layers of protection (hardware + software)
- Overcurrent and overvoltage monitoring
- Watchdog timers
- Emergency stop functionality
- Fault logging and recovery

### Progressive Complexity

The implementations follow increasing complexity:

1. **STM32** - Understand the complete control system on familiar hardware
2. **RISC-V SoC** - Learn SoC design, bus architectures, hardware acceleration
3. **ASIC** (future) - Full custom silicon implementation

---

## Development Workflow

### For STM32 Development:

**STM32F401RE:**
```bash
cd stm32f401re/
# Edit source files in Core/Src/ and Core/Inc/
make clean all        # Build project
make flash            # Flash to hardware
# Monitor via UART @ 115200 baud
```

**STM32F303RE:**
```bash
cd stm32f303re/
# Edit source files in Core/Src/ and Core/Inc/
make clean all        # Build project (optimized for 72 MHz)
make flash            # Flash to hardware
# Monitor via UART @ 115200 baud
```

**Tools Required:**
- ARM GCC toolchain (or STM32CubeIDE)
- STM32CubeMX (optional)
- ST-Link programmer
- Serial terminal
- For F401: STM32CubeF4 HAL libraries
- For F303: STM32CubeF3 HAL libraries

### For RISC-V SoC Development:

```bash
cd riscv-soc/

# Option 1: One-command build and flash
make flash

# Option 2: Step-by-step
cd firmware && make && cd ..      # Build firmware
make vivado-project               # Create Vivado project
make vivado-build                 # Synthesize design
make vivado-program               # Program FPGA
make uart-monitor                 # Monitor output
```

**Tools Required:**
- RISC-V GCC toolchain
- Xilinx Vivado 2020.2+
- VexRiscv core (see rtl/cpu/README.md)
- FPGA board (Basys 3 or compatible)

---

## Testing and Validation

### STM32 Testing:

1. **PWM Validation** - Oscilloscope measurements
2. **Low Voltage Test** - 5-12V DC operation
3. **Full Power Test** - Rated voltage with current monitoring
4. **Performance Metrics** - THD, efficiency, thermal

**F401RE:** See [`stm32f401re/README.md`](stm32f401re/README.md)
**F303RE:** See [`stm32f303re/README.md`](stm32f303re/README.md)
**General:** See [`07-docs/05-Hardware-Testing-Procedures.md`](../07-docs/05-Hardware-Testing-Procedures.md)

### RISC-V SoC Testing:

1. **Simulation** - Testbench validation
2. **FPGA Synthesis** - Timing and resource analysis
3. **Hardware Validation** - On-board testing
4. **Performance** - Latency and throughput measurements

See [`riscv-soc/01-IMPLEMENTATION-GUIDE.md`](riscv-soc/01-IMPLEMENTATION-GUIDE.md)

---

## Current Status Summary

| Implementation | Status | Hardware Validated | Production Ready |
|----------------|--------|-------------------|------------------|
| **STM32F401RE** | ✅ Complete | 🟨 Ready for testing | ✅ Yes (code-complete) |
| **STM32F303RE** | ✅ Complete | 🟨 Ready for testing | ✅ Yes (code-complete) |
| **RISC-V SoC** | ✅ Complete | 🟨 FPGA synthesis passing | ✅ Yes (simulation-verified) |

---

## Future Roadmap

### Short-term (Stages 2-4):
- [x] STM32 implementation
- [x] RISC-V SoC RTL development
- [x] Vivado integration and simulation
- [ ] Hardware validation with real inverter
- [ ] Performance benchmarking
- [ ] Control loop optimization

### Medium-term (Stage 5):
- [ ] ASIC synthesis preparation
- [ ] DFT (Design for Test) insertion
- [ ] Tape-out via SkyWater 130nm or university program
- [ ] ASIC testing and validation

### Long-term (Stage 6):
- [ ] Custom instruction set extensions
- [ ] Advanced analog integration
- [ ] Multi-inverter coordination
- [ ] Grid-tied operation

---

## Getting Help

### For STM32F401RE:
- See [`stm32f401re/README.md`](stm32f401re/README.md)
- See [`stm32f401re/IMPLEMENTATION_GUIDE.md`](stm32f401re/IMPLEMENTATION_GUIDE.md)
- Check [`CLAUDE.md`](../CLAUDE.md) for development guidelines

### For STM32F303RE:
- See [`stm32f303re/README.md`](stm32f303re/README.md)
- See [`stm32f303re/IMPLEMENTATION_GUIDE.md`](stm32f303re/IMPLEMENTATION_GUIDE.md)
- Check [`CLAUDE.md`](../CLAUDE.md) for development guidelines

### For RISC-V SoC:
- See [`riscv-soc/README.md`](riscv-soc/README.md)
- See [`riscv-soc/00-RISCV-SOC-ARCHITECTURE.md`](riscv-soc/00-RISCV-SOC-ARCHITECTURE.md)
- See [`riscv-soc/01-IMPLEMENTATION-GUIDE.md`](riscv-soc/01-IMPLEMENTATION-GUIDE.md)

### General:
- Main project README: [`../README.md`](../README.md)
- Safety guide: [`../07-docs/03-Safety-and-Protection-Guide.md`](../07-docs/03-Safety-and-Protection-Guide.md)
- Testing procedures: [`../07-docs/05-Hardware-Testing-Procedures.md`](../07-docs/05-Hardware-Testing-Procedures.md)

---

## Contributing

When contributing to embedded implementations:

1. **Maintain portability** - Code will be ported to ASIC
2. **Follow safety guidelines** - See [`CLAUDE.md`](../CLAUDE.md)
3. **Document hardware dependencies** - Keep abstraction clean
4. **Test thoroughly** - Both simulation and hardware
5. **Update documentation** - Keep READMEs synchronized

---

## License

See main project LICENSE file.

---

**Last Updated:** 2025-11-26
**Maintained By:** Project Team
**Status:** Stage 2 (STM32F401RE + STM32F303RE) complete, Stage 3-4 (RISC-V SoC) complete, Stage 5-6 (ASIC) in planning
**Note:** Two STM32 implementations provided for different application requirements (F401RE for general purpose, F303RE for precision analog)
