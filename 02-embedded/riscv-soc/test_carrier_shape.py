#!/usr/bin/env python3
"""
Test to verify carrier waveforms are smooth triangles, not trapezoids.
This calculates what the carrier values should be mathematically.
"""

def test_carrier_generator():
    """Simulate the carrier generator logic"""

    # Parameters
    freq_div = 5000
    carrier_increment = 0x80000000 // freq_div  # 2^31 / 5000 = 429497

    print(f"Carrier Increment: {carrier_increment} (0x{carrier_increment:08X})")
    print(f"Expected after {freq_div} cycles: {carrier_increment * freq_div}")
    print(f"2^31 = {0x80000000}")
    print()

    # Simulate carrier generation
    carrier_phase = 0
    counter_dir = 0  # 0 = up, 1 = down

    samples = []

    # Run for 2 complete periods (20,000 cycles)
    for cycle in range(20000):
        # Extract top 16 bits as carrier_unsigned
        carrier_unsigned = (carrier_phase >> 16) & 0xFFFF

        # Calculate carrier1 (as example)
        carrier1_unsigned = carrier_unsigned >> 1  # Divide by 2
        carrier1 = carrier1_unsigned - 32768  # Signed conversion

        # Store sample every 500 cycles
        if cycle % 500 == 0:
            samples.append((cycle, carrier_unsigned, carrier1))

        # Update phase accumulator
        if counter_dir == 0:
            carrier_phase = (carrier_phase + carrier_increment) & 0xFFFFFFFF
        else:
            carrier_phase = (carrier_phase - carrier_increment) & 0xFFFFFFFF

        # Toggle direction every freq_div cycles
        if (cycle + 1) % freq_div == 0:
            counter_dir = 1 - counter_dir

    # Print samples
    print("Cycle\tCarrier_Unsigned\tCarrier1 (signed)")
    print("=" * 50)
    for cycle, carrier_unsigned, carrier1 in samples:
        print(f"{cycle}\t{carrier_unsigned}\t\t{carrier1}")

    # Check if it's a triangle (should increase then decrease smoothly)
    print("\n" + "=" * 50)
    print("Analysis:")
    print("=" * 50)

    # Check first half (should increase)
    first_half = [s[1] for s in samples[:10]]  # First 5000 cycles
    increasing = all(first_half[i] < first_half[i+1] for i in range(len(first_half)-1))

    # Check second half (should decrease)
    second_half = [s[1] for s in samples[10:20]]  # Second 5000 cycles
    decreasing = all(second_half[i] > second_half[i+1] for i in range(len(second_half)-1))

    # Check peak value
    peak = max(s[1] for s in samples)
    expected_peak = 32767  # Should reach near full scale

    print(f"First half increasing: {increasing} [PASS]" if increasing else f"First half NOT increasing: {increasing} [FAIL]")
    print(f"Second half decreasing: {decreasing} [PASS]" if decreasing else f"Second half NOT decreasing: {decreasing} [FAIL]")
    print(f"Peak value: {peak} (expected ~{expected_peak})")

    if peak > 30000:  # Allow some tolerance
        print(f"Peak is close to full scale [PASS]")
    else:
        print(f"Peak is too low! This is a TRAPEZOID [FAIL]")

    # Check for smooth transitions (no jumps)
    max_step = 0
    for i in range(len(samples)-1):
        step = abs(samples[i+1][1] - samples[i][1])
        if step > max_step:
            max_step = step

    expected_step = (carrier_increment * 500) >> 16  # Step per 500 cycles
    print(f"\nMaximum step between samples (500 cycles apart): {max_step}")
    print(f"Expected step: ~{expected_step}")

    if max_step < expected_step * 1.2:  # Allow 20% tolerance
        print("Steps are smooth (no jumps) [PASS]")
    else:
        print("Large jumps detected! This is a TRAPEZOID [FAIL]")

    print("\n" + "=" * 50)
    if increasing and decreasing and peak > 30000:
        print("RESULT: Carriers are SMOOTH TRIANGLES [PASS]")
    else:
        print("RESULT: Carriers are TRAPEZOIDS (BUG!) [FAIL]")
    print("=" * 50)

if __name__ == "__main__":
    test_carrier_generator()
