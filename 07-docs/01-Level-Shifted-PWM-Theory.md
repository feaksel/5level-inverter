# Level-Shifted PWM Modulation Theory

**Document Type:** Educational / Theoretical
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0

---

## Table of Contents

1. [Introduction](#introduction)
2. [Multilevel Inverter Fundamentals](#multilevel-inverter-fundamentals)
3. [5-Level Cascaded H-Bridge Topology](#5-level-cascaded-h-bridge-topology)
4. [PWM Modulation Strategies](#pwm-modulation-strategies)
5. [Level-Shifted Carrier PWM](#level-shifted-carrier-pwm)
6. [Mathematical Analysis](#mathematical-analysis)
7. [Advantages and Limitations](#advantages-and-limitations)
8. [Practical Implementation](#practical-implementation)
9. [References](#references)

---

## Introduction

This document provides a comprehensive explanation of **level-shifted carrier PWM modulation** as implemented in our 5-level cascaded H-bridge multilevel inverter.

### Purpose

Multilevel inverters offer superior harmonic performance compared to conventional 2-level inverters by synthesizing AC waveforms from multiple DC voltage levels. Understanding the modulation strategy is crucial for:

- Minimizing total harmonic distortion (THD)
- Optimizing switch utilization
- Achieving balanced power distribution
- Implementing digital control systems

### Scope

This document covers:
- Theoretical foundations of multilevel modulation
- Comparison of modulation strategies
- Detailed explanation of level-shifted carrier PWM
- Mathematical derivations and analysis
- Practical implementation considerations

---

## Multilevel Inverter Fundamentals

### Why Multilevel Inverters?

Traditional 2-level inverters can only produce two voltage levels (e.g., +Vdc and -Vdc), resulting in:
- High dv/dt (voltage rate of change)
- Significant harmonic content
- Large filter requirements
- EMI issues

**Multilevel inverters** synthesize AC waveforms from multiple discrete voltage levels, providing:

1. **Lower THD** - More levels ≈ closer to pure sine wave
2. **Reduced dv/dt** - Smaller voltage steps, less stress on insulation
3. **Smaller filters** - Less harmonic filtering needed
4. **Higher voltage capability** - Series connection of switches
5. **Better efficiency** - Lower switching losses at higher power

### Number of Levels vs. Performance

For an m-level inverter:

**Number of voltage levels:** m
**Number of switching states:** Typically 2^(m-1)
**THD improvement:** Approximately inversely proportional to number of levels

Example:
- 2-level inverter: THD ≈ 30-40%
- 5-level inverter: THD ≈ 3-8%
- 9-level inverter: THD ≈ 1-3%

Our **5-level inverter** provides an excellent balance between:
- Performance (THD < 5%)
- Complexity (2 H-bridges = 8 switches)
- Cost

---

## 5-Level Cascaded H-Bridge Topology

### Topology Description

Our inverter uses **2 cascaded H-bridges** (CHB), each supplied by an isolated DC source:

```
     +Vdc1-    +Vdc2-
       |         |
    [H-Bridge1][H-Bridge2] → Output
       |         |
     -Vdc1-    -Vdc2-
```

**Each H-bridge contains 4 switches:**
- H-Bridge 1: S1, S2, S3, S4
- H-Bridge 2: S5, S6, S7, S8

**Total:** 8 power switches (MOSFETs or IGBTs)

### Voltage Levels Synthesis

With Vdc1 = Vdc2 = 50V, we can produce **5 discrete voltage levels:**

| Level | H-Bridge 1 | H-Bridge 2 | Output Voltage |
|-------|-----------|-----------|----------------|
| +2Vdc | +50V | +50V | **+100V** |
| +Vdc  | +50V | 0V   | **+50V**  |
| 0     | 0V   | 0V   | **0V**    |
| -Vdc  | -50V | 0V   | **-50V**  |
| -2Vdc | -50V | -50V | **-100V** |

**Key advantage:** Series connection allows lower voltage-rated switches while achieving higher output voltage.

### H-Bridge States

Each H-bridge can produce 3 states:

1. **Positive:** S1 and S4 ON → +Vdc
2. **Zero:** S1 and S2 ON (or S3 and S4 ON) → 0V
3. **Negative:** S2 and S3 ON → -Vdc

**Critical:** S1-S2 and S3-S4 are complementary pairs and must NEVER be ON simultaneously (shoot-through protection required).

---

## PWM Modulation Strategies

Several modulation strategies exist for multilevel inverters:

### 1. Phase-Shifted Carrier PWM

**Concept:** Multiple triangular carriers with phase shifts.

- Carriers have **same amplitude and frequency**
- Phase shift = 360° / (number of bridges)
- For 2 bridges: Carrier 2 shifted by 180°

**Characteristics:**
- Natural current sharing between bridges
- Good harmonic performance
- Complex to implement digitally

### 2. Level-Shifted Carrier PWM

**Concept:** Multiple triangular carriers at different amplitude levels.

- Carriers have **same frequency but different DC offsets**
- All carriers compared with single reference
- Simpler digital implementation

**Variants:**
- Phase Disposition (PD)
- Phase Opposition Disposition (POD)
- Alternative Phase Opposition Disposition (APOD)

**Our implementation:** Level-shifted (similar to PD)

### 3. Space Vector Modulation (SVM)

**Concept:** Vector-based switching state selection.

- Complex calculations
- Optimal switch utilization
- Typically used in motor drives

### Comparison

| Strategy | THD | Implementation | Voltage Utilization | Real-time |
|----------|-----|----------------|---------------------|-----------|
| Phase-Shifted | Good | Complex | Good | Moderate |
| **Level-Shifted** | **Excellent** | **Simple** | **Excellent** | **Easy** |
| Space Vector | Excellent | Very Complex | Optimal | Difficult |

**We chose level-shifted carrier PWM** for its simplicity and excellent performance.

---

## Level-Shifted Carrier PWM

### Principle of Operation

**Core idea:** Compare a single sinusoidal reference with multiple triangular carriers positioned at different DC levels.

### Carrier Arrangement

For our 5-level inverter (2 H-bridges):

**Carrier 1 (H-Bridge 1):** -1.0 to 0.0 (lower level)
**Carrier 2 (H-Bridge 2):** 0.0 to +1.0 (upper level)

**Reference signal:** -1.0 to +1.0 (sinusoidal, 50Hz)

### Visual Representation

```
 +1.0 ┌─────────────────────────────┐
      │    Carrier 2 (Triangle)     │ ← Upper level
  0.0 ├─────────────────────────────┤
      │    Carrier 1 (Triangle)     │ ← Lower level
 -1.0 └─────────────────────────────┘

      ───── Sine Reference (50Hz) ────
```

### Switching Logic

For each H-bridge:

**H-Bridge 1:**
```
IF (sine_ref > carrier1):
    Output = +Vdc1
ELSE:
    Output = 0V or -Vdc1 (depending on sine polarity)
```

**H-Bridge 2:**
```
IF (sine_ref > carrier2):
    Output = +Vdc2
ELSE:
    Output = 0V or -Vdc2 (depending on sine polarity)
```

### Modulation Index

The **modulation index (MI)** controls output voltage amplitude:

```
MI = V_out_desired / V_out_max
```

Where:
- V_out_max = 2 × Vdc (for 2 bridges)
- MI ranges from 0 to 1 (0% to 100%)

**Examples:**
- MI = 0.5 → 50V RMS output (from 100V max)
- MI = 0.8 → 80V RMS output
- MI = 1.0 → 100V RMS output (full voltage)

Implementation:
```c
sine_reference = MI × sin(2πft)
```

### Carrier Frequency

The **carrier frequency** is the PWM switching frequency:

- Our implementation: **5 kHz**
- Industry typical: 2-20 kHz

**Trade-offs:**
- Higher frequency → Lower harmonic content, but higher switching losses
- Lower frequency → Higher losses in output filter

**Selection criteria:**
- Switching device capabilities
- Acoustic noise considerations
- EMI requirements
- Efficiency targets

---

## Mathematical Analysis

### Harmonic Analysis

The output voltage can be expressed as a Fourier series:

```
V_out(t) = Σ [A_n × sin(nωt + φ_n)]
           n=1,2,3,...
```

Where:
- A_n = amplitude of nth harmonic
- ω = fundamental frequency (2π × 50 Hz)
- φ_n = phase of nth harmonic

### THD Calculation

Total Harmonic Distortion is defined as:

```
        _______________
       /  ∞
      / Σ A_n²
     /  n=2
THD = ─────────  × 100%
         A_1
```

Where A_1 is the fundamental amplitude.

**For 5-level inverter with level-shifted PWM:**

Theoretical THD (unfiltered):
```
THD ≈ 100% × √(Σ(A_h²)) / A_1
```

With proper modulation:
- Fundamental: ~98% of output power
- Harmonics primarily at carrier frequency multiples
- **Expected THD: 3-5% (unfiltered)**

### Switching Frequency Selection

Carrier frequency affects harmonic distribution:

**Lower sideband harmonics:**
```
f_h = f_c - k×f_m
```

**Upper sideband harmonics:**
```
f_h = f_c + k×f_m
```

Where:
- f_c = carrier frequency (5 kHz)
- f_m = modulation frequency (50 Hz)
- k = 1, 2, 3, ...

**For our system:**
- First harmonic group centered at 5 kHz
- Second group at 10 kHz
- Easy to filter (> 100× fundamental)

### Voltage Utilization

Maximum achievable output voltage:

```
V_out_max = (Number of bridges) × Vdc × MI
```

For MI = 1.0:
```
V_out_max = 2 × 50V × 1.0 = 100V (peak)
          = 70.7V RMS
```

**Over-modulation (MI > 1.0):**
- Possible but increases THD
- Can be used for brief periods
- Requires careful control

---

## Advantages and Limitations

### Advantages of Level-Shifted Carrier PWM

1. **Simplicity**
   - Single reference signal
   - Easy digital implementation
   - Straightforward carrier generation

2. **Performance**
   - Low THD (3-5%)
   - Good voltage utilization
   - Balanced switch stress

3. **Scalability**
   - Easy to extend to more levels
   - Same algorithm for n levels
   - Modular implementation

4. **Real-time Implementation**
   - Low computational requirements
   - Suitable for microcontrollers
   - Predictable execution time

5. **Control Flexibility**
   - Independent MI control
   - Frequency changes straightforward
   - Compatible with PI/PR controllers

### Limitations

1. **Isolated DC Sources Required**
   - Each H-bridge needs isolated supply
   - More complex power supply design
   - Higher cost than single source

2. **Switch Count**
   - 4 switches per bridge
   - More devices than some topologies
   - But simpler than NPC/flying capacitor

3. **DC Voltage Balance**
   - Must maintain equal Vdc for each bridge
   - Monitoring and control needed
   - Unbalance causes THD increase

4. **Protection Complexity**
   - 8 switches to protect
   - Dead-time insertion critical
   - Fault detection more complex

### Comparison with Alternatives

**vs. 2-Level Inverter:**
- ✅ Much lower THD (5% vs 30%)
- ✅ Lower dv/dt stress
- ❌ More switches and drivers
- ❌ Isolated supplies needed

**vs. 3-Level NPC:**
- ✅ Simpler switch configuration
- ✅ Modular/scalable design
- ❌ Isolated supplies required
- ≈ Similar THD performance

**vs. Flying Capacitor:**
- ✅ No voltage balancing issues
- ✅ More robust
- ❌ Isolated supplies
- ≈ Similar complexity

---

## Practical Implementation

### Digital Implementation (STM32)

**Step 1: Carrier Generation**
```c
// Level-shifted triangular carriers
float carrier1 = triangle_wave(t, f_carrier) - 0.5;  // -1 to 0
float carrier2 = triangle_wave(t, f_carrier) + 0.5;  //  0 to +1
```

**Step 2: Reference Generation**
```c
// Sinusoidal reference with MI
float sine_ref = MI * sin(2 * PI * f_out * t);  // -MI to +MI
```

**Step 3: Comparison**
```c
// PWM generation for each bridge
bool pwm1_high = (sine_ref > carrier1);
bool pwm2_high = (sine_ref > carrier2);
```

**Step 4: Dead-time Insertion**
```c
// Hardware timer dead-time (1μs typical)
// Prevents shoot-through in H-bridges
```

### FPGA Implementation

Advantages of FPGA:
- **Parallel processing** - All carriers simultaneously
- **No jitter** - Deterministic timing
- **High resolution** - 16-bit carriers
- **Scalable** - Easy to add levels

See `03-fpga/` directory for complete Verilog implementation.

### Key Parameters

**Switching Frequency:**
```
f_carrier = 5 kHz (our choice)
Range: 2-20 kHz typical
```

**Dead-time:**
```
t_dead = 1 μs (our choice)
Calculation: Based on gate driver + switch turn-on/off times
```

**Modulation Index:**
```
MI = 0.8 to 1.0 (normal operation)
MI = 0.5 (reduced voltage)
```

### Carrier Synchronization

**Critical:** Both carriers must be synchronized:
- Same frequency
- Phase-locked
- Updated simultaneously

In our implementation:
- **STM32:** TIM1 (master) synchronizes with TIM8 (slave)
- **FPGA:** Single carrier generator with level-shifting

---

## References

### Academic Papers

1. Rodriguez, J., et al. "Multilevel Inverters: A Survey of Topologies, Controls, and Applications." IEEE Transactions on Industrial Electronics, 2002.

2. McGrath, B. P., and Holmes, D. G. "Multicarrier PWM Strategies for Multilevel Inverters." IEEE Transactions on Industrial Electronics, 2002.

3. Tolbert, L. M., et al. "Multilevel Converters for Large Electric Drives." IEEE Transactions on Industry Applications, 1999.

### Books

4. Rashid, M. H. "Power Electronics Handbook." Butterworth-Heinemann, 2017.

5. Kazmierkowski, M. P., et al. "Control in Power Electronics: Selected Problems." Academic Press, 2002.

### Application Notes

6. Texas Instruments, "Multilevel Inverter Design Guide," SLVA372, 2010.

7. Infineon, "Application Note: IGBTs in Multilevel Converters," 2015.

### Standards

8. IEEE Standard 519-2014: "Recommended Practice for Harmonic Control in Electric Power Systems."

9. IEC 61000-3-2: "Limits for Harmonic Current Emissions."

---

## Appendix: Comparison Table

### Modulation Strategy Comparison

| Parameter | Level-Shifted | Phase-Shifted | Space Vector |
|-----------|--------------|---------------|--------------|
| **THD** | 3-5% | 4-6% | 2-4% |
| **CPU Load** | Low | Medium | High |
| **Memory** | Low | Low | High |
| **Scalability** | Excellent | Good | Limited |
| **Voltage Utilization** | ~97% | ~94% | ~100% |
| **Implementation** | Simple | Moderate | Complex |
| **Real-time** | Easy | Moderate | Difficult |

### Topology Comparison

| Topology | Switches/Level | Isolated Supplies | Complexity |
|----------|---------------|-------------------|------------|
| **Cascaded H-Bridge** | **4n** | **Yes (n)** | **Low** |
| Neutral Point Clamped | 2(n-1) | No | Medium |
| Flying Capacitor | 2(n-1) | No | High |
| Modular Multilevel | 2n | No | Very High |

---

**Document End**

*For implementation details, see:*
- *CLAUDE.md - Project guide*
- *02-embedded/stm32/ - STM32 implementation*
- *03-fpga/ - FPGA implementation*
