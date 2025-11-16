# ==============================================================================
# Makefile for RISC-V SoC Firmware
# ==============================================================================

# RISC-V toolchain
PREFIX = riscv32-unknown-elf-

CC = $(PREFIX)gcc
AS = $(PREFIX)as
LD = $(PREFIX)ld
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump
SIZE = $(PREFIX)size

# Target architecture
ARCH = rv32imc
ABI = ilp32

# Compiler flags
CFLAGS = -march=$(ARCH) -mabi=$(ABI) -O2 -g
CFLAGS += -Wall -Wextra -Werror
CFLAGS += -ffreestanding -nostdlib -nostartfiles
CFLAGS += -ffunction-sections -fdata-sections

# Linker flags
LDFLAGS = -march=$(ARCH) -mabi=$(ABI)
LDFLAGS += -T linker.ld
LDFLAGS += -nostdlib -nostartfiles
LDFLAGS += -Wl,--gc-sections

# Source files
ASM_SRC = crt0.S
C_SRC = main.c

# Object files
ASM_OBJ = $(ASM_SRC:.S=.o)
C_OBJ = $(C_SRC:.c=.o)
OBJS = $(ASM_OBJ) $(C_OBJ)

# Output files
TARGET = firmware
ELF = $(TARGET).elf
BIN = $(TARGET).bin
HEX = $(TARGET).hex
LST = $(TARGET).lst
MAP = $(TARGET).map

# ==============================================================================
# Targets
# ==============================================================================

.PHONY: all clean info

all: $(HEX) $(BIN) $(LST)
	@echo ""
	@echo "====================================="
	@echo "Firmware build complete!"
	@echo "====================================="
	@echo "ELF:  $(ELF)"
	@echo "BIN:  $(BIN)"
	@echo "HEX:  $(HEX)"
	@echo "LST:  $(LST)"
	@echo "MAP:  $(MAP)"
	@echo ""
	@$(SIZE) $(ELF)
	@echo ""

# Compile C files
%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Compile assembly files
%.o: %.S
	@echo "Assembling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Link
$(ELF): $(OBJS) linker.ld
	@echo "Linking..."
	$(CC) $(LDFLAGS) $(OBJS) -o $@ -Wl,-Map=$(MAP)

# Generate binary
$(BIN): $(ELF)
	@echo "Generating binary..."
	$(OBJCOPY) -O binary $< $@

# Generate hex file (for ROM initialization)
$(HEX): $(ELF)
	@echo "Generating hex file..."
	$(OBJCOPY) -O verilog $< $@

# Generate listing
$(LST): $(ELF)
	@echo "Generating listing..."
	$(OBJDUMP) -D -S $< > $@

# Display size information
info: $(ELF)
	@echo ""
	@echo "====================================="
	@echo "Firmware Size Information"
	@echo "====================================="
	@$(SIZE) -A -x $(ELF)
	@echo ""
	@echo "Memory Usage:"
	@$(SIZE) -B $(ELF)
	@echo ""

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -f $(OBJS) $(ELF) $(BIN) $(HEX) $(LST) $(MAP)
	@echo "Clean complete."

# ==============================================================================
# Help
# ==============================================================================

help:
	@echo "RISC-V Firmware Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build firmware (default)"
	@echo "  clean    - Remove build artifacts"
	@echo "  info     - Display size information"
	@echo "  help     - Show this help message"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - RISC-V GCC toolchain (riscv32-unknown-elf-gcc)"
	@echo "  - Install: https://github.com/riscv-collab/riscv-gnu-toolchain"
	@echo ""
	@echo "Output files:"
	@echo "  $(ELF) - Executable ELF file"
	@echo "  $(BIN) - Raw binary"
	@echo "  $(HEX) - Verilog hex format (for ROM initialization)"
	@echo "  $(LST) - Disassembly listing"
	@echo "  $(MAP) - Linker map file"
	@echo ""
