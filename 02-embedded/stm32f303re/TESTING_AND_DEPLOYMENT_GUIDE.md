# STM32F303RE Testing and Deployment Guide

**Complete guide from bench testing to production deployment**

---

## Table of Contents

1. [Phase 1: Bench Testing (No Hardware)](#phase-1-bench-testing-no-hardware)
2. [Phase 2: Low-Power Hardware Testing](#phase-2-low-power-hardware-testing)
3. [Phase 3: Sensor Calibration](#phase-3-sensor-calibration)
4. [Phase 4: Progressive Power-Up](#phase-4-progressive-power-up)
5. [Phase 5: Production Deployment](#phase-5-production-deployment)
6. [Troubleshooting](#troubleshooting)
7. [Safety Checklist](#safety-checklist)

---

## Phase 1: Bench Testing (No Hardware)

### Overview

**You can test PWM generation WITHOUT building the power circuit!** The firmware is designed with test modes that are safe to run with no load connected.

### Why This Works

The safety system only checks for **OVER**-conditions:
- Overcurrent: Triggers at `current > 15.0A`
- Overvoltage: Triggers at `voltage > 125.0V`

Without sensors connected:
- ADC reads ≈ 0V on all channels
- Converts to: `0A` current, `0V` voltage
- Safety checks: `0A < 15A` ✓ and `0V < 125V` ✓
- **Safety passes, PWM runs normally**

### Equipment Needed

- ✅ STM32F303RE Nucleo board
- ✅ USB cable (programming + UART)
- ✅ Oscilloscope (2+ channels recommended)
- ✅ USB-to-Serial adapter (optional, for UART debug)
- ❌ NO power circuit needed
- ❌ NO gate drivers needed
- ❌ NO DC supply needed

### Test Mode Selection

The firmware has built-in test modes in [main.c:25](Core/Src/main.c#L25):

```c
#define TEST_MODE 1  // Change this value
```

| Mode | Description | Frequency | MI | Best For |
|------|-------------|-----------|----|---------|
| **0** | **PWM Test (50% duty)** | 5kHz | 50% | **Recommended: Simplest waveform** |
| **1** | **Low Frequency Sine** | 5 Hz | 50% | **Good: Slow, easy to see** |
| 2 | Normal Operation | 50 Hz | 80% | Fast, varies quickly |
| 3 | Full Power | 50 Hz | 100% | Fast, max amplitude |
| 4 | Closed-loop Control | 50 Hz | Variable | Requires feedback sensors |

### Recommended: TEST_MODE 0

**Best for initial validation - constant 50% duty cycle on all outputs.**

#### Step 1: Configure for Bench Test

Edit [main.c:25](Core/Src/main.c#L25):
```c
#define TEST_MODE 0  // PWM test mode
```

#### Step 2: Build and Flash

```bash
cd /home/furka/5level-inverter/02-embedded/stm32f303re
make clean
make all
make flash
```

Or using STM32CubeIDE:
1. Import project: `File → Open Projects from File System`
2. Build: `Project → Build All` (Ctrl+B)
3. Flash: `Run → Debug` (F11)

#### Step 3: Verify with Oscilloscope

**Pin connections:**
```
Probe Channel 1 → PA8  (TIM1_CH1 - S1 high-side)
Probe Channel 2 → PB13 (TIM1_CH1N - S2 low-side)
Ground          → Any GND pin on Nucleo
```

**Expected waveform:**
- **Frequency**: 5 kHz (200 µs period)
- **Duty cycle**: 50% constant (100 µs high, 100 µs low)
- **Amplitude**: 3.3V (MCU logic level)
- **Dead-time**: ~1 µs between complementary transitions
- **Phase**: CH1 and CH1N are complementary (when one is high, other is low)

**What to check:**
1. ✓ Both channels toggle at 5 kHz
2. ✓ Dead-time visible (~1 µs gap between falling edge of one and rising edge of other)
3. ✓ No overlap (would indicate shoot-through risk)
4. ✓ Clean edges (no ringing or noise)

#### Step 4: Verify All 8 Outputs

Check all PWM pins systematically:

| H-Bridge 1 (TIM1) | Pin | Expected |
|-------------------|-----|----------|
| S1 (high-side) | PA8 | 50% duty, 5 kHz |
| S2 (low-side) | PB13 | Complementary to PA8 |
| S3 (high-side) | PA9 | 50% duty, 5 kHz |
| S4 (low-side) | PB14 | Complementary to PA9 |

| H-Bridge 2 (TIM8) | Pin | Expected |
|-------------------|-----|----------|
| S5 (high-side) | PC6 | 50% duty, 5 kHz |
| S6 (low-side) | PC10 | Complementary to PC6 |
| S7 (high-side) | PC7 | 50% duty, 5 kHz |
| S8 (low-side) | PC11 | Complementary to PC7 |

**Note:** All outputs should be synchronized (same phase) because TIM1 is master and TIM8 is slave.

#### Step 5: Optional - UART Debug Output

Connect USB-to-Serial adapter:
```
PA2 (TX) → Adapter RX
PA3 (RX) → Adapter TX
GND      → Adapter GND
```

Open serial terminal (115200 baud, 8N1):
```bash
# Linux
screen /dev/ttyUSB0 115200

# Or use any terminal emulator
minicom -D /dev/ttyUSB0 -b 115200
```

**Expected output:**
```
=====================================
  5-Level Cascaded H-Bridge Inverter
  STM32F401RE Implementation
  With ADC, Logging, Soft-Start, PR
=====================================
Test Mode: 0
System initialized. Starting PWM...

Mode 0: PWM Test (50% duty cycle)
All systems started. Running...

Updates: 5000, Faults: 0, MI: 0.00, Freq: 0.0 Hz
I=0.00A, V=0.0V, DC1=0.0V, DC2=0.0V
```

**What the values mean:**
- `Updates: 5000` - Timer interrupt count (should increase)
- `Faults: 0` - No faults triggered ✓
- `MI: 0.00` - Modulation index (0 because modulator disabled in mode 0)
- `I=0.00A, V=0.0V` - Sensors read 0 (expected without hardware)

### Alternative: TEST_MODE 1 (Slow Sine)

**Good for visualizing the modulation algorithm.**

#### Step 1: Configure

Edit [main.c:25](Core/Src/main.c#L25):
```c
#define TEST_MODE 1  // 5 Hz sine wave
```

#### Step 2: Build and Flash

```bash
make clean && make all && make flash
```

#### Step 3: Observe with Oscilloscope

**What you'll see:**
- **Envelope**: 5 Hz sine wave (200 ms period)
- **Carrier**: 5 kHz PWM switching
- **Positive half-cycle** (0-100 ms):
  - CH1 duty increases from 0% → 50%
  - CH2 stays at 0%
  - Output would be +Vdc × (0 to 0.5) if power circuit connected
- **Negative half-cycle** (100-200 ms):
  - CH1 stays at 0%
  - CH2 duty increases from 0% → 50%
  - Output would be -Vdc × (0 to 0.5) if power circuit connected

**Trigger settings:**
- Trigger on any PWM pin
- Timebase: 50 ms/div (to see full 200 ms cycle)
- Use "envelope" or "peak detect" mode to see modulation

**DC coupling vs AC coupling:**
- Use **DC coupling** to see absolute duty cycle
- Math channel: Average the PWM to see sine envelope

### Bench Test Success Criteria

✅ **Pass if:**
1. All 8 PWM outputs toggle at correct frequency
2. Complementary pairs have dead-time (no overlap)
3. No faults reported in UART output
4. Update counter increases (ISR running)
5. Waveforms clean with minimal noise

❌ **Fail if:**
1. No PWM output → Check clock config, timer init, GPIO alternate function
2. Wrong frequency → Verify `PWM_PERIOD` calculation
3. Overlapping complementary outputs → Increase dead-time
4. Faults trigger → Check safety thresholds
5. No UART output → Check baud rate, TX/RX pins

### What You've Validated

At this point, you've confirmed:
- ✅ MCU is properly clocked (72 MHz)
- ✅ Timers configured correctly (5 kHz PWM)
- ✅ Dead-time insertion working (1 µs)
- ✅ Timer synchronization working (TIM1 master, TIM8 slave)
- ✅ Modulation algorithm executing
- ✅ Interrupt service routine running
- ✅ Safety system operational
- ✅ UART debug working

**You're now ready for hardware testing!**

---

## Phase 2: Low-Power Hardware Testing

### Overview

**NEVER test directly at 50V!** Start with low voltage to validate the complete system safely.

### Safety Warnings

⚠️ **HIGH VOLTAGE - POTENTIALLY LETHAL**

- Use isolated power supplies only
- Implement hardware emergency stop
- Current-limit your power supply (start at 0.5A)
- Use insulated tools
- Keep one hand in pocket when adjusting
- Never work alone
- Have emergency contact ready

### Equipment Needed

- ✅ Completed H-bridge power board (2× H-bridges)
- ✅ Gate drivers (e.g., IR2110, TLP250)
- ✅ MOSFETs or IGBTs (rated for >100V, >10A)
- ✅ **Isolated DC power supply** (adjustable 0-60V, current limiting)
- ✅ Oscilloscope (4 channels recommended)
- ✅ Multimeter
- ✅ Current probe (optional but recommended)
- ✅ Thermal camera or IR thermometer

### Pre-Power Checklist

Before applying ANY power:

**Mechanical:**
- [ ] All screws tight
- [ ] No loose wires
- [ ] Heat sinks properly mounted
- [ ] Thermal paste applied
- [ ] Adequate ventilation
- [ ] Enclosure grounded if metal

**Electrical:**
- [ ] Gate driver power supply isolated (typically 12-15V)
- [ ] Gate driver grounds properly referenced
- [ ] All gate resistors in place (typically 10-22Ω)
- [ ] No short circuits (use continuity tester)
- [ ] DC bus capacitors correct polarity
- [ ] Snubber circuits installed (if used)

**Signal:**
- [ ] PWM signals reach gate drivers (test with scope)
- [ ] Logic levels correct (3.3V from STM32 → 15V to gates)
- [ ] No inverted signals (verify complementary pairs)
- [ ] Dead-time visible at gate driver outputs

**Software:**
- [ ] Set to TEST_MODE 1 (slow, 5 Hz)
- [ ] Modulation index at 50% or lower
- [ ] Safety limits appropriate

### Step 1: Gate Driver Validation (No DC Power)

**Power only the gate drivers (12-15V), NOT the DC bus.**

#### Check 1: Logic Level Translation

Connect oscilloscope:
- Ch1: PA8 (STM32 output, 3.3V logic)
- Ch2: Gate of S1 (should be 15V logic after driver)
- Ch3: Gate of S2 (complementary to S1)

**Expected:**
- When PA8 is HIGH (3.3V) → S1 gate is HIGH (15V), S2 gate is LOW (0V)
- When PA8 is LOW (0V) → S1 gate is LOW (0V), S2 gate is HIGH (15V)
- Dead-time: ~1 µs where both are LOW

✅ **Pass:** Correct translation and dead-time visible
❌ **Fail:** Check gate driver power, input connections, dead-time resistor/capacitor

#### Check 2: All Gate Signals

Verify all 8 gate signals are present and correct:

| Switch | Gate Signal | Complementary To | Expected |
|--------|-------------|------------------|----------|
| S1 | PA8 → Driver → Gate S1 | S2 | 15V, 50% duty (Mode 1: varies) |
| S2 | PB13 → Driver → Gate S2 | S1 | Complementary with dead-time |
| S3 | PA9 → Driver → Gate S3 | S4 | 15V, 50% duty (Mode 1: varies) |
| S4 | PB14 → Driver → Gate S4 | S3 | Complementary with dead-time |
| S5 | PC6 → Driver → Gate S5 | S6 | 15V, 50% duty (Mode 1: varies) |
| S6 | PC10 → Driver → Gate S6 | S5 | Complementary with dead-time |
| S7 | PC7 → Driver → Gate S7 | S8 | 15V, 50% duty (Mode 1: varies) |
| S8 | PC11 → Driver → Gate S8 | S7 | Complementary with dead-time |

### Step 2: First Power-Up (5V DC Bus)

**Use LOW voltage first to limit damage if something goes wrong.**

#### Power Supply Settings

```
Voltage: 5.0V per H-bridge (10V total if non-isolated)
Current Limit: 0.5A (protects against short circuit)
```

#### Configuration

Set TEST_MODE 1 in [main.c:25](Core/Src/main.c#L25):
```c
#define TEST_MODE 1  // 5 Hz, 50% MI
```

Rebuild and flash:
```bash
make clean && make all && make flash
```

#### Power-Up Sequence

1. **Enable current limiting** on power supply (0.5A)
2. **Set voltage to 5V**
3. **Connect ONLY H-bridge 1** first (test one at a time)
4. **Monitor current draw** (should be < 100 mA idle)
5. **Observe output with oscilloscope**

#### Expected Output (H-Bridge 1)

Measure between H-bridge 1 output terminals:

**Positive half-cycle (0-100 ms):**
- Output voltage ramps from 0V → +2.5V (50% of 5V)
- Staircase waveform visible

**Negative half-cycle (100-200 ms):**
- Output voltage ramps from 0V → -2.5V
- Mirror image of positive half

**Cycle repeats every 200 ms (5 Hz)**

#### Measurements

Use multimeter (AC mode):
- **RMS voltage**: ~1.77V (2.5V peak × 0.707)
- **Frequency**: 5 Hz (slow enough to see on meter)

Use oscilloscope:
- **Waveform shape**: Should resemble sine wave with 5 levels
- **Peak voltage**: ±2.5V (for MI=0.5, Vdc=5V)
- **Frequency**: 5 Hz
- **Levels visible**: 5 distinct levels (+5V, +2.5V, 0V, -2.5V, -5V)

#### Check for Problems

Monitor continuously for 5 minutes:

**Current:**
- Idle current < 100 mA ✓
- If current limit trips → Short circuit! Stop immediately!
- Current spikes during switching (normal, use current probe for detail)

**Temperature:**
- MOSFETs/IGBTs: Should be cool (<40°C at no load)
- Gate drivers: Should be cool (<40°C)
- If hot → Check for oscillation, check gate resistors

**Waveform:**
- Clean switching edges ✓
- No ringing (if present, add snubbers)
- No DC offset (if present, check for faulty switch)

### Step 3: Add Second H-Bridge

If H-bridge 1 works correctly:

1. **Power down completely**
2. **Connect H-bridge 2** to second isolated 5V supply
3. **Power up both**
4. **Measure composite output** (H-bridge 1 + H-bridge 2)

**Expected output:**
- 5-level waveform with ±5V peak (full 10V span)
- Better sine approximation than single H-bridge
- Each bridge contributes ±2.5V

### Step 4: Load Testing (5V)

Add a small resistive load:

**Suggested load:**
- 50Ω, 10W resistor
- Expected current: ~0.1A RMS
- Expected power: ~0.5W

**Measurements:**
- Voltage waveform should not change
- Current waveform should match voltage (resistive load)
- MOSFETs should remain cool
- No thermal runaway

**Run for 10 minutes** while monitoring temperature.

### Low-Power Test Success Criteria

✅ **Pass if:**
1. Clean 5-level output waveform
2. Correct frequency (5 Hz)
3. Correct amplitude (±2.5V per H-bridge)
4. No current limit trips
5. Components remain cool
6. Can sustain load for 10+ minutes
7. No faults reported via UART

❌ **Fail if:**
1. Current limit trips → Short circuit, check for shoot-through
2. Components get hot → Check dead-time, gate resistors, switching losses
3. Waveform distorted → Check synchronization, gate signals
4. DC offset present → Faulty switch or gate driver
5. Oscillation/ringing → Add snubbers (RC across switches)

### What You've Validated

- ✅ Power circuit works correctly
- ✅ Gate drivers functioning properly
- ✅ No shoot-through (dead-time adequate)
- ✅ Level-shifted modulation correct
- ✅ Both H-bridges synchronized
- ✅ System can sustain continuous operation
- ✅ Thermal design adequate (at low power)

**You're now ready for sensor integration!**

---

## Phase 3: Sensor Calibration

### Overview

Before increasing power, you **must** calibrate your current and voltage sensors for accurate measurements and safety protection.

### Required Sensors

1. **Output current sensor** (e.g., ACS712, LEM HAS 50-S)
2. **Output voltage sensor** (voltage divider with isolation)
3. **DC bus 1 voltage sensor** (voltage divider)
4. **DC bus 2 voltage sensor** (voltage divider)

### ADC Channel Assignment

From [main.c:529-556](Core/Src/main.c#L529-L556):

| Channel | Pin | Measures | Range |
|---------|-----|----------|-------|
| ADC_CHANNEL_0 | PA0 | Output current | ±20A typical |
| ADC_CHANNEL_1 | PA1 | Output voltage | ±150V peak |
| ADC_CHANNEL_4 | PA4 | DC bus 1 | 0-60V |
| ADC_CHANNEL_5 | PA5 | DC bus 2 | 0-60V |

### Sensor Specifications Needed

Before starting, you need to know:

**Current sensor:**
- Offset voltage (typically 2.5V for Hall effect sensors)
- Sensitivity (e.g., 100 mV/A for ACS712-20A)
- Maximum current (e.g., ±20A)

**Voltage dividers:**
- Divider ratio (e.g., 10:1 for 100kΩ + 10kΩ)
- Input impedance
- Maximum input voltage

### Calibration Procedure

#### Step 1: Update Sensor Scaling

Edit [adc_sensing.c:16-29](Core/Src/adc_sensing.c#L16-L29) with YOUR sensor specs:

**Example for ACS712-20A current sensor:**
```c
float voltage_to_current(float voltage)
{
    // ACS712-20A: 2.5V offset, 100mV/A sensitivity
    const float OFFSET_VOLTAGE = 2.5f;  // Center at 2.5V
    const float SENSITIVITY = 0.1f;     // 100mV/A = 0.1 V/A

    return (voltage - OFFSET_VOLTAGE) / SENSITIVITY;
}
```

**Example for 10:1 voltage divider:**
```c
float voltage_to_bus_voltage(float voltage)
{
    // Voltage divider: 100kΩ + 10kΩ = 11:1 ratio
    const float DIVIDER_RATIO = 11.0f;  // (R1 + R2) / R2

    return voltage * DIVIDER_RATIO;
}
```

#### Step 2: Zero Current Calibration

**With NO load connected and power circuit OFF:**

Add this function to [main.c](Core/Src/main.c) after line 56:

```c
void calibrate_zero_current(void)
{
    debug_print("\r\n=== ZERO CURRENT CALIBRATION ===\r\n");
    debug_print("Ensure NO current flowing...\r\n");
    HAL_Delay(3000);

    // Sample ADC 100 times
    float current_sum = 0.0f;
    for (int i = 0; i < 100; i++) {
        adc_sensor_update(&adc_sensor);
        const sensor_data_t *data = adc_sensor_get_data(&adc_sensor);
        current_sum += data->output_current;
        HAL_Delay(10);
    }

    float zero_offset = current_sum / 100.0f;
    debug_printf("Measured zero offset: %.3f A\r\n", zero_offset);
    debug_print("Update CURRENT_OFFSET in adc_sensing.c\r\n");
    debug_print("================================\r\n\r\n");
}
```

Call it in `main()` before starting PWM (around line 119):
```c
// Calibration routines
calibrate_zero_current();
```

**What to do with results:**

If offset is, for example, `-0.15A`, update [adc_sensing.c:22](Core/Src/adc_sensing.c#L22):
```c
return (voltage - offset_voltage) * CURRENT_SCALE + 0.15f;  // Add measured offset
```

Rebuild, reflash, and verify offset is now close to 0.00A.

#### Step 3: Known Current Calibration

**Apply a known DC current** (use precision DC power supply):

1. Set power supply to 5V, 1.0A current limit
2. Connect to output through 5Ω power resistor
3. Expected current: I = V/R = 5V / 5Ω = 1.0A

**Read actual current from firmware:**

Add to [main.c](Core/Src/main.c):
```c
void calibrate_current_scale(void)
{
    debug_print("\r\n=== CURRENT SCALE CALIBRATION ===\r\n");
    debug_print("Apply 1.0A DC current...\r\n");
    HAL_Delay(3000);

    // Sample ADC
    float current_sum = 0.0f;
    for (int i = 0; i < 100; i++) {
        adc_sensor_update(&adc_sensor);
        const sensor_data_t *data = adc_sensor_get_data(&adc_sensor);
        current_sum += data->output_current;
        HAL_Delay(10);
    }

    float measured = current_sum / 100.0f;
    float actual = 1.0f;  // Known applied current
    float cal_factor = actual / measured;

    debug_printf("Measured: %.3f A\r\n", measured);
    debug_printf("Actual: %.3f A\r\n", actual);
    debug_printf("Calibration factor: %.4f\r\n", cal_factor);
    debug_print("Update CURRENT_SCALE in adc_sensing.c\r\n");
    debug_print("=================================\r\n\r\n");
}
```

If firmware reads `0.87A` when actual is `1.0A`:
- Calibration factor = 1.0 / 0.87 = 1.15

Update [adc_sensing.c:90](Core/Src/adc_sensing.c#L90):
```c
sensor->data.output_current = voltage_to_current(adc_voltages[0]) * 1.15f * sensor->current_cal;
```

#### Step 4: Voltage Calibration

**Apply known DC voltage** to voltage sense inputs:

1. Use precision DC supply (e.g., 10.0V)
2. Connect to voltage divider input
3. Measure with multimeter (verify it's actually 10.0V)

**Read from firmware:**

```c
void calibrate_voltage_scale(void)
{
    debug_print("\r\n=== VOLTAGE SCALE CALIBRATION ===\r\n");
    debug_print("Apply 10.0V DC to voltage input...\r\n");
    HAL_Delay(3000);

    // Sample ADC
    float voltage_sum = 0.0f;
    for (int i = 0; i < 100; i++) {
        adc_sensor_update(&adc_sensor);
        const sensor_data_t *data = adc_sensor_get_data(&adc_sensor);
        voltage_sum += data->output_voltage;
        HAL_Delay(10);
    }

    float measured = voltage_sum / 100.0f;
    float actual = 10.0f;  // Known applied voltage
    float cal_factor = actual / measured;

    debug_printf("Measured: %.2f V\r\n", measured);
    debug_printf("Actual: %.2f V\r\n", actual);
    debug_printf("Calibration factor: %.4f\r\n", cal_factor);
    debug_print("Update voltage_to_bus_voltage() or voltage_cal\r\n");
    debug_print("==================================\r\n\r\n");
}
```

Apply calibration factor to [adc_sensing.c](Core/Src/adc_sensing.c).

#### Step 5: DC Bus Voltage Calibration

Repeat voltage calibration for both DC bus sensors (channels 4 and 5).

**Verify accuracy:**
- Within ±1% at 10V
- Within ±1% at 25V
- Within ±1% at 50V (final operating voltage)

#### Step 6: Store Calibration Factors

**Option A: Hardcode in source** (simple, requires reflash if hardware changes)

In [adc_sensing.c](Core/Src/adc_sensing.c), set calibration constants.

**Option B: Store in EEPROM/Flash** (advanced, persistent calibration)

```c
// Store calibration in STM32 flash (future enhancement)
typedef struct {
    float current_offset;
    float current_scale;
    float voltage_scale;
    uint32_t crc;  // For validation
} calibration_data_t;

// Write to flash at 0x0800F800 (last page)
// Read on startup and apply
```

### Verification

After calibration, verify accuracy:

**Test 1: Zero check**
- No current: Should read 0.00A ± 0.01A
- No voltage: Should read 0.0V ± 0.1V

**Test 2: Span check**
- Apply 5A → Read 5.0A ± 0.05A
- Apply 25V → Read 25.0V ± 0.25V

**Test 3: Linearity check**
- Test at 25%, 50%, 75%, 100% of range
- Error should be < 2% across full range

### Calibration Success Criteria

✅ **Pass if:**
1. Zero offset < 0.05A at no load
2. Span error < 1% at known current/voltage
3. Linearity error < 2% across range
4. Stable readings (< 1% variation over 10 seconds)
5. Both DC bus sensors agree within 0.5V

❌ **Fail if:**
1. Large offset (> 0.2A) → Check sensor zero point
2. Span error > 5% → Check divider ratio or sensitivity
3. Noisy readings → Add filtering, check grounding
4. DC bus sensors disagree → Check for ground loops

---

## Phase 4: Progressive Power-Up

### Overview

**NEVER jump straight to 50V!** Increase power gradually while monitoring for problems.

### Safety Reminders

⚠️ **DANGER: LETHAL VOLTAGE ABOVE 30V**

- Always use insulated tools
- Implement hardware emergency stop
- Keep one hand behind back when adjusting
- Use current-limited supply
- Monitor continuously
- Have fire extinguisher nearby
- Work with partner (buddy system)

### Power-Up Sequence

| Stage | DC Bus Voltage | RMS Output | Power | Duration | Notes |
|-------|----------------|------------|-------|----------|-------|
| 1 | 5V per HB | 3.5V | ~0.1W | 5 min | Component checkout |
| 2 | 12V per HB | 8.5V | ~0.7W | 10 min | Sensor validation |
| 3 | 25V per HB | 17.7V | ~3W | 15 min | Quarter power |
| 4 | 35V per HB | 24.7V | ~6W | 30 min | Half power |
| 5 | 50V per HB | 35V | ~12W | Monitor | 70% power |
| 6 | 50V, MI=0.9 | 70V | ~50W | Monitor | Near full |
| 7 | 50V, MI=1.0 | 100V | ~100W | Monitor | Full power |

### Stage 1: 5V (Already Completed)

This was done in Phase 2 - Low Power Testing.

**Checklist:**
- [x] PWM verified at 5V
- [x] 5-level waveform correct
- [x] No shoot-through
- [x] Components remain cool
- [x] Can run continuously

### Stage 2: 12V Per H-Bridge

#### Configuration

Keep TEST_MODE 1 (5 Hz, 50% MI):
```c
#define TEST_MODE 1
```

No rebuild needed if coming from Stage 1.

#### Power Supply Settings

```
Each H-bridge: 12V DC
Current limit: 1A per supply
Total DC span: 24V
```

#### Expected Output

- **RMS voltage**: 8.5V (12V × 0.707 × MI)
- **Peak voltage**: ±12V
- **Frequency**: 5 Hz
- **Waveform**: 5-level sine

#### Measurements

**Before applying power:**
1. Verify DC bus voltages with multimeter
2. Check sensor calibration (ADC should read ~12V per bus)
3. Confirm current limit set to 1A

**After power-up:**
1. Check ADC readings via UART:
   ```
   DC1=12.0V, DC2=12.0V  // Should match multimeter
   I=0.00A               // No load
   V=8.5V                // Output RMS
   ```

2. Verify safety system working:
   - DC bus undervoltage: Should NOT trip (above minimum)
   - DC bus balance: Should be within tolerance (<1V difference)

3. Add 100Ω load (2W rating minimum):
   - Expected current: 8.5V / 100Ω = 0.085A RMS
   - Monitor temperature for 10 minutes

#### Success Criteria

✅ **Pass:**
- Sensor readings accurate (within 2% of multimeter)
- Safety system stable (no false trips)
- Temperature rise < 10°C above ambient
- Can sustain 10 minutes continuous

❌ **Stop if:**
- Sensor readings incorrect (>5% error)
- Safety trips occur
- Temperature > 50°C
- Current limit trips

### Stage 3: 25V Per H-Bridge (Quarter Power)

#### Configuration

Switch to TEST_MODE 2 (50 Hz operation):
```c
#define TEST_MODE 2  // Normal 50Hz, 80% MI
```

Rebuild and flash:
```bash
make clean && make all && make flash
```

#### Power Supply Settings

```
Each H-bridge: 25V DC
Current limit: 2A per supply
Total DC span: 50V
Expected output: ~17.7V RMS @ 80% MI
```

#### Expected Output

- **RMS voltage**: 17.7V (25V × 0.707 × 0.8 MI)
- **Peak voltage**: ±25V
- **Frequency**: 50 Hz (normal AC)
- **Current**: ~0.18A RMS with 100Ω load
- **Power**: ~3W

#### Measurements

Watch for:
1. **Soft-start sequence**: MI should ramp from 0% → 80% over configured time
2. **Stable operation**: No oscillations at 50 Hz
3. **THD**: Waveform should look sinusoidal (if you have THD analyzer, aim for <10% at this point)

**Monitor continuously for 15 minutes:**
- Temperature every minute
- Current waveform (should match voltage for resistive load)
- Sensor readings
- Fault status

#### Load Testing

Progressive load steps with 15 min soak at each:

| Load | Expected Current | Expected Power | Temperature Target |
|------|------------------|----------------|-------------------|
| 100Ω | 0.18A | 3W | <50°C |
| 50Ω | 0.35A | 6W | <60°C |
| 25Ω | 0.71A | 12W | <70°C |

If temperature exceeds targets, improve cooling before continuing.

#### Success Criteria

✅ **Pass:**
- Soft-start works smoothly
- 50 Hz output stable
- Temperature within limits at all load steps
- No sensor or safety faults
- Can sustain 15 minutes at each load

### Stage 4: 35V Per H-Bridge (Half Power)

#### Configuration

Stay with TEST_MODE 2:
```c
#define TEST_MODE 2  // 50Hz, 80% MI
```

#### Power Supply Settings

```
Each H-bridge: 35V DC
Current limit: 3A per supply
Total output: ~24.7V RMS
```

#### Expected Performance

- **RMS voltage**: 24.7V
- **Power with 50Ω load**: ~12W
- **Current**: ~0.5A RMS
- **Peak voltage**: ±35V

#### Thermal Monitoring

At this power level, thermal management becomes critical:

**Use thermal camera or IR thermometer:**
- MOSFETs/IGBTs: <70°C steady state
- Gate drivers: <60°C
- DC bus capacitors: <60°C
- Current sensors: <50°C

**If temperature exceeds limits:**
1. Improve heat sink thermal contact
2. Increase airflow (add fan)
3. Reduce duty cycle temporarily
4. Check for gate oscillation (increases losses)

#### Run Duration

**Minimum 30 minutes** at 50Ω load (steady state).

Monitor:
- Temperature stabilization (should plateau)
- Efficiency (measure input vs output power)
- Waveform stability (no drift or distortion)

#### Success Criteria

✅ **Pass:**
- Temperature stable < 70°C for MOSFETs
- No thermal runaway
- Waveform clean (minimal distortion)
- Efficiency > 90% (estimate)
- 30 min continuous operation

### Stage 5: 50V Per H-Bridge (70% Power, MI=0.7)

#### Configuration

Reduce modulation index for safety:
```c
modulation_set_index(&modulator, 0.7f);  // Add in apply_test_mode()
```

Or create TEST_MODE 5 in [main.c](Core/Src/main.c).

#### Power Supply Settings

```
Each H-bridge: 50V DC (FULL DC BUS VOLTAGE!)
Current limit: 5A per supply
Modulation index: 0.7 (70%)
Expected output: ~35V RMS
```

⚠️ **This is high voltage! Exercise extreme caution.**

#### Pre-Power Checklist

- [ ] Emergency stop tested and functional
- [ ] All wiring secure (no loose connections)
- [ ] Enclosure closed (if required)
- [ ] Safety interlocks verified
- [ ] Fire extinguisher nearby
- [ ] Observer/partner present
- [ ] Clear evacuation path

#### Expected Performance

- **RMS voltage**: 35V (50V × 0.707 × 0.7)
- **Power with 50Ω**: ~24W
- **Current**: ~0.7A RMS
- **Peak voltage**: ±70V

#### Monitoring

**Continuous monitoring required:**
- Temperature (every 30 seconds)
- Current waveform (for distortion)
- Voltage waveform (for imbalance)
- DC bus voltages (should remain balanced within 1V)
- Safety system status

**Run for 30 minutes minimum**, watching for:
- Thermal stability
- No component degradation
- Clean waveforms
- Accurate sensor readings

### Stage 6: 50V, MI=0.9 (Near Full Power)

#### Configuration

Increase modulation index:
```c
modulation_set_index(&modulator, 0.9f);
```

#### Expected Performance

- **RMS voltage**: 70V (50V × 0.707 × 0.9)
- **Power with 50Ω**: ~98W
- **Current**: ~1.4A RMS

This is approaching your 100V RMS, 500W design target.

#### Load Testing

Test with appropriate loads:

| Load | Power | Current | Notes |
|------|-------|---------|-------|
| 50Ω | ~100W | 1.4A | Full electrical load |
| Motor | Variable | Variable | Real load (if applicable) |

**Watch for:**
- Increased switching losses
- Higher temperatures
- Potential THD increase at high MI

### Stage 7: Full Power (MI=1.0)

#### Configuration

```c
#define TEST_MODE 3  // Full power: 50Hz, 100% MI
```

Rebuild and flash.

#### Expected Performance

- **RMS voltage**: 100V (50V × 2 × 0.707)
- **Peak voltage**: ±100V (2× 50V sources)
- **Rated power**: 500W at 5A load
- **Target THD**: < 5%

#### Verification

**Electrical:**
- [ ] Output voltage: 100V RMS ±2%
- [ ] Frequency: 50 Hz ±0.1 Hz
- [ ] THD < 5% (measure with analyzer)
- [ ] No DC offset (< 1V)
- [ ] Both H-bridges contributing equally

**Thermal (at 500W):**
- [ ] MOSFETs < 80°C steady state
- [ ] Gate drivers < 70°C
- [ ] Capacitors < 65°C
- [ ] Can sustain 1 hour continuous

**Safety:**
- [ ] Overcurrent protection tested (briefly exceed 15A)
- [ ] Overvoltage protection tested (briefly exceed 125V)
- [ ] Emergency stop < 1ms shutdown time

#### Long-Duration Test

**Run for 1 hour minimum** at rated power:
- Monitor temperature every 5 minutes
- Record efficiency (input power vs output power)
- Check for component degradation
- Verify no parameter drift

#### THD Optimization

If THD > 5%:

1. **Check waveform symmetry**: DC offset causes odd harmonics
2. **Verify synchronization**: Timing errors between H-bridges
3. **Tune dead-time**: Too long causes low-order harmonics
4. **Check switching frequency**: Higher reduces THD but increases losses
5. **Optimize level-shifted carriers**: Verify -1/0/+1 regions correct

Adjust `SINE_TABLE_SIZE` in [multilevel_modulation.h](Core/Inc/multilevel_modulation.h) for higher resolution.

#### Full Power Success Criteria

✅ **Pass:**
- 100V RMS output ±2%
- THD < 5%
- Temperature stable < 80°C for 1 hour
- Efficiency > 93%
- All safety systems functional
- Sensors accurate within ±2%

🎉 **Congratulations! Hardware validation complete!**

---

## Phase 5: Production Deployment

### Overview

Now that hardware is validated, prepare for real-world deployment by adding production-grade features.

### Required Modifications

#### 1. Add Undervoltage Protection

**Current problem:** Safety only checks OVERcurrent/OVERvoltage. System will continue running even if DC bus drops too low!

**Add to [safety.h](Core/Inc/safety.h) line 16:**
```c
#define MAX_CURRENT_A           15.0f
#define MAX_VOLTAGE_V           125.0f
#define MIN_BUS_VOLTAGE_V       45.0f    // NEW: Undervoltage threshold
#define MAX_BUS_VOLTAGE_V       55.0f    // NEW: DC bus overvoltage
#define MAX_BUS_IMBALANCE_V     5.0f     // NEW: Max difference between buses
#define FAULT_RESET_DELAY_MS    5000
```

**Add to [safety.h](Core/Inc/safety.h) fault flags (line 20):**
```c
typedef enum {
    FAULT_NONE              = 0x00,
    FAULT_OVERCURRENT       = 0x01,
    FAULT_OVERVOLTAGE       = 0x02,
    FAULT_OVERTEMPERATURE   = 0x04,
    FAULT_EMERGENCY_STOP    = 0x08,
    FAULT_HARDWARE          = 0x10,
    FAULT_UNDERVOLTAGE      = 0x20,  // NEW
    FAULT_BUS_IMBALANCE     = 0x40,  // NEW
    FAULT_SENSOR_FAULT      = 0x80   // NEW
} fault_flag_t;
```

**Add to [safety.h](Core/Inc/safety.h) struct (line 30):**
```c
typedef struct {
    uint32_t fault_flags;
    float current_a;
    float voltage_v;
    float temperature_c;
    float dc_bus1_voltage;  // NEW
    float dc_bus2_voltage;  // NEW
    uint32_t fault_timestamp;
    bool estop_active;
} safety_monitor_t;
```

**Update [safety.c](Core/Src/safety.c) line 21:**
```c
void safety_update(safety_monitor_t *safety, float current, float voltage,
                   float dc_bus1, float dc_bus2)
{
    if (safety == NULL) return;

    safety->current_a = current;
    safety->voltage_v = voltage;
    safety->dc_bus1_voltage = dc_bus1;
    safety->dc_bus2_voltage = dc_bus2;

    // Existing checks
    if (current > MAX_CURRENT_A) {
        safety->fault_flags |= FAULT_OVERCURRENT;
        safety->fault_timestamp = HAL_GetTick();
    }

    if (voltage > MAX_VOLTAGE_V) {
        safety->fault_flags |= FAULT_OVERVOLTAGE;
        safety->fault_timestamp = HAL_GetTick();
    }

    // NEW: Undervoltage protection
    if (dc_bus1 < MIN_BUS_VOLTAGE_V || dc_bus2 < MIN_BUS_VOLTAGE_V) {
        safety->fault_flags |= FAULT_UNDERVOLTAGE;
        safety->fault_timestamp = HAL_GetTick();
    }

    // NEW: DC bus overvoltage
    if (dc_bus1 > MAX_BUS_VOLTAGE_V || dc_bus2 > MAX_BUS_VOLTAGE_V) {
        safety->fault_flags |= FAULT_OVERVOLTAGE;
        safety->fault_timestamp = HAL_GetTick();
    }

    // NEW: Bus imbalance detection
    float imbalance = fabs(dc_bus1 - dc_bus2);
    if (imbalance > MAX_BUS_IMBALANCE_V) {
        safety->fault_flags |= FAULT_BUS_IMBALANCE;
        safety->fault_timestamp = HAL_GetTick();
    }

    // NEW: Sensor validation (detect open circuit or short)
    if (dc_bus1 < 1.0f || dc_bus2 < 1.0f) {  // Should never be <1V if powered
        safety->fault_flags |= FAULT_SENSOR_FAULT;
        safety->fault_timestamp = HAL_GetTick();
    }
}
```

**Update [main.c](Core/Src/main.c) line 160:**
```c
// Old:
safety_update(&safety, sensor->output_current, sensor->dc_bus1_voltage);

// New:
safety_update(&safety, sensor->output_current, sensor->output_voltage,
              sensor->dc_bus1_voltage, sensor->dc_bus2_voltage);
```

#### 2. Implement Runtime Mode Selection

**Problem:** TEST_MODE is hardcoded - requires reflashing to change modes.

**Solution:** Add runtime mode selection via UART commands.

**Add to [main.c](Core/Src/main.c) after line 42:**
```c
/* Operating modes */
typedef enum {
    MODE_STANDBY,      // No output, PWM disabled
    MODE_CALIBRATION,  // Run calibration routines
    MODE_TEST_PWM,     // 50% duty test (was TEST_MODE 0)
    MODE_TEST_SLOW,    // 5 Hz sine (was TEST_MODE 1)
    MODE_OPEN_LOOP,    // 50 Hz open-loop (was TEST_MODE 2)
    MODE_CLOSED_LOOP   // PR controller active (was TEST_MODE 4)
} operating_mode_t;

volatile operating_mode_t current_mode = MODE_STANDBY;
```

**Add mode change function:**
```c
void set_operating_mode(operating_mode_t new_mode)
{
    // Stop current operation
    if (current_mode != MODE_STANDBY) {
        modulator.enabled = false;
        pwm_stop(&pwm_ctrl);
    }

    switch (new_mode) {
        case MODE_STANDBY:
            debug_print("Mode: STANDBY\r\n");
            break;

        case MODE_TEST_PWM:
            debug_print("Mode: PWM TEST (50% duty)\r\n");
            modulator.enabled = false;
            pwm_start(&pwm_ctrl);
            pwm_test_50_percent(&pwm_ctrl);
            break;

        case MODE_TEST_SLOW:
            debug_print("Mode: SLOW SINE (5 Hz)\r\n");
            modulation_set_index(&modulator, 0.5f);
            modulation_set_frequency(&modulator, 5.0f);
            modulator.enabled = true;
            pwm_start(&pwm_ctrl);
            break;

        case MODE_OPEN_LOOP:
            debug_print("Mode: OPEN LOOP (50 Hz)\r\n");
            modulation_set_index(&modulator, 0.8f);
            modulation_set_frequency(&modulator, 50.0f);
            modulator.enabled = true;
            soft_start_begin(&soft_start, 0.8f);
            pwm_start(&pwm_ctrl);
            break;

        case MODE_CLOSED_LOOP:
            if (!sensors_calibrated()) {
                debug_print("ERROR: Sensors not calibrated!\r\n");
                return;
            }
            debug_print("Mode: CLOSED LOOP (PR Controller)\r\n");
            modulation_set_frequency(&modulator, 50.0f);
            modulation_set_index(&modulator, 0.5f);
            modulator.enabled = true;
            pr_controller_reset(&pr_ctrl);
            soft_start_begin(&soft_start, 0.5f);
            pwm_start(&pwm_ctrl);
            break;
    }

    current_mode = new_mode;
}
```

**Add UART command handler:**
```c
void process_uart_command(char cmd)
{
    switch (cmd) {
        case '0': set_operating_mode(MODE_STANDBY); break;
        case '1': set_operating_mode(MODE_TEST_PWM); break;
        case '2': set_operating_mode(MODE_TEST_SLOW); break;
        case '3': set_operating_mode(MODE_OPEN_LOOP); break;
        case '4': set_operating_mode(MODE_CLOSED_LOOP); break;
        case 'c': calibrate_sensors(); break;
        case 's': print_status(); break;
        case 'e': safety_emergency_stop(&safety); break;
        case 'r': safety_clear_faults(&safety); break;
        default:
            debug_print("Unknown command. Commands:\r\n");
            debug_print("  0 - Standby\r\n");
            debug_print("  1 - PWM Test\r\n");
            debug_print("  2 - Slow Sine (5Hz)\r\n");
            debug_print("  3 - Open Loop (50Hz)\r\n");
            debug_print("  4 - Closed Loop (PR)\r\n");
            debug_print("  c - Calibrate sensors\r\n");
            debug_print("  s - Print status\r\n");
            debug_print("  e - Emergency stop\r\n");
            debug_print("  r - Reset faults\r\n");
            break;
    }
}
```

**Add to main loop:**
```c
// In main loop
while (1) {
    // Check for UART command (non-blocking)
    uint8_t rx_char;
    if (HAL_UART_Receive(&huart2, &rx_char, 1, 0) == HAL_OK) {
        process_uart_command((char)rx_char);
    }

    // ... rest of main loop
}
```

#### 3. Tune PR Controller

**The default PR gains may not be optimal for your hardware.**

**Tuning procedure:**

1. Set mode to CLOSED_LOOP (mode 4)
2. Start with conservative gains:
   ```c
   pr_controller_init(&pr_ctrl, 1.0f, 100.0f, 5.0f);  // Kp, Kr, Wc
   ```

3. Increase Kp until response is fast but stable:
   - Start: 1.0
   - Try: 2.0, 3.0, 5.0
   - Stop when: Oscillation begins (back off 20%)

4. Increase Kr to reduce steady-state error at 50 Hz:
   - Start: 100.0
   - Try: 200.0, 500.0, 1000.0
   - Stop when: THD < 5%

5. Adjust Wc (bandwidth):
   - Lower (2-5): Narrower resonance, better disturbance rejection
   - Higher (10-20): Wider resonance, faster tracking

**Measure THD after each adjustment:**

Use oscilloscope FFT or dedicated THD analyzer to measure harmonics.

**Target:**
- Fundamental (50 Hz): 100% (0 dB)
- 3rd harmonic (150 Hz): < -26 dB (5%)
- 5th harmonic (250 Hz): < -32 dB (2.5%)
- 7th harmonic (350 Hz): < -38 dB (1.25%)

#### 4. Add Over-Temperature Protection

**Current issue:** No temperature monitoring in production code.

**Add to [main.c](Core/Src/main.c):**

```c
// After includes
#include <math.h>

// Temperature sensor (optional - internal STM32 sensor or external thermistor)
float read_temperature(void)
{
    // Option 1: Internal STM32 temperature sensor (ADC channel 16)
    // Option 2: External thermistor on ADC channel
    // Option 3: Digital sensor via I2C (e.g., LM75)

    // Placeholder - implement based on your hardware
    return 25.0f;  // TODO: Read actual temperature
}

// In main loop
if ((HAL_GetTick() - last_temp_check) >= 1000) {
    last_temp_check = HAL_GetTick();
    float temp = read_temperature();

    if (temp > MAX_TEMPERATURE_C) {
        safety_emergency_stop(&safety);
        debug_printf("OVERTEMPERATURE: %.1f°C\r\n", temp);
    }
}
```

#### 5. Implement Persistent Calibration Storage

**Problem:** Calibration lost on power cycle.

**Solution:** Store calibration in STM32 flash memory.

**Implementation:**

```c
// Define flash address for calibration data (last page of flash)
#define CAL_FLASH_ADDR    0x0801F800  // Last 2KB page

typedef struct {
    float current_offset;
    float current_scale;
    float voltage_scale;
    float dc_bus1_scale;
    float dc_bus2_scale;
    uint32_t magic;  // 0xCAFEBABE to verify valid data
    uint32_t crc32;  // CRC for data integrity
} calibration_data_t;

// Write calibration to flash
int save_calibration(calibration_data_t *cal)
{
    cal->magic = 0xCAFEBABE;
    cal->crc32 = calculate_crc32((uint8_t*)cal, sizeof(*cal) - 4);

    HAL_FLASH_Unlock();

    // Erase page
    FLASH_EraseInitTypeDef erase;
    erase.TypeErase = FLASH_TYPEERASE_PAGES;
    erase.PageAddress = CAL_FLASH_ADDR;
    erase.NbPages = 1;
    uint32_t page_error;
    HAL_FLASHEx_Erase(&erase, &page_error);

    // Write data
    uint32_t *data = (uint32_t*)cal;
    for (int i = 0; i < sizeof(*cal)/4; i++) {
        HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD,
                         CAL_FLASH_ADDR + i*4, data[i]);
    }

    HAL_FLASH_Lock();
    return 0;
}

// Load calibration from flash
int load_calibration(calibration_data_t *cal)
{
    memcpy(cal, (void*)CAL_FLASH_ADDR, sizeof(*cal));

    // Verify magic and CRC
    if (cal->magic != 0xCAFEBABE) {
        return -1;  // Not calibrated
    }

    uint32_t crc = calculate_crc32((uint8_t*)cal, sizeof(*cal) - 4);
    if (crc != cal->crc32) {
        return -2;  // Corrupted
    }

    return 0;  // OK
}

// In main():
calibration_data_t cal;
if (load_calibration(&cal) == 0) {
    adc_sensor_calibrate(&adc_sensor, cal.current_scale, cal.voltage_scale);
    debug_print("Calibration loaded from flash\r\n");
} else {
    debug_print("No valid calibration found - using defaults\r\n");
}
```

#### 6. Add Watchdog Timer

**Critical safety feature:** Detects software crashes and resets system.

**Add to [main.c](Core/Src/main.c):**

```c
IWDG_HandleTypeDef hiwdg;

void MX_IWDG_Init(void)
{
    hiwdg.Instance = IWDG;
    hiwdg.Init.Prescaler = IWDG_PRESCALER_64;
    hiwdg.Init.Reload = 4095;  // ~4 second timeout
    HAL_IWDG_Init(&hiwdg);
}

// In main():
MX_IWDG_Init();

// In main loop (must be called more frequently than timeout):
HAL_IWDG_Refresh(&hiwdg);
```

**Important:** Only refresh watchdog if system is healthy:

```c
// In main loop:
if (!safety_is_fault(&safety) && sensors_ok() && pwm_ctrl.state == PWM_STATE_RUNNING) {
    HAL_IWDG_Refresh(&hiwdg);  // System healthy
} else {
    // Don't refresh - let watchdog reset system
}
```

### Production Configuration Checklist

Before deploying to production:

**Code:**
- [ ] All TEST_MODE references removed or replaced with runtime selection
- [ ] Calibration stored in flash (persistent)
- [ ] Watchdog timer enabled
- [ ] All safety checks enabled (over/under voltage/current, temperature)
- [ ] Fault logging implemented
- [ ] Emergency stop tested
- [ ] PR controller tuned (THD < 5%)

**Hardware:**
- [ ] All sensors calibrated and verified
- [ ] Emergency stop button functional
- [ ] Thermal management adequate (1 hour full-power test passed)
- [ ] Enclosure grounded
- [ ] Proper isolation verified (hi-pot test)
- [ ] Current limiting fuses installed
- [ ] Strain relief on all cables

**Documentation:**
- [ ] Schematic updated
- [ ] Calibration values recorded
- [ ] Operating procedures written
- [ ] Maintenance schedule defined
- [ ] Troubleshooting guide created

**Testing:**
- [ ] 100 hour burn-in test at full power
- [ ] Power cycle test (1000 cycles)
- [ ] Fault injection testing (verify all safety features)
- [ ] EMC testing (if required)
- [ ] Safety certification (if required)

### Production Deployment Success

🎉 **Congratulations!** Your inverter is now production-ready.

**Recommended monitoring:**
- Log operating hours
- Track fault events
- Monitor efficiency over time
- Schedule preventive maintenance

---

## Troubleshooting

### Common Issues and Solutions

#### Problem: No PWM Output

**Symptoms:**
- Oscilloscope shows no signal on PWM pins
- UART debug shows "PWM start failed"

**Checks:**
1. Verify clock configuration (should be 72 MHz)
2. Check timer initialization return values
3. Verify GPIO alternate function settings
4. Check if PWM was stopped due to fault

**Solution:**
```c
// Add debug output in pwm_start()
debug_printf("TIM1 start result: %d\r\n", HAL_TIM_PWM_Start(...));
```

#### Problem: Wrong PWM Frequency

**Symptoms:**
- Measured frequency doesn't match expected (e.g., 4.8 kHz instead of 5 kHz)

**Checks:**
1. Verify system clock: `debug_printf("SYSCLK: %lu\r\n", HAL_RCC_GetSysClockFreq());`
2. Check timer prescaler (should be 0 for 5 kHz)
3. Verify PWM_PERIOD calculation

**Solution:**
```c
// In multilevel_modulation.h
#define PWM_FREQUENCY_HZ  5000
#define PWM_PERIOD  ((72000000 / PWM_FREQUENCY_HZ) - 1)  // Should be 14399
```

#### Problem: Shoot-Through (Current Limit Trips)

**Symptoms:**
- Power supply current limit trips immediately
- MOSFETs/IGBTs overheat
- Loud bang or smoke

**Cause:** Complementary switches ON simultaneously (no dead-time).

**Solution:**
1. Increase dead-time:
   ```c
   sBreakDeadTimeConfig.DeadTime = 144;  // Increase from 72 to 144 (2µs)
   ```

2. Verify gate driver polarity:
   - Check if CH1 and CH1N are truly complementary on scope

3. Check gate drive power supply:
   - Should have adequate current capability
   - Check for voltage sag during switching

#### Problem: Distorted Output Waveform

**Symptoms:**
- Output not sinusoidal
- High THD (> 10%)
- Visible steps or glitches

**Checks:**
1. Verify level-shifted carriers correct
2. Check sine table resolution (`SINE_TABLE_SIZE`)
3. Verify both H-bridges synchronized

**Solutions:**
1. Increase sine table size:
   ```c
   #define SINE_TABLE_SIZE  400  // Increase from 200
   ```

2. Check carrier offsets in [multilevel_modulation.c](Core/Src/multilevel_modulation.c):
   ```c
   // Carrier 1: -1 to 0
   float carrier1 = -0.5f + 0.5f * triangle;
   // Carrier 2: 0 to +1
   float carrier2 = 0.5f * triangle;
   ```

3. Verify timer synchronization:
   - TIM1 should trigger TIM8
   - Both should have same period

#### Problem: DC Offset in Output

**Symptoms:**
- Multimeter shows DC voltage (should be 0V DC)
- Positive and negative half-cycles unequal

**Causes:**
- Faulty switch (always ON or always OFF)
- Unbalanced DC buses
- Asymmetric modulation

**Solution:**
1. Check DC bus voltages (should be equal within 0.5V)
2. Verify all 8 switches functional:
   - Scope each gate signal
   - Check each switch with current probe
3. Check for modulation offset:
   ```c
   // Should be centered at 0
   float reference = sinf(angle);  // Range: -1 to +1
   ```

#### Problem: Sensor Readings Incorrect

**Symptoms:**
- Current shows constant offset
- Voltage readings don't match multimeter
- DC bus voltages differ from actual

**Solution:**
1. Re-run calibration procedures (Phase 3)
2. Check ADC reference voltage:
   ```c
   debug_printf("VREFINT: %u\r\n", __HAL_ADC_CALC_VREFANALOG_VOLTAGE(adc_vref));
   ```
3. Verify sensor power supply
4. Check for ground loops (use differential probes)

#### Problem: Overheating

**Symptoms:**
- MOSFETs/IGBTs hot (>80°C)
- System trips on over-temperature

**Causes:**
- Excessive switching losses
- Inadequate heat sinking
- Gate oscillation
- Too high switching frequency

**Solutions:**
1. Reduce switching frequency:
   ```c
   #define PWM_FREQUENCY_HZ  5000  // Reduce from 10000
   ```

2. Optimize dead-time (too long increases losses):
   - Measure with scope, aim for 1 µs

3. Check for gate oscillation:
   - Add gate resistor (10-22Ω)
   - Add ferrite bead on gate

4. Improve thermal design:
   - Larger heat sink
   - Forced air cooling
   - Thermal paste

#### Problem: System Resets Randomly

**Symptoms:**
- STM32 resets during operation
- Watchdog timer triggering

**Causes:**
- Power supply noise
- EMI from switching
- Stack overflow
- Interrupt overrun

**Solutions:**
1. Add decoupling capacitors near MCU (100nF + 10µF)
2. Separate analog and digital grounds
3. Increase stack size in linker script
4. Check ISR execution time:
   ```c
   // In HAL_TIM_PeriodElapsedCallback:
   uint32_t start = DWT->CYCCNT;
   // ... ISR code ...
   uint32_t cycles = DWT->CYCCNT - start;
   debug_printf("ISR cycles: %lu\r\n", cycles);  // Should be < 3600 (50µs @ 72MHz)
   ```

#### Problem: Safety System False Trips

**Symptoms:**
- Faults trigger when system is operating normally
- "FAULT: 0x01" messages in UART

**Causes:**
- Safety thresholds too tight
- Sensor noise
- Incorrect calibration

**Solutions:**
1. Add hysteresis to safety checks:
   ```c
   // Add 10% hysteresis
   if (current > MAX_CURRENT_A * 1.1f) {
       // Trip
   } else if (current < MAX_CURRENT_A * 0.9f) {
       // Clear
   }
   ```

2. Add filtering to sensor readings:
   ```c
   // Simple moving average
   sensor->data.output_current = 0.9f * sensor->data.output_current_prev +
                                 0.1f * current_new;
   ```

3. Increase thresholds slightly:
   ```c
   #define MAX_CURRENT_A  18.0f  // Increase from 15.0
   ```

---

## Safety Checklist

### Before Every Power-Up

- [ ] Emergency stop tested and functional
- [ ] All connections secure
- [ ] No damaged components visible
- [ ] Adequate ventilation
- [ ] Fire extinguisher nearby
- [ ] Observer present (buddy system)
- [ ] Clear workspace (no flammable materials)

### During Operation

- [ ] Monitor temperature continuously
- [ ] Watch for unusual sounds (arcing, buzzing)
- [ ] Check for smoke or burning smell
- [ ] Verify output waveform periodically
- [ ] Keep hands clear of high voltage
- [ ] Use insulated tools only

### After Power-Down

- [ ] Wait for capacitors to discharge (>5 minutes)
- [ ] Verify 0V with multimeter before touching
- [ ] Inspect for damage or overheating
- [ ] Log operating hours and any faults
- [ ] Clean dust from heat sinks

### Emergency Procedures

**If current limit trips:**
1. Immediately press emergency stop
2. Power down DC supply
3. Wait for discharge
4. Inspect for short circuit
5. Check all switches with multimeter

**If smoke appears:**
1. Press emergency stop
2. Power down immediately
3. Evacuate if necessary
4. Use Class C fire extinguisher if fire starts
5. Do NOT use water

**If electrical shock occurs:**
1. Do NOT touch victim if still in contact
2. Cut power immediately (circuit breaker)
3. Call emergency services
4. Administer first aid if trained
5. Document incident

---

## Summary

This guide covers the complete testing and deployment process:

1. ✅ **Phase 1**: Bench testing without hardware (PWM validation)
2. ✅ **Phase 2**: Low-power hardware testing (5V safety check)
3. ✅ **Phase 3**: Sensor calibration (accuracy validation)
4. ✅ **Phase 4**: Progressive power-up (5V → 50V gradual increase)
5. ✅ **Phase 5**: Production deployment (enhanced safety, runtime config)

**Key Takeaways:**

- **Never skip low-voltage testing** - catches 90% of problems safely
- **Calibrate sensors carefully** - accuracy critical for safety
- **Increase power gradually** - thermal issues appear slowly
- **Monitor continuously** - early detection prevents damage
- **Add production features** - runtime config, persistent cal, watchdog

**Safety First:** This is high-voltage equipment. Always prioritize safety over schedule.

---

**Document Version:** 1.0
**Last Updated:** 2025-12-09
**Target Hardware:** STM32F303RE + 5-Level Cascaded H-Bridge Inverter
**Review Status:** Ready for field testing

For questions or issues, refer to:
- [README.md](README.md) - Project overview
- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Basic setup
- [CLAUDE.md](../../CLAUDE.md) - Development guidelines
