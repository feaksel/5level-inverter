# Complete Hardware Fixes for 5-Level Inverter

**Last Updated:** 2025-11-22
**Status:** ✅ **ALL FIXES COMPLETE AND VERIFIED**

---

## Summary of Changes

This document describes the hardware and firmware fixes implemented to achieve:
1. **50 Hz AC output** (proper inverter frequency)
2. **4 level-shifted carriers** (for true 5-level operation)
3. **100% modulation index** (full sine amplitude)
4. **All 8 PWM channels working** (4 complementary pairs)

---

## Problem 1: Sine Frequency Too High (76 kHz instead of 50 Hz)

### Root Cause
The phase accumulator concatenation in `pwm_accelerator.v` used only the lower 16 bits:
```verilog
.freq_increment({sine_freq, 16'd0})  // Multiply by 65536
```

This created frequency steps that were too large, with a minimum achievable frequency of 763 Hz.

### Fix Applied
**File:** `rtl/peripherals/pwm_accelerator.v` (Line 113)

```verilog
// OLD - Could not achieve 50 Hz:
.freq_increment({sine_freq, 16'd0}),

// NEW - Can achieve 50 Hz:
.freq_increment({8'd0, sine_freq, 8'd0}),
```

**Frequency Formula:**
```
OLD: f_out = (sine_freq × 65536 × CLK_FREQ) / 2^32
NEW: f_out = (sine_freq × 256 × CLK_FREQ) / 2^32
```

**For 50 Hz @ 50 MHz clock:**
```
OLD: sine_freq = 0.0655 (impossible - minimum is 1)
NEW: sine_freq = 17 → f_out = 50.664 Hz (1.3% error)
```

### Firmware Update
**File:** `firmware/inverter_firmware_fixed_v2.hex` (Lines 52-57)

```assembly
// OLD - 76 kHz:
addi a0, zero, 100
sw   a0, 16(t1)

// NEW - 50 Hz:
addi a0, zero, 17
sw   a0, 16(t1)
```

**Result:** ✅ Achieved 50.664 Hz (1.3% error from 50 Hz target)

---

## Problem 2: Only 2 Carriers Instead of 4

### Root Cause
The original design was for a 3-level inverter (1 H-bridge, 2 carriers). A 5-level cascaded H-bridge inverter requires 4 separate H-bridges with 4 level-shifted carriers.

### Fix Applied
**File:** `rtl/utils/carrier_generator.v`

Added 2 additional carrier outputs:

```verilog
// OLD - Only 2 carriers:
output reg  signed [CARRIER_WIDTH-1:0]  carrier1,  // -32768 to 0
output reg  signed [CARRIER_WIDTH-1:0]  carrier2,  // 0 to +32767

// NEW - 4 carriers for 5-level:
output reg  signed [CARRIER_WIDTH-1:0]  carrier1,  // -32768 to -16384
output reg  signed [CARRIER_WIDTH-1:0]  carrier2,  // -16384 to 0
output reg  signed [CARRIER_WIDTH-1:0]  carrier3,  // 0 to +16384
output reg  signed [CARRIER_WIDTH-1:0]  carrier4,  // +16384 to +32767
```

**Carrier Generation Logic (Lines 102-120):**
```verilog
// carrier_unsigned goes 0 → 32767 → 0 (triangle wave)
// Scale each to half range and shift to different DC levels

// Carrier 1: -32768 to -16384 (bottom quarter)
carrier1 <= $signed({1'b0, carrier_unsigned[15:1]}) - 16'd32768;

// Carrier 2: -16384 to 0 (lower-mid quarter)
carrier2 <= $signed({1'b0, carrier_unsigned[15:1]}) - 16'd16384;

// Carrier 3: 0 to +16384 (upper-mid quarter)
carrier3 <= $signed({1'b0, carrier_unsigned[15:1]});

// Carrier 4: +16384 to +32767 (top quarter)
carrier4 <= $signed({1'b0, carrier_unsigned[15:1]}) + 16'd16384;
```

**Key Points:**
- Each carrier is a proper triangle wave (0→16383→0)
- Each is shifted to a different DC level
- All carriers have the same frequency (5 kHz)
- This creates the "level-shifted" PWM topology

---

## Problem 3: PWM Comparator Assignments

### Fix Applied
**File:** `rtl/peripherals/pwm_accelerator.v` (Lines 126-180)

Updated all 4 PWM comparators to use the correct carriers:

```verilog
// H-Bridge 1 (S1, S1') - uses carrier1 (-32768 to -16384)
pwm_comparator pwm_comp1 (
    .carrier(carrier1),
    .pwm_high(pwm_out[0]),  // S1
    .pwm_low(pwm_out[1])    // S1'
);

// H-Bridge 2 (S2, S2') - uses carrier2 (-16384 to 0)
pwm_comparator pwm_comp2 (
    .carrier(carrier2),
    .pwm_high(pwm_out[2]),  // S2
    .pwm_low(pwm_out[3])    // S2'
);

// H-Bridge 3 (S3, S3') - uses carrier3 (0 to +16384)
pwm_comparator pwm_comp3 (
    .carrier(carrier3),
    .pwm_high(pwm_out[4]),  // S3
    .pwm_low(pwm_out[5])    // S3'
);

// H-Bridge 4 (S4, S4') - uses carrier4 (+16384 to +32767)
pwm_comparator pwm_comp4 (
    .carrier(carrier4),
    .pwm_high(pwm_out[6]),  // S4
    .pwm_low(pwm_out[7])    // S4'
);
```

**Result:** ✅ All 8 PWM channels now functional

---

## Problem 4: Modulation Index Too Low

### Root Cause
With 50% modulation index (16384), the sine reference only ranged from -16384 to +16384. This didn't properly overlap with:
- **carrier1** (-32768 to -16384): sine was always >= carrier → stuck HIGH
- **carrier4** (+16384 to +32767): sine was always <= carrier → stuck LOW

### Fix Applied
**Testbench:** `tb/pwm_quick_test.v` (Lines 96-99)
```verilog
// OLD - 50% modulation:
write_reg(8'h08, 32'h00004000);  // 16384

// NEW - 100% modulation:
write_reg(8'h08, 32'h00007FFF);  // 32767
```

**Firmware:** `firmware/inverter_firmware_fixed_v2.hex` (Lines 61-65)
```assembly
// OLD - 50% modulation:
lui  a0, 0x4       # 0x00004000 = 16384
sw   a0, 8(t1)

// NEW - 100% modulation:
lui  a0, 0x8       # 0x00008000
addi a0, a0, -1    # 0x00007FFF = 32767
sw   a0, 8(t1)
```

**Result:** ✅ Sine now spans -32768 to +32767, properly modulating all 4 carriers

---

## Verification Results

### Verilog Simulation (Vivado xsim)
```
[PASS] All channels switching!
[PASS] PWM is WORKING with fixed firmware values!

Transitions in 2,000,000 clock cycles (40ms @ 50 MHz):
  CH0 (S1 ): 133 transitions  ✓
  CH1 (S1'): 136 transitions  ✓
  CH2 (S2 ): 69 transitions   ✓
  CH3 (S2'): 70 transitions   ✓
  CH4 (S3 ): 74 transitions   ✓
  CH5 (S3'): 76 transitions   ✓
  CH6 (S4 ): 132 transitions  ✓
  CH7 (S4'): 129 transitions  ✓

Configuration verified:
  FREQ_DIV  = 5000  → 5 kHz carrier
  SINE_FREQ = 17    → 50.664 Hz sine
  MOD_INDEX = 32767 → 100% modulation
  DEADTIME  = 50    → 1 μs dead-time
```

### PWM State Cycling
```
Sample states over 2 sine cycles:
  0x15 → 0x55 → 0x95 → 0xa5 → 0xa8 → 0x85 → 0x15 → ...

Binary breakdown shows all 8 channels actively switching
```

---

## Carrier Voltage Mapping

For 5-level cascaded H-bridge with 4 modules:

```
Signal Flow:
┌───────────────────────────────────────────────────────────────┐
│                  4 Level-Shifted Carriers                     │
├────────┬──────────────┬──────────────┬──────────────┬─────────┤
│Carrier │ Voltage Range│  H-Bridge    │  PWM Outputs │ DC Level│
├────────┼──────────────┼──────────────┼──────────────┼─────────┤
│carrier1│-32768 to     │      1       │ pwm_out[0:1] │ -24576  │
│        │   -16384     │              │   (S1, S1')  │         │
├────────┼──────────────┼──────────────┼──────────────┼─────────┤
│carrier2│-16384 to 0   │      2       │ pwm_out[2:3] │  -8192  │
│        │              │              │   (S2, S2')  │         │
├────────┼──────────────┼──────────────┼──────────────┼─────────┤
│carrier3│     0 to     │      3       │ pwm_out[4:5] │  +8192  │
│        │  +16384      │              │   (S3, S3')  │         │
├────────┼──────────────┼──────────────┼──────────────┼─────────┤
│carrier4│+16384 to     │      4       │ pwm_out[6:7] │ +24576  │
│        │  +32767      │              │   (S4, S4')  │         │
└────────┴──────────────┴──────────────┴──────────────┴─────────┘
```

**Output Voltage Levels:**
When each H-bridge outputs +Vdc, 0, or -Vdc, the total output can be:
```
+4Vdc  = All bridges positive
+3Vdc  = 3 bridges positive, 1 zero
+2Vdc  = 2 bridges positive, 2 zero
+1Vdc  = 1 bridge positive, 3 zero
 0Vdc  = All bridges zero
-1Vdc  = 1 bridge negative, 3 zero
-2Vdc  = 2 bridges negative, 2 zero
-3Vdc  = 3 bridges negative, 1 zero
-4Vdc  = All bridges negative
```

This gives 9 possible voltage levels for high-quality AC synthesis.

---

## Waveform Characteristics

### At 50 Hz with 5 kHz Carrier:
```
Carrier frequency:  5 kHz (200 μs period)
Sine frequency:     50.664 Hz (19.74 ms period)
Ratio:              98.7:1 (nearly 100:1)

Expected waveforms:
- Carriers: 4 triangular waves at different DC levels
- Sine: Slow 50 Hz sinusoid spanning -32768 to +32767
- PWM: Duty cycle varies slowly following sine envelope
- Dead-time: 1 μs gaps between complementary transitions
```

### Viewing Waveforms:
```bash
# Launch Vivado GUI with waveform viewer:
vivado -mode tcl -source view_pwm_waveforms.tcl

# Or run batch simulation:
vivado -mode batch -source run_pwm_test.tcl
```

**Recommended signals to view:**
1. `carrier1`, `carrier2`, `carrier3`, `carrier4` (as Analog or Signed Decimal)
2. `sine_ref` (as Analog or Signed Decimal)
3. `pwm_out[7:0]` (as Digital/Bus)
4. Individual channels: `pwm_out[0]`, `pwm_out[1]`, etc.

---

## Files Modified

### RTL Hardware:
1. ✅ `rtl/utils/carrier_generator.v` - Added carrier3, carrier4 outputs
2. ✅ `rtl/peripherals/pwm_accelerator.v` - Fixed sine frequency, added 4-carrier support

### Firmware:
1. ✅ `firmware/inverter_firmware_fixed_v2.hex` - Updated SINE_FREQ=17, MOD_INDEX=32767

### Testbench:
1. ✅ `tb/pwm_quick_test.v` - Extended runtime, updated parameters

### Documentation:
1. ✅ `HARDWARE_FIXES_COMPLETE.md` (this file)
2. ✅ `LEVEL_SHIFTED_PWM_EXPLAINED.md` (frequency problem analysis)
3. ✅ `view_pwm_waveforms.tcl` (waveform viewer script)

---

## Comparison: Before vs After

| Parameter | Before (Broken) | After (Fixed) | Status |
|-----------|----------------|---------------|--------|
| **Sine Freq** | 76 kHz | 50.664 Hz | ✅ FIXED |
| **Carrier Freq** | 5 kHz | 5 kHz | ✅ Same |
| **Frequency Ratio** | 1:15 (backwards!) | 100:1 (correct!) | ✅ FIXED |
| **Number of Carriers** | 2 | 4 | ✅ FIXED |
| **Modulation Index** | 50% (16384) | 100% (32767) | ✅ FIXED |
| **PWM Channels Working** | 4 (CH2-5 only) | 8 (all) | ✅ FIXED |
| **Carrier Waveforms** | Distorted | Smooth triangles | ✅ FIXED |
| **Suitable for Inverter** | ❌ No | ✅ Yes | ✅ FIXED |

---

## Key Lessons Learned

1. **Phase Accumulator Design:** Bit positioning in concatenation critically affects frequency resolution
2. **Modulation Index Range:** For N-level inverters with level-shifted carriers, need high MI (80-100%)
3. **Signed Arithmetic in Verilog:** Proper use of `$signed()` and bit manipulation for DC level shifting
4. **Simulation Duration:** Need long enough testbench to observe slow modulation (50 Hz = 20 ms period)
5. **Carrier Verification:** Always verify carriers are smooth triangles, not distorted waveforms

---

## Performance Metrics

**System Clock:** 50 MHz
**PWM Switching Frequency:** 5 kHz
**AC Output Frequency:** 50.664 Hz (1.3% error)
**Dead-time:** 1 μs (50 clock cycles)
**Modulation Index:** 100% (full-range)
**Output Levels:** 9 levels (±4Vdc in 1Vdc steps)
**THD (estimated):** <5% (level-shifted PWM with 4 carriers)

---

## Next Steps for Hardware Deployment

1. **Synthesize for FPGA:**
   ```tcl
   launch_runs synth_1
   wait_on_run synth_1
   ```

2. **Implement and generate bitstream:**
   ```tcl
   launch_runs impl_1 -to_step write_bitstream
   wait_on_run impl_1
   ```

3. **Program Basys 3 FPGA:**
   ```tcl
   open_hw_manager
   program_hw_devices [get_hw_devices xc7a35t_0]
   ```

4. **Hardware Testing:**
   - Connect gate driver circuits to Pmod JA and JB
   - Verify 3.3V PWM signals with oscilloscope
   - Measure carrier frequency (should be 5 kHz)
   - Observe sine modulation (should be ~50 Hz)
   - Check dead-time insertion (~1 μs gaps)

5. **Power Stage Connection:**
   - Connect to 4 isolated H-bridge modules
   - Apply DC bus voltage (start low, e.g., 12V)
   - Measure AC output voltage
   - Verify 5-level waveform
   - Calculate THD with spectrum analyzer

---

## Status Summary

✅ **50 Hz sine generation** - WORKING
✅ **4 level-shifted carriers** - WORKING
✅ **All 8 PWM channels** - WORKING
✅ **Complementary pairs with dead-time** - WORKING
✅ **100% modulation index** - WORKING
✅ **Verified in Verilog simulation** - PASSED

**System is ready for FPGA deployment and hardware testing!**

---

**Date:** 2025-11-22
**Version:** 3.0 - All Hardware Fixes Complete
**Author:** 5-Level Inverter Project
