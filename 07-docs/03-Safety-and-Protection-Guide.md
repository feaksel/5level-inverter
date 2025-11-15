# Safety and Protection Guide

**Document Type:** Safety Critical / Engineering Guide
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0

⚠️ **WARNING:** This document contains safety-critical information. Read completely before working with the inverter.

---

## Table of Contents

1. [Safety Overview](#safety-overview)
2. [Electrical Hazards](#electrical-hazards)
3. [Protection Requirements](#protection-requirements)
4. [Hardware Protection](#hardware-protection)
5. [Software Protection](#software-protection)
6. [Safe Operating Procedures](#safe-operating-procedures)
7. [Emergency Procedures](#emergency-procedures)
8. [Testing Safety](#testing-safety)
9. [Maintenance and Inspection](#maintenance-and-inspection)

---

## Safety Overview

### ⚠️ DANGER: HIGH VOLTAGE

This inverter operates at voltages **up to 141V peak (100V RMS)** and currents **up to 10A**.

**These voltage and current levels can be LETHAL.**

### Who Should Read This Document

**REQUIRED READING for:**
- Anyone designing the inverter hardware
- Anyone building/assembling the inverter
- Anyone testing or commissioning the system
- Anyone maintaining the equipment

### Safety Philosophy

**Defense in Depth:**
1. **Prevent** failures through proper design
2. **Detect** abnormal conditions early
3. **Protect** against damage when faults occur
4. **Isolate** hazardous voltages from users
5. **Inform** operators of system status

### Regulatory Standards

This system must comply with:
- **IEC 61010-1:** Safety requirements for electrical equipment
- **IEC 60950-1:** Information technology equipment safety
- **IEEE 519:** Harmonic control in power systems
- **Local electrical codes** (NEC in USA, IEC in Europe, etc.)

---

## Electrical Hazards

### Primary Hazards

#### 1. Electric Shock

**Voltage Levels:**
- DC Bus: 2 × 50V = 100V DC
- AC Output: 100V RMS (141V peak)
- Transients: Up to 200V possible

**Risk:**
- 50V+ can cause severe shock
- 100V+ can be **lethal** under certain conditions
- Risk increased with wet conditions, poor insulation

**Protection:**
- All high-voltage terminals must be insulated
- Use SELV (Safety Extra-Low Voltage) for control circuits
- Employ electrical isolation between power and control

#### 2. Arc Flash

**Conditions:**
- Short circuits
- Component failures
- Improper connections

**Consequences:**
- Severe burns
- Fire hazard
- Equipment damage
- Molten metal

**Prevention:**
- Proper circuit protection (fuses, circuit breakers)
- Adequate clearances and creepage distances
- Enclosed construction

#### 3. Fire Hazard

**Sources:**
- Overheating components
- Short circuits
- Arc faults
- Insulation breakdown

**Prevention:**
- Proper component ratings
- Thermal management (heatsinks, fans)
- Current limiting
- Fire-resistant enclosures

### Secondary Hazards

#### 4. Stored Energy

**Capacitors:**
- DC bus capacitors store significant energy
- Can remain charged after power off
- Discharge resistors required

**Inductors:**
- Output filter inductors store magnetic energy
- Sudden disconnection can cause voltage spikes

#### 5. EMI/RFI

**Sources:**
- Fast switching (5kHz PWM)
- High dv/dt and di/dt
- Parasitic resonances

**Effects:**
- Interference with nearby electronics
- Communication disruption
- Compliance issues

**Mitigation:**
- EMI filters
- Shielding
- Proper grounding
- Twisted-pair wiring

---

## Protection Requirements

### Mandatory Protection Features

All implementations **MUST** include:

#### 1. Overcurrent Protection

**Requirements:**
- Hardware current sensing on output
- Software current limiting
- Fast shutdown (< 1ms response)
- Hardware fuse/breaker backup

**Limits:**
- Continuous: 10A maximum
- Short-term (1s): 15A
- Instantaneous trip: 20A
- Fuse rating: 15A fast-blow

#### 2. Overvoltage Protection

**Requirements:**
- DC bus voltage monitoring
- AC output voltage monitoring
- Overvoltage shutdown
- Transient suppression (TVS diodes)

**Limits:**
- DC bus: 60V maximum (20% over nominal)
- AC output: 125V RMS (25% over nominal)
- Transient: 200V absolute maximum

#### 3. Shoot-Through Protection

**Critical for H-bridge operation:**

**Requirement:** S1-S2 and S3-S4 must **NEVER** be ON simultaneously.

**Implementation:**
- Hardware dead-time insertion (1μs minimum)
- Software interlocks
- Independent verification

**Consequences of failure:**
- Immediate destruction of switches
- Possible fire/explosion
- PCB damage

#### 4. Thermal Protection

**Requirements:**
- Temperature sensors on heatsinks
- Thermal shutdown
- Over-temperature warning

**Limits:**
- MOSFETs/IGBTs: 100°C maximum case temperature
- Ambient shutdown: 70°C
- Warning threshold: 60°C

#### 5. Ground Fault Detection

**Requirements:**
- Ground fault current sensing
- Isolation monitoring (if applicable)
- GFCI-like protection

**Limits:**
- Ground fault trip: 30mA (RCD Class A)
- Response time: < 30ms

### Optional but Recommended

#### 6. Phase Loss Detection

For 3-phase variants or grid-tie:
- Detect missing phase
- Detect phase imbalance
- Automatic shutdown

#### 7. Under-Voltage Lockout (UVLO)

**Purpose:** Prevent operation with insufficient DC supply.

**Thresholds:**
- Turn-on: > 45V per bridge
- Turn-off: < 40V per bridge
- Hysteresis prevents chattering

---

## Hardware Protection

### Power Stage Protection

#### Current Sensing

**Method:** Hall-effect current sensor or shunt resistor

**Specifications:**
- Range: ±20A minimum
- Accuracy: ±1%
- Bandwidth: > 10kHz
- Isolation: 2.5kV minimum (if using shunt)

**Recommended Sensors:**
- ACS712 (Hall-effect, ±20A, 5V output)
- LEM HO series (Hall-effect, high accuracy)
- Shunt + isolated amplifier (e.g., AMC1200)

**Placement:**
- Output current (AC side)
- Optional: DC bus current per bridge

#### Voltage Sensing

**DC Bus Monitoring:**
```
Voltage divider:
R1 = 100kΩ (high voltage side)
R2 = 3.3kΩ  (low voltage side)

Scaling: 50V → ~1.6V (ADC range)
```

**Isolation:**
- Optocoupler-based isolation recommended
- Isolated amplifiers for high accuracy
- Ensure adequate creepage/clearance

#### Gate Driver Protection

**Requirements:**
- Isolated power supplies (15V typical)
- Under-voltage lockout (UVLO)
- Desaturation (overcurrent) detection
- Fault feedback to microcontroller

**Recommended ICs:**
- Si827x series (Silicon Labs)
- ADUM4223 (Analog Devices)
- UCC21520 (Texas Instruments)

**Features needed:**
- 2.5kV+ isolation
- Dead-time insertion capability
- Enable/disable control
- Fault output

#### Fusing and Circuit Protection

**Primary Protection:**
```
DC Input (per bridge):
- 15A fast-blow fuse
- Or 10A circuit breaker

AC Output:
- 15A fast-blow fuse
- Transient voltage suppressors (TVS)
```

**TVS Diode Selection:**
```
Type: Bidirectional TVS
Voltage: 150V breakdown (for 100V system)
Power: 1500W minimum peak
Example: P6KE150CA
```

### PCB Design Safety

#### Creepage and Clearance

**Per IEC 60664-1:**

For 100V DC (overvoltage category II, pollution degree 2):
- **Clearance:** 1.5mm minimum
- **Creepage:** 2.5mm minimum

For critical isolation (power to control):
- **Clearance:** 4.0mm minimum
- **Creepage:** 6.0mm minimum

#### PCB Layout Guidelines

1. **Separate power and control planes**
   - Physical separation > 5mm
   - No crossing traces
   - Independent ground returns initially, single-point connection

2. **High-current traces**
   - Width: 2mm minimum for 10A (1oz copper)
   - Use copper pour for power distribution
   - Minimize trace inductance

3. **Switching node isolation**
   - Keep SW nodes away from sensitive circuits
   - Shield with ground plane
   - Short traces to minimize ringing

4. **Thermal relief**
   - Thermal vias under power devices
   - Heatsink attachment points
   - Adequate copper area for dissipation

---

## Software Protection

### Protection Software Architecture

**Layered approach:**

```
Layer 1: Hardware (fastest response)
  ├── Gate driver UVLO
  ├── Hardware comparators
  └── Fuses

Layer 2: Interrupt-based (fast)
  ├── ADC overcurrent detection
  ├── Emergency PWM shutdown
  └── < 100μs response

Layer 3: Main loop (moderate)
  ├── Thermal monitoring
  ├── Voltage range checking
  └── < 10ms response

Layer 4: User interface (slow)
  ├── Status reporting
  ├── Parameter validation
  └── Human-readable alerts
```

### Critical Software Functions

#### 1. Initialization Checks

**Before enabling PWM:**

```c
bool system_safe_to_enable(void) {
    // Check all safety preconditions
    if (dc_bus_voltage < MIN_VOLTAGE) return false;
    if (dc_bus_voltage > MAX_VOLTAGE) return false;
    if (heatsink_temp > MAX_TEMP) return false;
    if (gate_drivers_not_ready()) return false;
    if (current_sensor_fault()) return false;

    return true;  // All checks passed
}
```

#### 2. Real-Time Protection (ISR)

**In PWM interrupt (5kHz):**

```c
void PWM_ISR(void) {
    // Read sensors
    float current = adc_read_current();
    float dc_voltage = adc_read_dc_bus();

    // Fast protection checks
    if (fabs(current) > CURRENT_LIMIT) {
        pwm_emergency_shutdown();
        set_fault_flag(FAULT_OVERCURRENT);
        return;
    }

    if (dc_voltage > OVERVOLTAGE_LIMIT) {
        pwm_emergency_shutdown();
        set_fault_flag(FAULT_OVERVOLTAGE);
        return;
    }

    // Normal operation continues...
}
```

#### 3. Watchdog Timer

**Purpose:** Detect software crashes/hangs

```c
// Initialize watchdog
IWDG_Init(1000);  // 1 second timeout

// In main loop (must execute regularly)
void main_loop(void) {
    while (1) {
        // Refresh watchdog
        IWDG_Refresh();

        // Normal operations
        // ...

        // If this loop stops, watchdog triggers reset
    }
}
```

#### 4. Fault Handling

**Fault flags:**

```c
typedef enum {
    FAULT_NONE = 0x00,
    FAULT_OVERCURRENT = 0x01,
    FAULT_OVERVOLTAGE = 0x02,
    FAULT_UNDERVOLTAGE = 0x04,
    FAULT_OVERTEMP = 0x08,
    FAULT_SENSOR_FAIL = 0x10,
    FAULT_WATCHDOG = 0x20,
    FAULT_SHOOT_THROUGH = 0x40
} fault_t;
```

**Fault response:**

```c
void handle_fault(fault_t fault) {
    // Immediate actions
    pwm_emergency_shutdown();      // Turn off all PWM
    disable_gate_drivers();         // Disable drivers
    turn_on_fault_led();           // Visual indication

    // Log fault
    fault_log[fault_count++] = fault;

    // Persistent storage (EEPROM)
    save_fault_to_nvram(fault);

    // Wait for manual reset
    while (1) {
        // Require button press or power cycle to clear
        if (reset_button_pressed()) {
            clear_fault(fault);
            break;
        }
    }
}
```

### Dead-Time Verification

**Critical code section:**

```c
// Hardware timer configuration (STM32)
TIM_BreakDeadTimeConfigTypeDef deadtime_config;
deadtime_config.DeadTime = 84;  // 1μs @ 84MHz

// Verify configuration
uint32_t actual_deadtime = READ_DEADTIME_REGISTER();
if (actual_deadtime != 84) {
    // Configuration error!
    set_fault_flag(FAULT_CONFIG_ERROR);
    Error_Handler();
}
```

---

## Safe Operating Procedures

### Pre-Operation Checklist

**Before EVERY power-on:**

- [ ] Visual inspection for damage
- [ ] All connections secure
- [ ] No foreign objects in enclosure
- [ ] Heatsinks properly attached
- [ ] Cooling (fans) operational
- [ ] Load disconnected (for initial test)
- [ ] Emergency stop accessible
- [ ] Test equipment ready (scope, multimeter)
- [ ] Safety glasses on
- [ ] Work area clear

### Initial Power-Up Sequence

**Step-by-step:**

1. **Verify DC supply polarity**
   - Use multimeter
   - Check voltage level (should be ~50V per bridge)

2. **Connect DC supplies (power OFF)**
   - Bridge 1 positive to DC1+
   - Bridge 1 negative to DC1-
   - Bridge 2 positive to DC2+
   - Bridge 2 negative to DC2-
   - Verify isolation between bridges

3. **Connect control power (5V/3.3V)**
   - Microcontroller should boot
   - Check status LEDs
   - Verify UART communication

4. **Verify PWM outputs (scope)**
   - Enable PWM test mode
   - Check all 8 outputs
   - Verify complementary operation
   - Confirm dead-time present

5. **Power on DC supplies (no load)**
   - Monitor DC bus voltages
   - Check for abnormal behavior
   - Temperature should remain low

6. **Enable PWM with load**
   - Start with resistive load (light bulbs)
   - Monitor current and voltage
   - Check waveform quality on scope
   - Verify protection systems

### Normal Operation

**Continuous monitoring:**

- DC bus voltages
- Output current
- Output voltage
- Heatsink temperatures
- Fault indicators

**Periodic checks:**

- Every 15 minutes: Temperature
- Hourly: Visual inspection
- Daily: Connection tightness
- Weekly: Detailed inspection

### Shutdown Procedure

**Orderly shutdown:**

1. Reduce load gradually (if possible)
2. Disable PWM via software
3. Wait 5 seconds for stored energy discharge
4. Turn off DC supplies
5. Disconnect load
6. Wait 30 seconds before touching any components
7. Verify capacitors discharged (measure voltage)

---

## Emergency Procedures

### Emergency Stop

**Hardware E-Stop:**
- Physical button that cuts all power
- Latching type (requires manual reset)
- Wired to relay/contactor
- Clearly marked red button

**When to use:**
- Smoke or fire
- Unusual sounds (arcing, buzzing)
- Unexpected behavior
- Loss of control
- Any safety concern

### Fire Emergency

**If electrical fire occurs:**

1. **DO NOT use water**
2. Press emergency stop
3. Use CO₂ or class C fire extinguisher
4. Evacuate if fire spreads
5. Call emergency services if needed

**Prevention:**
- Keep fire extinguisher nearby
- No flammable materials near inverter
- Proper ventilation

### Electric Shock Response

**If someone is shocked:**

1. **DO NOT touch the person directly**
2. Cut power immediately (E-stop)
3. Use non-conductive object to separate person from source
4. Call emergency services
5. Administer CPR if trained and necessary

**Prevention:**
- Never work on live circuits alone
- Use one-hand rule when possible
- Wear insulating gloves for high voltage work
- Keep work area dry

---

## Testing Safety

### Lab Testing Requirements

**Minimum safety equipment:**
- Safety glasses (mandatory)
- Insulating gloves (for > 50V)
- Fire extinguisher (CO₂ or Class C)
- Emergency stop button
- First aid kit
- Isolation transformer (recommended)

**Test setup:**
- Clear work area
- Good lighting
- Proper ventilation
- Grounded workbench (ESD mat)
- Scope probes with proper ratings

### Reduced Voltage Testing

**Always start with reduced voltage:**

1. **5V test:** Logic and control only
2. **12V test:** Gate drivers, low-power PWM
3. **24V test:** Partial power operation
4. **50V test:** Full voltage, reduced load
5. **100V test:** Full operation

**Never skip steps!**

### Load Testing

**Progressive loading:**

1. **No load:** Verify PWM, check for oscillations
2. **Resistive load (10%):** Light bulbs, heaters
3. **Resistive load (50%):** Higher power resistors
4. **Inductive load (10%):** Small inductor
5. **Full load:** Rated current and voltage

**Monitor continuously during testing.**

---

## Maintenance and Inspection

### Periodic Inspections

**Monthly:**
- Visual inspection for damage
- Connection tightness
- Dust/debris removal
- Thermal paste condition

**Quarterly:**
- Full electrical inspection
- Insulation resistance test (megger)
- Protection system verification
- Calibration check

**Annually:**
- Complete disassembly and inspection
- Component replacement (capacitors, fans)
- Full functional test
- Documentation update

### Component Lifetime

**Expected lifetimes:**

| Component | Lifetime | Replacement Interval |
|-----------|----------|---------------------|
| Electrolytic caps | 5-10 years | 5 years |
| MOSFETs/IGBTs | 10-20 years | As needed (if failed) |
| Gate drivers | 10-15 years | As needed |
| Fans | 3-5 years | 3 years |
| Fuses | Unlimited | After trip |
| Thermal paste | 2-3 years | 2 years |

### Decommissioning

**Safe disposal:**

1. Discharge all capacitors
2. Remove hazardous materials (if any)
3. Separate recyclable components
4. Follow local e-waste regulations
5. Document disposal

---

## Safety Training

### Required Knowledge

**All operators must understand:**
- Electrical hazard risks
- Protection system operation
- Emergency procedures
- First aid basics
- Equipment limitations

### Recommended Training

- Electrical safety (NFPA 70E or equivalent)
- Arc flash awareness
- CPR and first aid
- Fire extinguisher use
- Lockout/tagout procedures

---

## Disclaimer

**This document provides guidelines but does not guarantee safety.**

**Users are responsible for:**
- Compliance with local regulations
- Proper training and qualifications
- Risk assessment for their application
- Additional safety measures as needed

**The project maintainers assume no liability for:**
- Injury or death
- Property damage
- Regulatory violations
- Consequential damages

**This is an educational/experimental project. Not for commercial use without proper certification.**

---

**Document End**

*For implementation details, see:*
- *`02-embedded/stm32/Core/Src/safety.c` - Software protection*
- *`04-hardware/` - Hardware schematics and PCB design (when available)*
- *CLAUDE.md - General safety considerations*
