#!/usr/bin/env python3
"""Test complete PWM output generation - carrier + sine + comparator"""

def simulate_carrier(freq_div, clocks):
    """Simulate carrier generator"""
    counter = 0
    counter_dir = 0
    carrier_unsigned = 0
    carriers = []

    for _ in range(clocks):
        if counter >= freq_div - 1:
            counter = 0
            if counter_dir == 0:
                counter_dir = 1
                carrier_unsigned = 32767
            else:
                counter_dir = 0
                carrier_unsigned = 0
        else:
            counter += 1
            if counter_dir == 0:
                carrier_unsigned = min(carrier_unsigned + 1, 32767)
            else:
                carrier_unsigned = max(carrier_unsigned - 1, 0)

        carrier1 = carrier_unsigned - 32768  # -32768 to -1
        carrier2 = carrier_unsigned          # 0 to 32767
        carriers.append((carrier1, carrier2))

    return carriers

def simulate_sine(sine_freq, clocks):
    """Simulate sine generator with phase accumulator"""
    import math
    phase_acc = 0
    sines = []

    # Hardware does: freq_increment = {sine_freq[15:0], 16'b0} = sine_freq * 2^16
    freq_increment = sine_freq * 65536

    for _ in range(clocks):
        # phase_acc is 32-bit, increments by freq_increment each clock
        phase_acc = (phase_acc + freq_increment) & 0xFFFFFFFF

        # Convert phase to angle (0 to 2*pi)
        angle = (phase_acc / (2**32)) * 2 * math.pi

        # Generate sine value: -32768 to +32767
        sine_val = int(32767 * math.sin(angle))
        sines.append(sine_val)

    return sines

def pwm_comparator(carrier, sine_ref, mod_index):
    """PWM comparator logic from pwm_comparator.v"""
    # Scale sine reference by modulation index
    # mod_index: 0-65535 represents 0.0-1.0
    scaled_sine = (sine_ref * mod_index) // 65536

    # Compare: PWM high when scaled_sine > carrier
    return 1 if scaled_sine > carrier else 0

def test_pwm_complete(test_sine_freq=None):
    """Test complete PWM generation with actual values from firmware"""
    print("="*80)
    print("COMPLETE PWM OUTPUT SIMULATION")
    print("="*80)

    # Parameters from firmware
    freq_div = 5000
    sine_freq = test_sine_freq if test_sine_freq is not None else 4295
    mod_index = 32768  # 50%
    clocks = 10000  # 1 full carrier period

    print(f"\nParameters:")
    print(f"  freq_div = {freq_div}")
    print(f"  sine_freq = {sine_freq} (0x{sine_freq:04X})")
    print(f"  mod_index = {mod_index} ({(mod_index*100)//65536}%)")
    print(f"  Simulating {clocks} clock cycles")

    # Generate carriers and sine
    print(f"\n[1/4] Generating carriers...")
    carriers = simulate_carrier(freq_div, clocks)

    print(f"[2/4] Generating sine reference...")
    sines = simulate_sine(sine_freq, clocks)

    print(f"[3/4] Running PWM comparators...")

    # Generate PWM outputs for all 8 channels
    pwm_outputs = []
    for i in range(clocks):
        carrier1, carrier2 = carriers[i]
        sine = sines[i]

        # Bridge 1 uses carrier1 (-32768 to -1)
        # Bridge 2 uses carrier2 (0 to 32767)

        # For level-shifted carriers, we compare separately
        ch0_raw = pwm_comparator(carrier1, sine, mod_index)  # S1
        ch2_raw = pwm_comparator(carrier1, sine, mod_index)  # S2 (same as S1 for now)
        ch4_raw = pwm_comparator(carrier2, sine, mod_index)  # S3
        ch6_raw = pwm_comparator(carrier2, sine, mod_index)  # S4 (same as S3 for now)

        # Complementary outputs (inverted)
        ch1_raw = 1 - ch0_raw  # S1'
        ch3_raw = 1 - ch2_raw  # S2'
        ch5_raw = 1 - ch4_raw  # S3'
        ch7_raw = 1 - ch6_raw  # S4'

        pwm = (ch0_raw, ch1_raw, ch2_raw, ch3_raw, ch4_raw, ch5_raw, ch6_raw, ch7_raw)
        pwm_outputs.append(pwm)

    print(f"[4/4] Analyzing outputs...")

    # Count transitions for each channel
    transitions = [0] * 8
    for i in range(1, len(pwm_outputs)):
        for ch in range(8):
            if pwm_outputs[i][ch] != pwm_outputs[i-1][ch]:
                transitions[ch] += 1

    print(f"\nResults:")
    print(f"  Carrier1 range: {min(c[0] for c in carriers)} to {max(c[0] for c in carriers)}")
    print(f"  Carrier2 range: {min(c[1] for c in carriers)} to {max(c[1] for c in carriers)}")
    print(f"  Sine range: {min(sines)} to {max(sines)}")
    print(f"\nPWM Transitions per channel (in {clocks} clocks):")
    for ch in range(8):
        print(f"    CH{ch}: {transitions[ch]} transitions")

    # Check if PWM is working
    total_transitions = sum(transitions)

    print(f"\n  Total transitions: {total_transitions}")

    if total_transitions == 0:
        print(f"\n  [FAIL] NO TRANSITIONS! PWM outputs are STUCK!")
        print(f"  Debugging info:")
        print(f"    First 10 PWM states:")
        for i in range(min(10, len(pwm_outputs))):
            pwm = pwm_outputs[i]
            carrier1, carrier2 = carriers[i]
            sine = sines[i]
            scaled = (sine * mod_index) // 65536
            print(f"      CLK {i}: carr1={carrier1:6d} carr2={carrier2:5d} sine={sine:6d} scaled={scaled:6d} PWM={pwm}")
        return False
    elif total_transitions < 10:
        print(f"\n  [FAIL] Very few transitions! PWM barely switching")
        return False
    else:
        print(f"\n  [PASS] PWM is switching!")

        # Show sample of outputs
        print(f"\n  Sample PWM outputs (first 20 clocks):")
        for i in range(min(20, len(pwm_outputs))):
            pwm = pwm_outputs[i]
            pwm_byte = sum(b << i for i, b in enumerate(pwm))
            print(f"    CLK {i:4d}: {pwm} = 0x{pwm_byte:02X}")

        # Check complementary pairs
        print(f"\n  Checking complementary pairs:")
        pair_errors = 0
        for i in range(len(pwm_outputs)):
            ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7 = pwm_outputs[i]
            if ch0 == ch1:  # Should be opposite
                pair_errors += 1

        if pair_errors > 0:
            print(f"    [FAIL] CH0/CH1 are NOT complementary ({pair_errors} errors)")
            return False
        else:
            print(f"    [PASS] Complementary pairs working")
            return True

if __name__ == '__main__':
    import sys
    sine_freq_arg = int(sys.argv[1]) if len(sys.argv) > 1 else None
    result = test_pwm_complete(sine_freq_arg)
    sys.exit(0 if result else 1)
