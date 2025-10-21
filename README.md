# 5-Level Cascaded H-Bridge Multilevel Inverter

[![Build Status](https://github.com/yourusername/5level-inverter/workflows/STM32%20Build/badge.svg)](https://github.com/yourusername/5level-inverter/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Progress](https://img.shields.io/badge/progress-Stage%202-orange.svg)](PROJECT_STATUS.md)

## Overview

Complete control system implementation for a 5-level cascaded H-bridge multilevel inverter, progressing from STM32 microcontroller through FPGA to RISC-V and eventual ASIC implementation.

### Key Features
- 🔌 **Power**: 400W, 80V RMS output, 4×40V DC input
- 🎛️ **Control**: Digital PR current control, PI voltage control
- 📊 **Performance**: THD < 5%, 10kHz switching frequency
- 🔧 **Platforms**: STM32 → FPGA → RISC-V → ASIC migration path
- 📚 **Educational**: Fully documented learning journey

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
- STM32F303 Nucleo board
- STM32CubeIDE or VSCode + PlatformIO
- Git for version control
- Oscilloscope for testing

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/5level-inverter.git
cd 5level-inverter

# Initialize submodules (if any)
git submodule update --init --recursive

# STM32 build
cd 02-embedded/stm32
make all

# Flash to board
make flash
```

### First Test

1. Connect oscilloscope to PA8 (PWM output)
2. Run the basic PWM test:
```bash
cd 02-embedded/stm32
make flash TEST=pwm_basic
```
3. Verify 10kHz square wave on scope

## Development Roadmap

### ✅ Stage 1: MATLAB/Simulink (Complete)
- [x] System modeling
- [x] Control algorithm validation
- [x] Reference waveform generation

### 🚧 Stage 2: STM32 Implementation (Current)
- [x] Task 1: Environment setup
- [x] Task 2: Basic PWM generation
- [ ] Task 3: Complementary PWM with dead-time
- [ ] Task 4: Multi-channel synchronization
- [ ] Tasks 5-20: [See full list](docs/progress/task_checklist.md)

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
- STM32F303RE Nucleo board
- 4× H-bridge modules with IR2110 drivers
- 4× 40V DC power supplies (or single 160V with isolation)
- IRFZ44N MOSFETs (or equivalent)
- Basic test equipment (multimeter, oscilloscope)

### Recommended Tools
- 4-channel oscilloscope (≥50MHz)
- Logic analyzer
- Current probes
- Isolated power supplies
- Electronic load

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
