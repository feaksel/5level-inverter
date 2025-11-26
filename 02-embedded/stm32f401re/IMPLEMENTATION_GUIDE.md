# STM32F401RE 5-Level Inverter Implementation Guide

## Quick Start

### Hardware Setup
1. Connect STM32F401RE Nucleo board
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

## Build & Flash

### Using STM32CubeIDE:
1. Open project: `File → Open Projects from File System`
2. Import `02-embedded/stm32/` folder
3. Build: `Project → Build All`
4. Flash: `Run → Debug` or `Run → Run`

### Using Command Line:
```bash
cd 02-embedded/stm32
make clean
make all
make flash
```

## How It Works

### Phase-Shifted PWM Strategy
- **TIM1** generates PWM for H-bridge 1 with carrier at 0°
- **TIM8** generates PWM for H-bridge 2 with carrier at 180° phase shift
- Both timers synchronized (TIM1 is master, TIM8 is slave)
- Dead-time: 1μs inserted automatically by hardware

### Modulation Flow
1. **Interrupt** fires at 10 kHz (PWM frequency)
2. **Calculate** sine reference from lookup table
3. **Compare** reference with phase-shifted carriers
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
#define PWM_FREQUENCY_HZ        10000  // Carrier frequency
#define OUTPUT_FREQUENCY_HZ     50     // Default output
#define SINE_TABLE_SIZE         200    // Resolution
```

## Testing Procedure

### Test 1: Basic PWM (No Load)
1. Flash firmware
2. Check with oscilloscope:
   - PA8: Should see 10kHz PWM
   - PB13: Complementary to PA8 with dead-time
   - PC6: Phase-shifted relative to PA8
3. Measure dead-time: Should be ~1μs

### Test 2: Low Voltage Operation
1. Apply 5V DC to each H-bridge input (instead of 40V)
2. Measure output: Should be 50Hz sine wave ±10V peak
3. Check waveform quality with scope

### Test 3: Full Power (CAREFUL!)
1. Start with MI = 0.1 (low output)
2. Gradually increase modulation index
3. Monitor current and temperature
4. Check THD with analyzer if available

## Troubleshooting

**No PWM output:**
- Check HAL initialization in `main.c`
- Verify clock configuration (84 MHz)
- Check timer enable in debugger

**Wrong frequency:**
- Verify `PWM_PERIOD = 8399` (for 10kHz at 84MHz)
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

### Disable Output:
```c
modulator.enabled = false;
```

### Emergency Stop:
```c
pwm_emergency_stop(&pwm_ctrl);  // Immediate shutdown
```

## File Structure
```
stm32/
├── Core/
│   ├── Inc/
│   │   ├── main.h
│   │   ├── pwm_control.h           // Low-level PWM driver
│   │   └── multilevel_modulation.h // Phase-shifted modulation
│   └── Src/
│       ├── main.c                  // Application entry
│       ├── pwm_control.c           // PWM implementation
│       └── multilevel_modulation.c // Modulation logic
├── inverter_5level.ioc             // STM32CubeMX config
├── Makefile                        // Build system
└── IMPLEMENTATION_GUIDE.md         // This file
```

## Next Steps

1. Get basic PWM working
2. Test with low voltage (5-12V)
3. Validate phase shift with 2-channel scope
4. Implement current sensing (future)
5. Add closed-loop control (future)
