#!/usr/bin/env python3
"""
Convert Verilog hex format to $readmemh format
Input: Intel HEX-like format with @ addresses and space-separated bytes
Output: One 32-bit hex word per line (little-endian)
"""

import sys

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} <input.hex> <output.mem>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

# Read hex file
with open(input_file, "r") as f:
    lines = f.readlines()

# Parse hex bytes
hex_bytes = []
for line in lines:
    line = line.strip()
    if line.startswith("@"):
        continue
    hex_bytes.extend(line.split())

# Convert to 32-bit words (little-endian)
words = []
for i in range(0, len(hex_bytes), 4):
    if i + 3 < len(hex_bytes):
        b0 = int(hex_bytes[i], 16)
        b1 = int(hex_bytes[i + 1], 16)
        b2 = int(hex_bytes[i + 2], 16)
        b3 = int(hex_bytes[i + 3], 16)
        word = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
        words.append(f"{word:08x}")

# Write mem file
with open(output_file, "w") as f:
    for word in words:
        f.write(f"{word}\n")

print(f"Converted {len(hex_bytes)} bytes to {len(words)} words")
