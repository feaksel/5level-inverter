# RISC-V Firmware

This directory contains the firmware for the RISC-V SoC.

## Overview

The firmware is written in C with RISC-V assembly startup code and runs directly on the VexRiscv CPU core.

**Features:**
- Bare-metal firmware (no OS)
- Direct hardware register access
- UART debug output
- Peripheral initialization and control
- Watchdog management
- Fault monitoring

---

## File Structure

```
firmware/
├── README.md           # This file
├── Makefile            # Build system
├── linker.ld           # Linker script (memory layout)
├── crt0.S              # Startup code (assembly)
├── main.c              # Main firmware logic
├── soc_regs.h          # Peripheral register definitions
└── firmware.hex        # Generated hex file (for ROM initialization)
```

---

## Prerequisites

### RISC-V GCC Toolchain

You need the RISC-V cross-compiler toolchain.

**Installation (Ubuntu/Debian):**
```bash
# Option 1: Pre-built toolchain (recommended)
sudo apt-get install gcc-riscv64-unknown-elf

# Option 2: Build from source
git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv32imc --with-abi=ilp32
make
export PATH=/opt/riscv/bin:$PATH
```

**Verify installation:**
```bash
riscv32-unknown-elf-gcc --version
```

---

## Building Firmware

### Quick Start

```bash
# Build firmware
make

# View size information
make info

# Clean build artifacts
make clean
```

### Build Process

The build process:

1. **Compile C code** → `main.o`
2. **Assemble startup code** → `crt0.o`
3. **Link** → `firmware.elf` (using `linker.ld`)
4. **Generate binary** → `firmware.bin`
5. **Generate hex file** → `firmware.hex` (for ROM initialization)
6. **Create listing** → `firmware.lst` (disassembly)

### Output Files

| File | Description |
|------|-------------|
| `firmware.elf` | Executable ELF file (with debug symbols) |
| `firmware.bin` | Raw binary (for external flash programming) |
| `firmware.hex` | Verilog hex format (for ROM initialization) |
| `firmware.lst` | Disassembly listing (for debugging) |
| `firmware.map` | Linker map (symbol addresses) |

---

## Memory Layout

Defined in `linker.ld`:

```
ROM (32 KB): 0x00000000 - 0x00007FFF
  .text     - Code
  .rodata   - Constants and strings

RAM (64 KB): 0x00008000 - 0x00017FFF
  .data     - Initialized variables
  .bss      - Uninitialized variables
  .heap     - Dynamic allocation (8 KB)
  .stack    - Stack (8 KB, grows downward)
```

**Memory Usage:**
- Stack: 8 KB (configurable in `linker.ld`)
- Heap: 8 KB (configurable in `linker.ld`)
- Remaining RAM: ~48 KB for `.data` and `.bss`

---

## Adding New Code

### Adding New Files

1. Create your C/assembly files
2. Add to `Makefile`:
   ```makefile
   C_SRC = main.c your_file.c another_file.c
   ```
3. Rebuild: `make`

### Using Peripheral Registers

All peripherals are defined in `soc_regs.h`:

```c
#include "soc_regs.h"

// Example: Write to PWM peripheral
PWM->CTRL = PWM_CTRL_ENABLE;
PWM->MOD_INDEX = 32768;  // 50% modulation

// Example: Read ADC data
uint32_t adc_value = ADC->DATA_CH0;

// Example: Send UART data
UART->DATA = 'A';
while (!(UART->STATUS & UART_STATUS_TX_EMPTY));
```

### Adding Interrupt Handlers

Basic interrupt support is included. To add handlers:

1. Define handler function:
   ```c
   void __attribute__((interrupt)) timer_irq_handler(void) {
       // Handle timer interrupt
       TIMER->STATUS = TIMER_STATUS_MATCH;  // Clear flag
   }
   ```

2. Set up interrupt vector (in `crt0.S` or early in `main()`)

---

## Debugging

### UART Debug Output

The firmware prints debug messages via UART (115200 baud):

```c
uart_puts("Debug message\r\n");
uart_print_hex(some_value);
```

**Monitor UART on host PC:**
```bash
# Linux
screen /dev/ttyUSB0 115200

# Or use minicom
minicom -D /dev/ttyUSB0 -b 115200
```

### Disassembly Listing

View the generated assembly:

```bash
less firmware.lst
```

### Memory Map

Check symbol addresses:

```bash
less firmware.map
```

### GDB Debugging (Advanced)

If you have JTAG or simulation:

```bash
riscv32-unknown-elf-gdb firmware.elf
(gdb) target remote :3333  # OpenOCD or simulator
(gdb) load
(gdb) break main
(gdb) continue
```

---

## Performance Optimization

### Compiler Flags

Current: `-O2` (good balance of size and speed)

**Options:**
- `-O0`: No optimization (for debugging)
- `-O1`: Minimal optimization
- `-O2`: Default (recommended)
- `-O3`: Maximum optimization (may increase code size)
- `-Os`: Optimize for size

**To change:**
```makefile
# In Makefile
CFLAGS = -march=$(ARCH) -mabi=$(ABI) -Os  # Optimize for size
```

### Code Size Reduction

1. **Enable link-time optimization:**
   ```makefile
   CFLAGS += -flto
   LDFLAGS += -flto
   ```

2. **Remove unused functions:**
   ```makefile
   CFLAGS += -ffunction-sections -fdata-sections
   LDFLAGS += -Wl,--gc-sections
   ```

3. **Use compressed instructions (RV32IMC):**
   - Already enabled via `-march=rv32imc`
   - Saves ~30% code size

---

## Common Issues

### Issue: Toolchain not found

**Error:** `riscv32-unknown-elf-gcc: command not found`

**Solution:** Install RISC-V GCC toolchain (see Prerequisites)

### Issue: Firmware too large

**Error:** `section '.text' will not fit in region 'ROM'`

**Solutions:**
- Remove unused code
- Enable optimization (`-Os`)
- Reduce debug symbols (`-g0`)
- Increase ROM size (modify Verilog and linker script)

### Issue: Stack overflow

**Symptoms:** Crashes, random behavior, corrupted variables

**Solutions:**
- Increase stack size in `linker.ld`
- Reduce recursion and large local variables
- Use heap instead of stack for large arrays

### Issue: Uninitialized variables

**Symptoms:** Variables have random values

**Causes:**
- Forgot to initialize variables
- `.bss` section not properly zeroed

**Solution:** Check `crt0.S` properly zeros `.bss`

---

## ASIC Considerations

When preparing firmware for ASIC tape-out:

1. **Fixed memory map:** Ensure addresses match ASIC memory configuration
2. **No floating-point:** Use fixed-point math (or include FPU in ASIC)
3. **Deterministic timing:** Avoid variable-length operations in critical paths
4. **Low power:** Use WFI (wait-for-interrupt) instruction when idle
5. **Fault tolerance:** Implement watchdog and error checking

---

## Next Steps

After building firmware:

1. **Integrate with FPGA build:**
   ```bash
   cd ..
   make vivado-build  # Automatically includes firmware.hex
   ```

2. **Program FPGA:**
   ```bash
   make vivado-program
   ```

3. **Monitor output:**
   ```bash
   make uart-monitor
   ```

---

## References

- **RISC-V ISA Manual:** https://riscv.org/technical/specifications/
- **VexRiscv Documentation:** https://github.com/SpinalHDL/VexRiscv
- **GCC RISC-V Options:** https://gcc.gnu.org/onlinedocs/gcc/RISC-V-Options.html

---

**Last Updated:** 2025-11-16
