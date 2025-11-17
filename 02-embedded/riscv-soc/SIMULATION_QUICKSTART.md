# UART Simulation Quick Start Guide

This guide shows you how to quickly verify the RISC-V SoC UART module works correctly, including verification that the **tx_empty race condition is fixed**.

## What Was Fixed

The UART module had a race condition where the `tx_empty` flag was being set every clock cycle in the TX_IDLE state. This caused:
- **Symptom**: Second character transmission delayed by seconds instead of milliseconds
- **Root Cause**: Line 123 in `uart.v` was setting `tx_empty = 1'b1` every cycle
- **Fix**: Only set `tx_empty = 1'b1` when transmission actually completes (line 167)

## Quick Test (Recommended)

The easiest way to verify the UART is working is to use the automated test script:

```bash
cd 02-embedded/riscv-soc
./run_uart_test.sh
```

This script will:
1. Auto-detect available simulation tools (Icarus Verilog or Vivado)
2. Compile the UART module and testbench
3. Run comprehensive tests
4. Display clear PASS/FAIL results

### Expected Output

If everything is working, you'll see:

```
================================================================================
                           TEST SUMMARY
================================================================================
Total Tests:    23
Tests Passed:   23
Tests Failed:   0
Characters Sent:     9
Characters Received: 9

     ██████╗  █████╗ ███████╗███████╗
     ██╔══██╗██╔══██╗██╔════╝██╔════╝
     ██████╔╝███████║███████╗███████╗
     ██╔═══╝ ██╔══██║╚════██║╚════██║
     ██║     ██║  ██║███████║███████║
     ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝

     ✓ ALL TESTS PASSED!
     ✓ UART tx_empty race condition is FIXED
     ✓ UART is working correctly
```

## Installation

### Option 1: Icarus Verilog (Open Source - Recommended for Quick Tests)

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave
```

**macOS:**
```bash
brew install icarus-verilog gtkwave
```

**Verify installation:**
```bash
iverilog -v
```

### Option 2: Vivado (Commercial - Full FPGA Toolchain)

1. Download Vivado from Xilinx website (WebPACK edition is free)
2. Install following Xilinx instructions
3. Source settings:
   ```bash
   source /tools/Xilinx/Vivado/2023.2/settings64.sh  # Adjust path
   ```

**Verify installation:**
```bash
xvlog -version
```

## Manual Simulation

If you prefer to run simulations manually:

### With Icarus Verilog

```bash
cd 02-embedded/riscv-soc

# Create simulation directory
mkdir -p sim

# Compile
iverilog -g2012 -o sim/uart_test.vvp \
    rtl/peripherals/uart.v \
    tb/uart_vivado_test.v

# Run
vvp sim/uart_test.vvp

# View waveform (optional)
gtkwave sim/uart_vivado_test.vcd
```

### With Vivado XSim

```bash
cd 02-embedded/riscv-soc/sim

# Compile
xvlog ../rtl/peripherals/uart.v
xvlog ../tb/uart_vivado_test.v

# Elaborate
xelab uart_vivado_test -debug typical -s uart_sim

# Run
xsim uart_sim -runall -log uart_test.log

# View waveform (optional)
xsim --gui uart_sim
```

### With Vivado GUI (Full Project)

If you have a Vivado project created:

```bash
cd 02-embedded/riscv-soc
vivado build/riscv_soc.xpr
```

Then in Vivado GUI:
1. Click **Flow Navigator** → **Simulation** → **Run Simulation** → **Run Behavioral Simulation**
2. In the TCL Console at bottom: `set_property top uart_vivado_test [get_filesets sim_1]`
3. Right-click **Simulation Sources** → **Add Sources** → Add `tb/uart_vivado_test.v`
4. Click **Run** → **Restart** then **Run All**
5. View results in TCL Console and waveform window

## Test Coverage

The `uart_vivado_test.v` testbench verifies:

### Test 1: Basic Register Access
- ✓ Read STATUS register (TX_EMPTY should be 1 after reset)
- ✓ Read CTRL register (TX/RX enabled by default)
- ✓ Wishbone bus interface working

### Test 2: Single Character Transmission
- ✓ Send 'A' (0x41) via TX
- ✓ Character received correctly
- ✓ Transmission timing reasonable

### Test 3: Back-to-Back Transmission (**Critical Test for Race Condition**)
- ✓ Send 'B' then 'C' immediately
- ✓ Both characters received
- ✓ **Timing < 1ms** (not seconds!) - proves race condition is fixed
- ✓ tx_empty flag behavior correct

### Test 4: Multiple Characters
- ✓ Send string "HELLO"
- ✓ All 5 characters received in order
- ✓ No data corruption

### Test 5: UART RX
- ✓ Receive byte from external device (via uart_rx pin)
- ✓ RX_READY flag set correctly
- ✓ Data read correctly from register
- ✓ RX_READY cleared after read

### Test 6: Status Flags
- ✓ TX_EMPTY = 0 during transmission
- ✓ TX_EMPTY = 1 when idle
- ✓ Flag transitions at correct times

## Troubleshooting

### Problem: "iverilog: command not found"

**Solution**: Install Icarus Verilog (see Installation section above)

### Problem: "xvlog: command not found"

**Solution**: Either:
1. Install Vivado and source settings64.sh
2. Use Icarus Verilog instead (easier for quick tests)

### Problem: Simulation hangs or times out

**Possible causes**:
1. **Race condition still present** - check if uart.v lines 123-124 have the fix
2. **Wrong baud rate** - verify CLK_FREQ and BAUD_RATE parameters match
3. **Missing files** - ensure all files are present in rtl/peripherals/ and tb/

**Check the fix is present**:
```bash
grep -A 3 "TX_IDLE:" rtl/peripherals/uart.v
```

Should show:
```verilog
TX_IDLE: begin
    uart_tx <= 1'b1;
    // tx_empty is set in TX_STOP when transmission completes
    // Removed race condition: was setting tx_empty=1 every cycle here
```

### Problem: Tests fail

**Check simulation log**:
```bash
cat sim/uart_test.log
```

Look for `[FAIL]` messages which will indicate what went wrong.

### Problem: Waveform not created

**Icarus Verilog**: Make sure `$dumpfile` and `$dumpvars` are in testbench (they are in uart_vivado_test.v)

**Vivado**: Use `--debug typical` or `--debug all` when running xelab

## Viewing Waveforms

Waveforms help you visually debug timing issues.

### GTKWave (Icarus Verilog)

```bash
gtkwave sim/uart_vivado_test.vcd
```

**Signals to add**:
- `dut.tx_state` - TX state machine
- `dut.tx_empty` - **Critical**: Watch this flag transition
- `dut.uart_tx` - Serial output
- `wb_stb`, `wb_ack` - Wishbone bus activity
- `chars_sent`, `chars_received` - Progress counters

### Vivado Waveform Viewer

```bash
cd sim
xsim --gui uart_sim
```

Then add signals from Objects window to waveform.

## Key Timing Values

Understanding these helps interpret simulation results:

| Parameter | Value | Notes |
|-----------|-------|-------|
| Clock Frequency | 50 MHz | 20 ns period |
| Baud Rate | 115200 bps | Standard UART speed |
| Bit Period | ~8680 ns | 1 / 115200 |
| Character Time | ~86,800 ns | 10 bits × 8680 ns |
| 2 Characters | ~173,600 ns | **0.174 ms** |

**Critical**: If back-to-back characters take > 1ms, race condition is present!

## What to Look For

### Good Behavior (Race Condition Fixed)
```
[TIME=245720] Writing 'B' to UART...
    [INFO] TX completed (polled 217 times)
[TIME=419960] Writing 'C' to UART immediately...
    [INFO] TX completed (polled 219 times)
  Total time for 2 chars: 174240 ns (0.174 ms)
  Expected time: ~173600 ns (0.174 ms)
  [PASS] Timing is fast (race condition FIXED)
```

### Bad Behavior (Race Condition Present)
```
[TIME=245720] Writing 'B' to UART...
    [INFO] TX completed (polled 217 times)
[TIME=419960] Writing 'C' to UART immediately...
    [ERROR] TX timeout after 100000 polls!
ERROR: Simulation timeout!
```

## Integration with Full SoC

Once UART is verified, you can test it in the full SoC:

```bash
# Compile full SoC
make firmware          # Build RISC-V firmware
make sim-soc          # Simulate complete SoC

# Or use Vivado
vivado -mode batch -source vivado/sim.tcl -tclargs soc_top_tb
```

## Next Steps

After UART verification passes:

1. **✓ UART verified** - You're here!
2. Test other peripherals (PWM, ADC, Protection, Timer, GPIO)
3. Run full SoC simulation with firmware
4. Synthesize for FPGA
5. Test on hardware (Basys 3 board)

## Files Reference

| File | Purpose |
|------|---------|
| `rtl/peripherals/uart.v` | UART module implementation (333 lines) |
| `tb/uart_vivado_test.v` | Comprehensive testbench (650+ lines) |
| `run_uart_test.sh` | Automated test script |
| `vivado/sim_uart_quick.tcl` | Vivado batch simulation |
| `sim/uart_test.log` | Simulation output (created after run) |
| `sim/uart_vivado_test.vcd` | Waveform data (created after run) |

## Support

If tests fail or you encounter issues:

1. Check this guide's **Troubleshooting** section
2. Review the detailed logs in `sim/uart_test.log`
3. View waveforms to debug timing
4. Check that uart.v has the race condition fix (lines 123-124, 167)
5. Verify simulation tool installation

## Summary

**To quickly verify UART is working:**

```bash
cd 02-embedded/riscv-soc
./run_uart_test.sh
```

**Expected result**: "ALL TESTS PASSED" message

**Critical test**: Back-to-back transmission takes ~0.174ms (not seconds!)

This confirms the tx_empty race condition is fixed and UART is ready for use! 🎉
