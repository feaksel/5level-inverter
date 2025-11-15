# CLAUDE.md - AI Assistant Guide for 5-Level Inverter Project

**Last Updated:** 2025-11-15
**Project Stage:** Stage 2 - STM32 Implementation
**Repository:** 5level-inverter

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Codebase Structure](#codebase-structure)
3. [Development Workflows](#development-workflows)
4. [Key Technologies & Platforms](#key-technologies--platforms)
5. [Coding Conventions & Standards](#coding-conventions--standards)
6. [Testing Strategy](#testing-strategy)
7. [Documentation Guidelines](#documentation-guidelines)
8. [Safety & Critical Considerations](#safety--critical-considerations)
9. [Common Tasks & Commands](#common-tasks--commands)
10. [AI Assistant Guidelines](#ai-assistant-guidelines)

---

## Project Overview

### Purpose
This project implements a complete control system for a **5-level cascaded H-bridge multilevel inverter**. The project follows a progressive implementation path from simulation through multiple hardware platforms.

### Technical Specifications
- **Power Output:** 400W, 80V RMS
- **Input:** 2× 40V DC isolated sources (2 H-bridges)
- **Control:** Digital PR (Proportional-Resonant) current control + PI voltage control
- **Switching Frequency:** 10 kHz
- **Target THD:** < 5%
- **Topology:** 2 Cascaded H-Bridges (8 switches) → 5 voltage levels (+2V, +V, 0, -V, -2V)

### Development Stages
1. **✅ Stage 1: MATLAB/Simulink** - System modeling and control validation
2. **🚧 Stage 2: STM32 Implementation** - Current stage, microcontroller-based control
3. **📅 Stage 3: FPGA Implementation** - Hardware acceleration
4. **🔮 Stage 4: RISC-V Implementation** - Custom soft-core processor
5. **🔮 Stage 5: RISC-V ASIC** - Application-specific integrated circuit
6. **🔮 Stage 6: Custom ASIC** - Full custom silicon implementation

### Current Focus
The project is currently in **Stage 2** focusing on:
- STM32F401RE microcontroller implementation
- Dual-timer PWM generation (TIM1 + TIM8) with dead-time insertion
- Timer synchronization for 2 H-bridges (8 switches total)
- 5-level cascaded modulation strategy
- Hardware abstraction layers for future portability

---

## Codebase Structure

### Directory Organization

```
5level-inverter/
├── 01-simulation/          # MATLAB/Simulink models
│   ├── inverter_1.slx      # Main Simulink model
│   └── README.md
│
├── 02-embedded/            # Microcontroller implementations
│   ├── stm32/              # STM32F401RE implementation
│   │   ├── Core/           # STM32 HAL code
│   │   ├── Inc/            # Header files
│   │   ├── Src/            # Source files
│   │   ├── Makefile        # Build system
│   │   └── *.ioc           # STM32CubeMX project
│   ├── riscv/              # Future RISC-V implementation
│   └── README.md
│
├── 03-fpga/                # FPGA implementations
│   ├── verilog/            # Verilog modules (future)
│   ├── vhdl/               # VHDL modules (future)
│   └── README.md
│
├── 04-hardware/            # PCB designs and schematics
│   ├── schematics/         # KiCad/Eagle schematics
│   ├── pcb/                # PCB layouts
│   ├── bom/                # Bill of materials
│   └── README.md
│
├── 05-test/                # Test suites and validation
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   ├── hardware/           # Hardware-in-loop tests
│   └── README.md
│
├── 06-tools/               # Build tools and utilities
│   ├── scripts/            # Build and automation scripts
│   ├── analysis/           # Analysis tools
│   └── README.md
│
├── 07-docs/                # Documentation
│   ├── Abstract System Diagram.png
│   ├── Hybrid system diagram.png
│   ├── stm32 only diagram.png
│   ├── design/             # Design documents (to be created)
│   ├── guides/             # User guides (to be created)
│   └── README.md
│
└── 08-releases/            # Binary releases (future)
```

### File Naming Conventions

**C/C++ Files:**
- Header files: `module_name.h`
- Source files: `module_name.c`
- Use lowercase with underscores for multi-word names
- Example: `pwm_generator.c`, `current_controller.h`

**MATLAB/Simulink:**
- Simulink models: `descriptive_name.slx`
- MATLAB scripts: `descriptive_name.m`
- Example: `inverter_1.slx`, `control_tuning.m`

**Documentation:**
- Design docs: Use descriptive names with spaces
- Example: `Abstract System Diagram.png`

---

## Development Workflows

### Git Workflow

**Branch Strategy:**
- `main` - Production-ready code (protected)
- `develop` - Integration branch (protected)
- `feature/*` - Feature development branches
- `bugfix/*` - Bug fix branches
- `claude/*` - AI assistant working branches

**Commit Message Format:**
```
<type>: <brief description>

<detailed description if needed>

<footer: references, breaking changes>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test additions/modifications
- `refactor:` - Code restructuring
- `perf:` - Performance improvements
- `build:` - Build system changes
- `ci:` - CI/CD changes

**Examples:**
```
feat: Add complementary PWM with dead-time insertion

Implement dead-time insertion for STM32 Timer 1 channels to prevent
shoot-through in H-bridge circuits. Dead-time set to 1μs based on
IR2110 driver specifications.

Refs: #12
```

### Development Cycle

1. **Planning**
   - Create/update GitHub issue
   - Reference project roadmap
   - Check task checklist

2. **Implementation**
   - Create feature branch from `develop`
   - Implement with frequent commits
   - Follow coding standards
   - Add inline documentation

3. **Testing**
   - Write unit tests
   - Run integration tests
   - Validate against MATLAB reference
   - Hardware testing (when applicable)

4. **Documentation**
   - Update relevant README files
   - Add/update API documentation
   - Update diagrams if architecture changed

5. **Review & Merge**
   - Create pull request
   - Code review
   - Merge to `develop`
   - Tag releases appropriately

### Build Process

**STM32 Build:**
```bash
cd 02-embedded/stm32
make all              # Build project
make clean            # Clean build artifacts
make flash            # Flash to hardware
make debug            # Start debug session
```

**MATLAB Simulation:**
```matlab
% Open Simulink model
open('01-simulation/inverter_1.slx')
% Run simulation
sim('inverter_1')
```

---

## Key Technologies & Platforms

### Current Platform (Stage 2)

**Microcontroller:** STM32F401RE
- ARM Cortex-M4F core @ 84 MHz
- 512 KB Flash, 96 KB RAM
- FPU for floating-point operations
- Advanced timers (TIM1, TIM8) with complementary outputs

**Development Tools:**
- **IDE:** STM32CubeIDE (primary) or VSCode + PlatformIO
- **HAL:** STM32 HAL library
- **Debugger:** ST-Link v2
- **Build:** GNU ARM Embedded Toolchain + Make

**Key Peripherals:**
- Timer 1: Advanced timer for PWM generation
- ADC: Current and voltage sensing
- DMA: High-speed data transfer
- UART: Debug and communication

### Simulation Platform

**MATLAB/Simulink:**
- Version: R2020b or later recommended
- Required toolboxes:
  - Simulink
  - Simscape Power Systems
  - Control System Toolbox
  - Fixed-Point Designer (for code generation)

### Future Platforms

**FPGA (Stage 3):**
- Xilinx Artix-7 or equivalent
- Vivado Design Suite
- Verilog/VHDL

**RISC-V (Stage 4-5):**
- Custom soft-core implementation
- Custom instructions for power control

---

## Coding Conventions & Standards

### C/C++ Style Guide

**General Principles:**
- Follow MISRA C guidelines where applicable (safety-critical code)
- Optimize for clarity first, then performance
- Comment complex algorithms thoroughly
- Use const correctness

**Formatting:**
```c
// Function naming: lowercase with underscores
void pwm_init(void);
uint32_t adc_read_current(uint8_t channel);

// Variables: descriptive names, lowercase with underscores
uint32_t switching_frequency_hz = 10000;
float current_setpoint_a = 0.0f;

// Constants: uppercase with underscores
#define PWM_FREQUENCY_HZ    10000
#define DEAD_TIME_NS        1000

// Structures: lowercase with _t suffix
typedef struct {
    float kp;
    float ki;
    float integrator;
} pi_controller_t;

// Enums: descriptive names
typedef enum {
    PWM_STATE_IDLE,
    PWM_STATE_RUNNING,
    PWM_STATE_FAULT
} pwm_state_t;
```

**Documentation:**
```c
/**
 * @brief Initialize PWM generation for H-bridge control
 *
 * Configures Timer 1 for complementary PWM output with dead-time
 * insertion. Sets switching frequency to 10 kHz with 1μs dead-time.
 *
 * @param frequency_hz Switching frequency in Hz (1000-20000)
 * @param deadtime_ns Dead-time in nanoseconds (500-2000)
 * @return 0 on success, negative error code on failure
 *
 * @note This function must be called before pwm_start()
 * @warning Dead-time must be appropriate for gate drivers used
 */
int pwm_init(uint32_t frequency_hz, uint32_t deadtime_ns);
```

### Control Algorithm Conventions

**Fixed-Point Arithmetic:**
- Use Q15 or Q31 formats for efficiency
- Document scaling factors clearly
- Validate against floating-point MATLAB reference

**Sampling and Timing:**
- Control loop frequency: Tied to PWM frequency (10 kHz)
- Use consistent time bases
- Document all timing assumptions

**Safety Checks:**
- Always validate inputs
- Implement overcurrent protection
- Include fault detection and handling
- Use watchdog timers

---

## Testing Strategy

### Test Hierarchy

1. **Unit Tests**
   - Test individual functions in isolation
   - Mock hardware dependencies
   - Use CUnit or Unity framework
   - Target: >80% code coverage

2. **Integration Tests**
   - Test module interactions
   - Use hardware simulators when possible
   - Validate against MATLAB reference

3. **Hardware-in-Loop (HIL) Tests**
   - Test on actual STM32 hardware
   - Use oscilloscope verification
   - Automated test scripts

4. **System Validation**
   - Full inverter testing (with safety precautions)
   - Performance metrics (THD, efficiency, etc.)
   - Long-duration reliability tests

### Test Commands

```bash
# Unit tests
cd 05-test/unit/stm32
make test

# Integration tests
cd 05-test/integration
python test_runner.py

# Compare with MATLAB reference
cd 06-tools/analysis
python compare_with_matlab.py
```

### Validation Criteria

**PWM Generation:**
- Frequency accuracy: ±0.1%
- Dead-time accuracy: ±50 ns
- Jitter: < 100 ns

**Control Performance:**
- THD: < 5%
- Step response settling time: < 2 cycles
- Steady-state error: < 1%

---

## Documentation Guidelines

### Code Documentation

**Every module should have:**
1. File header with purpose and author
2. Function documentation (parameters, returns, side effects)
3. Complex algorithm explanations
4. Hardware dependencies noted

**Example:**
```c
/**
 * @file current_controller.c
 * @brief Proportional-Resonant current controller implementation
 *
 * Implements discrete PR controller for sinusoidal current tracking.
 * Controller is tuned for 50/60 Hz fundamental with 10 kHz sampling.
 *
 * @author Your Name
 * @date 2024-11-15
 * @version 1.0
 */
```

### Documentation Files

**Update when:**
- Architecture changes
- New features added
- API changes
- Build process changes

**Key docs to maintain:**
- README.md (main overview)
- Individual module READMEs
- API documentation
- Architecture diagrams
- Task checklists

---

## Safety & Critical Considerations

### ⚠️ HIGH VOLTAGE WARNING

This project involves **potentially lethal voltages**. All development must prioritize safety.

### Safety Requirements

**Code Safety:**
1. **Overcurrent Protection**
   - Hardware and software limits
   - Fault detection within 1 control cycle
   - Safe shutdown procedures

2. **Initialization Checks**
   - Verify all peripherals before starting PWM
   - Check sensor readings are valid
   - Confirm gate drivers are ready

3. **Fault Handling**
   - Disable PWM immediately on fault
   - Log fault conditions
   - Require manual reset

4. **Watchdog Timer**
   - Always enable independent watchdog
   - Refresh only in safe states

**Hardware Safety:**
- Use isolated power supplies
- Implement hardware interlocks
- Include emergency stop functionality
- Use current-limiting resistors during testing
- Always test with reduced voltage first

### Critical Code Sections

**NEVER modify without review:**
- Dead-time insertion logic
- Overcurrent protection
- Fault handling
- PWM initialization sequences

**Always include in commits:**
- Safety check code
- Fault detection mechanisms
- Protection limits

---

## Common Tasks & Commands

### Quick Reference

**Initial Setup:**
```bash
# Clone repository
git clone https://github.com/username/5level-inverter.git
cd 5level-inverter

# Create working branch
git checkout -b feature/your-feature-name

# Setup STM32 environment (assuming tools installed)
cd 02-embedded/stm32
# Generate code from .ioc file or create project
```

**Build & Flash:**
```bash
cd 02-embedded/stm32
make clean all          # Clean build
make flash              # Flash to STM32
make debug              # Start debugging session
```

**Run Tests:**
```bash
# Unit tests
cd 05-test/unit
make test

# Integration tests
cd 05-test/integration
./run_tests.sh
```

**Simulation:**
```bash
# Run MATLAB simulation
cd 01-simulation
matlab -batch "sim('inverter_1')"
```

**Documentation:**
```bash
# Generate API docs (if Doxygen configured)
doxygen Doxyfile

# View architecture diagrams
open 07-docs/*.png
```

---

## AI Assistant Guidelines

### When Working on This Project

1. **Always Consider Safety First**
   - Review safety implications of any code changes
   - Never remove or bypass safety checks
   - Add safety validations where needed

2. **Maintain Portability**
   - This code will be ported to FPGA, RISC-V, and ASIC
   - Keep hardware-specific code isolated
   - Use clear abstraction layers
   - Document hardware dependencies

3. **Follow the Roadmap**
   - Check current stage and tasks
   - Align work with project progression
   - Reference task checklists
   - Update progress documentation

4. **Validate Against MATLAB**
   - All control algorithms must match Simulink reference
   - Use fixed-point analysis tools
   - Document any deviations

5. **Embedded Best Practices**
   - Minimize dynamic memory allocation
   - Avoid floating-point in ISRs when possible
   - Consider real-time constraints
   - Optimize critical paths

6. **Documentation is Critical**
   - This is an educational project
   - Document the "why" not just the "what"
   - Keep diagrams updated
   - Explain design decisions

7. **Testing is Mandatory**
   - Write tests for new functionality
   - Validate on hardware when possible
   - Compare with MATLAB reference
   - Check performance metrics

8. **Git Hygiene**
   - Use descriptive commit messages
   - Reference issues and tasks
   - Keep commits atomic
   - Follow branch naming conventions

### Typical Workflows for AI Assistants

**Adding New Feature:**
```
1. Review current stage and task list
2. Check if feature aligns with roadmap
3. Plan implementation with safety in mind
4. Write code following conventions
5. Add unit tests
6. Update documentation
7. Test on hardware (if applicable)
8. Commit with proper message
9. Update task checklist
```

**Debugging:**
```
1. Reproduce issue (simulation or hardware)
2. Check safety systems are functioning
3. Analyze with oscilloscope/debugger
4. Compare with MATLAB reference
5. Fix root cause, not symptoms
6. Add test to prevent regression
7. Document findings
```

**Code Review:**
```
1. Verify safety checks present
2. Check coding conventions followed
3. Validate algorithm matches MATLAB
4. Review documentation completeness
5. Check test coverage
6. Verify hardware abstraction
```

### Questions to Ask Before Proceeding

- Does this change affect safety-critical code?
- Is this compatible with future FPGA/ASIC implementation?
- Does this match the MATLAB reference?
- Have I documented hardware-specific assumptions?
- Are there appropriate tests?
- Is the real-time performance acceptable?
- Have I updated relevant documentation?

### Resources and References

**Internal:**
- Main README: Project overview and quick start
- System diagrams: `07-docs/*.png`
- Simulink model: `01-simulation/inverter_1.slx`
- Task checklist: Referenced in main README

**External:**
- STM32F401 Reference Manual: [STM32F401xE Datasheet](https://www.st.com/resource/en/datasheet/stm32f401re.pdf)
- Application Notes: Dead-time insertion, current sensing
- H-Bridge design guides
- MISRA C guidelines

### Current Status Summary

**Completed:**
- ✅ Project structure setup
- ✅ MATLAB/Simulink modeling
- ✅ Initial system diagrams
- ✅ Documentation framework

**In Progress:**
- 🚧 STM32 PWM implementation
- 🚧 Control algorithm porting

**Next Steps:**
- Complementary PWM with dead-time
- Multi-channel synchronization
- ADC integration for sensing
- Current control loop implementation

---

## Appendix: Key Specifications

### Electrical Specifications
| Parameter | Value | Unit |
|-----------|-------|------|
| Output Power | 400 | W |
| Output Voltage (RMS) | 80 | V |
| Output Frequency | 50/60 | Hz |
| DC Input (per cell) | 40 | V |
| Number of Cells | 4 | - |
| Switching Frequency | 10 | kHz |
| Dead-time | 1 | μs |
| Target THD | < 5 | % |

### Timing Specifications
| Parameter | Value | Unit |
|-----------|-------|------|
| Control Loop Frequency | 10 | kHz |
| ADC Sampling Rate | 10 | kHz |
| PWM Period | 100 | μs |
| Maximum ISR Execution | < 50 | μs |

### MCU Resources (STM32F401RE)
| Resource | Usage | Allocation |
|----------|-------|------------|
| Timer 1 | H-Bridge 1 PWM (S1-S4) | CH1/CH1N, CH2/CH2N |
| Timer 8 | H-Bridge 2 PWM (S5-S8) | CH1/CH1N, CH2/CH2N |
| ADC 1 | Current Sensing | 2 channels |
| ADC 2 | Voltage Sensing | 2 channels |
| UART 2 | Debug/Communication | TX/RX |
| DMA | ADC Transfer | 2 channels |

---

**Document Version:** 1.0
**Last Updated:** 2025-11-15
**Maintained By:** Project Team
**Review Frequency:** Every major milestone or stage transition
