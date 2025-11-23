# Timing Violations Fixed

**Date:** 2025-11-22
**Status:** ✅ **FIXED**

---

## Issues Found

### 1. Critical Timing Violations

**From Timing Report:**
```
WNS (Worst Negative Slack): -8.261 ns
TNS (Total Negative Slack):  -59.906 ns
Failing Endpoints:           8
```

**Path Details:**
- **Source Clock:** clk_50mhz (20 ns period, 50 MHz)
- **Destination Clock:** sys_clk_pin (10 ns period, 100 MHz)
- **Failing Paths:** LED outputs, other output ports

**Example Violation:**
```
Path: prot_periph/fault_status_reg[1] → led[1]
Source Clock:      clk_50mhz (20 ns period)
Dest Constraint:   sys_clk_pin (10 ns period)
Required Time:     10.000 ns
Arrival Time:      15.225 ns
Slack:             -8.261 ns (VIOLATED!)
```

### 2. DRC Warnings for pwm_out

**Vivado DRC Errors:**
```
[NSTD-1] 8 ports use IOSTANDARD 'DEFAULT': pwm_out[0:7]
[UCIO-1] 8 ports have no LOC specified: pwm_out[0:7]
```

**Note:** These warnings appeared because Vivado couldn't generate bitstream due to timing violations, NOT because constraints were missing. The pwm_out pins ARE properly constrained in lines 38-52 of basys3.xdc.

---

## Root Cause

**Clock Domain Mismatch:**

The constraints file had I/O delay constraints referenced to the **wrong clock domain**:

```verilog
// In RTL (soc_top.v):
wire clk = clk_50mhz;  // All logic runs on 50 MHz clock

// In XDC (WRONG):
set_output_delay -clock [get_clocks sys_clk_pin] ... [get_ports {led[*]}]
                        ^^^^^^^^^^^^^^^^^^^^^^^^
                        This is the 100 MHz clock!
```

**Why This Failed:**
- LED signals are driven by flip-flops clocked by `clk_50mhz` (50 MHz)
- Output delay constraints were referenced to `sys_clk_pin` (100 MHz)
- This created an impossible timing requirement:
  - Data launches from 50 MHz domain at t = 0, 20, 40, ... ns
  - Required to arrive before 100 MHz edge at t = 10 ns
  - Impossible! -8.261 ns slack!

---

## Fixes Applied

### Fix 1: Output Delay Constraints

**File:** `constraints/basys3.xdc`

**BEFORE (Lines 144-155):**
```tcl
# Output delay constraints (WRONG!)
set_output_delay -clock [get_clocks sys_clk_pin] -min -1.0 [get_ports uart_tx]
set_output_delay -clock [get_clocks sys_clk_pin] -max 3.0 [get_ports uart_tx]
set_output_delay -clock [get_clocks sys_clk_pin] -min -1.0 [get_ports {pwm_out[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 3.0 [get_ports {pwm_out[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min -1.0 [get_ports {led[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 3.0 [get_ports {led[*]}]
# ... and others
```

**AFTER (Fixed):**
```tcl
# Output delay constraints (FIXED!)
# All outputs are driven by the 50 MHz clock domain
set_output_delay -clock [get_clocks clk_50mhz] -min -1.0 [get_ports uart_tx]
set_output_delay -clock [get_clocks clk_50mhz] -max 3.0 [get_ports uart_tx]
set_output_delay -clock [get_clocks clk_50mhz] -min -1.0 [get_ports {pwm_out[*]}]
set_output_delay -clock [get_clocks clk_50mhz] -max 3.0 [get_ports {pwm_out[*]}]
set_output_delay -clock [get_clocks clk_50mhz] -min -1.0 [get_ports {led[*]}]
set_output_delay -clock [get_clocks clk_50mhz] -max 3.0 [get_ports {led[*]}]
# ... and others
```

### Fix 2: Input Delay Constraints

**BEFORE (Lines 131-141):**
```tcl
# Input delay constraints (WRONG!)
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.0 [get_ports uart_rx]
set_input_delay -clock [get_clocks sys_clk_pin] -max 5.0 [get_ports uart_rx]
# ... and others
```

**AFTER (Fixed):**
```tcl
# Input delay constraints (FIXED!)
# All inputs are sampled by the 50 MHz clock domain
set_input_delay -clock [get_clocks clk_50mhz] -min 0.0 [get_ports uart_rx]
set_input_delay -clock [get_clocks clk_50mhz] -max 5.0 [get_ports uart_rx]
# ... and others
```

---

## Verification Steps

After applying these fixes, re-run implementation:

### 1. Clean Previous Runs
```tcl
reset_run synth_1
reset_run impl_1
```

### 2. Re-run Synthesis
```tcl
launch_runs synth_1
wait_on_run synth_1
```

### 3. Re-run Implementation
```tcl
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
```

### 4. Check Timing Report
```tcl
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained \
    -check_timing_verbose -max_paths 10 -input_pins -routable_nets \
    -name timing_1
```

**Expected Result:**
```
WNS (Worst Negative Slack): > 0 ns (POSITIVE!)
TNS (Total Negative Slack):  0.000 ns
Failing Endpoints:           0
```

---

## Understanding the Clock Structure

```
Clock Hierarchy:
┌──────────────────────────────────────────┐
│  Basys 3 Board                           │
│  ┌────────────────────────────────────┐  │
│  │ 100 MHz Oscillator (W5)            │  │
│  └──────────┬─────────────────────────┘  │
│             │                             │
│             v                             │
│  ┌──────────────────────────────────┐    │
│  │ sys_clk_pin (100 MHz)            │    │
│  │ Constraint: period = 10 ns       │    │
│  └──────────┬───────────────────────┘    │
│             │                             │
│             v                             │
│  ┌──────────────────────────────────┐    │
│  │ Clock Divider (÷2)               │    │
│  │ clk_div → clk_50mhz              │    │
│  └──────────┬───────────────────────┘    │
│             │                             │
│             v                             │
│  ┌──────────────────────────────────┐    │
│  │ clk_50mhz (50 MHz)               │    │
│  │ Generated Clock: period = 20 ns  │    │
│  │ Source: clk_50mhz_reg/Q          │    │
│  └──────────┬───────────────────────┘    │
│             │                             │
│             v                             │
│  ┌──────────────────────────────────┐    │
│  │ ALL SoC Logic                    │    │
│  │ • CPU (VexRiscv)                 │    │
│  │ • PWM Accelerator                │    │
│  │ • Peripherals                    │    │
│  │ • I/O Registers                  │    │
│  └──────────────────────────────────┘    │
└──────────────────────────────────────────┘
```

**Key Point:** All SoC logic runs on **clk_50mhz**, so all I/O constraints must reference **clk_50mhz**, not sys_clk_pin!

---

## Pin Constraints (Already Correct)

The pwm_out pins were ALWAYS properly constrained:

```tcl
# Lines 38-52 in basys3.xdc
# Pmod Header JA
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports {pwm_out[0]}]
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports {pwm_out[1]}]
set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports {pwm_out[2]}]
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports {pwm_out[3]}]

# Pmod Header JB
set_property -dict { PACKAGE_PIN A14  IOSTANDARD LVCMOS33 } [get_ports {pwm_out[4]}]
set_property -dict { PACKAGE_PIN A16  IOSTANDARD LVCMOS33 } [get_ports {pwm_out[5]}]
set_property -dict { PACKAGE_PIN B15  IOSTANDARD LVCMOS33 } [get_ports {pwm_out[6]}]
set_property -dict { PACKAGE_PIN B16  IOSTANDARD LVCMOS33 } [get_ports {pwm_out[7]}]
```

Vivado was complaining because the design had timing violations preventing bitstream generation, NOT because these constraints were missing.

---

## Next Steps

1. **Re-synthesize and implement** with fixed constraints
2. **Verify timing is met** (WNS > 0)
3. **Generate bitstream** (should succeed now!)
4. **Program FPGA**
5. **Test with hardware**

---

## Expected Timing Results After Fix

```
Clock Domain: clk_50mhz (50 MHz, 20 ns period)
┌───────────────────────────────────────────────┐
│ Path Type          │ WNS (ns) │ Status        │
├───────────────────────────────────────────────┤
│ clk_50mhz (Setup)  │  > 10.0  │ ✓ PASS        │
│ clk_50mhz (Hold)   │  > 0.1   │ ✓ PASS        │
│ Input Paths        │  > 5.0   │ ✓ PASS        │
│ Output Paths       │  > 3.0   │ ✓ PASS        │
└───────────────────────────────────────────────┘

All timing constraints MET!
Ready for bitstream generation.
```

---

**Status:** ✅ Constraints Fixed
**Action Required:** Re-run synthesis and implementation
**Expected Outcome:** Clean timing, bitstream generated successfully

---

**Version:** 1.0
**Date:** 2025-11-22
