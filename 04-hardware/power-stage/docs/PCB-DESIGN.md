# PCB Design and Manufacturing Guide

**Project:** 5-Level Cascaded H-Bridge Inverter Power Stage
**Power Rating:** 707W, 70.7V RMS / 100V Peak AC, 10A RMS
**PCB Type:** 4-Layer High-Power PCB (2oz copper)
**Dimensions:** 150mm × 100mm
**Date:** 2025-12-03

---

## Table of Contents

1. [PCB Specifications](#pcb-specifications)
2. [Layer Stackup](#layer-stackup)
3. [Component Placement Strategy](#component-placement-strategy)
4. [Power Routing Guidelines](#power-routing-guidelines)
5. [Signal Routing Guidelines](#signal-routing-guidelines)
6. [Thermal Management](#thermal-management)
7. [EMI/EMC Considerations](#emiemc-considerations)
8. [Manufacturing Files](#manufacturing-files)
9. [Assembly Process](#assembly-process)

---

## PCB Specifications

### Physical Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Board Dimensions** | 150mm × 100mm | Single PCB for both H-bridges |
| **Layer Count** | 4 layers | L1: Top, L2: GND, L3: Power, L4: Bottom |
| **Board Thickness** | 1.6mm | Standard FR-4 |
| **Copper Weight** | 2 oz (70µm) | Top/bottom for high current |
| | 1 oz (35µm) | Inner layers |
| **Minimum Trace Width** | 0.3mm (12 mil) | Signal traces |
| **Power Trace Width** | 3-10mm | Depends on current |
| **Minimum Spacing** | 0.3mm (12 mil) | Standard clearance |
| **High Voltage Spacing** | 2.5mm (100 mil) | For 100V isolation |
| **Via Size** | 0.6mm hole, 1.0mm pad | Standard |
| **Via Current** | 0.5A per via | De-rate for safety |
| **Solder Mask** | Green LPI | Standard |
| **Silkscreen** | White | Top and bottom |
| **Surface Finish** | ENIG (gold) | Or HASL lead-free |

### Electrical Specifications

| Parameter | Value |
|-----------|-------|
| **Maximum Voltage** | 100V DC buses |
| **Maximum Current** | 10A continuous per trace |
| **Isolation** | 2.5mm creepage/clearance |
| **Impedance Control** | Not required (digital only) |

---

## Layer Stackup

### 4-Layer Configuration

```
┌─────────────────────────────────────────────────┐
│  Layer 1 (Top)    - Signal + Power (2 oz Cu)   │  ← Components here
├─────────────────────────────────────────────────┤
│  Prepreg (~0.2mm)                               │
├─────────────────────────────────────────────────┤
│  Layer 2 (Inner)  - GND Plane (1 oz Cu)        │  ← Solid ground
├─────────────────────────────────────────────────┤
│  Core (~1.2mm)                                  │
├─────────────────────────────────────────────────┤
│  Layer 3 (Inner)  - Power Planes (1 oz Cu)     │  ← +12V, +15V, +5V
├─────────────────────────────────────────────────┤
│  Prepreg (~0.2mm)                               │
├─────────────────────────────────────────────────┤
│  Layer 4 (Bottom) - Signal + Power (2 oz Cu)   │  ← Optional components
└─────────────────────────────────────────────────┘

Total thickness: 1.6mm
```

### Layer Purposes

**Layer 1 (Top - 2oz):**
- MOSFETs (IRFZ44N), TLP250 gate drivers, power connectors
- High-current DC bus traces (up to 10mm wide for 10A)
- PWM signal routing
- Component placement

**Layer 2 (Inner - 1oz) - GND Plane:**
- Solid copper pour (as much as possible)
- Minimal splits (only for isolation)
- Connects all GND points with low impedance
- Provides return path for signals
- Heat spreading

**Layer 3 (Inner - 1oz) - Power Planes:**
- Separate pours for each voltage:
  - +50V_DC1 (H-Bridge 1 supply)
  - +50V_DC2 (H-Bridge 2 supply)
  - +15V (gate driver supply)
  - +5V (sensor supply)
  - +3.3V (logic supply)
- Keep pours separated by > 2mm
- Use thermal relief for vias

**Layer 4 (Bottom - 2oz):**
- Sensing circuits (AMC1301, ACS724)
- Control connectors
- Auxiliary power circuits
- Additional routing if needed

---

## Component Placement Strategy

### Principle: Minimize Loop Area

**High-current loops** create EMI and voltage spikes. Minimize loop area!

### H-Bridge 1 Placement (Example for one bridge)

```
                    DC Input J1
                        │
         ┌──────────────┼──────────────┐
         │       C_bulk (1000µF)       │
         │       C_bypass (1µF × 4)    │
         │                             │
    ┌────▼────┐                   ┌────▼────┐
    │   Q1    │                   │   Q3    │
    │  IGBT   │                   │  IGBT   │
    │ (TO-247)│                   │ (TO-247)│
    └────┬────┘                   └────┬────┘
         │                             │
         │   ┌─────────────────┐      │
         └───┤  OUTPUT J3      ├──────┘
             └─────────────────┘
         │                             │
    ┌────┴────┐                   ┌────┴────┐
    │   Q2    │                   │   Q4    │
    │  IGBT   │                   │  IGBT   │
    │ (TO-247)│                   │  (TO-247)│
    └────┬────┘                   └────┬────┘
         │                             │
         └──────────────┬──────────────┘
                       GND

Gate Drivers (DIP-14):
    U1: IR2110 ──► Q1, Q2 (close to IGBTs)
    U2: IR2110 ──► Q3, Q4 (close to IGBTs)

Bootstrap components:
    D_bs, C_bs (10µF) - within 10mm of IR2110
```

### Placement Rules

#### 1. Power Stage (Q1-Q4 and capacitors)

**Requirements:**
- Keep DC bus capacitors **< 10mm from IGBT collectors**
- Bypass ceramics (1µF × 4) **< 5mm from IGBT collectors**
- Minimize trace length from cap to IGBT
- IGBTs in a cluster (easy heatsinking)

**Orientation:**
- IGBTs facing same direction (collectors together)
- Allow heatsink mounting (keep area clear)
- Leave 5mm clearance around IGBTs for airflow

#### 2. Gate Drivers (U1-U4)

**Requirements:**
- Place IR2110 **< 20mm from IGBT gates**
- Gate resistors (10Ω) **immediately** at IGBT gate pin
- Bootstrap diode and cap **< 10mm from VB/VS pins**
- VCC bypass caps **< 5mm from VCC pin**

**Trace Lengths (keep short!):**
- HO/LO to gate resistor: < 10mm
- Gate resistor to IGBT gate: < 10mm
- VS to IGBT emitter: < 10mm (high-side emitter)

#### 3. Sensing Circuits

**Requirements:**
- Place on **opposite side** of board from power switches
- Keep away from high dv/dt nodes (IGBT collectors)
- Use guard rings around sensitive analog circuits
- Filter components close to sensor ICs

#### 4. Power Supplies

**Requirements:**
- Isolated DC-DC converters in **separate area** from switching
- Input/output filtering close to converter pins
- Keep switching loop (inside converter) away from sensitive circuits

---

## Power Routing Guidelines

### DC Bus Routing (High Current Paths)

#### Trace Width Calculation

**Formula (IPC-2221):**
```
Width (mm) = (Current / (k × ΔT^0.44))^(1/0.725) × 0.048

Where:
- Current in Amps
- k = 0.048 for external layers (2oz copper)
- ΔT = temperature rise (°C), typically 10-20°C
```

**Example for 10A, 10°C rise, 2oz copper:**
```
Width = (10 / (0.048 × 10^0.44))^(1/0.725) × 0.048
Width ≈ 5.5mm
```

**Recommended Widths:**

| Current | Trace Width (2oz) | Notes |
|---------|-------------------|-------|
| 1A | 0.5mm (20 mil) | Minimum |
| 2A | 1.0mm (40 mil) | |
| 5A | 2.5mm (100 mil) | |
| 10A | 5.5mm (220 mil) | Max current |
| 15A | 10mm (400 mil) | Use copper pour |

#### DC Bus Layout

**Priority 1: Minimize commutation loop**

```
Commutation Loop (most critical):

    Cbypass ─┬─► IGBT Collector
             │        │
             │        │ (switch opens)
             │        ↓
             └──◄ IGBT Emitter

This loop must be TINY (< 50mm perimeter)
```

**Implementation:**
1. Place bypass capacitors **directly adjacent** to IGBT
2. Use **wide, short traces** (or copper pours)
3. Use **multiple vias** (10+) to inner power plane
4. Top layer: C_bypass → IGBT (direct connection)
5. Inner layer: Power plane provides return path

**Priority 2: Bulk capacitance**

```
DC Input ──► C_bulk (1000µF) ──► C_bypass ──► IGBT
         │                                   │
         └──────────────GND──────────────────┘

Bulk cap can be 20-50mm away (handles low frequency)
Bypass caps must be < 5mm (handles switching transients)
```

#### Power Plane Connections

**Use stitching vias:**
- Via array: 4×4 vias (16 total) near high-current components
- Via spacing: 2-3mm apart
- Purpose: Low inductance connection to plane

**Example via array for IGBT collector:**

```
    Collector pad (TO-247)
           │
    ┌──────▼──────┐
    │  ● ● ● ●   │  ← 4 vias in a row
    │  ● ● ● ●   │  ← 4 vias in a row
    │  ● ● ● ●   │  ← 4 vias in a row
    │  ● ● ● ●   │  ← 4 vias in a row
    └─────────────┘

    16 vias × 0.5A = 8A capacity (safe for 10A peak)
```

---

## Signal Routing Guidelines

### PWM Signal Routing

**Requirements:**
- Keep traces short (< 100mm)
- Route away from power traces
- Use ground plane as return (Layer 2)
- Add series termination resistor (100Ω) near source

**Routing technique:**

```
MCU ──100Ω──► ┌─────────────┐ ──► IR2110 HIN
              │   PCB trace   │
              │   (over GND)  │
              └─────────────┘
                    ↕ (capacitance to GND plane)
```

### Gate Drive Signal Routing

**Critical paths:**
1. IR2110 HO → Gate resistor → IGBT gate (Q1)
2. IR2110 LO → Gate resistor → IGBT gate (Q2)

**Requirements:**
- **Minimize inductance** (short, wide traces)
- Route on **top layer only** (don't use vias if possible)
- Keep gate trace **< 10mm total length**
- Use **0.5mm (20 mil) trace width** minimum

**Kelvin connection for gate:**

```
         Gate resistor (10Ω)
              ┌───┐
    HO ───────┤   ├─────┬──► IGBT Gate
              └───┘     │
                        │
                       10k to Emitter (separate trace)
```

### Bootstrap Traces

**Critical:** VS and VB traces carry high dv/dt (fast-switching).

**Routing:**
- Keep D_bootstrap and C_bootstrap **very close** to IR2110
- Use **short, direct traces**
- **No sharp corners** (use 45° or curved)
- Trace width: 0.5mm minimum

**Layout:**

```
    +15V ───┬──► D_bs (UF4007)
            │         │
           10µF      VB (pin 5) IR2110
                      │
                     VS (pin 7) ───► Q1 Emitter (floating)
                                      │
                                      └─► Midpoint node
```

---

## Thermal Management

### IGBT Heatsinking

**Calculation:**

```
Thermal resistance calculation:
θJA = θJC + θCS + θSA

Where:
- θJC = Junction-to-case (IGBT): 0.5°C/W (from datasheet)
- θCS = Case-to-sink (thermal pad): 0.3°C/W
- θSA = Sink-to-ambient (heatsink): 5°C/W

Total: θJA = 5.8°C/W

For Tamb = 50°C, Tjmax = 125°C:
Pdiss = (Tjmax - Tamb) / θJA = (125-50) / 5.8 = 12.9W per IGBT

Check: At 50V, 5A, 2% duty cycle:
Pswitch = 50V × 5A × 0.02 = 5W (OK, < 12.9W)
```

**Heatsink Selection:**

| Heatsink | θSA (°C/W) | Size (mm) | Mount | Price |
|----------|------------|-----------|-------|-------|
| **Small** | 10°C/W | 40×40×20 | TO-247 × 2 | $3 |
| **Medium** | 5°C/W | 60×50×25 | TO-247 × 4 | $6 |
| **Large** | 2.5°C/W | 100×50×30 | TO-247 × 8 | $12 |

**Recommended:** Medium heatsink (5°C/W) for 500W continuous operation.

### PCB Copper Heat Spreading

**Use large copper pours:**
- Connect IGBT tabs (collectors/emitters) to large areas
- Use top copper as heatsink (2oz provides some cooling)
- Add thermal vias under IGBT pads (connect to inner planes)

**Thermal via array (under IGBT tab):**

```
    IGBT Package Outline
    ┌─────────────────┐
    │                 │
    │  ● ● ● ● ● ●   │  ← Thermal vias (0.6mm holes)
    │  ● ● ● ● ● ●   │
    │  ● ● ● ● ● ●   │  6×6 array = 36 vias
    │                 │  Transfers heat to inner planes
    └─────────────────┘
```

### Forced Air Cooling

**For 500W continuous operation:**
- **Required:** 20 CFM fan (40mm × 40mm)
- **Placement:** Blow across heatsinks
- **Direction:** Front-to-back (exhaust hot air)

---

## EMI/EMC Considerations

### High dv/dt Nodes (IGBT Collectors)

**Problem:** Collectors switch 0V → 50V in ~100ns → dv/dt = 500 V/µs

**Solutions:**

1. **Snubber circuits** (already in design)
   - 47Ω + 100nF across each IGBT
   - Damp voltage ringing

2. **Guard rings** around sensitive circuits
   - GND trace around analog sensors
   - Connected to Layer 2 GND plane with vias

3. **Keep-out zones**
   - No sensitive traces under IGBT collectors
   - Minimum 10mm spacing to sensor circuits

### Common-Mode Noise

**Problem:** Fast dv/dt couples to GND plane through parasitic capacitance.

**Solutions:**

1. **Y-capacitors** (line-to-ground)
   - 1-10nF ceramic, 250VAC rated
   - Between DC bus and chassis ground
   - Helps with EMI compliance

2. **Common-mode choke** on AC output
   - Reduces conducted emissions
   - Ferrite core, 1-10mH

### Differential-Mode Noise

**Problem:** PWM switching creates current harmonics.

**Solution:**

1. **Output LC filter** (already in design)
   - 500µH + 10µF @ 10kHz
   - Attenuates switching frequency by 40 dB

2. **Input capacitance** (already in design)
   - 1000µF + 4µF ceramic
   - Provides high-frequency bypass

---

## Manufacturing Files

### Gerber Files (RS-274X format)

Required layers:
1. **Top Copper** (*.GTL)
2. **Bottom Copper** (*.GBL)
3. **Inner Layer 2 (GND)** (*.G2L)
4. **Inner Layer 3 (Power)** (*.G3L)
5. **Top Solder Mask** (*.GTS)
6. **Bottom Solder Mask** (*.GBS)
7. **Top Silkscreen** (*.GTO)
8. **Bottom Silkscreen** (*.GBO)
9. **Board Outline** (*.GKO)
10. **Drill File** (*.TXT or *.DRL)

### Pick-and-Place File

**CSV format:**

```
Designator, X, Y, Rotation, Layer, Comment
Q1, 50.0, 75.0, 90, Top, IKW15N120H3
Q2, 50.0, 65.0, 90, Top, IKW15N120H3
U1, 35.0, 70.0, 0, Top, IR2110PBF
C1, 45.0, 77.0, 0, Top, 1000uF
...
```

### Bill of Materials (BOM)

**CSV format with required columns:**
- Designator (e.g., Q1, U1, R1)
- Comment/Value (e.g., IKW15N120H3, 10Ω)
- Footprint (e.g., TO-247-3, DIP-14)
- Manufacturer
- Manufacturer Part Number
- Quantity

---

## Assembly Process

### Recommended Assembly Flow

#### Option A: Manual Assembly (Prototype)

**Step 1: Solder SMD components first**
1. Apply solder paste to pads (stencil recommended)
2. Place SMD components (resistors, capacitors, ICs)
3. Reflow using hot air or reflow oven
   - Profile: 150°C preheat, 240°C peak, 60s above 220°C

**Step 2: Through-hole components**
1. Insert through-hole parts (connectors, IGBTs, capacitors)
2. IGBTs: Use thermal paste on mounting surface
3. Solder from bottom side
4. Trim leads

**Step 3: Heatsink mounting**
1. Clean IGBT surfaces
2. Apply thermal paste (thin, even layer)
3. Place thermal pads (if using electrically isolated heatsinks)
4. Mount heatsink with screws
5. **Torque:** 0.5 Nm (hand-tight, don't crack package)

**Step 4: Inspection**
1. Visual inspection (shorts, cold joints, polarity)
2. Continuity test (all GND points connected)
3. Isolation test (DC buses isolated from GND)

#### Option B: PCB Assembly Service

**Recommended for production quantities (> 10 units):**

1. **JLCPCB:** $20-40 per board (assembled)
2. **PCBWay:** $25-50 per board
3. **Seeed Fusion:** $30-45 per board

**Files needed:**
- Gerbers (zipped)
- BOM (CSV)
- Pick-and-place (CSV)
- Assembly drawing (PDF)

---

## PCB Testing Checklist

### Pre-Power Tests

- [ ] Visual inspection (no shorts, correct polarity)
- [ ] Continuity: All GND points connected (< 1Ω)
- [ ] Isolation: DC+ to GND (> 10MΩ)
- [ ] Isolation: DC+ to GND (> 10MΩ)
- [ ] Component orientation (ICs, diodes, capacitors)
- [ ] Solder joints quality (no cold joints, bridges)

### Low-Voltage Tests (12V)

- [ ] Apply +15V to gate driver VCC
- [ ] Measure VCC at each IR2110 (14.5-15.5V)
- [ ] Apply +12V to DC bus
- [ ] Measure DC bus voltage (11.5-12.5V)
- [ ] Check quiescent current (< 100mA)
- [ ] Apply PWM signals (low duty cycle, 10%)
- [ ] Verify gate signals with scope (0-15V)
- [ ] Check midpoint voltage switches correctly

### Full Power Tests (50V)

⚠️ **High voltage - extreme caution required!**

- [ ] Discharge capacitors procedure ready
- [ ] Emergency stop accessible
- [ ] Apply +50V DC (current limit 2A initially)
- [ ] Monitor for smoke, smell, overheating
- [ ] Gradually increase current limit
- [ ] Test with resistive load (25Ω, 100W)
- [ ] Measure output waveform quality
- [ ] Check IGBT temperatures (< 80°C)
- [ ] Verify efficiency (Pout / Pin > 90%)

---

**NEXT:** See ASSEMBLY-GUIDE.md for detailed step-by-step assembly with photos/diagrams.
**BACK:** POWER-STAGE-COMPLETE.md for complete component specifications.
