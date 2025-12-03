# Breadboard Testing and Prototyping Guide

**Project:** 5-Level Cascaded H-Bridge Inverter
**Power Rating:** 707W, 70.7V RMS / 100V Peak AC, 10A RMS
**Document:** Breadboard Prototype Assembly and Testing
**Date:** 2025-12-03
**Safety Level:** ⚠️ **HIGH VOLTAGE & HIGH CURRENT - READ SAFETY SECTION FIRST**

---

## Table of Contents

1. [Safety Precautions](#safety-precautions)
2. [Required Equipment](#required-equipment)
3. [Stage 1: Gate Driver Testing (Low Voltage)](#stage-1-gate-driver-testing-low-voltage)
4. [Stage 2: Single Switch Testing](#stage-2-single-switch-testing)
5. [Stage 3: Half-Bridge Testing](#stage-3-half-bridge-testing)
6. [Stage 4: Full H-Bridge Testing](#stage-4-full-h-bridge-testing)
7. [Stage 5: Dual H-Bridge (5-Level) Testing](#stage-5-dual-h-bridge-5-level-testing)
8. [Stage 6: Sensing Circuit Testing](#stage-6-sensing-circuit-testing)
9. [Troubleshooting Guide](#troubleshooting-guide)

---

## Safety Precautions

### ⚠️ DANGER - HIGH VOLTAGE & HIGH CURRENT

This project involves potentially **LETHAL VOLTAGES AND CURRENTS** (up to 100V peak AC, 10A RMS). Follow these rules:

### Mandatory Safety Rules

1. **NEVER** work on live circuits
2. **ALWAYS** discharge capacitors before touching
3. **USE** isolated power supplies only
4. **WEAR** safety glasses
5. **KEEP** one hand in pocket when probing (prevent across-chest shock)
6. **USE** insulated tools
7. **WORK** with a buddy (someone nearby in case of emergency)
8. **HAVE** fire extinguisher nearby
9. **KNOW** where circuit breaker/emergency stop is
10. **START** at low voltage (12V) and increase gradually

### Capacitor Discharge Procedure

**Before touching ANY component:**

1. Turn OFF all power
2. Wait 30 seconds
3. Short DC bus with insulated 10kΩ resistor (2W minimum)
4. Measure voltage with multimeter - must be < 5V
5. Only then touch components

### First Aid

- **Electric shock:** Call emergency services immediately, perform CPR if needed
- **Burns:** Cool with water, seek medical attention
- **Fire:** Use CO2 extinguisher (NOT water on electrical fires)

---

## Required Equipment

### Test Equipment

| Equipment | Specifications | Purpose |
|-----------|----------------|---------|
| **Oscilloscope** | 2+ channels, 100 MHz | PWM waveform verification |
| **Digital Multimeter** | True RMS, 600V rating | Voltage/current measurement |
| **Function Generator** | 0-20 kHz, 5V output | PWM signal generation |
| **DC Power Supply** | 0-50V, 10A+, isolated | DC bus supply (10A continuous) |
| **Bench Power Supply** | 5V/15V, 2A | Logic and gate driver supply |
| **Current Probe** | DC-20 kHz, 15A+ | Load current measurement (14A peak) |
| **Resistive Load** | 10Ω, 200W minimum | Safe initial testing (700W rated) |

### Breadboard Supplies

| Item | Quantity | Notes |
|------|----------|-------|
| **Solderless Breadboard** | 3× large (830 points) | High-quality with good contacts |
| **Jumper Wire Kit** | 1 kit | Various lengths, 22 AWG solid |
| **Alligator Clips** | 10+ pairs | Insulated, various colors |
| **Banana Plug Cables** | 6+ | For power connections |
| **Heat Shrink Tubing** | Assorted sizes | Insulation |
| **Wire Strippers** | 1 | 20-30 AWG |
| **Side Cutters** | 1 | For trimming leads |

### Safety Equipment

| Item | Purpose |
|------|---------|
| **Safety Glasses** | Protect from arc flash |
| **Rubber Gloves** | Electrical insulation (1000V rated) |
| **Insulated Tools** | Prevent shorts |
| **Fire Extinguisher** | Class C (electrical) |
| **First Aid Kit** | Emergency response |

---

## Stage 1: Gate Driver Testing (Low Voltage)

### Objective
Verify IR2110 gate driver operation with **NO high voltage** and **NO IGBTs**.

### Circuit Diagram

```
         +15V
          │
     ┌────┴────┐
     │  100µF  │ VCC bypass
     └────┬────┘
          │
     ┌────┴──────────┐
     │    IR2110     │
     │               │
PWM_H ───►HIN    HO──┼──► Scope CH1 (High-side output)
     │               │
PWM_L ───►LIN    LO──┼──► Scope CH2 (Low-side output)
     │               │
     │    VB ◄───────┤ +15V (for testing, bootstrap later)
     │    VS ────────┤ GND (for testing, floating later)
     │   COM ────────┤ GND
     └───────────────┘
          │
         GND
```

### Step-by-Step Procedure

#### 1.1 Build Power Supply Section

**On Breadboard 1:**

1. Insert IR2110 IC (DIP package) - note pin 1 orientation
2. Connect pin 1 (VCC) to +15V rail
3. Connect pin 9 (COM) to GND rail
4. Add 100µF electrolytic between VCC (pin 1) and GND (pin 9)
   - **Polarity:** Negative stripe to GND
5. Add 100nF ceramic between VCC and GND (parallel to electrolytic)

**Verification:**
- Measure VCC to GND: Should be 15V ±0.5V
- Check electrolytic polarity (reverse = explosion risk!)

#### 1.2 Add Bootstrap Circuit (Temporary Direct Connection)

**For testing only** (we'll use proper bootstrap later):

6. Connect pin 5 (VB) to +15V rail (directly)
7. Connect pin 7 (VS) to GND rail (temporarily)

**⚠️ Note:** In final circuit, VB-VS must float! This is test configuration only.

#### 1.3 Connect PWM Inputs

8. Connect function generator CH1 to pin 10 (HIN)
   - Through 100Ω resistor (protection)
9. Connect function generator CH2 to pin 12 (LIN)
   - Through 100Ω resistor (protection)
10. Connect function generator GND to breadboard GND

**Function Generator Settings:**
- Frequency: 1 kHz (slow for easy observation)
- Amplitude: 5V
- Duty cycle: 25% (safe, non-overlapping)
- Offset: 0V (0-5V square wave)
- CH1 and CH2: **NOT simultaneous** (add dead-time manually)

#### 1.4 Connect Oscilloscope

11. Scope CH1 → IR2110 pin 7 (HO) - High-side output
12. Scope CH2 → IR2110 pin 1 (LO) - Low-side output
13. Scope GND → Breadboard GND

**Scope Settings:**
- Timebase: 500 µs/div (to see 1 kHz waveform)
- CH1/CH2: 5V/div
- Trigger: CH1, rising edge

#### 1.5 Power-On Test

14. **Double-check all connections** (VCC, GND, polarity)
15. Apply +15V power
16. **Immediately check IC temperature** (should be cool/warm, NOT hot)
   - If hot: Power OFF, find short circuit

#### 1.6 Apply PWM Signals and Verify

17. Start function generator with:
    - **First:** Only CH1 active (HIN), CH2 OFF
    - Observe HO output on scope CH1
    - Should see clean 0-15V square wave matching input

18. **Then:** Only CH2 active (LIN), CH1 OFF
    - Observe LO output on scope CH2
    - Should see clean 0-15V square wave

19. **Finally:** Both channels active with dead-time
    - HIN: 25% duty, 1 kHz
    - LIN: 25% duty, 1 kHz, **delayed by 500 µs** (180° phase shift)
    - Observe both HO and LO
    - Should see **non-overlapping** pulses

**Expected Waveforms:**

```
HIN:  ____┌─────┐_________________┌─────┐____
          │     │                 │     │

HO:   ____┌─────┐_________________┌─────┐____  (15V high)

LIN:  _________________┌─────┐_________________
                       │     │

LO:   _________________┌─────┐_________________  (15V high)

Dead-time: ______┘     └_____┌     └______
                   ^         ^
                   No overlap! Safe operation
```

### 1.7 Measurements and Verification

**Use DMM and scope to verify:**

| Parameter | Expected Value | Measured | Pass/Fail |
|-----------|---------------|----------|-----------|
| VCC voltage | 15V ±0.5V | _____ V | ☐ |
| HO high level | 14-15V | _____ V | ☐ |
| HO low level | < 0.5V | _____ V | ☐ |
| LO high level | 14-15V | _____ V | ☐ |
| LO low level | < 0.5V | _____ V | ☐ |
| HIN-HO delay | < 500 ns | _____ ns | ☐ |
| LIN-LO delay | < 500 ns | _____ ns | ☐ |
| IC temperature | < 50°C | _____ °C | ☐ |
| Supply current | < 20 mA | _____ mA | ☐ |

**If all tests pass: Stage 1 COMPLETE ✓**

---

## Stage 2: Single Switch Testing

### Objective
Test ONE IGBT with gate driver at **LOW voltage (12V DC bus)**.

### Safety Note
Even 12V can cause **large currents** through IGBTs. Use current-limited supply (max 2A).

### Circuit Diagram

```
        +12V (DC bus, current-limited to 2A)
          │
          ├──── 1000µF capacitor to GND
          │
      ┌───▼───┐  Collector
      │       │
      │  Q1   │  IGBT (IKW15N120H3)
      │ IGBT  │
      │       │
      └───┬───┘  Emitter
          │
          ├──── 10Ω shunt resistor
          │
         GND

Gate Drive:
      IR2110 HO ───┬─── 10Ω gate resistor ──► Q1 Gate
                   │
                  10k
                   │
                  GND (Q1 Emitter)
```

### Step-by-Step Procedure

#### 2.1 Build IGBT Circuit on Breadboard 2

**IMPORTANT:** Keep gate driver circuit (Breadboard 1) separate from power circuit (Breadboard 2) initially.

1. Insert IGBT Q1 into breadboard
   - **Identify pins:** Use datasheet (Collector, Gate, Emitter)
   - Heatsink not needed for 12V/2A testing

2. Add 10Ω gate resistor between IR2110 HO and IGBT gate
   - **Keep lead short** (< 5cm) to reduce inductance

3. Add 10kΩ gate-emitter resistor
   - Between gate and emitter of Q1

4. Add RC snubber across collector-emitter
   - 47Ω (2W) in series with 100nF ceramic
   - **Short leads** for effectiveness

5. Add 10Ω, 5W shunt resistor in emitter (for current measurement)

#### 2.2 Build DC Bus

6. Connect +12V supply (current limit: 2A) to breadboard +rail
7. Add 1000µF, 25V electrolytic capacitor from +12V to GND
   - **Check polarity!**
8. Add 4× 1µF ceramic capacitors (parallel) near IGBT collector

#### 2.3 Connect Gate Driver to IGBT

9. Connect IR2110 HO (Breadboard 1) to gate resistor (Breadboard 2)
   - Use short, direct wire
10. Connect IR2110 COM to IGBT emitter (common ground)

#### 2.4 Add Instrumentation

11. **Oscilloscope CH1:** IGBT collector (measure VCE)
    - Use 100:1 probe or differential probe
12. **Oscilloscope CH2:** Gate signal (after 10Ω resistor)
13. **Oscilloscope CH3:** Emitter shunt resistor (measure current)
    - V_shunt = I_IGBT × 10Ω

#### 2.5 Power-On Test (LOW POWER)

14. Set function generator to **VERY LOW duty cycle** (5%)
    - Frequency: 1 kHz
    - Amplitude: 5V
    - Pulse width: 50 µs

15. **Pre-flight checks:**
    - ☐ DC supply current limit set to 2A
    - ☐ DC supply voltage set to 12V
    - ☐ All connections secure
    - ☐ No short circuits (measure resistance)

16. **Apply gate driver power (+15V) first**
17. **Apply DC bus power (+12V) second**
18. **Enable PWM signal**

#### 2.6 Observe Waveforms

**Expected behavior:**

```
Gate signal (CH2):
    0V ────┌────────┐─────────┌──
           │ 50µs   │         │
          15V      0V        15V

Collector voltage (CH1):
   12V ────┐        └─────────┐
           │                  │
           │  VCE(sat)~2V    12V

Emitter current (CH3):
    0A ────┐        └─────────┐
           │                  │
         ~1A                  0A
```

**Verify:**
- Gate voltage swings 0-15V cleanly
- Collector voltage drops when gate high (IGBT conducting)
- VCE(sat) approximately 2V (varies with current)
- Current flows through shunt when IGBT on

#### 2.7 Increase Duty Cycle Gradually

19. Increase duty cycle in steps: 5% → 10% → 25% → 50%
20. **At each step:**
    - Monitor IGBT case temperature (should be < 60°C)
    - Measure VCE(sat) (should be < 3V @ 2A)
    - Verify clean switching (no oscillation)

#### 2.8 Measurements

| Parameter | Expected | Measured | Pass/Fail |
|-----------|----------|----------|-----------|
| Gate high voltage | 14-15V | _____ V | ☐ |
| Gate low voltage | < 0.5V | _____ V | ☐ |
| VCE(sat) @ 2A | < 3V | _____ V | ☐ |
| Collector current | < 2A | _____ A | ☐ |
| IGBT temperature | < 60°C | _____ °C | ☐ |
| Turn-on time | < 200ns | _____ ns | ☐ |
| Turn-off time | < 500ns | _____ ns | ☐ |

**If all tests pass: Stage 2 COMPLETE ✓**

---

## Stage 3: Half-Bridge Testing

### Objective
Test high-side + low-side switches with bootstrap supply at **12V DC bus**.

### Circuit Diagram

```
            +12V DC Bus
                │
                ├──── 1000µF + 4×1µF caps
                │
           ┌────┴────┐  Q1 High-side
           │  IGBT   │
           │   Q1    │
           └────┬────┘
                │ Midpoint (OUTPUT)
           ┌────┴────┐  Q2 Low-side
           │  IGBT   │
           │   Q2    │
           └────┬────┘
                │
               GND

Gate Driver:
    IR2110 with PROPER bootstrap circuit
    (VB - VS floating supply)
```

### Critical Addition: Bootstrap Circuit

**This is where it gets tricky!**

#### 3.1 Build Bootstrap Circuit

1. **Remove** temporary VB connection to +15V (from Stage 1)
2. **Add** bootstrap diode:
   - Anode to +15V rail
   - Cathode to VB (pin 5)
   - Use UF4007 (fast recovery)
3. **Add** bootstrap capacitor:
   - 10µF ceramic, 25V between VB (pin 5) and VS (pin 7)
   - **Polarity matters** if using electrolytic (+ to VB)
4. **Connect VS (pin 7) to Q1 emitter** (high-side IGBT emitter)
   - This is now the "floating" reference

**How Bootstrap Works:**

```
When Q2 (low-side) is ON:
    VS pulled to GND → VB charges through diode from +15V
    C_bootstrap charges to ~15V

When Q1 (high-side) is ON:
    VS at +12V (Q2 off, midpoint high)
    VB at +12V + 15V = +27V (floating above VS)
    This provides 15V gate drive for Q1
```

#### 3.2 Add Both IGBTs

5. Insert Q1 (high-side) into breadboard:
   - Collector to +12V rail
   - Emitter to midpoint
   - Gate through 10Ω resistor to IR2110 HO

6. Insert Q2 (low-side) into breadboard:
   - Collector to midpoint (same as Q1 emitter)
   - Emitter to GND
   - Gate through 10Ω resistor to IR2110 LO

7. Add gate-emitter resistors (10kΩ) for both IGBTs

8. Add snubbers (47Ω + 100nF) across BOTH IGBTs

#### 3.3 Dead-Time Configuration

**CRITICAL:** High-side and low-side must **NEVER** be on simultaneously (shoot-through).

Configure function generator for complementary PWM with dead-time:

**Option A: Use MCU/microcontroller**
- STM32 or Arduino with complementary PWM library
- Set dead-time to 1 µs minimum

**Option B: Manual complementary signals**
- CH1: High-side PWM (HIN)
- CH2: Inverted, with 2 µs delay (LIN)

**Waveforms:**

```
HIN:  ┌────┐____┌────┐____
      │    │    │    │

      Dead-time
      ↓  ↓
LIN:  ____┌────┐____┌────┐
          │    │    │    │

No overlap → Safe!
```

#### 3.4 Power-On Sequence

9. **Apply +15V to gate driver VCC**
10. **Apply +12V to DC bus**
11. **Start PWM with 25% duty cycle, 10 kHz**
12. **Observe midpoint voltage:**
    - Should switch between 0V (Q2 on) and +12V (Q1 on)
    - Measure with scope

#### 3.5 Verify Bootstrap Operation

13. **Measure VB-VS voltage while running:**
    - Should be 14-15V (constant during operation)
    - If VB-VS droops below 12V: increase C_bootstrap or check diode

14. **Scope both gate signals referenced to their emitters:**
    - **Q1 gate-emitter:** Should be 0-15V square wave
    - **Q2 gate-emitter:** Should be 0-15V square wave
    - Use differential probes or isolated channels

#### 3.6 Load Testing

15. **Add resistive load** (25Ω, 50W) from midpoint to GND
16. **Observe:**
    - Midpoint voltage under load (may droop slightly)
    - IGBT temperatures (should be < 60°C)
    - Collector currents (I = V/R = 12V/25Ω = 0.48A)

### 3.7 Measurements

| Parameter | Expected | Measured | Pass/Fail |
|-----------|----------|----------|-----------|
| Midpoint high level | ~12V | _____ V | ☐ |
| Midpoint low level | < 0.5V | _____ V | ☐ |
| VB-VS voltage | 14-15V | _____ V | ☐ |
| Q1 VGE (on) | 14-15V | _____ V | ☐ |
| Q2 VGE (on) | 14-15V | _____ V | ☐ |
| Dead-time | > 1 µs | _____ µs | ☐ |
| Load current | ~0.5A | _____ A | ☐ |
| Q1 temperature | < 60°C | _____ °C | ☐ |
| Q2 temperature | < 60°C | _____ °C | ☐ |

**If all tests pass: Stage 3 COMPLETE ✓**

---

## Stage 4: Full H-Bridge Testing

### Objective
Build and test complete single H-bridge with 4 switches at **12V DC bus**.

### Circuit Expansion

Add second leg (Q3, Q4) with second IR2110 driver, following same procedure as Stage 3.

**H-Bridge Configuration:**

```
       +12V
         │
    ┌────┴────┐
    │   Q1    │    │   Q3    │
    └────┬────┘    └────┬────┘
         │              │
      OUT1           OUT2
         │              │
    ┌────┴────┐    ┌────┴────┐
    │   Q2    │    │   Q4    │
    └────┬────┘    └────┬────┘
         │              │
        GND            GND
```

**Resistive Load:** Connect between OUT1 and OUT2 (25Ω, 100W)

### PWM Patterns for 3-Level Output

| Q1 | Q2 | Q3 | Q4 | Output (OUT1 - OUT2) |
|----|----|----|----|----------------------|
| ON | OFF | OFF | ON | +12V |
| OFF | ON | ON | OFF | -12V |
| ON | OFF | ON | OFF | 0V (freewheel) |
| OFF | ON | OFF | ON | 0V (freewheel) |

**⚠️ Never:**
- Q1 + Q2 ON simultaneously (leg 1 shoot-through)
- Q3 + Q4 ON simultaneously (leg 2 shoot-through)

### Test Procedure

1. Start with DC output (all switches off)
2. Test +12V state (Q1 + Q4 on)
3. Test -12V state (Q2 + Q3 on)
4. Test 0V state (Q1 + Q3 on OR Q2 + Q4 on)
5. Generate AC by alternating states at 50 Hz

**Expected waveform (50 Hz, 3-level):**

```
V_out:
 +12V  ────┐    ┌────┐    ┌────
           │    │    │    │
   0V  ────┼────┼    ┼────┼
           │    │    │    │
 -12V  ────┘    └────┘    └────

       10ms period (50 Hz)
```

---

## Stage 5: Dual H-Bridge (5-Level) Testing

### Objective
Combine two H-bridges to generate 5-level output waveform.

### Configuration

**DC Source 1:** +12V → H-Bridge 1 (Q1-Q4)
**DC Source 2:** +12V → H-Bridge 2 (Q5-Q8)
**Load:** Connect in series: H-Bridge1_OUT — LOAD — H-Bridge2_OUT

### 5-Level Output States

| H-Bridge 1 | H-Bridge 2 | Total Output |
|------------|------------|--------------|
| +12V | +12V | +24V |
| +12V | 0V | +12V |
| 0V | 0V | 0V |
| 0V | -12V | -12V |
| -12V | -12V | -24V |

**Test at 50 Hz to generate 5-level AC:**

```
V_out:
 +24V  ─┐  ┌─┐  ┌─
        │  │ │  │
 +12V  ─┼──┼─┼──┼─
        │  │ │  │
   0V  ─┼──┼─┼──┼─
        │  │ │  │
 -12V  ─┼──┼─┼──┼─
        │  │ │  │
 -24V  ─┘  └─┘  └─

    5 distinct levels
```

---

## Stage 6: Sensing Circuit Testing

### Current Sensor Testing (ACS724)

1. **Build circuit** as per schematic
2. **Apply 5V** to VCC
3. **With no current:** Verify output = 2.5V ±0.1V
4. **Apply known current** (use precision shunt):
   - +5A → Vout should be ~2.83V (2.5V + 5A × 0.0667V/A)
   - -5A → Vout should be ~2.17V
5. **Verify linearity** across range
6. **Check bandwidth:** Apply 1 kHz square wave current, verify tracking

### Voltage Sensor Testing (AMC1301)

1. **Build voltage divider + AMC1301**
2. **Apply 5V to both VDD1 and VDD2**
3. **Apply known input voltage** (use precision power supply):
   - 10V input → Vout = 10V × (1k/197k) × 8.2 = 0.416V
   - 50V input → Vout = 2.08V
4. **Verify isolation:** Ground one side, measure leakage (should be pA level)
5. **Check frequency response:** Apply 1 kHz sine, verify gain and phase

---

## Troubleshooting Guide

### Problem: IR2110 gets hot immediately

**Causes:**
- VCC or VB shorted to GND
- Wrong polarity on bypass capacitors
- COM not connected to GND

**Solution:**
- Power off immediately
- Check all connections with multimeter (power off)
- Verify capacitor polarity
- Replace IC if damaged

### Problem: IGBT won't turn on (VCE stays high)

**Causes:**
- Gate resistor too high or missing
- Gate-emitter shorted (0Ω)
- Dead IGBT
- Insufficient gate voltage (VGE < 10V)

**Solution:**
- Measure VGE with scope (should be 14-15V when on)
- Check gate resistor value (should be 10Ω, not 10kΩ!)
- Test IGBT with multimeter diode mode

### Problem: Bootstrap voltage (VB-VS) droops

**Causes:**
- C_bootstrap too small
- Bootstrap diode wrong direction or too slow
- Duty cycle too high (> 90%)
- Leakage in IR2110

**Solution:**
- Increase C_bootstrap to 22µF
- Use faster diode (UF4007 or better)
- Ensure low-side turns on regularly to recharge bootstrap

### Problem: Shoot-through (both IGBTs on simultaneously)

**Symptoms:**
- Large current spike
- IGBTs get very hot
- Blown fuse

**Causes:**
- Insufficient dead-time
- Gate resistor too small (fast switching)
- Miller effect (dv/dt coupling)

**Solution:**
- Increase dead-time to 2µs
- Add 10kΩ gate-emitter resistors
- Use larger gate resistor (15-22Ω)

---

**CONTINUE TO:** PCB-DESIGN.md for permanent implementation
**SEE ALSO:** POWER-STAGE-COMPLETE.md for complete schematics
