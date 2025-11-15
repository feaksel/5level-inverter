# Hardware Testing Procedures

**Document Type:** Technical Procedure / Test Plan
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0

⚠️ **Safety First:** Read the Safety and Protection Guide before performing any tests.

---

## Table of Contents

1. [Test Overview](#test-overview)
2. [Required Equipment](#required-equipment)
3. [Test Environment Setup](#test-environment-setup)
4. [Phase 1: Component Testing](#phase-1-component-testing)
5. [Phase 2: Subsystem Testing](#phase-2-subsystem-testing)
6. [Phase 3: Low-Power Integration](#phase-3-low-power-integration)
7. [Phase 4: Full-Power Testing](#phase-4-full-power-testing)
8. [Phase 5: Performance Validation](#phase-5-performance-validation)
9. [Documentation and Data Collection](#documentation-and-data-collection)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## Test Overview

### Testing Philosophy

**Progressive validation approach:**
1. Start with individual components
2. Test subsystems in isolation
3. Integrate gradually with reduced power
4. Scale up to full power only after all checks pass
5. Validate performance against specifications

**Never skip steps!** Each phase builds on the previous one.

### Test Objectives

**Primary goals:**
- Verify correct hardware operation
- Validate protection systems
- Characterize performance
- Identify and fix issues early
- Ensure safety before full-power operation

**Success criteria defined for each phase.**

### Testing Timeline

Estimated duration (for first unit):
- Phase 1: 2-4 hours
- Phase 2: 3-6 hours
- Phase 3: 4-8 hours
- Phase 4: 2-4 hours
- Phase 5: 4-8 hours

**Total: 2-3 days minimum**

Do not rush! Safety and thoroughness are paramount.

---

## Required Equipment

### Mandatory Test Equipment

#### Power Supplies

| Equipment | Specification | Purpose |
|-----------|---------------|---------|
| **DC Power Supply 1** | 0-60V, 10A min | H-Bridge 1 DC bus |
| **DC Power Supply 2** | 0-60V, 10A min | H-Bridge 2 DC bus |
| **Bench Supply** | 5V/3.3V, 2A | Control logic power |

**Requirements:**
- Current limiting capability
- Voltage/current display
- Isolated outputs (critical!)
- Short-circuit protection

#### Measurement Equipment

| Equipment | Specification | Purpose |
|-----------|---------------|---------|
| **Digital Multimeter (DMM)** | True RMS, 1000V rated | Voltage measurements |
| **Oscilloscope** | 100 MHz+, 4 channels | Waveform analysis |
| **Scope Probes** | 100 MHz, 10:1, isolated | Safe measurements |
| **Current Probe** | AC/DC, 20A+ | Current measurement |
| **Logic Analyzer** | 8+ channels (optional) | Digital signal debug |

**Oscilloscope must have:**
- Differential probes or isolated channels
- Math functions (FFT for THD)
- Sufficient memory depth (> 10k points)
- Screenshot/data export capability

#### Test Loads

| Load Type | Specification | Purpose |
|-----------|---------------|---------|
| **Resistive** | 10Ω, 200W | Initial testing |
| **Resistive** | 20Ω, 100W | Mid-power testing |
| **Incandescent Bulbs** | 100W, 120V AC | Visual indicator |
| **Inductive (optional)** | Motor or inductor | Real-world load testing |

**Never test with no load!** (Open circuit testing should be brief)

### Safety Equipment

| Equipment | Purpose |
|-----------|---------|
| Safety glasses | Eye protection (mandatory) |
| Insulating gloves | For >50V work |
| ESD wrist strap | Component protection |
| Fire extinguisher | Class C (electrical), nearby |
| First aid kit | Emergency response |
| Emergency stop button | Immediate shutdown |

### Software and Tools

- **Serial terminal:** PuTTY, screen, or similar (115200 baud)
- **Waveform analysis:** Python scripts from `06-tools/`
- **STM32 programmer:** ST-Link or similar
- **Multimeter with datalogging** (if available)

### Optional but Useful

- Thermal camera (for hotspot detection)
- Power analyzer (for efficiency measurement)
- Spectrum analyzer (for EMI testing)
- Second oscilloscope (simultaneous multi-point measurement)

---

## Test Environment Setup

### Physical Setup

**Workbench requirements:**
- **Grounded:** ESD mat connected to earth ground
- **Non-conductive surface:** For high-voltage work
- **Well-lit:** Good visibility for connections
- **Ventilated:** For heat dissipation
- **Clear:** No clutter, adequate workspace

**Layout:**

```
┌──────────────────────────────────────┐
│                                      │
│  [DC Supply 1] [DC Supply 2]        │
│       │             │                │
│       ├─────┬───────┤                │
│       │     │       │                │
│   ┌───┴─────┴───────┴────┐          │
│   │   Inverter Under Test │          │
│   │   (with E-Stop)       │          │
│   └───┬───────────────┬───┘          │
│       │               │              │
│   [Load]          [Scope]            │
│                                      │
│   [Control PC]  [DMM]                │
│                                      │
└──────────────────────────────────────┘
```

**Cable management:**
- Short, direct paths for power
- Separate power and signal cables
- Strain relief on all connections
- Color-coded wires (red=+, black=-, green=ground)

### Pre-Test Checklist

**Before ANY test:**

- [ ] Read and understand test procedure
- [ ] Safety equipment ready and worn
- [ ] Emergency stop accessible
- [ ] Fire extinguisher nearby
- [ ] Test area clear of personnel (if first power-on)
- [ ] All equipment properly grounded
- [ ] Camera/phone ready for documentation
- [ ] Test log prepared
- [ ] Load connected (if required for test)
- [ ] Scope probes checked and calibrated

---

## Phase 1: Component Testing

### Objective

Verify individual components before integration.

**Duration:** 2-4 hours

### Test 1.1: Power Supply Verification

**Purpose:** Ensure DC supplies are safe and meet specifications.

**Procedure:**

1. **Set both supplies to 0V, current limit to 1A**
2. **Measure output with DMM**
   - Verify 0V reading
   - Check polarity (red probe = +)
3. **Gradually increase Supply 1 to 50V**
   - Monitor voltage accuracy (±1V acceptable)
   - Check for ripple on scope (< 100mV p-p)
4. **Repeat for Supply 2**
5. **Verify isolation between supplies**
   - Disconnect both from ground
   - Measure resistance between Supply 1 GND and Supply 2 GND
   - Should be > 1MΩ (isolated)
6. **Test current limiting**
   - Connect 10Ω load
   - Set current limit to 2A
   - Verify supply limits current

**Pass criteria:**
- ✅ Voltage within ±2% of setpoint
- ✅ Ripple < 200mV p-p
- ✅ Supplies are isolated (> 1MΩ)
- ✅ Current limiting works

### Test 1.2: Control Power Verification

**Purpose:** Verify 5V/3.3V power for microcontroller.

**Procedure:**

1. **Connect bench supply to control board**
2. **Set to 5V (or 3.3V depending on design)**
3. **Measure voltage at multiple points:**
   - MCU VDD pin
   - Gate driver supply
   - ADC reference
4. **Check for noise on oscilloscope**
   - Should be < 50mV ripple
5. **Verify current draw** (typically < 500mA without PWM)

**Pass criteria:**
- ✅ Voltage within ±5% of nominal
- ✅ Low noise (< 100mV p-p)
- ✅ Current draw reasonable (< 1A)

### Test 1.3: Microcontroller Boot Test

**Purpose:** Verify MCU operates correctly.

**Procedure:**

1. **Connect USB/UART to PC**
2. **Open serial terminal (115200 baud)**
3. **Power on control board**
4. **Observe boot messages:**
   ```
   5-Level Inverter v1.0
   Initializing...
   PWM: OK
   ADC: OK
   Safety: OK
   Ready.
   ```
5. **Check status LEDs** (if present)
6. **Test commands via UART** (if implemented)

**Pass criteria:**
- ✅ MCU boots successfully
- ✅ All initialization passes
- ✅ UART communication works

### Test 1.4: Gate Driver Supply Test

**Purpose:** Verify isolated 15V supplies for gate drivers.

**Procedure:**

1. **Measure each gate driver supply:**
   - Should be 15V ±0.5V
   - Low ripple (< 200mV)
2. **Verify isolation:**
   - Each gate driver should be isolated
   - Check with DMM (> 1MΩ between different drivers)
3. **Load test:**
   - Connect 100Ω resistor to gate driver output
   - Verify voltage remains stable

**Pass criteria:**
- ✅ All gate driver supplies at 15V ±0.5V
- ✅ Isolated from each other and from control
- ✅ Stable under load

### Test 1.5: Current Sensor Calibration

**Purpose:** Calibrate current sensors before use.

**Procedure:**

1. **Zero current test:**
   - No current flowing
   - Read ADC value
   - Should be near Vref/2 (e.g., 1.65V for 3.3V system)
2. **Known current test:**
   - Apply known DC current (e.g., 5A through precision resistor)
   - Measure sensor output
   - Calculate scaling factor
3. **Update software calibration constants**

**Pass criteria:**
- ✅ Zero reading within ±50mV of expected
- ✅ Linearity error < 2%
- ✅ Scaling factor documented

---

## Phase 2: Subsystem Testing

### Objective

Test functional blocks independently without high power.

**Duration:** 3-6 hours

### Test 2.1: PWM Generation (No Power Switches)

**Purpose:** Verify PWM signals before connecting to gates.

**Setup:**
- Disconnect gate driver inputs
- Connect scope to MCU PWM outputs

**Procedure:**

1. **Enable PWM in test mode (50% duty, 5kHz)**
2. **Measure on oscilloscope:**
   - Channel 1: PWM1_CH1 (S1)
   - Channel 2: PWM1_CH1N (S2)
   - Channel 3: PWM1_CH2 (S3)
   - Channel 4: PWM1_CH2N (S4)
3. **Verify:**
   - Frequency = 5kHz ±1%
   - Duty cycle = 50% ±2%
   - Complementary signals are inverted
   - Dead-time present (measure, should be ~1μs)
4. **Repeat for PWM2 (H-Bridge 2)**

**Measurements to record:**
- Actual frequency: _______ kHz
- Duty cycle: _______ %
- Dead-time: _______ μs
- Rise time: _______ ns
- Fall time: _______ ns

**Pass criteria:**
- ✅ Frequency within ±1% of 5kHz
- ✅ Dead-time between 0.8-1.2μs
- ✅ All 8 signals present and correct
- ✅ No shoot-through possible

### Test 2.2: Modulation Algorithm Test

**Purpose:** Verify modulation calculations produce correct duty cycles.

**Procedure:**

1. **Set modulation index to 50%**
2. **Run at 5Hz (slow, visible on scope)**
3. **Capture waveform:**
   - Should show sinusoidal variation of duty cycle
   - Duty varies from 0% to 100% following sine
4. **Test different MI values:**
   - 25%, 50%, 75%, 100%
   - Verify amplitude scales correctly
5. **Test frequency changes:**
   - 1Hz, 5Hz, 10Hz, 50Hz
   - Verify correct period

**Pass criteria:**
- ✅ Duty cycle follows sinusoidal pattern
- ✅ MI scaling correct
- ✅ Frequency accurate

### Test 2.3: Protection System Functional Test

**Purpose:** Verify all protection mechanisms before applying power.

**Procedure:**

1. **Simulate overcurrent:**
   - Inject false current reading via ADC
   - Verify PWM shuts down within 1 cycle
   - Check fault flag set
2. **Simulate overvoltage:**
   - Inject false voltage reading
   - Verify shutdown
3. **Test watchdog:**
   - Halt main loop
   - Verify watchdog reset occurs (< 1 second)
4. **Test E-Stop:**
   - Press emergency stop button
   - Verify immediate PWM shutdown
   - Verify requires manual reset

**Pass criteria:**
- ✅ All protection responses work
- ✅ Response time < 200μs for fast faults
- ✅ System enters safe state (all PWM OFF)
- ✅ Faults logged correctly

---

## Phase 3: Low-Power Integration

### Objective

First integration with power switches at reduced voltage.

**Duration:** 4-8 hours

### Test 3.1: Gate Driver Verification (12V Test)

**Purpose:** Verify gate drivers switch properly at safe voltage.

**Setup:**
- DC supplies set to 12V (reduced from 50V)
- Resistive load (100Ω, 50W)
- Current limit: 2A per supply

**⚠️ DANGER POINT:** This is first time connecting power! Double-check all connections.

**Procedure:**

1. **Pre-power checks:**
   - Verify all connections
   - Check polarity (measure with DMM)
   - Load connected
   - E-Stop accessible
2. **Apply 12V to DC1 (H-Bridge 1 only)**
   - Monitor current (should be minimal with PWM off)
3. **Enable PWM at 50% duty, low frequency (1Hz)**
4. **Observe on oscilloscope:**
   - Gate-source voltage of MOSFETs (should be 0V or 15V)
   - Switching node voltage (should switch between 0 and 12V)
   - Output current waveform
5. **Verify dead-time:**
   - Zoom in on transitions
   - Confirm both switches are OFF during dead-time
6. **Repeat for H-Bridge 2**

**Measurements:**
- Gate drive voltage: _______ V
- Switching node voltage: _______ V
- Dead-time verified: [ ] Yes [ ] No
- Any shoot-through observed: [ ] Yes [ ] No

**Pass criteria:**
- ✅ Clean gate drive signals (15V)
- ✅ Switches operate correctly
- ✅ No shoot-through detected
- ✅ Output voltage present at load

### Test 3.2: Both Bridges Operating (12V)

**Purpose:** Test full 5-level operation at safe voltage.

**Procedure:**

1. **Apply 12V to both DC supplies**
2. **Enable PWM with level-shifted modulation**
3. **Start with low MI (25%)**
4. **Observe output waveform:**
   - Should see multiple voltage levels
   - Levels: ±24V, ±12V, 0V
5. **Gradually increase MI to 100%**
6. **Capture waveform on scope:**
   - Save screenshot
   - Export data for analysis
7. **Monitor temperatures:**
   - Check MOSFETs, gate drivers
   - Should remain cool (< 40°C)

**Pass criteria:**
- ✅ All 5 voltage levels visible
- ✅ Clean transitions
- ✅ No oscillations or ringing
- ✅ Temperature remains low

### Test 3.3: Protection Verification Under Power

**Purpose:** Test protection systems with real power flowing.

**Procedure:**

1. **Test overcurrent protection:**
   - Reduce load resistance (creating overcurrent)
   - Verify shutdown occurs
   - Check response time on scope
2. **Test overvoltage protection:**
   - Increase DC supply above limit
   - Verify shutdown
3. **Test thermal protection:**
   - If possible, heat a MOSFET with heat gun
   - Verify shutdown at threshold

**Pass criteria:**
- ✅ All protections function correctly
- ✅ No damage to components
- ✅ System recovers after fault cleared

---

## Phase 4: Full-Power Testing

### Objective

Scale up to rated voltage (50V per bridge) and full power.

**Duration:** 2-4 hours

### Test 4.1: Rated Voltage, No Load

**Purpose:** Verify operation at 100V output without load.

**⚠️ HIGH VOLTAGE - Extra caution required!**

**Setup:**
- DC supplies set to 50V
- Current limit: 5A initially
- NO load (open circuit test, brief only)

**Procedure:**

1. **Final safety check:**
   - Insulated enclosure closed
   - No exposed conductors
   - E-Stop ready
   - Safety glasses on
2. **Gradually increase DC1 to 50V**
   - Monitor for any issues
   - Check current draw (should be minimal)
3. **Increase DC2 to 50V**
4. **Enable PWM (25% MI, 50Hz)**
5. **Measure output voltage on scope:**
   - Peak should be ≈ 35V (25% of 141V peak)
   - RMS ≈ 25V
6. **Increase to 50% MI**
   - Peak ≈ 71V
   - RMS ≈ 50V
7. **Brief test at 100% MI**
   - Peak ≈ 141V
   - RMS ≈ 100V
   - **Keep this brief (< 10 seconds) with no load!**

**Pass criteria:**
- ✅ Output voltage matches expected
- ✅ Waveform clean
- ✅ No protection trips
- ✅ No abnormal sounds or smells

### Test 4.2: Full Power with Resistive Load

**Purpose:** Test at rated power (500W).

**Setup:**
- Load: 20Ω, 500W resistor (or parallel 100W bulbs)
- Expected current: ~5A RMS @ 100V

**Procedure:**

1. **Connect load**
2. **Start with 50% MI (reduced power)**
3. **Increase MI gradually to 100%**
4. **Monitor:**
   - Output voltage (scope)
   - Output current (current probe)
   - DC bus voltages (should remain stable)
   - Temperatures (MOSFETs, inductors)
5. **Run for 10 minutes**
6. **Check thermal performance:**
   - MOSFETs should be < 70°C
   - Use thermal camera if available
7. **Capture waveforms:**
   - Voltage and current on same scope
   - Calculate power factor
   - Export for THD analysis

**Pass criteria:**
- ✅ Full 500W operation achieved
- ✅ Voltage and current stable
- ✅ Thermal performance acceptable
- ✅ No protection trips
- ✅ Waveform quality good

### Test 4.3: Dynamic Load Test

**Purpose:** Test response to load changes.

**Procedure:**

1. **Start with light load (10% power)**
2. **Suddenly apply full load**
3. **Observe on scope:**
   - Voltage droop
   - Current rise
   - Recovery time
4. **Remove load suddenly**
5. **Observe voltage spike (should be limited)**

**Pass criteria:**
- ✅ System remains stable
- ✅ No excessive overshoot
- ✅ Recovery < 2 cycles

---

## Phase 5: Performance Validation

### Objective

Characterize performance and validate against specifications.

**Duration:** 4-8 hours

### Test 5.1: THD Measurement

**Purpose:** Measure Total Harmonic Distortion.

**Equipment:** Oscilloscope with FFT or power analyzer

**Procedure:**

1. **Set up at rated power (100V RMS, 5A)**
2. **Capture voltage waveform:**
   - 10 cycles minimum
   - High resolution (1 MS/s+)
3. **Perform FFT analysis:**
   - Identify fundamental (50Hz)
   - Identify harmonics (100Hz, 150Hz, ...)
4. **Calculate THD:**
   ```
   THD = sqrt(sum of harmonic powers) / fundamental × 100%
   ```
5. **Use Python script from 06-tools:**
   ```bash
   python waveform_analyzer.py captured_data.csv
   ```

**Target:** THD < 5%

**If THD too high:**
- Check output filter
- Verify modulation algorithm
- Check for distortion in power stage

### Test 5.2: Efficiency Measurement

**Purpose:** Measure power conversion efficiency.

**Procedure:**

1. **Measure input power:**
   - DC voltage: V_dc1, V_dc2
   - DC current: I_dc1, I_dc2
   - P_in = V_dc1 × I_dc1 + V_dc2 × I_dc2
2. **Measure output power:**
   - AC voltage RMS: V_ac
   - AC current RMS: I_ac
   - Power factor: PF (should be ~1.0 for resistive load)
   - P_out = V_ac × I_ac × PF
3. **Calculate efficiency:**
   ```
   η = (P_out / P_in) × 100%
   ```
4. **Test at various loads:**
   - 10%, 25%, 50%, 75%, 100%
   - Plot efficiency curve

**Target:** Efficiency > 90% at rated load

**Typical results:**
- Light load (10%): 85-90%
- Rated load (100%): 92-95%

### Test 5.3: Frequency Response

**Purpose:** Verify operation at different output frequencies.

**Procedure:**

1. **Test at:**
   - 40Hz
   - 45Hz
   - 50Hz (nominal)
   - 55Hz
   - 60Hz
2. **For each frequency:**
   - Measure output voltage accuracy
   - Check THD
   - Verify stable operation

**Pass criteria:**
- ✅ Operates correctly from 40-60Hz
- ✅ Voltage accuracy within ±2%
- ✅ THD remains < 5%

### Test 5.4: Transient Response (with PR Controller)

**Purpose:** Test closed-loop current control performance.

**Procedure:**

1. **Enable Test Mode 4 (PR controller)**
2. **Set current reference to 5A @ 50Hz**
3. **Measure actual current waveform**
4. **Calculate error:**
   - Steady-state error
   - Settling time
5. **Step response:**
   - Change reference from 3A to 5A
   - Measure overshoot and settling time

**Target:**
- Steady-state error: < 1%
- Settling time: < 40ms (2 cycles)
- Overshoot: < 10%

### Test 5.5: Long-Duration Reliability Test

**Purpose:** Verify reliable operation over extended period.

**Procedure:**

1. **Set to 75% power (safer for long test)**
2. **Run continuously for 2 hours minimum**
3. **Monitor every 15 minutes:**
   - Temperature
   - Voltage stability
   - Current stability
   - Any alarms/faults
4. **Log data continuously if possible**

**Pass criteria:**
- ✅ No thermal runaway
- ✅ No degradation in performance
- ✅ No protection trips
- ✅ All parameters stable

---

## Documentation and Data Collection

### Test Log Template

**For each test:**

```
Test ID: ________
Date: ________
Operator: ________
Equipment S/N: ________

Test Conditions:
- DC Voltage: _______ V
- Load: _______ Ω
- Modulation Index: _______ %
- Output Frequency: _______ Hz

Results:
- Output Voltage RMS: _______ V
- Output Current RMS: _______ A
- Input Power: _______ W
- Output Power: _______ W
- Efficiency: _______ %
- THD: _______ %
- Max Temperature: _______ °C

Pass/Fail: _______
Notes: _______________________________________
```

### Required Captures

**Save for each major test:**

1. **Oscilloscope screenshots:**
   - Voltage waveform (full scale)
   - Voltage waveform (zoomed on levels)
   - Voltage and current together
   - FFT spectrum

2. **CSV data exports:**
   - For offline analysis
   - Import into Python tools
   - Compare with MATLAB simulation

3. **Photos:**
   - Test setup
   - Thermal images (if available)
   - Any anomalies

### Performance Summary Report

**After all testing:**

```markdown
# 5-Level Inverter Test Report

## Unit Information
- Serial Number:
- Date of Test:
- Test Engineer:

## Performance Summary

| Parameter | Specification | Measured | Pass/Fail |
|-----------|---------------|----------|-----------|
| Output Voltage | 100V RMS ±2% | ___ V | ___ |
| Output Power | 500W | ___ W | ___ |
| THD | < 5% | ___ % | ___ |
| Efficiency | > 90% | ___ % | ___ |
| Frequency Accuracy | ±0.1 Hz | ___ Hz | ___ |

## Test Results
- All phases completed: [ ] Yes [ ] No
- Issues encountered: ___
- Remedial actions: ___

## Final Disposition
- [ ] PASS - Ready for operation
- [ ] FAIL - Rework required
- [ ] CONDITIONAL - Needs monitoring

Signature: ____________ Date: ________
```

---

## Troubleshooting Guide

### Issue: No PWM Output

**Symptoms:** Scope shows flat line

**Check:**
- [ ] Control power present (5V/3.3V)
- [ ] MCU running (check UART output)
- [ ] PWM enabled in software
- [ ] Correct scope channel/probe
- [ ] Timer configuration correct

**Solution:** Verify initialization sequence, check fuses

### Issue: Shoot-Through / Overcurrent Trip

**Symptoms:** Immediate shutdown, high current spike

**Check:**
- [ ] Dead-time configured correctly
- [ ] Gate drive signals complementary
- [ ] No false triggering
- [ ] MOSFETs not damaged

**Solution:** Increase dead-time, check gate driver

### Issue: Distorted Output Waveform

**Symptoms:** THD > 10%, visible distortion

**Check:**
- [ ] Carrier frequency correct (5kHz)
- [ ] Modulation algorithm implementation
- [ ] DC bus voltages equal
- [ ] Output filter values correct
- [ ] Load appropriate

**Solution:** Verify modulation code, check filter

### Issue: Overheating

**Symptoms:** Temperature > 70°C, thermal shutdown

**Check:**
- [ ] Heatsink properly attached
- [ ] Thermal paste applied
- [ ] Adequate airflow
- [ ] Switching frequency not too high
- [ ] Dead-time not excessive (more loss)

**Solution:** Improve cooling, reduce power

### Issue: Oscillations / Ringing

**Symptoms:** High-frequency oscillations on waveform

**Check:**
- [ ] Parasitic inductance in layout
- [ ] Snubber circuits present
- [ ] Gate resistors installed
- [ ] Ground loop issues

**Solution:** Add snubbers, improve layout

### Issue: Voltage Imbalance

**Symptoms:** DC bus voltages unequal, asymmetric output

**Check:**
- [ ] Supply voltage equality
- [ ] Load on each bridge
- [ ] Component mismatches

**Solution:** Balance supplies, check symmetry

---

## Conclusion

**Successful completion of all test phases indicates:**
- ✅ Hardware is correctly built
- ✅ Protection systems functional
- ✅ Performance meets specifications
- ✅ Unit is safe to operate
- ✅ Ready for advanced testing or deployment

**Remember:**
- Document everything
- Never skip safety checks
- When in doubt, power down and investigate
- Testing is iterative - expect to find issues

**Good luck with your testing!**

---

**Document End**

*For questions about specific tests, consult the theory documents or project maintainers.*
