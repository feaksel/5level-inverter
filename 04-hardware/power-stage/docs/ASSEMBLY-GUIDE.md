# Complete Assembly Guide

**Project:** 5-Level Cascaded H-Bridge Inverter Power Stage
**Assembly Level:** Intermediate (soldering experience required)
**Estimated Time:** 4-6 hours for complete assembly
**Date:** 2025-12-02

---

## Table of Contents

1. [Tools and Materials](#tools-and-materials)
2. [Pre-Assembly Preparation](#pre-assembly-preparation)
3. [Step 1: SMD Component Assembly](#step-1-smd-component-assembly)
4. [Step 2: Through-Hole Component Assembly](#step-2-through-hole-component-assembly)
5. [Step 3: Power Stage Assembly (IG BTs)](#step-3-power-stage-assembly-igbts)
6. [Step 4: Heatsink Installation](#step-4-heatsink-installation)
7. [Step 5: Connector Installation](#step-5-connector-installation)
8. [Step 6: Final Inspection](#step-6-final-inspection)
9. [Step 7: Initial Testing](#step-7-initial-testing)

---

## Tools and Materials

### Required Tools

| Tool | Specification | Purpose |
|------|--------------|---------|
| **Soldering Iron** | Temperature controlled, 60-80W | General soldering |
| **Soldering Iron Tips** | Chisel (3mm), Fine point (1mm) | Different components |
| **Solder** | 60/40 or 63/37, 0.8mm, flux core | Rosin core solder |
| **Solder Wick** | 2-3mm width | Remove excess solder |
| **Tweezers** | ESD-safe, fine point | SMD placement |
| **Wire Strippers** | 18-24 AWG | Strip wires |
| **Screwdrivers** | Phillips #1, #2 | Screw connectors |
| **Hex Drivers** | M3, M4 sizes | Heatsink mounting |
| **Multimeter** | True RMS, continuity mode | Testing |
| **Magnifying Glass** | 5-10× magnification | Inspection |
| **Hot Air Station** | Optional, for SMD rework | Desolder mistakes |
| **Thermal Paste** | Non-conductive, silicone-based | IGBT to heatsink |

### Safety Equipment

- ESD wrist strap (grounded)
- Safety glasses
- Ventilation/fume extractor
- Fire extinguisher (Class C)
- First aid kit

### Consumables

- Solder (lead or lead-free)
- Flux (liquid or gel)
- Isopropyl alcohol (IPA) 99%
- Lint-free wipes
- Cotton swabs
- Thermal paste (1g syringe)
- Thermal pads (optional, if using isolated heatsink)
- Heat shrink tubing (assorted)
- Cable ties

---

## Pre-Assembly Preparation

### 1. Workspace Setup

**Requirements:**
- Clean, flat, ESD-safe work surface
- Good lighting (1000+ lux)
- Organized component storage
- Soldering fume extraction
- Fire-safe area (no flammable materials nearby)

**ESD Protection:**
1. Wear ESD wrist strap connected to earth ground
2. Use ESD mat on work surface
3. Store ICs in anti-static bags until use

### 2. PCB Inspection

**Check received PCB for:**
- [ ] Correct dimensions (150mm × 100mm)
- [ ] 4 layers visible (check cross-section if cut)
- [ ] No physical damage (cracks, delamination)
- [ ] Copper quality (no oxidation, scratches)
- [ ] Solder mask alignment
- [ ] Silk screen legibility
- [ ] Plated through-holes (PTH) quality

**Measure with multimeter:**
- [ ] Layer 2 (GND) to Layer 3 (Power): > 10MΩ (isolated)
- [ ] Continuity of GND plane (probe different GND pads): < 1Ω

### 3. Component Organization

**Sort components by type:**

| Group | Components | Container |
|-------|------------|-----------|
| **Resistors** | All resistors by value | Labeled bags/boxes |
| **Capacitors - Ceramic** | By value and voltage | |
| **Capacitors - Electrolytic** | By value (watch polarity!) | |
| **Diodes** | By type (UF4007, TVS) | |
| **ICs** | IR2110, AMC1301, ACS724, etc. | Anti-static bag |
| **IGBTs** | Q1-Q8 | Anti-static bag |
| **Connectors** | Terminals, headers | |
| **Hardware** | Screws, standoffs, heatsinks | |

**Create assembly checklist:**
- Print BOM (Bill of Materials)
- Check off each component as installed
- Mark any substitutions or missing parts

---

## Step 1: SMD Component Assembly

**Order:** Smallest to largest (avoids shadowing)

### 1.1 Resistors (0805 package)

**Components:** R3a-R3c (output filter, 1kΩ), pull-ups, etc.

**Procedure:**
1. Apply small amount of solder to ONE pad
2. Heat pad, slide resistor into place with tweezers
3. Remove iron, let solder solidify (holds resistor)
4. Solder opposite side
5. Re-touch first side if needed

**Tips:**
- Resistors have no polarity (can go either way)
- Verify value with multimeter if markings unclear
- Check placement against silkscreen

### 1.2 Ceramic Capacitors (0805 and 1206 packages)

**Components:** 100nF, 1µF filter capacitors

**Procedure:**
1. Same as resistors (no polarity for ceramics)
2. Apply small amount of solder to one pad
3. Place capacitor, solder one side
4. Solder opposite side
5. Verify with visual inspection (no tombstoning)

**Common issues:**
- **Tombstoning:** Capacitor stands up on one end
  - Cause: Uneven heating or too much solder on one pad
  - Fix: Reflow both pads simultaneously with hot air or two irons

### 1.3 Integrated Circuits (SOIC packages)

**Components:** AMC1301 (SOIC-8), ACS724 (SOIC-8)

**Procedure:**
1. Apply solder paste or flux to pads
2. Align IC carefully (pin 1 marker to silkscreen indicator)
3. Tack one corner pin
4. Check alignment, adjust if needed (re-heat corner)
5. Solder all pins (drag soldering or individual)
6. Clean excess flux with IPA

**Pin 1 identification:**
- Dot or notch on IC package
- Square pad on PCB
- Silkscreen indicator

**Drag soldering technique:**
```
1. Apply flux to all pins
2. Load soldering iron tip with solder
3. Drag tip across pins (one side at a time)
4. Solder bridges between pins (this is OK!)
5. Use solder wick to remove bridges
6. Check with magnifier: no shorts, all pins connected
```

---

## Step 2: Through-Hole Component Assembly

**Order:** Smallest to tallest

### 2.1 Resistors (Through-Hole)

**Components:** Gate resistors (10Ω, 2W), snubber resistors (47Ω, 2W)

**Procedure:**
1. Insert resistor through holes (correct location by ref designator)
2. Bend leads outward on bottom side (prevents falling out)
3. Solder from bottom side
4. Trim leads with side cutters (leave ~2mm)

**Verification:**
- Measure resistance with multimeter (power OFF)
- Check for cold joints (shiny, solid solder joint required)

### 2.2 Diodes

**Components:** UF4007 (fast recovery diodes), TVS diodes (SMAJ3.3CA)

**⚠️ POLARITY CRITICAL:**
- **Cathode (marked with stripe) must match PCB silkscreen**
- Incorrect polarity = destroyed diode or circuit failure

**Procedure:**
1. Identify cathode marking (stripe or band)
2. Match to PCB silkscreen (square pad = cathode)
3. Insert, bend leads, solder
4. Trim leads

**Double-check polarity before soldering!**

### 2.3 Electrolytic Capacitors

**Components:** Bulk capacitors (1000µF, 100V), VCC bypass (100µF, 25V)

**⚠️ POLARITY CRITICAL:**
- **Negative lead (marked with stripe) goes to GND**
- Reverse polarity = explosion hazard

**Procedure:**
1. Identify negative lead (shorter lead, stripe on body)
2. Match to PCB silkscreen (filled pad = negative)
3. Insert (ensure fully seated)
4. Bend leads, solder
5. Trim leads

**Polarity verification:**
- Use multimeter in diode mode
- Measure across capacitor (unpowered)
- Forward bias should show ~0.5-0.7V (one direction only)

### 2.4 DIP ICs (IR2110 Gate Drivers)

**Components:** U1-U4 (IR2110PBF, DIP-14)

**Option A: IC Sockets (Recommended)**
1. Insert IC socket (notch matches silkscreen)
2. Solder all pins
3. Insert IC into socket later (after testing)

**Option B: Direct Soldering**
1. Insert IC (pin 1 to square pad, notch matches silkscreen)
2. Tack opposite corner pins
3. Solder all remaining pins
4. Check for bridges with magnifier

**Why use sockets?**
- Allows IC replacement if damaged
- Can test circuit before inserting expensive ICs
- Prevents heat damage to IC during soldering

---

## Step 3: Power Stage Assembly (IGBTs)

### 3.1 IGBT Preparation

**Components:** Q1-Q8 (IKW15N120H3, TO-247 package)

**Pre-installation checks:**
- [ ] Identify pins: Gate (G), Collector (C), Emitter (E)
- [ ] Verify datasheet pinout matches PCB
- [ ] Check IGBT not damaged (measure VGE with multimeter)

**Pin identification (TO-247 package):**
```
Front view (looking at pins):
┌─────────┐
│    Q1   │
│  IGBT   │
│         │
└─┬───┬───┘
  G   C   E
  1   2   3
```

### 3.2 IGBT Installation (NO Heatsink Yet)

**Procedure:**

1. **Prepare PCB pads:**
   - Clean pads with IPA
   - Apply flux

2. **Bend IGBT leads slightly (if needed):**
   - Match PCB hole spacing (usually 5.08mm / 0.2")
   - Don't bend excessively (stress on package)

3. **Insert IGBT into PCB:**
   - Push through until plastic body ~2mm above PCB
   - Verify pin alignment (Gate to gate pad, etc.)

4. **Temporarily support IGBT:**
   - Use tape or clamp to hold vertical
   - Or tack solder one pin

5. **Solder all three pins from bottom:**
   - Use high wattage iron (60-80W) or set temp to 350-400°C
   - Large thermal mass requires more heat
   - Solder should flow completely around pin

6. **Trim leads (leave 5-10mm):**
   - Don't trim flush (need some length for stress relief)

### 3.3 Gate Resistors and Pull-Downs

**Install immediately after IGBTs:**

**Gate Resistors (10Ω, 2W):**
- One lead to IR2110 output (HO or LO)
- Other lead to IGBT gate pin
- **Keep leads SHORT** (< 10mm total length)
- Solder and trim

**Gate-Emitter Resistors (10kΩ, 1/4W):**
- Between IGBT gate and emitter
- Pull gate low when driver off
- Solder and trim

### 3.4 Snubber Circuits

**Components per IGBT:** 47Ω (2W) + 100nF (100V ceramic)

**Procedure:**
1. Solder resistor and capacitor in series
2. Connect across collector-emitter of IGBT
3. **Keep leads very short** (< 20mm loop area)
4. Solder directly to IGBT pins if possible

---

## Step 4: Heatsink Installation

### 4.1 Heatsink Preparation

**Clean heatsink:**
1. Wipe with IPA to remove oils/oxidation
2. Inspect mounting holes (remove burrs if present)
3. Check flatness (should be flat within 0.1mm)

### 4.2 Thermal Interface Material

**Option A: Thermal Paste (Most Common)**

**Procedure:**
1. Clean IGBT metal tab with IPA
2. Apply small amount (rice grain size) to IGBT tab
3. Spread evenly with plastic card (thin layer, 0.1mm)
4. Do NOT over-apply (excess makes worse thermal contact)

**Option B: Thermal Pad (Electrically Isolating)**

**Use when:** IGBT collector (tab) must be isolated from heatsink

**Procedure:**
1. Cut thermal pad to size (slightly larger than IGBT tab)
2. Remove protective film from both sides
3. Place pad on heatsink first
4. Press IGBT onto pad

### 4.3 Heatsink Mounting

**Hardware:**
- M3 or M4 screws (depends on heatsink)
- Washers (prevent screw head damage to IGBT)
- Spring washers or lock washers (prevent loosening)

**Procedure:**

1. **Align heatsink with IGBTs:**
   - Ensure all IGBTs contact heatsink surface
   - If using single heatsink for multiple IGBTs, check alignment

2. **Insert screws (hand-tight first):**
   - Do NOT fully tighten yet
   - Allow slight movement for alignment

3. **Check IGBT alignment:**
   - All IGBTs should be parallel to PCB
   - No twisting or bending

4. **Tighten screws in cross pattern:**
   ```
   Tightening order for 4 IGBTs:

   Q1 ─── 1 ────── 3 ─── Q3
        │         │
        │         │
   Q2 ─── 4 ────── 2 ─── Q4

   Tighten: 1 → 2 → 3 → 4 (repeat 2-3 times)
   ```

5. **Torque specification:**
   - **0.5-0.8 Nm (5-7 kgf·cm)** for M3 screws
   - Hand-tight with small screwdriver (don't over-torque!)
   - Over-torquing cracks IGBT package

6. **Verify thermal contact:**
   - Slight resistance when trying to wiggle IGBT
   - No gaps visible between IGBT and heatsink

### 4.4 Thermal Verification

**After installation:**
- Run circuit at low power (12V, 25% duty cycle)
- Monitor IGBT temperature with IR thermometer
- Should heat up evenly (all IGBTs similar temperature)
- Temperature rise should be slow and controlled

**If one IGBT much hotter than others:**
- Poor thermal contact (re-apply thermal paste)
- Electrical issue (check circuit)

---

## Step 5: Connector Installation

### 5.1 Screw Terminal Blocks

**Components:**
- J1, J2: DC input terminals (2-pin, 5mm pitch, 20A rating)
- J3: AC output terminal (2-pin, 5mm pitch, 15A rating)

**Procedure:**
1. Insert terminals into PCB (match polarity marking)
2. Screw terminals have orientation (wire entry from top or side)
3. Solder all pins from bottom
4. Verify secure mechanical connection (pull test)

### 5.2 Pin Headers

**Components:**
- J4: PWM input (2×8 pin, 0.1" / 2.54mm pitch)
- J5: Sensor output (1×6 pin)

**Procedure:**
1. Insert header pins into PCB
2. Tape or use jig to hold perpendicular
3. Solder one pin, check alignment
4. Solder remaining pins
5. Trim any excess pin length on bottom

---

## Step 6: Final Inspection

### 6.1 Visual Inspection

**Check with magnifying glass:**

**Solder Joints:**
- [ ] Shiny, smooth surface (not dull/grainy = cold joint)
- [ ] Fillet shape (concave meniscus)
- [ ] No bridges between pads
- [ ] No gaps or cracks

**Component Orientation:**
- [ ] ICs: Pin 1 matches silkscreen
- [ ] Diodes: Cathode matches silkscreen
- [ ] Electrolytic caps: Negative to GND
- [ ] IGBTs: Correct pin assignment (G, C, E)

**Mechanical:**
- [ ] IGBTs mounted securely to heatsink
- [ ] No loose components
- [ ] Connectors firmly seated
- [ ] No solder splashes or debris

### 6.2 Cleaning

**Remove flux residue:**
1. Spray IPA on PCB (or use brush with IPA)
2. Scrub gently with soft brush (toothbrush works)
3. Wipe with lint-free cloth
4. Blow dry with compressed air or let air-dry

**Why clean flux?**
- Prevents corrosion long-term
- Improves insulation resistance
- Allows better visual inspection
- Looks professional

### 6.3 Electrical Tests (POWER OFF)

**Continuity Tests:**

| Test | Expected | Measured | Pass/Fail |
|------|----------|----------|-----------|
| GND continuity (all GND points) | < 1Ω | _____ Ω | ☐ |
| +50V DC1 to GND | > 10 MΩ | _____ MΩ | ☐ |
| +50V DC2 to GND | > 10 MΩ | _____ MΩ | ☐ |
| +15V to GND | > 10 MΩ | _____ MΩ | ☐ |
| +5V to GND | > 1 MΩ | _____ MΩ | ☐ |

**Diode Polarity Tests:**

Use multimeter in diode mode:
- Forward bias: ~0.5-0.7V drop
- Reverse bias: OL (open circuit)

Check all diodes (UF4007, TVS) in circuit.

**Gate-Emitter Resistance:**

For each IGBT (power OFF):
- Gate to Emitter: Should read ~10kΩ (pull-down resistor)
- If 0Ω: Short circuit (check for solder bridges)
- If OL: Open circuit (check pull-down resistor soldered)

---

## Step 7: Initial Testing

### 7.1 Low-Voltage Power-On

**Equipment needed:**
- Bench power supply (0-20V, current-limited to 0.5A)
- Multimeter
- Oscilloscope (optional)

**Procedure:**

1. **Apply +15V to gate driver supply (VCC):**
   - **Before connecting:** Set current limit to 0.5A
   - Connect +15V to VCC terminal
   - Connect GND to GND terminal
   - **Monitor current:** Should be < 50mA quiescent
   - **If current > 100mA:** Power off immediately, find short

2. **Measure voltages:**
   - VCC at each IR2110: Should be 14.5-15.5V
   - If any IC has wrong voltage: Check solder joints, traces

3. **Apply +12V to DC bus (NO PWM yet):**
   - Set current limit to 0.5A
   - Connect +12V to DC bus terminal
   - **Monitor current:** Should be < 10mA (just charging capacitors)
   - **Measure DC bus voltage:** Should be 11.5-12.5V

4. **Check IGBT gate voltages (PWM OFF):**
   - All gates should be at 0V (pulled low by 10kΩ resistors)

### 7.2 Gate Driver Functional Test

**Equipment needed:**
- Function generator or MCU with PWM
- Oscilloscope (2+ channels)

**Procedure:**

1. **Generate LOW-frequency PWM (100 Hz, 10% duty cycle):**
   - Connect PWM signal to HIN input (through 100Ω resistor)
   - GND to common ground
   - **Start with ONE driver only (test incrementally)**

2. **Measure gate drive outputs with oscilloscope:**
   - CH1: IGBT gate voltage (Gate to Emitter)
   - CH2: PWM input signal (reference)
   - **Expected:** Gate voltage swings 0-15V, following PWM input

3. **Verify waveforms:**
   - Gate high: 14-15V
   - Gate low: < 0.5V
   - Rise time: < 500ns
   - Fall time: < 500ns
   - No oscillations or ringing (small ringing OK, < 2V overshoot)

4. **Repeat for all 8 gate drivers**

### 7.3 Measurements Checklist

| Parameter | Expected | Measured | Pass/Fail |
|-----------|----------|----------|-----------|
| **Power Supply** ||||
| VCC (15V) | 14.5-15.5V | _____ V | ☐ |
| DC Bus (12V) | 11.5-12.5V | _____ V | ☐ |
| Quiescent current (15V) | < 50mA | _____ mA | ☐ |
| Quiescent current (12V) | < 10mA | _____ mA | ☐ |
| **Gate Driver 1 (Q1, Q2)** ||||
| Q1 Gate high | 14-15V | _____ V | ☐ |
| Q1 Gate low | < 0.5V | _____ V | ☐ |
| Q2 Gate high | 14-15V | _____ V | ☐ |
| Q2 Gate low | < 0.5V | _____ V | ☐ |
| **Gate Driver 2 (Q3, Q4)** ||||
| Q3 Gate high | 14-15V | _____ V | ☐ |
| Q3 Gate low | < 0.5V | _____ V | ☐ |
| Q4 Gate high | 14-15V | _____ V | ☐ |
| Q4 Gate low | < 0.5V | _____ V | ☐ |
| **Gate Driver 3 (Q5, Q6)** ||||
| Q5 Gate high | 14-15V | _____ V | ☐ |
| Q5 Gate low | < 0.5V | _____ V | ☐ |
| Q6 Gate high | 14-15V | _____ V | ☐ |
| Q6 Gate low | < 0.5V | _____ V | ☐ |
| **Gate Driver 4 (Q7, Q8)** ||||
| Q7 Gate high | 14-15V | _____ V | ☐ |
| Q7 Gate low | < 0.5V | _____ V | ☐ |
| Q8 Gate high | 14-15V | _____ V | ☐ |
| Q8 Gate low | < 0.5V | _____ V | ☐ |

**If ALL tests pass:**
✅ **Assembly COMPLETE and ready for full power testing**

**Next step:** See BREADBOARD-TESTING.md Stage 4+ for full power tests

---

## Troubleshooting During Assembly

### Problem: Cold Solder Joint

**Symptoms:**
- Dull, grainy appearance
- Component loose or falls off
- Intermittent connection

**Causes:**
- Insufficient heat
- Contaminated surfaces (oxidation, oil)
- Moved component during cooling

**Fix:**
1. Remove old solder with wick
2. Clean pads with IPA
3. Apply fresh flux
4. Reheat with proper temperature (350°C for lead, 380°C for lead-free)
5. Add fresh solder
6. Allow to cool without movement

### Problem: Solder Bridges

**Symptoms:**
- Unintended connection between adjacent pins/pads
- Short circuit
- IC doesn't work

**Fix:**
1. Add flux to bridged area
2. Use solder wick:
   - Place wick on bridge
   - Heat with soldering iron
   - Wick absorbs excess solder
3. Or: Use solder sucker (desoldering pump)
4. Verify with multimeter: adjacent pins should be isolated

### Problem: Lifted Pad

**Symptoms:**
- Copper pad detached from PCB
- Component can't be soldered

**Causes:**
- Excessive heat
- Excessive force when removing component
- Manufacturing defect

**Fix:**
- If trace visible: Scrape off solder mask, solder directly to trace
- If trace broken: Use wire jumper to nearest connection point
- Document repair for future reference

### Problem: Wrong Component Installed

**Best practice:** **STOP and evaluate**

- If not yet soldered: Remove and replace
- If soldered but not powered yet: Desolder carefully (use hot air or desoldering gun)
- If already powered: Check if component damaged, replace if needed

**Prevention:**
- Double-check component value before soldering
- Use checklist and mark off each component
- Organize components clearly

---

## Post-Assembly Storage

**If not immediately testing:**

1. **Protect assembled PCB:**
   - Store in anti-static bag
   - Keep in clean, dry environment
   - Avoid mechanical stress

2. **Document assembly:**
   - Take photos of completed board
   - Note any deviations from BOM or assembly plan
   - Record assembly date and builder name

3. **Label board:**
   - Write date, version, serial number on silkscreen with permanent marker

---

## Congratulations!

If you've completed all steps and passed all tests, you now have a **fully assembled 5-level inverter power stage**!

**Next steps:**
1. **Full power testing** at 50V DC bus (see BREADBOARD-TESTING.md)
2. **Load testing** with resistive and reactive loads
3. **Waveform quality verification** with oscilloscope
4. **Efficiency measurement** at different power levels
5. **Long-duration burn-in** (24-48 hours at 50% power)

**Keep this guide for reference during troubleshooting and repairs.**

---

**SAFETY REMINDER:** Even after assembly, this is a HIGH VOLTAGE device. Always follow safety precautions during testing and operation.
