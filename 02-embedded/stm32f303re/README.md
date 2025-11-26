# STM32F303RE 5-Level Inverter - Complete Implementation

Complete production-ready implementation for 5-level cascaded H-bridge multilevel inverter using level-shifted PWM.

## Quick Specs

- **MCU**: STM32F303RE @ 72MHz
- **Topology**: 2 Cascaded H-Bridges (8 switches) → 5 voltage levels
- **DC Input**: 2× 50V isolated sources
- **AC Output**: 100V RMS, 50Hz
- **Switching**: 5kHz with 1μs dead-time (configurable to 10kHz/20kHz)
- **Modulation**: Level-shifted carriers (carrier 1: -1 to 0, carrier 2: 0 to +1)
- **Features**: UART debug, safety protection, 4 test modes, enhanced ADC capabilities

## Key Advantages of STM32F303RE

### Enhanced Features vs F401RE
- **Superior ADC System**: 4x 12-bit ADCs @ 5 MSPS (vs 1x ADC on F401)
- **More Timers**: 8 timers (vs 6 on F401) - better for complex PWM patterns
- **Dual ADC Mode**: Simultaneous sampling on multiple channels
- **Core-Coupled Memory (CCM)**: 16KB ultra-fast RAM for time-critical code
- **Better Analog**: Built-in comparators and op-amps for precision sensing
- **Same Core**: Cortex-M4F with FPU @ 72 MHz (vs 84 MHz on F401)

### Ideal For
- Multi-channel current sensing with high precision
- Advanced control algorithms requiring fast ADC conversion
- Systems with tight timing requirements (CCM RAM)
- Applications needing analog signal conditioning

## Pin Mapping

### PWM Outputs
```
H-Bridge 1 (TIM1):          H-Bridge 2 (TIM8):
  PA8  → S1 (high-side)       PC6  → S5 (high-side)
  PB13 → S2 (low-side)        PC10 → S6 (low-side)
  PA9  → S3 (high-side)       PC7  → S7 (high-side)
  PB14 → S4 (low-side)        PC11 → S8 (low-side)
```

### Debug Interface
```
UART2 (115200 baud):
  PA2 → TX (to USB-Serial RX)
  PA3 → RX (to USB-Serial TX)
```

## Build Options

### Option 1: STM32CubeIDE (Recommended)
```
1. Open STM32CubeMX
2. Create new project for STM32F303RE
3. Configure peripherals (TIM1, TIM8, UART2, ADC)
4. Generate code (Project → Generate Code)
5. Copy all files from Core/ to generated project
6. Build and flash
```

### Option 2: Command Line
```bash
# Prerequisites
# - Download STM32CubeF3 from:
#   https://github.com/STMicroelectronics/STM32CubeF3
# - Extract to Drivers/ folder
# - Install arm-none-eabi-gcc toolchain

# Build
cd 02-embedded/stm32f303re
make clean all

# Flash
make flash
# or manually:
st-flash write build/inverter_5level.bin 0x8000000
```

## Test Modes

Change `TEST_MODE` in main.c:

```c
#define TEST_MODE 1  // Change this
```

| Mode | Description | Frequency | MI | Use Case |
|------|-------------|-----------|-----|----------|
| 0 | PWM Test | 5kHz carrier | 50% | Oscilloscope validation |
| 1 | Slow Sine | 5 Hz | 50% | Waveform visualization |
| 2 | Normal | 50 Hz | 80% | Standard operation |
| 3 | Full Power | 50 Hz | 100% | Maximum output |

## Changing Parameters

### Modulation Index (Amplitude)
In `main.c`, modify test mode function:
```c
modulation_set_index(&modulator, 0.9f);  // 90% amplitude
```

### Output Frequency
```c
modulation_set_frequency(&modulator, 60.0f);  // 60 Hz
```

### Switching Frequency
**Important**: Requires changes in multilevel_modulation.h and main.c

1. In `Core/Inc/multilevel_modulation.h`:
```c
#define PWM_FREQUENCY_HZ        10000  // Change to 10kHz
#define PWM_PERIOD              7199   // Recalculate: (72000000/10000)-1
```

**Formula**: `Period = (72000000 / Frequency) - 1`

**Available Frequencies**:
- 5kHz: Period = 14399 (default, lower switching losses)
- 10kHz: Period = 7199 (good balance)
- 20kHz: Period = 3599 (ultrasonic, higher losses)

### Dead-Time
In `main.c` timer init functions:
```c
sBreakDeadTimeConfig.DeadTime = 144;  // For 2μs @ 72MHz
// DeadTime = (desired_us × 72) for 72MHz clock
```

## Safety Features

- **Overcurrent**: 15A limit (configurable in `safety.h`)
- **Overvoltage**: 125V limit (100V RMS + margin)
- **Emergency Stop**: Immediate shutdown via `pwm_emergency_stop()`
- **Fault Reset**: 5 second delay before faults can be cleared
- **Status Monitoring**: Real-time fault reporting via UART

## File Structure

```
stm32f303re/
├── Core/
│   ├── Inc/                          (Header files)
│   │   ├── main.h
│   │   ├── pwm_control.h              # Low-level PWM driver (TIM1/TIM8)
│   │   ├── multilevel_modulation.h    # Level-shifted carrier modulation
│   │   ├── pr_controller.h            # Proportional-Resonant controller
│   │   ├── adc_sensing.h              # Current/voltage ADC sampling
│   │   ├── safety.h                   # Protection system (OCP/OVP)
│   │   ├── soft_start.h               # Soft-start ramp sequence
│   │   ├── data_logger.h              # Data logging to UART
│   │   ├── debug_uart.h               # UART debug output
│   │   ├── stm32f3xx_hal_conf.h      # HAL configuration
│   │   └── stm32f3xx_it.h             # Interrupt handlers
│   └── Src/                          (Source files)
│       ├── main.c                     # Application entry
│       ├── pwm_control.c              # PWM driver
│       ├── multilevel_modulation.c    # Modulation
│       ├── pr_controller.c            # PR controller
│       ├── adc_sensing.c              # ADC sensing
│       ├── data_logger.c              # Data logger
│       ├── safety.c                   # Safety
│       ├── soft_start.c               # Soft-start
│       ├── debug_uart.c               # Debug output
│       ├── stm32f3xx_it.c             # Interrupts
│       └── system_stm32f3xx.c         # System init
├── STM32F303RETx_FLASH.ld            # Linker script (with CCM RAM)
├── startup_stm32f303xe.s             # Startup code
├── Makefile                          # Build system
├── README.md                         # This file
└── IMPLEMENTATION_GUIDE.md           # Detailed testing guide
```

## How It Works

### Level-Shifted PWM Strategy
1. **Carrier 1** (H-bridge 1): Triangle wave from -1 to 0 (lower level)
2. **Carrier 2** (H-bridge 2): Triangle wave from 0 to +1 (upper level)
3. **Reference**: Single sine wave from -1 to +1
4. Each carrier at same frequency but different vertical position
5. Natural 5-level synthesis by comparing reference with both carriers

## Troubleshooting

| Problem | Check |
|---------|-------|
| No PWM output | Clock config (72MHz), timer enable, GPIO AF settings |
| Wrong frequency | Period = (72000000/freq)-1, prescaler = 0 |
| No UART output | PA2/PA3 connections, baud = 115200, TX/RX swapped |
| Shoot-through | Increase dead-time, check polarity, verify isolation |
| Compilation errors | Missing HAL drivers - download STM32CubeF3 |

## STM32F303RE vs F401RE Comparison

| Feature | STM32F303RE | STM32F401RE |
|---------|-------------|-------------|
| **Core** | Cortex-M4F | Cortex-M4F |
| **Clock** | 72 MHz | 84 MHz |
| **Flash** | 512 KB | 512 KB |
| **RAM** | 64 KB + 16KB CCM | 96 KB |
| **ADC** | 4x 12-bit @ 5 MSPS | 1x 12-bit @ 2.4 MSPS |
| **Timers** | 8 (with more features) | 6 |
| **Comparators** | 7 built-in | None |
| **Op-Amps** | 4 built-in | None |
| **Best For** | Precision analog, multi-sensing | General purpose, higher speed |

## Safety Warnings

⚠️ **HIGH VOLTAGE - POTENTIALLY LETHAL**

- Always start with LOW voltage (5-12V)
- Use isolated power supplies
- Implement hardware emergency stop
- Never work on live circuits
- Use proper isolation and safety equipment
- Monitor temperature continuously

## Implementation Status

### ✅ Completed Features
- [x] PWM generation (TIM1 + TIM8, configurable frequency, 1 μs dead-time)
- [x] Level-shifted carrier modulation
- [x] ADC current/voltage sensing (4 ADCs, DMA-based)
- [x] Proportional-Resonant (PR) current controller
- [x] Safety protection (overcurrent/overvoltage)
- [x] Soft-start sequence
- [x] Data logging system
- [x] UART debug output
- [x] 4 test modes
- [x] F303RE-optimized clock configuration (72 MHz)
- [x] Linker script with CCM RAM support

### 📋 Pending Hardware Validation
- [ ] Oscilloscope PWM validation
- [ ] Low voltage testing (5-12V)
- [ ] Full power testing (2×50V DC)
- [ ] Closed-loop current control validation
- [ ] THD measurement and optimization
- [ ] Thermal performance testing
- [ ] Long-duration reliability testing

### 🔮 Future Enhancements
- [ ] PI voltage outer loop
- [ ] Grid synchronization
- [ ] Advanced protection features
- [ ] Parameter tuning interface
- [ ] Real-time waveform capture
- [ ] Utilize CCM RAM for ultra-fast ISR execution

## Resources

- **STM32CubeF3**: https://github.com/STMicroelectronics/STM32CubeF3
- **STM32F303 Datasheet**: https://www.st.com/resource/en/datasheet/stm32f303re.pdf
- **Reference Manual**: https://www.st.com/resource/en/reference_manual/dm00043574.pdf
- **F401RE Implementation**: See ../stm32f401re/
- **Project Repository**: See main README.md

## Support

For detailed implementation guide, see `IMPLEMENTATION_GUIDE.md`

For project overview, see repository root `README.md`

For AI development guide, see `CLAUDE.md`

---

**Target MCU**: STM32F303RE (512KB Flash, 64KB RAM + 16KB CCM)
**Clock**: 72 MHz
**Implementation Date**: 2025-11-26
**Based on**: STM32F401RE implementation with F303-specific optimizations
