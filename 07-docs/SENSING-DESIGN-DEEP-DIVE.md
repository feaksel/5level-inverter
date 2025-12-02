# Sensing Design Deep Dive
## Understanding Comparators and ASIC Integration

**Version:** 1.0
**Date:** 2025-12-02
**Purpose:** Detailed explanation of Sigma-Delta ADC architecture and ASIC migration

---

## Table of Contents

1. [Why Comparators in Sigma-Delta ADC](#why-comparators-in-sigma-delta-adc)
2. [How Sigma-Delta ADC Works](#how-sigma-delta-adc-works)
3. [Comparator Requirements and Selection](#comparator-requirements-and-selection)
4. [ASIC Integration Approaches Explained](#asic-integration-approaches-explained)
5. [Design Trade-offs Analysis](#design-trade-offs-analysis)

---

## Why Comparators in Sigma-Delta ADC

### The Fundamental Problem

**Goal:** Convert analog voltage (0-3.3V) to digital number (12-bit)

**Traditional approach (SAR ADC):**
- Needs precision voltage ladder (expensive, many components)
- Needs sample-and-hold circuit
- Needs complex control logic

**Sigma-Delta approach:**
- Only needs 1 comparator (cheap!)
- Trades speed for resolution via oversampling
- Most complexity is digital (easy in FPGA/ASIC)

### What is a Comparator?

**Simplest analog circuit - just answers one question:**

```
Is Input A > Input B?
├─ YES → Output = HIGH (1)
└─ NO  → Output = LOW (0)
```

**Example: LM339 Comparator**

```
      +5V
       │
    ┌──┴──┐
    │  +  │── Output (digital: 0V or 5V)
VIN ─┤     │
    │  -  │
VREF─┤     │
    └─────┘
     LM339

If VIN > VREF:  Output = 5V (HIGH)
If VIN < VREF:  Output = 0V (LOW)
```

**That's it!** Just a 1-bit decision maker.

---

## How Sigma-Delta ADC Works

### The Clever Trick: Oversampling + Feedback

Instead of directly converting voltage to many bits, we:
1. **Sample very fast** (1 MHz instead of 10 kHz = 100× oversampling)
2. **Use 1-bit comparator** (simplest possible)
3. **Feed result back** to create error signal
4. **Accumulate many 1-bit samples** to get high resolution

### Step-by-Step Operation

```
┌─────────────────────────────────────────────────────────────┐
│               Sigma-Delta ADC Loop                          │
│                                                             │
│  Analog Input ──┬──► [Σ] ──► [∫] ──► [Comparator] ──┐     │
│  (0-2V)         │     ▲       │           │          │     │
│                 │     │       │           ▼          │     │
│                 │     │   Integrator   1-bit        │     │
│                 │     │   (digital)    output       │     │
│                 │     │                  │          │     │
│                 │     └────[1-bit DAC]───┘          │     │
│                 │           (FPGA GPIO)             │     │
│                 │                                    │     │
│                 └────────────────────────────────────┘     │
│                                                             │
│         ▼                                                   │
│    1-bit stream @ 1 MHz                                     │
│    Example: 1 0 1 1 0 1 1 1 0 1 ...                        │
│                                                             │
│         ▼                                                   │
│    [Decimation Filter]                                      │
│    Average 100 samples                                      │
│                                                             │
│         ▼                                                   │
│    12-bit result @ 10 kHz                                   │
│    Example: 2785 (represents input voltage)                │
└─────────────────────────────────────────────────────────────┘
```

### Example: Converting 1.65V Input

**Setup:**
- Input voltage: 1.65V (exactly half of 3.3V)
- Comparator reference: Varies (from 1-bit DAC feedback)
- Sampling: 1 MHz

**What Happens Over Time:**

| Time | Input | DAC Feedback | Integrator | Comp Result | Output Bit |
|------|-------|--------------|------------|-------------|------------|
| 1µs  | 1.65V | 0V           | +1.65      | HIGH        | 1 |
| 2µs  | 1.65V | 3.3V         | -1.65      | LOW         | 0 |
| 3µs  | 1.65V | 0V           | +1.65      | HIGH        | 1 |
| 4µs  | 1.65V | 3.3V         | -1.65      | LOW         | 0 |
| ... | ... | ... | ... | ... | ... |

**Pattern:** `1 0 1 0 1 0 1 0...` (50% ones)

**After decimation (average 100 samples):**
- Count: 50 ones, 50 zeros
- Result: 50% = 2048 (out of 4096 for 12-bit)
- Voltage: 2048 / 4096 × 3.3V = 1.65V ✓

### Why This Works

**Key insight:** The comparator oscillates around the input voltage, creating a **density-modulated bitstream**:

- **Low input (0.5V):** Bitstream = `0 0 0 1 0 0 0 1...` (few ones, ~15%)
- **Mid input (1.65V):** Bitstream = `0 1 0 1 0 1 0 1...` (half ones, 50%)
- **High input (2.8V):** Bitstream = `1 1 1 0 1 1 1 0...` (many ones, ~85%)

**The density of 1's is proportional to the input voltage!**

---

## Comparator Requirements and Selection

### What We Need

For our 1 MHz sampling, 12-bit resolution application:

| Parameter | Requirement | Reason |
|-----------|-------------|--------|
| **Speed** | >1 MHz | Must settle in <1µs |
| **Offset voltage** | <10 mV | Affects accuracy |
| **Hysteresis** | Minimal | Prevents oscillation |
| **Supply** | 3.3V or 5V | Matches FPGA I/O |
| **Output** | Digital (rail-to-rail) | FPGA GPIO compatible |
| **Channels** | 4 (or quad chip) | 4 sensing channels |
| **Cost** | <$1 | Budget constraint |

### Why LM339?

**LM339 Quad Comparator (Selected Choice):**

```
┌─────────────────────────────────────┐
│         LM339 (DIP-14)              │
│                                     │
│  Comparator 1:  Pin 4 (+)           │
│                 Pin 5 (-)           │
│                 Pin 2 (Out)         │
│                                     │
│  Comparator 2:  Pin 6 (+)           │
│                 Pin 7 (-)           │
│                 Pin 1 (Out)         │
│                                     │
│  Comparator 3:  Pin 9 (+)           │
│                 Pin 8 (-)           │
│                 Pin 14 (Out)        │
│                                     │
│  Comparator 4:  Pin 11 (+)          │
│                 Pin 10 (-)          │
│                 Pin 13 (Out)        │
│                                     │
│  Power:         Pin 3 (VCC = 5V)    │
│                 Pin 12 (GND)        │
└─────────────────────────────────────┘
```

**Specifications:**
- Response time: 1.3 µs (fast enough for 1 MHz)
- Offset voltage: 2 mV typical (excellent)
- Supply: 2V to 36V (flexible)
- Output: Open collector (needs pull-up to 3.3V for FPGA)
- **Cost: $0.60 for 4 comparators** (cheap!)
- Package: DIP-14 (easy to solder)

**Perfect match for our needs!**

### Alternative Comparators

| Part | Channels | Speed | Offset | Cost | Notes |
|------|----------|-------|--------|------|-------|
| **LM339** | 4 | 1.3µs | 2mV | $0.60 | ✅ Selected |
| LM393 | 2 | 1.3µs | 2mV | $0.30 | Need 2× chips |
| LM311 | 1 | 200ns | 2mV | $0.50 | Faster but 4× needed |
| TLV3501 | 1 | 4.5ns | 5mV | $2.00 | Overkill for 1MHz |

### Complete Comparator Circuit (1 Channel)

```
Sensor Output (0-2V) ──┬─ 1kΩ ──┬─ 100nF ──┬──────────┐
from AMC1301           │         │          │          │
                       │        GND        GND         │
                       │                               │
FPGA GPIO          ────┴─ 1kΩ ──────────────┘          │
(DAC feedback)                                         │
3.3V/0V                                         ┌──────▼─────┐
                                                │  LM339     │
                                          ┌─────┤  + (Pin 4) │
                                          │     │            │
                                         GND ───┤  - (Pin 5) │
                                                │            │
                                                │  Out ──────┼──┐
                                                │  (Pin 2)   │  │
                                                └────────────┘  │
                                                                │
                                              ┌─────────────────┘
                                              │
                                         10kΩ pull-up
                                              │
                                             3.3V
                                              │
                                      ┌───────┴───────┐
                                      │ FPGA GPIO     │
                                      │ (comp_in[0])  │
                                      └───────────────┘

Operation:
1. Sensor + DAC feedback mix at summing node (RC filter input)
2. RC filter smooths signal (cutoff ~1.6kHz)
3. Comparator compares filtered signal to ground
4. Output HIGH when signal > 0, LOW when signal < 0
5. FPGA reads 1-bit result
```

**Why RC Filter?**
- Prevents aliasing (high-freq noise from affecting 1MHz sampling)
- Smooths DAC output (single GPIO switching creates steps)
- Cutoff: fc = 1/(2π × 1kΩ × 100nF) = 1.6 kHz (below Nyquist)

**Why Pull-up Resistor?**
- LM339 has open-collector output (can only pull LOW)
- Pull-up ensures clean HIGH level for FPGA (3.3V)
- 10kΩ chosen for low power (0.3mA @ 3.3V)

---

## ASIC Integration Approaches Explained

### The ASIC Migration Challenge

**FPGA Implementation:**
```
External:           FPGA:
- LM339 comparator  - Sigma-Delta modulator (Verilog)
- RC filter         - CIC decimator (Verilog)
- Resistors/caps    - Control algorithm (Verilog)
```

**Goal:** Move as much as possible into ASIC for:
- ✅ Lower cost (fewer external parts)
- ✅ Smaller PCB area
- ✅ Better performance (shorter paths)
- ✅ Higher integration (system-on-chip)

**Challenge:** Comparator is **analog** (ASIC needs analog design)

### Three Integration Levels

---

### Level 1: Digital ASIC + External Comparator

**Architecture:**

```
┌──────────────────────────────────────────────────────────────┐
│                    External (PCB)                            │
│                                                              │
│  Sensor ──┬─ RC Filter ──► LM339 ──► ASIC Pin              │
│           │               Comparator  (digital input)       │
│           │                                                 │
│  ASIC Pin ┴─ 1kΩ ────────────┘                             │
│  (DAC)      (feedback)                                      │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    ASIC Chip (Digital)                       │
│                                                              │
│  GPIO Pad ──► Σ-Δ Modulator ──► CIC Filter ──► 12-bit ADC   │
│  (comp in)    (Verilog)          (Verilog)       result     │
│                                                              │
│  GPIO Pad ◄── 1-bit DAC output                              │
│  (DAC out)                                                   │
│                                                              │
│  CPU / Control Algorithm (Verilog)                          │
│  PWM Generator (Verilog)                                    │
└──────────────────────────────────────────────────────────────┘
```

**What Goes in ASIC:**
- ✅ All digital logic (Sigma-Delta, CIC, control)
- ✅ GPIO pads for comparator interface
- ✅ Power management, clocks, etc.

**What Stays External:**
- ❌ LM339 comparator (~$0.60 per 4 channels)
- ❌ RC filters (resistors + caps)
- ❌ Pull-up resistors

**Advantages:**
- ⚡ **Easiest ASIC design** - Pure digital
- ⚡ **Lowest risk** - Proven analog (LM339)
- ⚡ **Direct FPGA port** - Same Verilog code
- ⚡ **Cheap fabrication** - Digital-only process

**Disadvantages:**
- 📉 Still need external comparator chip
- 📉 More PCB area
- 📉 More components to assemble

**Cost Estimate:**
- ASIC chip: ~$5-10 (digital-only, 180nm process)
- External comparator: ~$0.60
- Passives: ~$1
- **Total: ~$7-12**

**Use Case:** First prototype, minimize ASIC risk

---

### Level 2: Mixed-Signal ASIC (On-Chip Comparator)

**Architecture:**

```
┌──────────────────────────────────────────────────────────────┐
│                    External (PCB)                            │
│                                                              │
│  Sensor ──┬─ RC Filter ──► ASIC Analog Pin                  │
│           │                (comparator input)               │
│           │                                                 │
│  ASIC Pin ┴─ 1kΩ ────────┘                                 │
│  (DAC)                                                      │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│           ASIC Chip (Mixed-Signal: Analog + Digital)         │
│                                                              │
│  ┌────────────────────────────────────────┐                 │
│  │        ANALOG BLOCK                    │                 │
│  │                                        │                 │
│  │  Analog    ┌───────────────┐          │                 │
│  │  Pad  ──►  │  Comparator   │          │                 │
│  │  (VIN)     │  (2 transistor│  ──► 1-bit                │
│  │            │   diff pair)  │      output                │
│  │            └───────────────┘          │                 │
│  │                                        │                 │
│  │  Bandgap reference, bias circuits      │                 │
│  └────────────┬───────────────────────────┘                 │
│               │                                             │
│               ▼                                             │
│  ┌────────────────────────────────────────┐                 │
│  │        DIGITAL BLOCK                   │                 │
│  │                                        │                 │
│  │  Σ-Δ Modulator ──► CIC Filter ──► ADC  │                 │
│  │  (Verilog)         (Verilog)      result               │
│  │                                        │                 │
│  │  Control Algorithm, PWM, etc.          │                 │
│  └────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────┘
```

**What Goes in ASIC:**
- ✅ All digital logic (same as Level 1)
- ✅ **Analog comparator** (custom design)
- ✅ Voltage reference (bandgap)
- ✅ Bias circuits
- ✅ Analog/Digital mixed pads

**What Stays External:**
- ❌ RC filter (resistors + caps)
- ❌ DAC feedback resistor

**Comparator Design (Simple Example):**

```
Analog domain inside ASIC:

VDD (1.8V or 3.3V)
    │
    ├──┤ PMOS ├──┬──┤ PMOS ├──┐
    │           │             │
    │      Current Mirror     │
    │           │             │
VIN+ ──┤ NMOS ├─┘        ┌────┤ NMOS ├── VREF
        │                │    │
        │         Differential Pair
        │                │    │
        └────────────────┴────┘
                    │
                   GND

Output: HIGH if VIN+ > VREF, LOW if VIN+ < VREF
```

**Design Complexity:**
- Need analog design expertise
- Requires mixed-signal simulation (SPICE)
- More layout complexity (analog sensitive)
- Process corners, temperature variations

**Advantages:**
- ⚡ **Fewer external parts** (no LM339)
- ⚡ **Smaller PCB**
- ⚡ **Better performance** (shorter analog path)
- ⚡ **Lower power** (optimized on-chip)

**Disadvantages:**
- 📉 **More complex ASIC design**
- 📉 **Requires analog expertise**
- 📉 **Higher fabrication cost** (mixed-signal)
- 📉 **Longer design time**

**Cost Estimate:**
- ASIC chip: ~$15-25 (mixed-signal, 180nm)
- Passives only: ~$1
- **Total: ~$16-26**

**Use Case:** Second iteration, proven digital works, want integration

---

### Level 3: Full Custom ASIC (Everything On-Chip)

**Architecture:**

```
┌──────────────────────────────────────────────────────────────┐
│                    External (PCB)                            │
│                                                              │
│  Sensor ────────────────────► ASIC Analog Pin               │
│  (0-2V direct)                (direct connection)           │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              Full Custom Mixed-Signal ASIC                    │
│                                                              │
│  ┌────────────────────────────────────────┐                 │
│  │        ANALOG BLOCK                    │                 │
│  │                                        │                 │
│  │  Sensor  ┌───────────┐  ┌──────────┐  │                 │
│  │  Input ──┤ On-chip   ├──┤ Comp     │  │                 │
│  │  (analog)│ RC Filter │  │          ├──► 1-bit            │
│  │          │ (integr)  │  └──────────┘  │                 │
│  │          └───────────┘                 │                 │
│  │          ┌───────────┐                 │                 │
│  │  DAC  ◄──┤ 1-bit DAC │                 │                 │
│  │  out     │ (current) │                 │                 │
│  │          └───────────┘                 │                 │
│  │                                        │                 │
│  │  Bandgap ref, biasing, LDO            │                 │
│  └────────────┬───────────────────────────┘                 │
│               │                                             │
│               ▼                                             │
│  ┌────────────────────────────────────────┐                 │
│  │        DIGITAL BLOCK                   │                 │
│  │  Σ-Δ Mod ──► CIC ──► Control ──► PWM   │                 │
│  └────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────┘
```

**What Goes in ASIC:**
- ✅ All digital logic
- ✅ Analog comparator
- ✅ **On-chip RC filter** (active filter or integrated cap)
- ✅ **1-bit current DAC** (instead of GPIO + resistor)
- ✅ **Voltage references**
- ✅ **LDO regulators**
- ✅ Complete system-on-chip

**What Stays External:**
- Minimal: just power supply and programming pins

**Advanced Analog Blocks:**

**On-Chip RC Filter:**
```
Active filter using op-amp + integrated capacitor:

VIN ─┬─ R ──┬───► Op-amp ───► Filtered output
     │       │        │
     │   MOS cap      │
     │       │        │
     └───────┴────────┘
    (on-chip resistor + MOS capacitor)
```

**Current-Mode DAC:**
```
Instead of GPIO + resistor, use current source:

Digital bit ──► [Current switch] ──► Summing node
    0/1           (steers current)     (analog output)
```

**Advantages:**
- ⚡ **Minimal external parts**
- ⚡ **Smallest PCB**
- ⚡ **Best performance**
- ⚡ **True system-on-chip**
- ⚡ **Lowest production cost** (at scale)

**Disadvantages:**
- 📉 **Highest design complexity**
- 📉 **Requires expert team**
- 📉 **Expensive NRE** (non-recurring engineering)
- 📉 **Long development time** (6-12 months)
- 📉 **High risk** (hard to debug analog)

**Cost Estimate:**
- ASIC chip: ~$30-100 (depending on volume)
- Minimal passives: ~$0.50
- **Total: ~$31-101**
- **But:** NRE cost $50k-200k+ (only makes sense for >10k units)

**Use Case:** Production product, high volume, proven design

---

## Design Trade-offs Analysis

### Comparison Matrix

| Feature | Level 1 (Ext Comp) | Level 2 (Mixed) | Level 3 (Full Custom) |
|---------|-------------------|-----------------|---------------------|
| **External Parts** | Comparator + passives | Passives only | Minimal |
| **ASIC Complexity** | Low (digital) | Medium (mixed) | High (full custom) |
| **Design Time** | 1-2 months | 3-6 months | 6-12 months |
| **Design Risk** | Low | Medium | High |
| **Unit Cost (@1k)** | $7-12 | $16-26 | $31-101 |
| **Unit Cost (@100k)** | $4-6 | $8-12 | $2-5 |
| **PCB Area** | Largest | Medium | Smallest |
| **Power** | ~100mW | ~75mW | ~50mW |
| **Performance** | Good | Better | Best |
| **Debugging** | Easy | Medium | Hard |

### Development Path Recommendation

**For Educational/Thesis Project:**

```
Phase 1: FPGA Prototype
├─ Implement in Verilog
├─ Test with LM339
└─ Validate algorithms
    ↓
Phase 2: Level 1 ASIC
├─ Port digital to ASIC
├─ Keep LM339 external
└─ Prove ASIC flow works
    ↓
Phase 3: Level 2 ASIC (optional)
├─ Add on-chip comparator
├─ Mixed-signal design
└─ Reduced external parts
    ↓
Phase 4: Level 3 ASIC (optional)
└─ Full integration (production)
```

**Timeline:**
- FPGA: 2 weeks
- Level 1 ASIC: 2 months (using OpenLane/SkyWater)
- Level 2 ASIC: 4-6 months (with analog design)
- Level 3 ASIC: 6-12 months (full team)

### For SkyWater SKY130 (Free Shuttle)

**Best approach: Level 2**

**Why?**
- ✅ SKY130 has standard cell library comparators
- ✅ Can use pre-designed analog blocks
- ✅ Good balance of integration vs complexity
- ✅ Fits in free shuttle area budget
- ✅ Educational value (learn mixed-signal)

**Resources:**
- Standard cells: https://skywater-pdk.readthedocs.io
- Analog library: https://github.com/efabless/sky130_ef_ip__comparator
- Example designs: https://github.com/efabless/caravel_user_project

**Example comparator from SKY130:**
```verilog
// Use existing comparator from PDK
sky130_fd_sc_hd__comp_1 comp_inst (
    .A(sensor_input),    // Analog input
    .B(reference_voltage),
    .Y(comp_out)         // Digital output
);
```

---

## Summary

### Why Comparator?

1. **Simplest analog component** (just yes/no decision)
2. **Enables oversampling** (trade speed for resolution)
3. **Moves complexity to digital** (easy in FPGA/ASIC)
4. **Cheap external** (LM339 = $0.60)
5. **Can integrate later** (ASIC Level 2/3)

### ASIC Path

**Start simple, integrate gradually:**

```
FPGA (external LM339)
  ↓ Port digital RTL
Level 1 ASIC (external LM339)
  ↓ Add analog comparator
Level 2 ASIC (on-chip comparator)
  ↓ Full integration
Level 3 ASIC (everything on-chip)
```

**Recommendation for thesis:**
- **FPGA stage:** Prove concept
- **Level 1 ASIC:** Safe first ASIC
- **Level 2 ASIC:** If time permits, great learning

**Key insight:** The comparator is the **bridge between analog and digital worlds** - keeping it simple enables powerful digital signal processing!

---

**This explains why our sensing design is so elegant:**
- External sensors (AMC1301, ACS724) → pre-isolated, pre-scaled
- Simple comparator (LM339) → analog-to-1-bit conversion
- Digital FPGA/ASIC → sophisticated processing
- Result: High resolution from simple parts!
