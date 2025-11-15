# 5-Level Cascaded H-Bridge Multilevel Inverter

[![Build Status](https://github.com/yourusername/5level-inverter/workflows/STM32%20Build/badge.svg)](https://github.com/yourusername/5level-inverter/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Progress](https://img.shields.io/badge/progress-Stage%202-orange.svg)](PROJECT_STATUS.md)

## Overview

Complete control system implementation for a 5-level cascaded H-bridge multilevel inverter, progressing from STM32 microcontroller through FPGA to RISC-V and eventual ASIC implementation.

### Key Features
- 🔌 **Power**: 400W, 80V RMS output, 2×40V DC input (2 H-bridges)
- ⚡ **Topology**: 5 voltage levels (+2V, +V, 0, -V, -2V)
- 🎛️ **Modulation**: Phase-shifted carrier PWM (180° between bridges)
- 📊 **Performance**: THD < 5%, 10kHz switching, 1μs dead-time
- 🔧 **Platforms**: STM32 → FPGA → RISC-V → ASIC migration path
- 🛡️ **Safety**: Overcurrent/overvoltage protection, UART debug monitoring
- 📚 **Educational**: Fully documented with 4 test modes

## Project Structure

```
📦 5level-cascaded-inverter
├── 📂 01-simulation     - MATLAB/Simulink models & verification
├── 📂 02-embedded       - STM32 & RISC-V implementations
├── 📂 03-fpga          - Verilog/VHDL implementations
├── 📂 04-hardware      - PCB designs & mechanical
├── 📂 05-test          - Test suites & validation
├── 📂 06-tools         - Build tools & utilities
├── 📂 07-docs          - Documentation & guides
└── 📂 08-releases      - Binary releases
```

## Quick Start

### Prerequisites
- **Hardware**: STM32F401RE Nucleo board
- **Software**: STM32CubeIDE or ARM GCC toolchain
- **Tools**: Oscilloscope, USB-Serial adapter (for debug)
- **Power**: 2× Isolated 40V DC sources (start with 5-12V for testing!)

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/5level-inverter.git
cd 5level-inverter

# Navigate to STM32 implementation
cd 02-embedded/stm32

# Option 1: STM32CubeIDE
# Open inverter_5level.ioc in STM32CubeMX, generate code, build & flash

# Option 2: Command Line (requires STM32CubeF4 HAL)
make clean all
make flash
```

### First Test

1. Flash firmware with TEST_MODE = 0 (PWM validation)
2. Connect oscilloscope:
   - Ch1: PA8 (TIM1_CH1)
   - Ch2: PB13 (TIM1_CH1N)
3. Verify:
   - Frequency: 10kHz
   - Dead-time: ~1μs
   - Complementary outputs
4. Check phase shift between PA8 and PC6 (should be 180°)

See `02-embedded/stm32/README.md` for detailed testing procedures.

## Development Roadmap

### ✅ Stage 1: MATLAB/Simulink (Complete)
- [x] System modeling
- [x] Control algorithm validation
- [x] Reference waveform generation

### ✅ Stage 2: STM32F401RE Implementation (Complete)
- [x] STM32F401RE @ 84MHz configuration
- [x] Phase-shifted PWM (TIM1 + TIM8 synchronized)
- [x] Complementary outputs with 1μs dead-time
- [x] Sine lookup table modulation (200 samples)
- [x] 4 test modes (PWM test, 5Hz, 50Hz@80%, 50Hz@100%)
- [x] UART debug output @ 115200 baud
- [x] Safety protection (overcurrent/overvoltage)
- [x] Complete build system and documentation
- [ ] Hardware validation (ready for testing)
- [ ] ADC current/voltage sensing
- [ ] Closed-loop PR current control
- [ ] PI voltage outer loop

### 📅 Stage 3: FPGA Implementation (Future)
- [ ] HDL module development
- [ ] STM32-FPGA hybrid system
- [ ] Full FPGA implementation

### 🔮 Stage 4-6: RISC-V & ASIC (Long-term)
- [ ] RISC-V soft-core implementation
- [ ] Custom instruction development
- [ ] ASIC tape-out preparation

## Documentation

- [Getting Started Guide](07-docs/guides/getting_started.md)
- [Architecture Overview](07-docs/design/architecture.md)
- [API Documentation](07-docs/api/index.html)
- [Task Progress](PROJECT_STATUS.md)

## Hardware Requirements

### Minimum Setup
- **STM32F401RE** Nucleo board (current implementation)
- **2× H-bridge modules** with gate drivers (IR2110 or similar)
- **2× 40V DC isolated power supplies**
- **8× Power MOSFETs** (IRFZ44N or equivalent)
- **Oscilloscope** (2+ channels, ≥50MHz)
- **USB-Serial adapter** for debug (optional but recommended)

### Recommended Tools
- 4-channel oscilloscope for phase verification
- Logic analyzer (helpful for debugging)
- Current probes and voltage probes
- Isolated power supplies (critical for safety)
- Electronic load for testing
- Thermal camera (for temperature monitoring)

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -am 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## Testing

```bash
# Run unit tests
cd 05-test/unit/stm32
make test

# Run integration tests
cd 05-test/integration
python test_runner.py

# Validate against MATLAB reference
cd 06-tools/analysis
python compare_with_matlab.py
```

## Safety Warning

⚠️ **HIGH VOLTAGE** - This project involves potentially dangerous voltages. Always:
- Use proper isolation
- Implement hardware protection
- Test with reduced voltage first
- Never work on live circuits
- Use appropriate safety equipment

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## Authors

- **Your Name** - *Initial work* - [GitHub](https://github.com/yourusername)

## Acknowledgments

- STMicroelectronics for HAL libraries
- Xilinx for Vivado tools
- RISC-V Foundation for specifications
- Open-source community for inspiration

## Links

- [Project Wiki](https://github.com/yourusername/5level-inverter/wiki)
- [Issue Tracker](https://github.com/yourusername/5level-inverter/issues)
- [Discussion Forum](https://github.com/yourusername/5level-inverter/discussions)

---

**Current Status**: 🟢 Active Development | **Stage**: 2/6 | **Last Update**: November 2024# 5level-inverter
