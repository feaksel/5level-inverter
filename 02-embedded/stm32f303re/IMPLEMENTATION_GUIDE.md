# STM32F303RE 5-Level Inverter Implementation Guide

## Quick Start

### Hardware Setup

1. Connect STM32F303RE Nucleo board
2. Wire gate drivers according to pin mapping below
3. Connect isolated DC supplies (start with LOW voltage for testing!)

### Pin Mapping

```
H-Bridge 1 (TIM1):
  PA8  → G1 (S1 high-side)
  PB13 → G2 (S2 low-side)
  PA9  → G3 (S3 high-side)
  PB14 → G4 (S4 low-side)

H-Bridge 2 (TIM8):
  PC6  → G5 (S5 high-side)
  PC10 → G6 (S6 low-side)
  PC7  → G7 (S7 high-side)
  PC11 → G8 (S8 low-side)
```

## Build & Flash !

### Using STM32CubeIDE:

1. Open project: `File → Open Projects from File System`
2. Import `02-embedded/stm32f303re/` folder
3. Build: `Project → Build All`
4. Flash: `Run → Debug` or `Run → Run`

### Using Command Line:

```bash
cd 02-embedded/stm32f303re
make clean
make all
make flash
```

## How It Works

### Level-Shifted PWM Strategy

- **TIM1** generates PWM for H-bridge 1 with carrier from -1 to 0
- **TIM8** generates PWM for H-bridge 2 with carrier from 0 to +1
- Both timers synchronized and use same frequency (5kHz/10kHz/20kHz)
- Dead-time: 1μs inserted automatically by hardware

### Modulation Flow

1. **Interrupt** fires at PWM frequency (5kHz/10kHz/20kHz)
2. **Calculate** sine reference from lookup table
3. **Compare** reference with level-shifted carriers
4. **Update** duty cycles for both H-bridges
5. **Advance** to next sample point

### Key Parameters to Adjust

In `main.c`:

```c
modulation_set_index(&modulator, 0.8f);  // 0.0 to 1.0 (80% = 0.8)
modulation_set_frequency(&modulator, 50.0f);  // Output Hz
```

In `multilevel_modulation.h`:

```c
#define PWM_FREQUENCY_HZ        5000   // Carrier frequency
#define OUTPUT_FREQUENCY_HZ     50     // Default output
#define SINE_TABLE_SIZE         200    // Resolution
#define PWM_PERIOD              14399  // For 5kHz @ 72MHz
```

## Testing Procedure

### Test 1: Basic PWM (No Load)

1. Flash firmware
2. Check with oscilloscope:
   - PA8: Should see 5kHz PWM (default)
   - PB13: Complementary to PA8 with dead-time
   - PC6: Level-shifted relative to PA8
3. Measure dead-time: Should be ~1μs

### Test 2: Low Voltage Operation

1. Apply 5V DC to each H-bridge input (instead of 50V)
2. Measure output: Should be 50Hz sine wave ±5V peak (for MI=0.5)
3. Check waveform quality with scope

### Test 3: Full Power (CAREFUL!)

1. Start with MI = 0.1 (low output)
2. Gradually increase modulation index
3. Monitor current and temperature
4. Check THD with analyzer if available

## Troubleshooting

**No PWM output:**

- Check HAL initialization in `main.c`
- Verify clock configuration (72 MHz)
- Check timer enable in debugger

**Wrong frequency:**

- Verify `PWM_PERIOD = 14399` (for 5kHz at 72MHz)
- Check `SINE_TABLE_SIZE` and step calculation

**Shoot-through (short circuit):**

- Dead-time too short - increase in timer config
- Check complementary output polarity
- Verify gate driver isolation

## Modifications

### Change Output Frequency:

```c
modulation_set_frequency(&modulator, 60.0f);  // For 60Hz
```

### Change Modulation Depth:

```c
modulation_set_index(&modulator, 0.5f);  // 50% amplitude
```

### Change Switching Frequency:

1. Update `PWM_FREQUENCY_HZ` in `multilevel_modulation.h`
2. Recalculate `PWM_PERIOD = (72000000 / freq) - 1`
3. Update timer initialization in `main.c`

### Disable Output:

```c
modulator.enabled = false;
```

### Emergency Stop:

```c
pwm_emergency_stop(&pwm_ctrl);  // Immediate shutdown
```

## STM32F303RE-Specific Features

### Core-Coupled Memory (CCM)

- 16KB of ultra-fast RAM at address 0x10000000
- Zero wait states for critical code
- Can be used for time-critical ISR variables
- Declared with: `__attribute__((section(".ccmram")))`

### Enhanced ADC Capabilities

- 4x 12-bit ADCs @ 5 MSPS
- Dual/Triple simultaneous sampling modes
- Better for multi-channel current sensing
- Hardware oversampling support

### Built-in Comparators

- 7 ultra-fast comparators
- Can be used for hardware overcurrent protection
- Faster response than software-based protection

## File Structure

```
stm32f303re/
├── Core/
│   ├── Inc/
│   │   ├── main.h
│   │   ├── pwm_control.h           // Low-level PWM driver
│   │   ├── multilevel_modulation.h // Level-shifted modulation
│   │   ├── stm32f3xx_hal_conf.h   // HAL configuration
│   │   └── stm32f3xx_it.h          // Interrupt handlers
│   └── Src/
│       ├── main.c                  // Application entry
│       ├── pwm_control.c           // PWM implementation
│       ├── multilevel_modulation.c // Modulation logic
│       ├── system_stm32f3xx.c     // System initialization
│       └── stm32f3xx_it.c          // Interrupt handlers
├── STM32F303RETx_FLASH.ld          // Linker script (with CCM)
├── startup_stm32f303xe.s           // Startup assembly
├── Makefile                        // Build system
└── IMPLEMENTATION_GUIDE.md         // This file
```

## Next Steps

1. Get basic PWM working
2. Test with low voltage (5-12V)
3. Validate level-shifted modulation with 2-channel scope
4. Implement enhanced ADC sampling (future)
5. Add closed-loop control (future)
6. Optimize using CCM RAM for ISRs (future)

## Comparison with F401RE Implementation

| Feature            | F303RE           | F401RE          |
| ------------------ | ---------------- | --------------- |
| Clock Speed        | 72 MHz           | 84 MHz          |
| RAM                | 64KB + 16KB CCM  | 96KB            |
| ADCs               | 4x @ 5 MSPS      | 1x @ 2.4 MSPS   |
| PWM Period (5kHz)  | 14399            | 16799           |
| PWM Period (10kHz) | 7199             | 8399            |
| Dead-time (1μs)    | 72 counts        | 84 counts       |
| Best For           | Precision analog | General purpose |

---

**Target**: STM32F303RE Nucleo Board
**Version**: 1.0
**Date**: 2025-11-26
