# Understanding the 5-Level Cascaded H-Bridge Inverter

**Document Type:** Educational / Tutorial
**Intended Audience:** Students, hobbyists, engineers new to multilevel inverters
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0

---

## Table of Contents

1. [What is an Inverter?](#what-is-an-inverter)
2. [From 2-Level to Multilevel](#from-2-level-to-multilevel)
3. [The H-Bridge Building Block](#the-h-bridge-building-block)
4. [Cascading H-Bridges](#cascading-h-bridges)
5. [How 5 Levels Are Created](#how-5-levels-are-created)
6. [PWM and Modulation](#pwm-and-modulation)
7. [Practical Applications](#practical-applications)
8. [Common Questions](#common-questions)

---

## What is an Inverter?

### The Basic Problem

**Input:** Direct Current (DC) - constant voltage, like from a battery or solar panel

**Desired Output:** Alternating Current (AC) - sinusoidal voltage, like from wall outlets

**Examples of DC sources:**
- Batteries (12V, 48V car batteries)
- Solar panels (varies, typically 30-60V)
- DC power supplies
- Fuel cells

**Why do we need AC?**
- Most household appliances run on AC (120V/230V @ 50/60Hz)
- AC motors are simpler and cheaper
- Power transmission over long distances is more efficient
- Grid-tied systems require AC

### What an Inverter Does

An **inverter converts DC to AC** using electronic switches.

**Simplified view:**
```
[DC Source] → [Inverter (switches)] → [AC Output]
   50V              electronics           100V RMS
  (constant)        (switching)           (sine wave)
```

---

## From 2-Level to Multilevel

### The Traditional 2-Level Inverter

**Simplest design:**

```
     +Vdc ─┬─ Switch A
           │
    Output ┼─────────  AC Output
           │
     -Vdc ─┴─ Switch B
```

**Operation:**
- Switch A ON, B OFF → Output = +Vdc
- Switch A OFF, B ON → Output = -Vdc

**Output voltage levels:** 2 (only +Vdc and -Vdc)

**Waveform:**
```
Voltage
  +Vdc ┌───┐   ┌───┐
       │   │   │   │
     0 ┼───┼───┼───┼──
       │   │   │   │
  -Vdc └───┘   └───┘
          Time →
```

**This is a square wave, NOT a sine wave!**

### Problems with 2-Level Inverters

1. **High Harmonic Distortion**
   - Square wave contains many harmonics
   - THD typically 30-40%
   - Requires large filters

2. **High dv/dt**
   - Voltage changes instantly from +Vdc to -Vdc
   - Stresses insulation
   - Creates EMI

3. **Acoustic Noise**
   - Harsh switching causes buzzing in transformers
   - Audible noise in motors

4. **Inefficiency**
   - Large filters required
   - Higher switching losses

### The Multilevel Solution

**Key idea:** Use multiple voltage levels instead of just 2.

**More levels = closer to sine wave**

Example with 5 levels:
```
Voltage
 +100V ┌─┐     ┌─┐
  +50V ├─┼─┐ ┌─┼─┤
    0V ┼─┼─┼─┼─┼─┼─
  -50V ├─┼─┴─┴─┼─┤
 -100V └─┘     └─┘
          Time →
```

**This looks much more like a sine wave!**

**Benefits:**
- ✅ Lower THD (3-5% instead of 30-40%)
- ✅ Lower dv/dt (smaller voltage steps)
- ✅ Smaller/simpler filters needed
- ✅ Less EMI
- ✅ Quieter operation
- ✅ Higher quality power

---

## The H-Bridge Building Block

### What is an H-Bridge?

An **H-bridge** is a circuit that can reverse the polarity of a voltage.

**Shape (looks like letter "H"):**

```
        S1         S3
         │         │
    ────┬┴─────────┴┬────
        │           │
    Vdc─┤  ┌─────┐ ├─Vdc
        │  │LOAD │ │
    ────┼──┴─────┴─┼────
        │           │
        ├───────────┤
        │           │
        S2         S4
```

**4 Switches:** S1, S2, S3, S4 (can be MOSFETs or IGBTs)

### H-Bridge Operation

**Three possible states:**

**State 1: Positive Voltage**
```
S1 ON, S4 ON → Current flows: Vdc → S1 → Load → S4 → GND
Output = +Vdc
```

**State 2: Negative Voltage**
```
S2 ON, S3 ON → Current flows: GND → S2 → Load (reverse) → S3 → Vdc
Output = -Vdc
```

**State 3: Zero Voltage**
```
S1 ON, S2 ON (or S3 ON, S4 ON) → Both sides of load at same potential
Output = 0V
```

**CRITICAL:** Never turn on S1 and S2 together, or S3 and S4 together!
This creates a short circuit (shoot-through) and destroys the switches instantly.

### Single H-Bridge Limitations

A single H-bridge can produce:
- +Vdc
- 0V
- -Vdc

**That's only 3 levels.** How do we get to 5 levels?

**Answer:** Cascade multiple H-bridges!

---

## Cascading H-Bridges

### The Cascading Concept

**Key insight:** Connect H-bridges in **series** (output to output).

```
DC1+ ┌────────┐      ┌────────┐ DC2+
─────┤H-Bridge├──┬───┤H-Bridge├─────
DC1- │   1    │  │   │   2    │ DC2-
     └────────┘  │   └────────┘
                 │
              Output
                (to load)
```

**Each bridge has its own isolated DC source.**

**Why isolated?**
- The bridges are in series
- Their voltages add up
- They must be electrically separated
- Common solutions: separate batteries, isolated DC-DC converters, transformers

### Voltage Addition

With 2 cascaded H-bridges, each with Vdc = 50V:

**Each bridge can contribute:**
- +50V (positive)
- 0V (zero)
- -50V (negative)

**Total output = Bridge 1 + Bridge 2:**

```
Bridge 1  Bridge 2  Total Output
  +50V   +   +50V   =   +100V
  +50V   +    0V    =    +50V
   0V    +    0V    =     0V
  -50V   +    0V    =    -50V
  -50V   +   -50V   =   -100V
```

**That's 5 discrete voltage levels!**

### Visual Representation

```
State: +100V
┌─────┐      ┌─────┐
│  +  │──┬───│  +  │  Both bridges positive
│  │  │  │   │  │  │  Output: +50 + 50 = +100V
└─────┘  │   └─────┘

State: +50V
┌─────┐      ┌─────┐
│  +  │──┬───│  0  │  Bridge 1 positive, Bridge 2 zero
│  │  │  │   │     │  Output: +50 + 0 = +50V
└─────┘  │   └─────┘

State: 0V
┌─────┐      ┌─────┐
│  0  │──┬───│  0  │  Both bridges zero
│     │  │   │     │  Output: 0 + 0 = 0V
└─────┘  │   └─────┘

State: -50V
┌─────┐      ┌─────┐
│  -  │──┬───│  0  │  Bridge 1 negative, Bridge 2 zero
│  │  │  │   │     │  Output: -50 + 0 = -50V
└─────┘  │   └─────┘

State: -100V
┌─────┐      ┌─────┐
│  -  │──┬───│  -  │  Both bridges negative
│  │  │  │   │  │  │  Output: -50 - 50 = -100V
└─────┘  │   └─────┘
```

---

## How 5 Levels Are Created

### Synthesis of AC Waveform

To create a 50Hz sine wave, we rapidly switch between the 5 voltage levels.

**Analogy:** Like drawing a curve with LEGO bricks - the more height levels you have, the smoother the curve.

### Example Timeline (50Hz sine wave)

```
Time    Desired Voltage   Closest Level   Bridge 1   Bridge 2
0ms          0V                0V             0V         0V
2ms         +71V             +100V           +50V       +50V
4ms        +100V             +100V           +50V       +50V
6ms         +71V             +100V           +50V       +50V (or +50V)
8ms          0V                0V             0V         0V
10ms       -71V             -100V           -50V       -50V
12ms      -100V             -100V           -50V       -50V
14ms       -71V             -100V           -50V       -50V
16ms         0V                0V             0V         0V
...
```

**Period of 50Hz:** 20ms (one complete cycle)

### Pulse Width Modulation (PWM)

To get even closer to a sine wave, we use **PWM** at high frequency (5kHz in our design).

**Concept:**
- Within each small time slice (200μs at 5kHz)
- Rapidly switch between adjacent levels
- The average voltage follows the sine wave

**Example for intermediate voltage:**

Want +75V (between +50V and +100V)?
- Spend 50% of time at +100V
- Spend 50% of time at +50V
- Average: (100 + 50) / 2 = 75V

**This is called Modulation Index (MI):**
```
MI = Desired_Voltage / Maximum_Voltage
```

For +75V with Vmax = 100V:
```
MI = 75 / 100 = 0.75 (or 75%)
```

---

## PWM and Modulation

### Level-Shifted Carrier PWM

Our implementation uses "level-shifted carrier PWM":

**Components:**
1. **Reference signal:** Sine wave at 50Hz (-1 to +1)
2. **Carrier 1:** Triangular wave at 5kHz (-1 to 0)  ← for Bridge 1
3. **Carrier 2:** Triangular wave at 5kHz (0 to +1)   ← for Bridge 2

**Switching rule:**
- When sine > carrier1 → Bridge 1 outputs positive
- When sine > carrier2 → Bridge 2 outputs positive
- Otherwise → output zero or negative (based on sine polarity)

**Visual:**
```
 +1 ─────────────────────────────
    │    /\/\/\/\  Carrier 2    │
  0 ├───────────────────────────┤
    │  /\/\/\/\    Carrier 1    │
 -1 ─────────────────────────────

    ───── Sine Reference ────────
```

### Why This Works

The high-frequency triangular carriers (5kHz) compared with the slow sine reference (50Hz) creates rapid switching that, when filtered, produces a clean sine wave output.

**Output filter (LC):**
- Inductor: Smooths current
- Capacitor: Removes high-frequency switching components
- Cutoff frequency: ~500Hz (between 50Hz fundamental and 5kHz switching)

**Result:** Clean 50Hz sine wave at the output!

---

## Practical Applications

### Where Are 5-Level Inverters Used?

#### 1. Solar Power Systems

**Application:** Convert DC from solar panels to AC for grid or home use

**Why 5-level?**
- High efficiency (important for solar ROI)
- Low THD for grid compliance
- Reliable operation

#### 2. Electric Vehicle Chargers

**Application:** Provide AC charging from DC battery

**Why 5-level?**
- Compact size
- Low EMI (important in automotive)
- Good power quality

#### 3. Uninterruptible Power Supplies (UPS)

**Application:** Provide clean AC power from batteries during outages

**Why 5-level?**
- Excellent power quality
- Fast response
- Scalable to higher power

#### 4. Motor Drives

**Application:** Variable frequency drives for industrial motors

**Why 5-level?**
- Reduced motor heating
- Lower acoustic noise
- Extended motor life

#### 5. Grid-Tied Inverters

**Application:** Feed power back to utility grid

**Why 5-level?**
- Meets grid standards (IEEE 519)
- Low THD < 5%
- Reactive power control

### Our Educational Project

**This is a learning platform for:**
- Understanding multilevel converters
- Embedded control systems
- Power electronics
- FPGA/ASIC design progression
- Real-time control

**Power rating:** 500W (manageable and safe for lab/home)

**Voltage:** 100V RMS (European appliance level, safer than 230V)

---

## Common Questions

### Q1: Why not just use a bigger filter with a 2-level inverter?

**A:** You could, but:
- Filter would be huge and expensive
- Higher losses in filter
- Slower dynamic response
- Still have dv/dt stress issues

Multilevel is a better engineering solution.

### Q2: Why 5 levels specifically? Why not 7 or 9?

**A:** Trade-off between performance and complexity:

**More levels:**
- ✅ Lower THD
- ✅ Better waveform quality
- ❌ More switches (expensive, complex)
- ❌ More isolated DC sources needed
- ❌ More complicated control

**5 levels offers:**
- Good THD (< 5%)
- Moderate complexity (2 bridges, 8 switches)
- Cost-effective
- Educational value

### Q3: What if the two DC sources have different voltages?

**A:** This causes **voltage imbalance** which:
- Increases THD
- Creates even-order harmonics
- Reduces effective output voltage
- Can damage components

**Solution:** Use regulation or balancing circuits to keep DC1 = DC2.

### Q4: Can I use one DC source with a transformer?

**A:** Yes! Common approach:

```
Single DC → DC-DC converters (isolated) → Multiple DC outputs
             (with transformers)
```

Or:

```
AC from grid → Transformer (multiple secondaries) → Rectifiers → Isolated DC sources
```

This is typical in industrial products.

### Q5: What happens if a switch fails?

**A:** Depends on failure mode:

**Short-circuit failure:**
- Immediate overcurrent
- Fuse blows or shutdown occurs
- That bridge outputs constant voltage

**Open-circuit failure:**
- That leg of bridge doesn't switch
- Reduced output voltage capability
- Possible THD increase

**Protection is critical!** (See Safety Guide)

### Q6: Can this run a motor?

**A:** Yes! But considerations:

- Motor creates inductive load
- Inrush current at startup
- Back-EMF when motor acts as generator
- Need current control (PR controller helps)

Variable-frequency operation allows speed control.

### Q7: How efficient is it?

**A:** Typical efficiency: 92-96%

**Losses come from:**
- Switching losses in MOSFETs/IGBTs (dominant)
- Conduction losses in switches
- Gate driver power
- Control circuit power
- Filter losses

Higher switching frequency → more loss.

### Q8: What's next? 7-level? 9-level?

**A:** Yes! General formula:

For **n cascaded H-bridges:**
- Voltage levels = **2n + 1**
- Required switches = **4n**

Examples:
- 3 bridges → 7 levels, 12 switches
- 4 bridges → 9 levels, 16 switches
- 5 bridges → 11 levels, 20 switches

Our modular design makes extension easy!

---

## Learning Path

### Recommended Study Sequence

**Level 1: Fundamentals**
1. DC/AC concepts
2. Basic electronics (resistors, capacitors, inductors)
3. MOSFETs and transistors
4. PWM basics

**Level 2: Power Electronics**
1. Power MOSFETs and IGBTs
2. Gate drivers
3. Snubbers and protection
4. Thermal management

**Level 3: Control Theory**
1. PID control
2. Digital control
3. State-space modeling
4. PR controllers

**Level 4: Implementation**
1. Microcontroller programming
2. FPGA/HDL design
3. PCB design
4. Practical testing

### Hands-On Exercises

**Exercise 1:** Simulate 2-level inverter in MATLAB/Simulink

**Exercise 2:** Calculate THD for different number of levels

**Exercise 3:** Design output filter (LC) for desired cutoff

**Exercise 4:** Implement basic H-bridge on breadboard (low voltage)

**Exercise 5:** Program microcontroller for PWM generation

**Exercise 6:** Implement level-shifted carrier algorithm

**Exercise 7:** Full system integration and testing

---

## Conclusion

The **5-level cascaded H-bridge** inverter is an elegant solution that:

✅ Produces high-quality AC waveforms
✅ Scales to higher voltages easily
✅ Offers excellent THD performance
✅ Provides a great learning platform
✅ Has real industrial applications

**Key takeaways:**
- Cascading H-bridges creates multiple voltage levels
- More levels = better sine wave approximation
- PWM modulation creates smooth output
- Isolated DC sources are required
- Proper control and protection are critical

**This is the foundation for advanced power electronics!**

---

## Further Reading

**Books:**
1. "Power Electronics" by Ned Mohan
2. "Power Electronics Handbook" by Muhammad H. Rashid
3. "Multilevel Converters for Industrial Applications" by Bin Wu

**Papers:**
1. "Multilevel Inverters: A Survey" (Rodriguez et al., IEEE 2002)
2. "Cascaded H-Bridge Multilevel Inverters" (Tolbert, IEEE 1999)

**Online Resources:**
1. MIT OpenCourseWare - Power Electronics
2. TI Power Electronics Training
3. Infineon Application Notes

**Our Documentation:**
1. `01-Level-Shifted-PWM-Theory.md` - Deep dive into modulation
2. `02-PR-Controller-Design-Guide.md` - Control system design
3. `03-Safety-and-Protection-Guide.md` - Critical safety information
4. `CLAUDE.md` - Complete project guide

---

**Document End**

*We hope this guide has demystified multilevel inverters and inspired you to learn more about power electronics!*

*For questions or contributions, see the project repository.*
