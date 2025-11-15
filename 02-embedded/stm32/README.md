# STM32F401RE 5-Level Inverter

Complete implementation for 5-level cascaded H-bridge multilevel inverter.

## Features

- **Phase-Shifted PWM**: 180° phase shift between H-bridges for harmonic reduction
- **10 kHz Switching**: Configurable carrier frequency
- **1μs Dead-Time**: Hardware-generated dead-time insertion
- **Multiple Test Modes**: Easy validation and development
- **UART Debug**: Real-time status monitoring @ 115200 baud
- **Safety Features**: Overcurrent/overvoltage protection
- **Synchronized Timers**: TIM1 master, TIM8 slave

## Pin Mapping

```
H-Bridge 1 (TIM1):
  PA8  → S1 (high-side)
  PB13 → S2 (low-side complementary)
  PA9  → S3 (high-side)
  PB14 → S4 (low-side complementary)

H-Bridge 2 (TIM8):
  PC6  → S5 (high-side)
  PC10 → S6 (low-side complementary)
  PC7  → S7 (high-side)
  PC11 → S8 (low-side complementary)

Debug UART:
  PA2  → TX (connect to USB-Serial RX)
  PA3  → RX (connect to USB-Serial TX)
```

## Quick Start

### Option 1: STM32CubeIDE (Easiest)

1. Open `inverter_5level.ioc` in STM32CubeMX
2. Generate code
3. Copy all `.c` and `.h` files from `Core/` to generated project
4. Build and flash

### Option 2: Command Line

**Requirements:**
- Download [STM32CubeF4](https://github.com/STMicroelectronics/STM32CubeF4)
- Extract to `Drivers/` folder
- Install ARM GCC toolchain

```bash
# Build
make clean all

# Flash
make flash

# Or manually with st-flash
st-flash write build/inverter_5level.bin 0x8000000
```

## Test Modes

Edit `TEST_MODE` in `main.c`:

```c
#define TEST_MODE 1  // Change this value
```

| Mode | Description | Use Case |
|------|-------------|----------|
| 0 | 50% duty PWM test | Verify PWM and dead-time with scope |
| 1 | 5 Hz sine (50% MI) | Low speed waveform visualization |
| 2 | 50 Hz (80% MI) | Normal operation testing |
| 3 | 50 Hz (100% MI) | Full power testing |

## Testing Procedure

### 1. PWM Validation (Mode 0)
```
1. Flash firmware with TEST_MODE = 0
2. Connect oscilloscope:
   - Ch1: PA8 (TIM1_CH1)
   - Ch2: PB13 (TIM1_CH1N)
3. Verify:
   - Frequency = 10 kHz
   - Dead-time ≈ 1 μs
   - Complementary outputs
4. Check phase shift:
   - Ch1: PA8 (TIM1_CH1)
   - Ch2: PC6 (TIM8_CH1)
   - Should see 180° phase difference
```

### 2. Low Voltage Test (Mode 1)
```
1. Change TEST_MODE = 1
2. Connect 5-12V DC supplies (NOT 40V!)
3. Wire H-bridge modules
4. Connect UART @ 115200 baud
5. Monitor output:
   - Should see 5 Hz sine wave
   - Amplitude = 50% of DC voltage
6. Check UART debug output for status
```

### 3. Normal Operation (Mode 2)
```
1. Change TEST_MODE = 2
2. Gradually increase DC voltage
3. Monitor current and temperature
4. Verify 50 Hz, 80% amplitude output
```

## UART Debug Output

Connect USB-Serial adapter:
- Baud: 115200
- Data: 8-bit
- Stop: 1-bit
- Parity: None

Expected output:
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
...
```

## File Structure

```
Core/
├── Inc/
│   ├── main.h
│   ├── pwm_control.h           # PWM driver
│   ├── multilevel_modulation.h # Phase-shifted modulation
│   ├── safety.h                # Protection
│   ├── debug_uart.h            # Debug output
│   ├── stm32f4xx_hal_conf.h   # HAL configuration
│   └── stm32f4xx_it.h          # Interrupt handlers
└── Src/
    ├── main.c                  # Application entry
    ├── pwm_control.c
    ├── multilevel_modulation.c
    ├── safety.c
    ├── debug_uart.c
    ├── stm32f4xx_it.c
    └── system_stm32f4xx.c      # System init

inverter_5level.ioc             # CubeMX config
STM32F401RETx_FLASH.ld          # Linker script
startup_stm32f401xe.s           # Startup code
Makefile                        # Build system
```

## Modifying Parameters

### Change Output Frequency
In `multilevel_modulation.h`:
```c
#define OUTPUT_FREQUENCY_HZ     60     // Change to 60 Hz
```

### Change Switching Frequency
In `multilevel_modulation.h`:
```c
#define PWM_FREQUENCY_HZ        20000  // Change to 20 kHz
```
Also update in timer init:
```c
htim1.Init.Period = (84000000 / 20000) - 1;  // Recalculate
```

### Change Modulation Index
In `main.c`:
```c
modulation_set_index(&modulator, 0.9f);  // 90% amplitude
```

## Troubleshooting

**No PWM output:**
- Check clock configuration (should be 84 MHz)
- Verify timer initialization
- Check GPIO alternate function settings

**Wrong frequency:**
- Verify PWM_PERIOD = 8399 for 10kHz @ 84MHz
- Check prescaler = 0

**No UART output:**
- Check PA2/PA3 connections
- Verify baud rate = 115200
- Ensure USB-Serial adapter TX/RX are swapped

**Shoot-through:**
- Increase dead-time: `DeadTime = 168` for 2μs
- Check complementary polarity
- Verify gate driver isolation

## Safety Notes

⚠️ **HIGH VOLTAGE - LETHAL**

- Always start with LOW voltage (5-12V)
- Use isolated power supplies
- Implement hardware emergency stop
- Monitor temperature continuously
- Never touch live circuits

## Next Steps

1. ✅ Basic PWM working
2. ✅ Phase shift verified
3. ⬜ Add current sensing (ADC)
4. ⬜ Implement closed-loop control
5. ⬜ Add soft-start
6. ⬜ THD measurement and optimization

## Support

For issues or questions:
- Check `IMPLEMENTATION_GUIDE.md`
- Review oscilloscope waveforms
- Check UART debug output
- Verify hardware connections
