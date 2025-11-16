# STM32F401RE 5-Level Inverter - Complete Implementation

Complete production-ready implementation for 5-level cascaded H-bridge multilevel inverter using phase-shifted PWM.

## Quick Specs

- **MCU**: STM32F401RE @ 84MHz
- **Topology**: 2 Cascaded H-Bridges (8 switches) → 5 voltage levels
- **DC Input**: 2× 50V isolated sources
- **AC Output**: 100V RMS, 50Hz
- **Switching**: 10kHz with 1μs dead-time
- **Modulation**: Level-shifted carriers (carrier 1: -1 to 0, carrier 2: 0 to +1)
- **Features**: UART debug, safety protection, 4 test modes

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
2. Load inverter_5level.ioc
3. Generate code (Project → Generate Code)
4. Copy all files from Core/ to generated project
5. Build and flash
```

### Option 2: Command Line
```bash
# Prerequisites
# - Download STM32CubeF4 from:
#   https://github.com/STMicroelectronics/STM32CubeF4
# - Extract to Drivers/ folder
# - Install arm-none-eabi-gcc toolchain

# Build
cd 02-embedded/stm32
make clean all

# Flash
make flash
# or manually:
st-flash write build/inverter_5level.bin 0x8000000
```

## Test Modes

Change `TEST_MODE` in main.c (line 20):

```c
#define TEST_MODE 1  // Change this
```

| Mode | Description | Frequency | MI | Use Case |
|------|-------------|-----------|-----|----------|
| 0 | PWM Test | 10kHz carrier | 50% | Oscilloscope validation |
| 1 | Slow Sine | 5 Hz | 50% | Waveform visualization |
| 2 | Normal | 50 Hz | 80% | Standard operation |
| 3 | Full Power | 50 Hz | 100% | Maximum output |

## Quick Start Testing

### 1. PWM Validation (Mode 0)
```bash
1. Flash with TEST_MODE = 0
2. Connect oscilloscope:
   Ch1: PA8 (TIM1_CH1)
   Ch2: PB13 (TIM1_CH1N)
3. Verify:
   - Frequency = 10kHz
   - Dead-time ≈ 1μs
   - Complementary outputs
4. Check phase shift:
   Ch1: PA8, Ch2: PC6
   Should see 180° phase difference
```

### 2. Low Voltage Test (Mode 1)
```bash
1. Change TEST_MODE = 1, rebuild
2. Use 5-12V DC supplies (NOT 50V!)
3. Connect H-bridge modules
4. Open serial terminal @ 115200 baud
5. Observe:
   - 5Hz sine wave output
   - 50% of DC voltage amplitude
   - UART status updates
```

### 3. Normal Operation (Mode 2)
```bash
1. TEST_MODE = 2
2. Start with low voltage
3. Gradually increase to rated voltage
4. Monitor temperature and current
5. Verify 50Hz output at 80% amplitude
```

## UART Debug Output

Terminal settings: 115200 baud, 8N1

Example output:
```
=====================================
  5-Level Cascaded H-Bridge Inverter
  STM32F401RE Implementation
=====================================
Test Mode: 1
System initialized. Starting PWM...

Mode 1: Low Frequency Test (5 Hz, 50% MI)
PWM started. Running...

Updates: 10000, Faults: 0, MI: 0.50, Freq: 5.0 Hz
Updates: 20000, Faults: 0, MI: 0.50, Freq: 5.0 Hz
```

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
**Important**: Requires 3 changes:

1. In `Core/Inc/multilevel_modulation.h`:
```c
#define PWM_FREQUENCY_HZ        20000  // Change to 20kHz
#define PWM_PERIOD              4199   // Recalculate: (84000000/20000)-1
```

2. In `Core/Src/main.c` MX_TIM1_Init() (line ~238):
```c
htim1.Init.Period = 4199;  // Match PWM_PERIOD
```

3. In `Core/Src/main.c` MX_TIM8_Init() (line ~300):
```c
htim8.Init.Period = 4199;  // Match PWM_PERIOD
```

**Formula**: `Period = (84000000 / Frequency) - 1`

### Dead-Time
In `main.c` timer init functions:
```c
sBreakDeadTimeConfig.DeadTime = 168;  // For 2μs @ 84MHz
// DeadTime = (desired_us × 84) for 84MHz clock
```

## Safety Features

- **Overcurrent**: 15A limit (configurable in `safety.h`)
- **Overvoltage**: 125V limit (100V RMS + margin)
- **Emergency Stop**: Immediate shutdown via `pwm_emergency_stop()`
- **Fault Reset**: 5 second delay before faults can be cleared
- **Status Monitoring**: Real-time fault reporting via UART

## File Structure

```
stm32/
├── Core/
│   ├── Inc/                          (11 header files, 706 lines)
│   │   ├── main.h
│   │   ├── pwm_control.h              # Low-level PWM driver (TIM1/TIM8)
│   │   ├── multilevel_modulation.h    # Level-shifted carrier modulation
│   │   ├── pr_controller.h            # Proportional-Resonant controller
│   │   ├── adc_sensing.h              # Current/voltage ADC sampling
│   │   ├── safety.h                   # Protection system (OCP/OVP)
│   │   ├── soft_start.h               # Soft-start ramp sequence
│   │   ├── data_logger.h              # Data logging to UART
│   │   ├── debug_uart.h               # UART debug output
│   │   ├── stm32f4xx_hal_conf.h      # HAL configuration
│   │   └── stm32f4xx_it.h             # Interrupt handlers
│   └── Src/                          (11 source files, 1,734 lines)
│       ├── main.c                     # Application entry (625 lines)
│       ├── pwm_control.c              # PWM driver (274 lines)
│       ├── multilevel_modulation.c    # Modulation (141 lines)
│       ├── pr_controller.c            # PR controller (122 lines)
│       ├── adc_sensing.c              # ADC sensing (122 lines)
│       ├── data_logger.c              # Data logger (96 lines)
│       ├── safety.c                   # Safety (77 lines)
│       ├── soft_start.c               # Soft-start (74 lines)
│       ├── debug_uart.c               # Debug output (47 lines)
│       ├── stm32f4xx_it.c             # Interrupts (76 lines)
│       └── system_stm32f4xx.c         # System init (80 lines)
├── inverter_5level.ioc               # CubeMX project
├── STM32F401RETx_FLASH.ld            # Linker script
├── startup_stm32f401xe.s             # Startup code
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

### Execution Flow
```
10kHz Timer Interrupt
  ↓
Safety Check
  ↓
Get Sine Sample from Lookup Table
  ↓
Compare with Carrier 1 (-1 to 0) → H-Bridge 1 duty
Compare with Carrier 2 (0 to +1) → H-Bridge 2 duty
  ↓
Update PWM Registers
  ↓
Advance Sample Index
```

### 5 Voltage Levels Achieved
- **+100V**: ref > 0, both bridges output +50V
- **+50V**: 0 > ref, bridge 1 outputs +50V, bridge 2 outputs 0V
- **0V**: ref crosses zero
- **-50V**: ref < 0, bridge 1 outputs 0V, bridge 2 outputs -50V
- **-100V**: ref < -1, both bridges output -50V

## Troubleshooting

| Problem | Check |
|---------|-------|
| No PWM output | Clock config (84MHz), timer enable, GPIO AF settings |
| Wrong frequency | Period = (84000000/freq)-1, prescaler = 0 |
| No UART output | PA2/PA3 connections, baud = 115200, TX/RX swapped |
| Shoot-through | Increase dead-time, check polarity, verify isolation |
| Compilation errors | Missing HAL drivers - download STM32CubeF4 |

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
- [x] PWM generation (TIM1 + TIM8, 10 kHz, 1 μs dead-time)
- [x] Level-shifted carrier modulation
- [x] ADC current/voltage sensing (4 channels, DMA-based)
- [x] Proportional-Resonant (PR) current controller
- [x] Safety protection (overcurrent/overvoltage)
- [x] Soft-start sequence
- [x] Data logging system
- [x] UART debug output
- [x] 4 test modes

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

## Resources

- **STM32CubeF4**: https://github.com/STMicroelectronics/STM32CubeF4
- **STM32F401 Datasheet**: https://www.st.com/resource/en/datasheet/stm32f401re.pdf
- **Reference Manual**: https://www.st.com/resource/en/reference_manual/dm00096844.pdf
- **Project Repository**: See main README.md

## Support

For detailed implementation guide, see `IMPLEMENTATION_GUIDE.md`

For project overview, see repository root `README.md`

For AI development guide, see `CLAUDE.md`
