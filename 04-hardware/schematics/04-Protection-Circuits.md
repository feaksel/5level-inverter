# Protection Circuits Design

**Document Type:** Hardware Design Specification - SAFETY CRITICAL
**Project:** 5-Level Cascaded H-Bridge Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0
**Status:** Design - Not Yet Validated
**Safety Level:** CRITICAL - DO NOT MODIFY WITHOUT REVIEW

---

## ⚠️ SAFETY WARNING

This document describes **MANDATORY safety-critical protection circuits**. These circuits prevent:
- Equipment damage
- Fire hazards
- Electric shock
- Personal injury

**All protection circuits MUST be implemented and tested before applying power.**

---

## Table of Contents

1. [Overview](#overview)
2. [Protection Requirements](#protection-requirements)
3. [Overcurrent Protection](#overcurrent-protection)
4. [Overvoltage Protection](#overvoltage-protection)
5. [Thermal Protection](#thermal-protection)
6. [Fault Detection and Response](#fault-detection-and-response)
7. [Emergency Shutdown System](#emergency-shutdown-system)
8. [Testing and Validation](#testing-and-validation)
9. [Bill of Materials](#bill-of-materials)

---

## Overview

### Protection Philosophy

**Layered Defense Strategy:**

```
Layer 1: Software Protection (STM32 monitoring)
           ↓ (if fails)
Layer 2: Hardware Comparators (immediate response)
           ↓ (if fails)
Layer 3: Fuses and Breakers (last resort)
```

**Design Principles:**
1. **Fail-Safe:** Default state is OFF (no PWM output)
2. **Redundant:** Multiple protection methods for critical faults
3. **Fast:** Hardware protection responds within microseconds
4. **Visible:** Fault indication via LEDs and serial output
5. **Recoverable:** Automatic recovery after fault clears (where safe)

### System Context

**Fault Scenarios:**

| Fault Type | Consequence | Response Time | Protection Method |
|------------|-------------|---------------|-------------------|
| Output Overcurrent | MOSFET damage | < 10 μs | Hardware comparator |
| DC Bus Overvoltage | Component damage | < 100 μs | Crowbar + shutdown |
| MOSFET Overtemperature | Junction damage | < 1 ms | Thermal shutdown |
| Shoot-Through | Catastrophic failure | < 1 μs | Dead-time (prevention) |
| Output Short Circuit | High current, fire | < 10 μs | OCP + fuse |
| Overload (sustained) | Thermal stress | < 100 ms | Software shutdown |

---

## Protection Requirements

### Electrical Limits

**Absolute Maximum Ratings (must never exceed):**

| Parameter | Normal | Warning | Shutdown | Absolute Max |
|-----------|--------|---------|----------|--------------|
| Output Current | 10A RMS | 12A RMS | 15A peak | 20A (fuse) |
| DC Bus Voltage | 50V | 55V | 60V | 65V (MOV) |
| MOSFET Temperature | 80°C | 100°C | 125°C | 150°C (Tj max) |
| Heatsink Temperature | 60°C | 70°C | 80°C | - |
| Gate Drive Voltage | 12V | 13V | 14V | 20V (Vgs max) |

### Response Times

**Hardware Protection (comparator-based):**
- Detection: < 500 ns
- Shutdown: < 10 μs (disable PWM)
- Total response: < 10 μs

**Software Protection (STM32 monitoring):**
- Sampling rate: 10 kHz (every 100 μs)
- Detection: 100-200 μs
- Shutdown: < 50 μs (disable timer)
- Total response: < 250 μs

### Protection Actions

**Fault Severity Levels:**

**Level 1: WARNING** (Continue operation with reduced performance)
- Log fault
- Activate warning LED
- Reduce power output (soft limiting)

**Level 2: SHUTDOWN** (Immediate safe shutdown, auto-recovery possible)
- Disable PWM outputs
- Activate fault LED
- Log fault type
- Wait for fault to clear
- Attempt restart after delay

**Level 3: LOCKOUT** (Permanent shutdown, manual reset required)
- Disable PWM outputs
- Latch fault condition
- Activate fault LED (continuous)
- Require power cycle or reset button

---

## Overcurrent Protection

### Hardware OCP (Fast Response)

**Topology:** Analog comparator with hardware shutdown

**Circuit:**

```
Current Sensor ──→ ACS724 ──→ 2.5V ± 0.6V ──┬──→ ADC (monitoring)
  (±15A max)                                 │
                                             │
                                             └──→ Comparator (-) ──→ Shutdown Logic
                                                      │
                                   Threshold Vref ───┘ (+)
                                     (3.1V = 15A)

Shutdown Logic ──→ PWM_DISABLE (to STM32) ──→ Disables TIM1/TIM8
```

**Comparator:**

Use **LM339** (quad comparator, cheap and fast):
- Response time: 1.3 μs
- Supply: 5V
- Open-collector output (pull-up to 5V)

**Threshold Calculation:**

For 15A peak shutdown:
```
V_threshold = V_zero + (I_limit × Sensitivity)
            = 2.5V + (15A × 0.04 V/A)
            = 2.5V + 0.6V
            = 3.1V
```

**Implementation:**

```
                    +5V
                     │
                 10kΩ │ (pull-up)
                     │
ACS724 Out ──────────┤- (LM339 pin 4)
(2.5V ± 0.6V)        │
                     │>────┬──→ FAULT_OCP (to STM32 PA10)
                     │     │
Vref (3.1V) ─────────┤+ (LM339 pin 5)
                     │
                    GND
```

**Voltage Reference (3.1V):**

Option 1: Resistive divider from 5V:
```
+5V ──┬─── 10kΩ ──┬──→ 3.1V
      │           │
      └─── 16kΩ ──┴──→ GND

Actual: 5V × 16kΩ / 26kΩ = 3.08V (close enough)
```

Option 2: Precision reference (TL431 + divider):
```
+5V ──→ TL431 ──→ 2.5V ──→ Divider ──→ 3.1V
```

**Use Option 1** for simplicity.

**Shutdown Logic:**

```
FAULT_OCP (active LOW) ──→ STM32 PA10 (interrupt + GPIO)
                             │
                             └──→ Firmware disables TIM1/TIM8 immediately
```

**Hardware Shutdown (Optional):**

For even faster response, directly disable gate drivers:

```
FAULT_OCP (active LOW) ──→ AND gate ──→ IR2110 SD (shutdown pin)
PWM_ENABLE (from STM32) ──┘
```

This disables PWM in < 1 μs.

---

### Software OCP (Sustained Overload)

**Monitoring:**

ADC reads current every 100 μs (10 kHz sampling).

**Algorithm:**

```c
#define I_PEAK_LIMIT    15.0f  // Amperes (immediate shutdown)
#define I_RMS_LIMIT     12.0f  // Amperes (sustained, 1 cycle)
#define I_OVERLOAD      10.0f  // Amperes (continuous warning)

float current_rms = calculate_rms(current_samples, 200); // 200 samples = 1 cycle @ 50Hz

if (fabs(current_peak) > I_PEAK_LIMIT) {
    fault_trigger(FAULT_OVERCURRENT_PEAK);
    shutdown_pwm();
}

if (current_rms > I_RMS_LIMIT) {
    fault_trigger(FAULT_OVERCURRENT_RMS);
    shutdown_pwm();
}

if (current_rms > I_OVERLOAD) {
    overload_counter++;
    if (overload_counter > 100) { // 100 cycles = 2 seconds
        fault_trigger(FAULT_OVERLOAD);
        reduce_power(0.8); // Reduce to 80%
    }
}
```

---

## Overvoltage Protection

### DC Bus OVP

**Topology:** Comparator + Crowbar (SCR)

**Circuit:**

```
DC Bus ──┬─── Divider ──┬──→ Comparator (-) ──→ Fault
(50V)   │              │          │
        │              │          └──→ SCR Gate (crowbar)
        └─── Fuse ─────┘
                       │
                  SCR Cathode ──→ GND
                  (shorts bus on fault)
```

**Voltage Divider:**

For 60V shutdown threshold:
```
V_div = 60V × (3.3kΩ / 50.3kΩ) = 3.94V

But ADC max is 3.3V, so use different divider for comparator:
60V → 4.5V threshold (with 5V supply comparator)

R1 = 82kΩ, R2 = 6.8kΩ
V_div = 60V × (6.8kΩ / 88.8kΩ) = 4.59V
```

**Comparator:**

```
DC Bus Divided ──────────┤- (LM339)
  (varies)               │
                         │>────┬──→ FAULT_OVP (to STM32)
                         │     │
Vref (4.5V)     ─────────┤+    └──→ SCR gate (crowbar circuit)
                         │
```

**Crowbar Circuit (Optional, for catastrophic OVP):**

```
                   DC Bus (+50V)
                         │
                    Fuse 20A ──────┐
                         │         │
                         │       [SCR]
                         │      C106D
                         │         │
                    To H-bridge    │
                                   │
                    FAULT_OVP ─→ Gate (via 1kΩ)
                                   │
                                  GND
```

**SCR (C106D or similar):**
- Trigger: > 60V on DC bus
- Action: Shorts bus to GND, blows fuse
- Use: Last-resort protection (prevents overvoltage damage)

**Warning:** Crowbar is destructive (blows fuse). Only for catastrophic failures.

**Recommended:** Software shutdown is sufficient for normal OVP. Omit crowbar for prototype.

---

### Output Overvoltage Protection

**Software Monitoring:**

```c
#define V_OUTPUT_MAX   150.0f  // Volts peak

float v_output = read_output_voltage();

if (fabs(v_output) > V_OUTPUT_MAX) {
    fault_trigger(FAULT_OVERVOLTAGE_OUTPUT);
    shutdown_pwm();
}
```

---

## Thermal Protection

### MOSFET Temperature Sensing

**Sensor:** NTC thermistor (10kΩ @ 25°C) attached to MOSFET heatsink

**Circuit:**

```
+3.3V ──┬─── 10kΩ (fixed) ──┬──→ ADC (PA6)
        │                   │
        └─── NTC (10kΩ@25°C)┴──→ GND
```

**Temperature Calculation:**

Using Steinhart-Hart equation:
```
1/T = A + B×ln(R) + C×(ln(R))³

For common NTC (10kΩ @ 25°C, β = 3950):
A = 1.129148e-3
B = 2.341077e-4
C = 8.775468e-8
```

**Simplified (Beta equation):**
```
T = β / (ln(R/R0) + β/T0)

Where:
R0 = 10kΩ (resistance at T0)
T0 = 298.15K (25°C)
β = 3950 (thermistor constant)
```

**Implementation:**

```c
#define TEMP_WARNING    100.0f  // °C
#define TEMP_SHUTDOWN   125.0f  // °C

float read_temperature_ntc(uint16_t adc_val) {
    float V_adc = adc_val * 3.3f / 4096.0f;
    float R_ntc = 10000.0f * V_adc / (3.3f - V_adc);

    // Steinhart-Hart
    float ln_R = logf(R_ntc / 10000.0f);
    float inv_T = 1.129148e-3 + 2.341077e-4 * ln_R + 8.775468e-8 * ln_R * ln_R * ln_R;
    float T_kelvin = 1.0f / inv_T;
    float T_celsius = T_kelvin - 273.15f;

    return T_celsius;
}

void check_thermal_protection(void) {
    float temp = read_temperature_ntc(adc_temperature);

    if (temp > TEMP_SHUTDOWN) {
        fault_trigger(FAULT_THERMAL_SHUTDOWN);
        shutdown_pwm();
    } else if (temp > TEMP_WARNING) {
        fault_trigger(FAULT_THERMAL_WARNING);
        reduce_power(0.9f); // Reduce to 90%
    }
}
```

**NTC Placement:**

- Attach to MOSFET heatsink with thermal epoxy
- Place on hottest MOSFET (typically high-side)
- Use one NTC per H-bridge (2 total)

---

### Gate Driver Thermal Protection

**IR2110 has built-in thermal shutdown:**
- Shutdown temperature: 150°C (typ)
- Automatic recovery when temperature drops
- No external circuit needed

**Monitoring:**

Watch for repeated thermal shutdowns (indicates inadequate cooling).

---

## Fault Detection and Response

### Fault Types

**Fault Register (bit-mapped):**

```c
typedef enum {
    FAULT_NONE                  = 0x0000,
    FAULT_OVERCURRENT_PEAK      = 0x0001,  // Hardware OCP triggered
    FAULT_OVERCURRENT_RMS       = 0x0002,  // Sustained overcurrent
    FAULT_OVERLOAD              = 0x0004,  // Long-term overload
    FAULT_OVERVOLTAGE_DC_BUS    = 0x0008,  // DC bus overvoltage
    FAULT_OVERVOLTAGE_OUTPUT    = 0x0010,  // AC output overvoltage
    FAULT_UNDERVOLTAGE_DC_BUS   = 0x0020,  // DC bus undervoltage
    FAULT_THERMAL_SHUTDOWN      = 0x0040,  // Overtemperature shutdown
    FAULT_THERMAL_WARNING       = 0x0080,  // Overtemperature warning
    FAULT_GATE_DRIVER_FAULT     = 0x0100,  // Gate driver fault signal
    FAULT_ADC_TIMEOUT           = 0x0200,  // ADC not responding
    FAULT_WATCHDOG_RESET        = 0x0400,  // Watchdog timer expired
    FAULT_EMERGENCY_STOP        = 0x0800,  // E-stop button pressed
} fault_t;

uint16_t fault_status = FAULT_NONE;
```

### Fault Response Table

| Fault | Severity | PWM Action | Auto-Recover | Manual Reset |
|-------|----------|------------|--------------|--------------|
| OCP Peak | Critical | Immediate OFF | No | Yes |
| OCP RMS | Critical | Immediate OFF | No | Yes |
| Overload | Warning | Reduce power | Yes | - |
| OVP DC Bus | Critical | Immediate OFF | Yes (if < 55V) | If > 55V |
| OVP Output | Critical | Immediate OFF | No | Yes |
| Thermal Shutdown | Critical | Immediate OFF | Yes (< 100°C) | - |
| Thermal Warning | Warning | Reduce power | Yes | - |
| E-Stop | Critical | Immediate OFF | No | Yes |

### Fault Indication

**LED Indicators:**

```
LED1 (Green):  Normal operation / Power ON
LED2 (Yellow): Warning (thermal, overload)
LED3 (Red):    Fault / Shutdown
```

**Blink Codes:**

Fault LED blinks to indicate fault type:
- 1 blink: Overcurrent
- 2 blinks: Overvoltage
- 3 blinks: Thermal
- 4 blinks: E-stop
- 5 blinks: Watchdog reset
- Continuous: Multiple faults

**Circuit:**

```
STM32 GPIO ──┬─── 470Ω ──┬─── LED (Green) ──→ GND
   (PA11)   │           │
            └─── 470Ω ──┼─── LED (Yellow) ──→ GND
                        │
                        └─── LED (Red) ──────→ GND
```

---

## Emergency Shutdown System

### E-Stop Button

**Hardware:**

```
+5V ──┬─── 10kΩ (pull-up) ──┬──→ STM32 PA9 (E_STOP input)
      │                      │
      └─── E-Stop Button ────┴──→ GND (normally open)
```

**Button:** Red mushroom button (Normally Open, latching)

**Firmware:**

```c
void EXTI9_IRQHandler(void) {
    if (EXTI->PR & EXTI_PR_PR9) { // PA9 interrupt
        EXTI->PR = EXTI_PR_PR9; // Clear flag

        // E-stop pressed
        fault_trigger(FAULT_EMERGENCY_STOP);
        shutdown_pwm_immediate();

        // Latch fault (requires manual reset)
        fault_latched = true;
    }
}
```

### Watchdog Timer

**Purpose:** Detect firmware crash and safely shutdown

**Configuration:**

```c
// Independent Watchdog (IWDG) - 32 kHz LSI clock
IWDG->KR = 0xCCCC;  // Enable IWDG
IWDG->KR = 0x5555;  // Allow configuration
IWDG->PR = 0x04;    // Prescaler /64 (500 Hz)
IWDG->RLR = 500;    // Reload value (1 second timeout)
IWDG->KR = 0xAAAA;  // Refresh watchdog

// Refresh in main loop (must occur every < 1 second)
while (1) {
    // ... main loop ...

    if (system_healthy) {
        IWDG->KR = 0xAAAA; // Refresh
    }
}
```

**Action on Watchdog Reset:**

```c
void check_reset_cause(void) {
    if (RCC->CSR & RCC_CSR_IWDGRSTF) {
        // Watchdog reset occurred
        fault_trigger(FAULT_WATCHDOG_RESET);
        fault_latched = true; // Require manual reset

        // Clear flag
        RCC->CSR |= RCC_CSR_RMVF;
    }
}
```

---

## Testing and Validation

### Protection Testing Procedure

**⚠️ WARNING: Testing protection circuits involves intentionally creating fault conditions. Use extreme caution.**

**Safety Precautions:**
- Test with reduced DC bus voltage (12V instead of 50V)
- Use current-limited power supply
- Wear safety glasses and gloves
- Have fire extinguisher nearby
- Test in well-ventilated area
- One person operates, one observes

---

### Test 1: Overcurrent Protection

**Setup:**
- Reduce DC bus to 12V
- Connect 1Ω / 25W resistive load
- Expected current: ~12A (above 10A limit)

**Procedure:**
1. Enable PWM at 50% duty cycle
2. Observe current increase
3. Verify OCP triggers before reaching 15A
4. Confirm PWM disabled within 10 μs
5. Check fault LED illuminated

**Pass Criteria:**
- OCP triggers at 12-15A
- Response time < 20 μs
- Fault logged correctly

---

### Test 2: Overvoltage Protection

**Setup:**
- Adjust PSU to 55V (warning level)
- Connect 100Ω load

**Procedure:**
1. Slowly increase PSU voltage to 60V
2. Verify OVP triggers
3. Confirm PWM shutdown
4. Check fault indication

**Pass Criteria:**
- OVP triggers at 58-62V
- No damage to components

---

### Test 3: Thermal Protection

**Setup:**
- Heat MOSFET heatsink with heat gun
- Monitor temperature via ADC

**Procedure:**
1. Run inverter at 50% power
2. Apply heat to NTC thermistor
3. Observe temperature reading
4. Verify shutdown at 125°C

**Pass Criteria:**
- Warning at 100°C ±5°C
- Shutdown at 125°C ±10°C
- Auto-recovery when cooled

---

### Test 4: E-Stop

**Procedure:**
1. Run inverter normally
2. Press E-stop button
3. Verify immediate shutdown
4. Confirm latched fault (no auto-restart)
5. Release button and power cycle
6. Verify normal operation restored

**Pass Criteria:**
- Shutdown within 1 ms
- Fault latched until reset

---

### Test 5: Watchdog

**Procedure:**
1. Add infinite loop in firmware (simulate crash)
2. Flash modified firmware
3. Observe watchdog reset after 1 second
4. Verify fault logged

**Pass Criteria:**
- Reset occurs within 1-2 seconds
- Fault logged correctly
- System enters safe state

---

## Bill of Materials

### BOM for Protection Circuits

| Qty | Part Number | Description | Specs | Price (approx) |
|-----|-------------|-------------|-------|----------------|
| 2 | LM339N | Quad comparator | DIP-14 or SOIC-14 | $0.50 each = $1.00 |
| 4 | Resistor 10kΩ | Pull-up, dividers | 1%, 1/4W | $0.05 each = $0.20 |
| 2 | Resistor 16kΩ | Voltage reference | 1%, 1/4W | $0.05 each = $0.10 |
| 2 | Resistor 82kΩ | OVP divider | 1%, 1W | $0.10 each = $0.20 |
| 2 | Resistor 6.8kΩ | OVP divider | 1%, 1/4W | $0.05 each = $0.10 |
| 2 | NTC 10kΩ | Thermistor | β=3950, 1% | $0.50 each = $1.00 |
| 2 | C106D | SCR (optional) | 400V, 4A | $0.30 each = $0.60 |
| 3 | LED 5mm | Indicators | Red, Yellow, Green | $0.10 each = $0.30 |
| 3 | Resistor 470Ω | LED current limit | 1/4W | $0.05 each = $0.15 |
| 1 | E-Stop Button | Emergency stop | Red mushroom, NO | $5.00 |
| 2 | Fuse 20A | DC bus protection | Fast-blow, 63V | $1.00 each = $2.00 |
| | Thermal epoxy | NTC attachment | Thermally conductive | $5.00 |
| | | | **Total** | **~$16** |

---

## Protection Circuit Diagram (Summary)

```
                        ┌─────────────────────────────────┐
                        │   STM32F401RE (Controller)      │
                        │                                 │
    E-Stop ─────────────┤ PA9 (E-Stop input)              │
                        │                                 │
    FAULT_OCP ──────────┤ PA10 (OCP interrupt)            │
                        │                                 │
    FAULT_OVP ──────────┤ PA11 (OVP interrupt)            │
                        │                                 │
    NTC_TEMP1 ──────────┤ PA6 (ADC_IN6, Temp 1)           │
                        │                                 │
    NTC_TEMP2 ──────────┤ PA7 (ADC_IN7, Temp 2)           │
                        │                                 │
    LED_GREEN ──────────┤ PB0 (Status LED)                │
                        │                                 │
    LED_YELLOW ─────────┤ PB1 (Warning LED)               │
                        │                                 │
    LED_RED ────────────┤ PB2 (Fault LED)                 │
                        │                                 │
                        │ TIM1/TIM8 PWM ───→ Gate Drivers │
                        │                                 │
                        │ Watchdog (IWDG) ─→ Auto-reset   │
                        └─────────────────────────────────┘
```

---

**Document Status:** Design complete, ready for implementation
**Next Steps:** PCB layout with protection circuits, thorough testing

**Related Documents:**
- `03-Current-Voltage-Sensing.md` - Sensors used for protection
- `01-Gate-Driver-Design.md` - Shutdown interface to drivers
- `../pcb/05-PCB-Layout-Guide.md` - Layout considerations for protection
- `../../07-docs/03-Safety-and-Protection-Guide.md` - Overall safety procedures
