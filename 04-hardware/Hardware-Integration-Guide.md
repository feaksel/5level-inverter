# Hardware Integration Guide

**Document Type:** Assembly and Integration Guide
**Project:** 5-Level Cascaded H-Bridge Multilevel Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 2.0
**Status:** Validated Design - TLP250 Configuration

---

## ⚠️ SAFETY WARNING

This project involves **POTENTIALLY LETHAL VOLTAGES** (up to 150V AC, 50V DC).

**Before proceeding:**
- Read and understand `../../07-docs/03-Safety-and-Protection-Guide.md`
- Ensure you have appropriate training and experience
- Use isolated power supplies and safety equipment
- Never work on live circuits
- Have a fire extinguisher readily available
- Work with a partner when dealing with high voltage

**If you are unsure about any step, STOP and seek expert assistance.**

---

## Table of Contents

1. [Overview](#overview)
2. [Required Tools and Equipment](#required-tools-and-equipment)
3. [Pre-Assembly Preparation](#pre-assembly-preparation)
4. [PCB Assembly](#pcb-assembly)
5. [Power Supply Integration](#power-supply-integration)
6. [Microcontroller Integration](#microcontroller-integration)
7. [Enclosure Assembly](#enclosure-assembly)
8. [System Wiring](#system-wiring)
9. [Pre-Power Testing](#pre-power-testing)
10. [Initial Power-Up](#initial-power-up)
11. [Troubleshooting](#troubleshooting)

---

## Overview

### Integration Stages

The hardware integration follows a **progressive, safe approach**:

```
Stage 1: PCB Assembly (1-2 days)
   ↓
Stage 2: Power Supply Integration (2-4 hours)
   ↓
Stage 3: Microcontroller Integration (1-2 hours)
   ↓
Stage 4: Enclosure Assembly (2-3 hours)
   ↓
Stage 5: System Wiring (2-4 hours)
   ↓
Stage 6: Pre-Power Testing (1-2 hours)
   ↓
Stage 7: Initial Power-Up (2-4 hours)
   ↓
Stage 8: Full System Testing (refer to separate testing doc)
```

**Total Estimated Time:** 2-3 days for first build (experienced builder)
**For beginners:** Allow 1 week with careful verification at each step

---

## Required Tools and Equipment

### Essential Tools

**Soldering:**
- [ ] Temperature-controlled soldering iron (60W, adjustable temp)
- [ ] Solder (60/40 or lead-free, 0.8mm diameter)
- [ ] Solder wick (for desoldering)
- [ ] Flux pen (rosin-based)
- [ ] Tweezers (fine-tip, ESD-safe)
- [ ] Magnifying glass or microscope (for SMD inspection)

**Mechanical:**
- [ ] Screwdrivers (Phillips #1, #2; Flathead)
- [ ] Hex keys (M3, M4)
- [ ] Wire strippers (18-24 AWG)
- [ ] Wire cutters (flush-cut)
- [ ] Pliers (needle-nose)
- [ ] Crimping tool (for terminals)

**Measurement:**
- [ ] Digital multimeter (DMM) with continuity test
- [ ] Oscilloscope (2-channel, 50 MHz minimum) - **CRITICAL**
- [ ] Isolated voltage probes (for high voltage measurements)
- [ ] Bench power supply (0-60V, 0-10A, current limiting)
- [ ] Function generator (optional, for testing PWM)

**Safety:**
- [ ] Safety glasses (ANSI Z87.1 rated)
- [ ] ESD wrist strap
- [ ] Insulated gloves (rated for electrical work)
- [ ] Fire extinguisher (Class C electrical)

**Consumables:**
- [ ] Thermal paste (Arctic MX-4 or equivalent)
- [ ] Heat shrink tubing (assorted sizes)
- [ ] Zip ties (for cable management)
- [ ] Wire (18 AWG silicone, red/black)
- [ ] Isopropyl alcohol (for cleaning flux)

---

## Pre-Assembly Preparation

### Step 1: Workspace Setup

**Requirements:**
- Clean, well-lit workspace (ESD-safe mat preferred)
- Adequate ventilation (for soldering fumes)
- Organized component storage (use bins or trays)
- Reference documents printed or on second monitor

**Checklist:**
- [ ] Workspace clean and clear
- [ ] Lighting adequate (500+ lux)
- [ ] Ventilation fan or fume extractor running
- [ ] Fire extinguisher within reach
- [ ] First aid kit available

### Step 2: Component Inventory

**Verify all components received:**
- [ ] Cross-check against BOM (`bom/Complete-BOM.md`)
- [ ] Inspect for damage (cracked ICs, bent pins)
- [ ] Sort by type (resistors, capacitors, ICs, etc.)
- [ ] Label bins or bags clearly

**Check critical components:**
- [ ] 2× Mean Well RSP-500-48 PSUs (50V DC power)
- [ ] 1× Mean Well RD-35B auxiliary PSU (+12V/+5V)
- [ ] 2× RECOM R-78E15-0.5 isolated DC-DC converters (12V→15V)
- [ ] 8× IRFZ44N MOSFETs (55V, 49A, TO-220)
- [ ] 8× TLP250 optocoupler gate drivers (DIP-8)
- [ ] 1× ACS724 current sensor
- [ ] 1× AMC1301 voltage sensor
- [ ] 1× STM32 Nucleo-F401RE board
- [ ] All passives (resistors, capacitors)
- [ ] 8× 150Ω resistors (LED current limiting for TLP250)
- [ ] 8× 10Ω gate resistors

### Step 3: PCB Inspection

**Before assembly, inspect PCB:**
- [ ] No visible scratches or defects
- [ ] Solder mask intact (no peeling)
- [ ] Copper traces not shorted (visual check)
- [ ] Drill holes clean (no burrs)
- [ ] Silkscreen readable
- [ ] Layer alignment correct (if visible through vias)

**Electrical Check:**
- [ ] Continuity between GND pads (should be <1Ω)
- [ ] No shorts between power rails and GND (should be >100kΩ)
- [ ] Measure DC resistance of power plane splits

---

## PCB Assembly

### Overview

Assembly follows **outside-in** strategy:
1. Smallest SMD components first (0603 resistors/caps)
2. Medium SMD (0805, SOIC ICs)
3. Through-hole passives
4. Large through-hole (electrolytic caps, terminals)
5. Power MOSFETs (on bottom layer)

**Reflow Soldering (for SMD):**

If using reflow oven or hot air station:

**Step 1: Apply Solder Paste**
- Use stencil aligned to PCB
- Apply thin, even layer of solder paste
- Check paste on all pads (use magnifier)

**Step 2: Place Components**
- Use tweezers to place components
- Align carefully (0.1mm precision for small SMD)
- Double-check orientation (IC pin 1, diode polarity)

**Step 3: Reflow**
- Preheat: 150°C for 60s
- Ramp: 1-3°C/s to 220°C
- Reflow: 235-245°C for 30-60s (lead-free)
- Cool: Natural cooling to <100°C

**Step 4: Inspect**
- Use magnifier to check solder joints
- Look for bridges (shorts between pins)
- Verify all pins wetted (shiny fillet)
- Check for tombstoning (component standing up)

---

**Hand Soldering (for through-hole):**

**Step 1: Resistors and Small Capacitors**

Order: Lowest profile first

1. Insert resistor leads through holes
2. Bend leads slightly (15°) to hold in place
3. Solder one pad, verify component seated
4. Solder second pad
5. Trim excess leads

**Settings:**
- Iron temp: 350°C (lead-free) or 320°C (60/40)
- Contact time: 2-3 seconds

**Step 2: IC Sockets (if used)**

**Recommended for:**
- IR2110 (allows easy replacement if damaged)
- LM339 comparators

**Procedure:**
1. Insert socket, verify orientation (notch)
2. Tape socket to hold in place
3. Solder opposite corner pins first
4. Verify alignment, solder remaining pins

**Step 3: Electrolytic Capacitors**

**CRITICAL: Check polarity!**
- Positive lead is longer
- Negative side has stripe
- PCB has + marking

**Procedure:**
1. Insert cap with correct polarity
2. Bend leads to hold
3. Solder and trim

**Step 4: Screw Terminals**

**For:**
- DC bus inputs (+50V per bridge)
- AC output
- Auxiliary power (12V, 5V, 3.3V)

**Procedure:**
1. Insert terminal block
2. Ensure flush with PCB
3. Solder all pins (use extra solder for mechanical strength)

---

### Power MOSFET Assembly (Critical)

**Location:** Bottom layer (Layer 4)

**Procedure:**

1. **Prepare MOSFET:**
   - Identify pins: Gate, Drain, Source (check datasheet)
   - Clean tab with isopropyl alcohol
   - Apply thin layer of thermal paste to tab

2. **Insert MOSFET:**
   - Insert leads through PCB holes (from bottom)
   - Ensure MOSFET tab aligns with heatsink mounting holes
   - Push flush against PCB bottom

3. **Solder from Top:**
   - Solder all 3 pins from top side
   - Use generous solder for mechanical strength
   - Verify good thermal connection to copper pour

4. **Attach Heatsink:**
   - Place thermal pad or mica insulator (if isolating)
   - Position heatsink over MOSFET tab
   - Insert M3 screw through: Heatsink → MOSFET → PCB
   - Tighten to 0.5 N⋅m (finger-tight + 1/4 turn)
   - Do NOT overtighten (can crack MOSFET!)

5. **Repeat for all 8 MOSFETs**

---

### Post-Assembly Inspection

**Visual Inspection:**
- [ ] All components populated (check against BOM)
- [ ] No solder bridges (especially on SMD ICs)
- [ ] No cold solder joints (dull, grainy appearance)
- [ ] All polarized components correct orientation
- [ ] No components misaligned or tombstoned

**Electrical Inspection:**
- [ ] Continuity: All GND points connected
- [ ] Isolation: Power rails not shorted to GND
- [ ] MOSFET pins: Gate, Drain, Source continuity to traces
- [ ] Bootstrap diodes: Correct polarity (use diode test mode)

**Cleaning:**
- [ ] Remove flux residue with isopropyl alcohol (optional)
- [ ] Inspect under magnification again after cleaning
- [ ] Allow to dry completely before power-up

---

## Power Supply Integration

### Mean Well RSP-500-48 Setup

**Quantity:** 2 (one per H-bridge)

**Step 1: Output Voltage Adjustment**

**⚠️ Use bench PSU for initial test, not AC mains!**

1. Connect +12V DC from bench PSU to Vcc and -Vcc pins (consult datasheet)
2. Measure output voltage with multimeter
3. Locate adjustment potentiometer (VR1 on RSP-500-48)
4. Adjust to exactly **50.0V ± 0.1V**
5. Disconnect power and wait 1 minute (capacitors discharge)
6. Repeat for second PSU

**Step 2: Mounting**

1. Identify mounting location in enclosure
2. Use M4 screws to secure PSU to enclosure or DIN rail
3. Ensure adequate ventilation (10cm clearance on all sides)
4. Route AC input cables through strain relief

**Step 3: AC Input Wiring**

**⚠️ DO NOT CONNECT TO AC MAINS YET**

Plan wiring (do not connect):
```
AC Mains ──→ Fuse (15A) ──→ NTC Thermistor ──→ EMI Filter ──→ PSU Input
                                                                 L (Line)
                                                                 N (Neutral)
                                                                 PE (Earth)
```

**Wire Gauge:**
- Use 14 AWG (2.5 mm²) for mains (120V AC, 10A)
- Use 12 AWG (4.0 mm²) for 240V AC regions

**Terminals:**
- Strip 8mm of insulation
- Use ferrules for stranded wire
- Tighten terminal screws to spec (0.5 N⋅m)

---

### Mean Well RD-35B Setup

**Purpose:** Provides +12V (gate drivers) and +5V (logic)

**Step 1: Mounting**
- Mount near main control PCB
- Use M3 screws or adhesive

**Step 2: Input Wiring**
- Connect to same AC mains as main PSUs
- Use fuse (5A) for protection

**Step 3: Output Wiring**
- +12V output → Gate driver Vcc (PCB screw terminal)
- +5V output → Logic supply (PCB screw terminal)
- GND → Common ground (star connection)

**Step 4: 3.3V Regulator (if not on PCB)**
- Use AMS1117-3.3 LDO regulator
- Input: +5V from RD-35B
- Output: +3.3V for STM32 and ADC
- Add 10μF cap on input and output

---

## Microcontroller Integration

### STM32 Nucleo-F401RE Setup

**Step 1: Firmware Programming**

Before connecting to power stage:

1. Connect Nucleo to PC via USB
2. Open STM32CubeIDE or PlatformIO
3. Load project from `02-embedded/stm32/`
4. Compile firmware (verify no errors)
5. Flash to Nucleo (via ST-Link)
6. Verify successful upload (LED blinks)

**Step 2: PWM Output Verification**

**⚠️ DO NOT connect PWM outputs to gate drivers yet!**

1. Run firmware in Test Mode 1 (open-loop PWM)
2. Use oscilloscope to verify PWM outputs:
   - TIM1_CH1, TIM1_CH2 (H-Bridge 1)
   - TIM8_CH1, TIM8_CH2 (H-Bridge 2)
3. Check frequency: 5 kHz (200 μs period)
4. Check duty cycle: ~50% at MI = 1.0
5. Verify dead-time: 1 μs gap between complementary signals

**Step 3: Level Shifter Connection**

If using SN74AHCT125 level shifter (3.3V → 5V):

```
STM32 GPIO ──→ Level Shifter Input (3.3V)
Level Shifter Output (5V) ──→ IR2110 HIN/LIN
```

**Connections:**
- 4 PWM channels (TIM1_CH1, CH2, TIM8_CH1, CH2)
- 4 complementary PWM channels (TIM1_CH1N, CH2N, etc.)
- Total: 8 signals to 4× IR2110 ICs

---

### Sensor Connection

**Current Sensor (ACS724):**
```
ACS724 Vout ──→ STM32 PA0 (ADC1_IN0)
```

**Voltage Sensor (AMC1301):**
```
AMC1301 Digital Out ──→ STM32 SPI/UART
```

**DC Bus Voltage:**
```
DC Bus 1 Divider ──→ STM32 PA4 (ADC1_IN4)
DC Bus 2 Divider ──→ STM32 PA5 (ADC1_IN5)
```

**Protection Signals:**
```
FAULT_OCP ──→ STM32 PA10 (interrupt)
FAULT_OVP ──→ STM32 PA11 (interrupt)
E-STOP ──→ STM32 PA9 (interrupt)
```

---

## Enclosure Assembly

### Hammond 1590WV Enclosure Preparation

**Step 1: Drilling and Cutting**

**Front Panel:**
- [ ] 3× LED holes (5mm) for status indicators
- [ ] 1× E-stop button hole (22mm)
- [ ] 1× Power switch hole (12mm)

**Rear Panel:**
- [ ] 1× IEC power inlet (rectangular cutout)
- [ ] 2× Screw terminals for AC output
- [ ] 1× USB connector pass-through (for programming)

**Top Panel:**
- [ ] Ventilation slots (for cooling)

**Use:**
- Step drill bit for round holes
- File for smooth edges
- Deburring tool to remove sharp edges

---

### Component Mounting

**Inside Enclosure:**

1. **PCB Mounting:**
   - Use 10mm M3 standoffs
   - Position for easy access to terminals and test points
   - Ensure MOSFETs/heatsinks clear enclosure walls (10mm)

2. **PSU Mounting:**
   - Mount both RSP-500-48 units on left side
   - Mount RD-35B on right side
   - Use M4 screws or DIN rail clips

3. **Cooling Fan:**
   - Mount 40mm fan on side wall (near MOSFETs)
   - Intake: Front, Exhaust: Rear
   - Connect to +12V rail

4. **Fuse Holders:**
   - Panel-mount fuse holders on rear panel
   - Accessible from outside for replacement

5. **E-Stop Button:**
   - Front panel, large and RED
   - Easy access in emergency

---

## System Wiring

### Power Distribution

**DC Bus Wiring (High Current!):**

Use 14 AWG silicone wire (red/black):

```
PSU 1 (+50V) ────→ Terminal Block ────→ PCB DC Bus 1 (+)
PSU 1 (GND)  ────→ Terminal Block ────→ PCB DC Bus 1 (-)

PSU 2 (+50V) ────→ Terminal Block ────→ PCB DC Bus 2 (+)
PSU 2 (GND)  ────→ Terminal Block ────→ PCB DC Bus 2 (-)
```

**CRITICAL:**
- Keep DC Bus 1 and DC Bus 2 grounds **ISOLATED** (no common connection)
- Use separate terminal blocks for each H-bridge
- Label clearly: "DC BUS 1 (+50V)", "DC BUS 2 (+50V)"

---

### AC Output Wiring

```
H-Bridge 1 Output ────┬──→ H-Bridge 2 Input
                      │
                      └──→ AC Output Terminal (100V RMS)

H-Bridge 2 Output ────→ AC Output Terminal (return)
```

Use 12 AWG wire (rated for 100V AC, 10A).

---

### Control Signal Wiring

**Low-Voltage Wiring (use ribbon cable or 24 AWG stranded):**

```
STM32 Nucleo ──→ Level Shifter ──→ Gate Driver PCB (8× PWM signals)
STM32 Nucleo ──→ Sensor Signals (4× ADC inputs)
STM32 Nucleo ──→ Protection Signals (3× interrupts)
```

**Best Practice:**
- Use ribbon cable with 2.54mm IDC connectors
- Twist pairs for differential signals
- Keep away from high-voltage/high-current wires

---

### Grounding Strategy

**Star Grounding (single-point ground):**

```
                  Main Ground Point
                  (on chassis near PSU input)
                         │
      ┌──────────────────┼──────────────────┐
      │                  │                  │
   Power GND        Analog GND         Digital GND
   (MOSFETs)        (Sensors)          (STM32, gate drivers)
```

**Chassis Ground:**
- Connect to AC mains protective earth (PE)
- Use braided ground strap (low impedance)
- All metal parts (heatsinks, enclosure) bonded to chassis ground

---

## Pre-Power Testing

### Before Applying Any Power

**Step 1: Visual Inspection**
- [ ] All wiring complete and secure
- [ ] No loose wires or components
- [ ] Proper wire routing (strain relief)
- [ ] Heatsinks properly attached
- [ ] Thermal paste applied to MOSFETs
- [ ] Enclosure ventilation not blocked

**Step 2: Continuity Tests**
- [ ] GND continuity: All ground points < 1Ω
- [ ] DC bus isolation: Bus 1 and Bus 2 not connected
- [ ] Power rail isolation: No shorts between +50V, +12V, +5V, +3.3V and GND

**Step 3: Resistance Tests**

Measure resistance (power OFF, no AC):

| Measurement | Expected | Actual | Pass/Fail |
|-------------|----------|--------|-----------|
| DC Bus 1 (+) to GND | > 100 kΩ | | |
| DC Bus 2 (+) to GND | > 100 kΩ | | |
| +12V to GND | > 10 kΩ | | |
| +5V to GND | > 10 kΩ | | |
| +3.3V to GND | > 1 kΩ | | |

**If any short detected:** Find and fix before proceeding!

---

## Initial Power-Up

### ⚠️ DANGER: HIGH VOLTAGE

**Follow these steps EXACTLY. Do not skip any step.**

---

### Phase 1: Auxiliary PSU Test (12V, 5V, 3.3V)

**Setup:**
1. Ensure main PSUs (50V) are **NOT** connected
2. Remove all PWM connections to gate drivers
3. Connect AC mains to auxiliary PSU (RD-35B) **ONLY**

**Power-Up:**
1. Plug in AC power (use isolated transformer if possible)
2. Turn on power switch
3. **Immediately measure:**
   - +12V rail: Should be 12.0V ± 0.2V
   - +5V rail: Should be 5.0V ± 0.1V
   - +3.3V rail: Should be 3.3V ± 0.1V

**If voltages incorrect:** Shut down immediately, troubleshoot.

**Current Check:**
- Measure current draw from AC mains: Should be < 1A
- If > 2A, shut down and check for shorts

**Duration:** Run for 5 minutes, monitor temperatures.

---

### Phase 2: Main PSU Test (50V DC)

**Setup:**
1. Keep auxiliary PSU powered
2. Connect AC mains to one main PSU (RSP-500-48 #1)
3. DO NOT connect output to PCB yet

**Power-Up:**
1. Turn on PSU #1
2. Measure output voltage: Should be 50.0V ± 0.5V
3. Measure ripple with oscilloscope: Should be < 500 mV p-p

**Load Test:**
1. Connect 10Ω / 100W resistor to output
2. Measure voltage under load: Should be 49.5-50.5V
3. Measure current: Should be ~5A
4. Monitor temperature for 2 minutes

**Repeat for PSU #2**

**Both PSUs working?** → Proceed
**Any issues?** → Troubleshoot before continuing

---

### Phase 3: Low-Voltage Gate Driver Test

**Setup:**
1. Power down all PSUs
2. Connect +12V and +5V to gate driver PCB
3. Connect STM32 PWM outputs to gate drivers
4. **DO NOT** connect gate outputs to MOSFETs yet (leave disconnected)

**Power-Up:**
1. Power on auxiliary PSU (+12V, +5V)
2. Verify gate driver ICs powered (check Vcc pins: 12V)
3. Verify bootstrap caps charging (measure VB pins)

**PWM Test:**
1. Run STM32 firmware (Test Mode 1)
2. Use oscilloscope to measure gate driver outputs (HO, LO):
   - Frequency: 5 kHz
   - Amplitude: 0-12V
   - Dead-time: ~1 μs
   - No overlap between HO and LO

**If waveforms correct:** → Proceed
**If incorrect:** → Debug firmware/hardware

---

### Phase 4: Full System Test (NO LOAD)

**Setup:**
1. Power down everything
2. Connect gate outputs to MOSFET gates (via 10Ω resistors)
3. Connect DC bus PSUs to PCB (50V per bridge)
4. **DO NOT** connect any load to AC output yet

**Safety:**
- Insulated gloves ON
- Safety glasses ON
- Oscilloscope probes isolated (differential or isolated)
- E-stop button accessible

**Power-Up Sequence:**
1. Power on auxiliary PSU (+12V, +5V, +3.3V)
2. Verify all voltages correct
3. Power on DC bus PSU #1 (50V)
4. **WAIT 5 seconds** (observe for any faults)
5. Power on DC bus PSU #2 (50V)
6. **WAIT 5 seconds**

**Monitoring:**
- DC bus voltages: Should be 50V each
- No smoke, no sparks, no unusual smells
- MOSFETs not heating up (should be cold with no load)

**Enable PWM:**
1. Activate soft-start in firmware
2. Gradually increase modulation index from 0 to 0.5
3. Measure AC output voltage with oscilloscope:
   - Should be 5-level waveform
   - Peak voltage: ~50V (for MI = 0.5)
   - Frequency: 50 Hz

**If all OK:** → Proceed to load testing
**If faults occur:** → Shut down immediately, check protection circuits

---

## Troubleshooting

### Common Issues and Solutions

**Problem:** No output voltage
- **Check:** PWM signals reaching gate drivers?
- **Check:** Gate driver power supply (12V, 5V)?
- **Check:** Bootstrap caps charged?
- **Check:** MOSFETs inserted correctly?

**Problem:** Output voltage incorrect
- **Check:** Modulation index setting in firmware
- **Check:** DC bus voltage (should be 50V)
- **Check:** Dead-time too large (reduces output)?

**Problem:** One H-bridge not working
- **Check:** Gate driver for that bridge powered?
- **Check:** PWM signals reaching that driver?
- **Check:** MOSFETs for that bridge functional (test with multimeter diode mode)?

**Problem:** Overcurrent fault triggering
- **Check:** Short circuit on output?
- **Check:** OCP threshold too low?
- **Check:** Current sensor calibration

**Problem:** Overvoltage fault triggering
- **Check:** DC bus voltage too high?
- **Check:** Adjust PSU output voltage to 50V
- **Check:** OVP threshold

**Problem:** MOSFETs overheating
- **Check:** Thermal paste applied?
- **Check:** Heatsink attached properly?
- **Check:** PWM frequency too high (check firmware)?
- **Check:** Dead-time too short (shoot-through)?

---

## Next Steps

After successful initial power-up:

1. **Proceed to Full Testing:**
   - Refer to `../../07-docs/05-Hardware-Testing-Procedures.md`
   - Phase 3: Low-power integration testing
   - Phase 4: Full-power testing
   - Phase 5: Performance validation

2. **Calibration:**
   - Current sensor offset and gain
   - Voltage sensor accuracy
   - PR controller tuning

3. **Load Testing:**
   - Resistive load (10Ω, 100W)
   - Inductive load (RL circuit)
   - Full 500W power test

4. **Performance Measurement:**
   - THD analysis
   - Efficiency calculation
   - Thermal performance
   - Long-duration reliability test

---

## Appendix: Wiring Diagrams

### System-Level Wiring Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                        Enclosure                             │
│                                                              │
│  AC Mains Input                                              │
│      │                                                       │
│      ├───→ Fuse ───→ RSP-500-48 #1 ───→ +50V (Bus 1)        │
│      │                                                       │
│      ├───→ Fuse ───→ RSP-500-48 #2 ───→ +50V (Bus 2)        │
│      │                                                       │
│      └───→ Fuse ───→ RD-35B ───┬───→ +12V ──┬── DC-DC #1 → +15V Iso1│
│                                 │            └── DC-DC #2 → +15V Iso2│
│                                 ├───→ +5V (Logic)            │
│                                 └───→ GND (Common)           │
│                                                              │
│  ┌────────────────────────────────────────┐                 │
│  │         Main Control PCB               │                 │
│  │                                        │                 │
│  │  ┌───────────┐      ┌──────────────┐  │                 │
│  │  │ STM32     │──PWM→│ TLP250 ×8    │  │                 │
│  │  │ Nucleo    │      │ (Optocoupler)│  │                 │
│  │  │ F401RE    │      │ Gate Drivers │  │                 │
│  │  └───────────┘      └──────┬───────┘  │                 │
│  │                            │           │                 │
│  │      +15V Iso1, Iso2 ──────┘           │                 │
│  │                            ↓           │                 │
│  │                     ┌─────────────┐    │                 │
│  │                     │  IRFZ44N    │    │                 │
│  │                     │  MOSFETs    │    │                 │
│  │                     │  (×8)       │    │                 │
│  │                     └──────┬──────┘    │                 │
│  │                            │           │                 │
│  └────────────────────────────┼───────────┘                 │
│                               │                             │
│                               ↓                             │
│                        AC Output Terminal                   │
│                        (100V RMS, 50 Hz)                    │
└──────────────────────────────────────────────────────────────┘
```

**Key TLP250 Integration Notes:**
- 8× TLP250 optocouplers provide galvanic isolation for all gate drives
- 2× isolated DC-DC converters (R-78E15-0.5) provide +15V power to isolated sides
- STM32 GPIO (3.3V) drives TLP250 LED inputs through 150Ω resistors
- TLP250 outputs drive MOSFET gates through 10Ω resistors
- Maintain 5mm isolation barrier on PCB between common and isolated sides

---

**Document Version:** 2.0
**Last Updated:** 2025-11-15
**Document Status:** Integration guide complete for TLP250 configuration

**Major Changes in v2.0:**
- Updated component checklist to include TLP250 optocouplers and DC-DC converters
- Replaced IR2110 references with TLP250 throughout
- Updated MOSFET specification from IRF540N to IRFZ44N
- Added isolated power supply requirements (2× DC-DC converters)
- Updated system wiring diagram to show TLP250 and isolated DC-DC architecture
- Added TLP250 integration notes (isolation barrier, resistor values)

**Critical Differences from IR2110:**
- **Component count:** 8× TLP250 (vs. 4× IR2110) - one per MOSFET
- **Power requirements:** Requires isolated +15V supplies (not bootstrap)
- **Isolation:** True galvanic isolation (2.5kV) vs. bootstrap
- **PCB complexity:** Requires isolation barriers on PCB layout
- **Assembly:** Optocouplers easier to assemble (no bootstrap diodes/caps)

**Next Steps:** Follow this guide step-by-step during hardware build

**Related Documents:**
- `schematics/01-Gate-Driver-Design.md` - TLP250 gate driver circuit
- `schematics/02-Power-Supply-Design.md` - Power supplies with isolated DC-DC
- `bom/Complete-BOM.md` - Complete component list
- `pcb/05-PCB-Layout-Guide.md` - PCB design with isolation barriers
- `../../07-docs/ELE401_Fall2025_IR_Group1.pdf` - Graduation project report
- `../../07-docs/03-Safety-and-Protection-Guide.md` - Safety procedures
- `../../07-docs/05-Hardware-Testing-Procedures.md` - Testing procedures
