#!/usr/bin/env python3
"""
Waveform Analyzer for 5-Level Inverter
Analyzes CSV data logged from STM32 via UART

Usage:
    python waveform_analyzer.py data.csv
    python waveform_analyzer.py data.csv --plot --save-fig output.png

Author: 5-Level Inverter Project
Date: 2025-11-15
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import signal
from scipy.fft import fft, fftfreq
import argparse
import sys
from pathlib import Path


class WaveformAnalyzer:
    """Analyzes waveform data from 5-level inverter"""

    def __init__(self, csv_file, sampling_freq=5000):
        """
        Initialize analyzer

        Args:
            csv_file: Path to CSV file
            sampling_freq: Sampling frequency in Hz (default: 5000 Hz)
        """
        self.csv_file = Path(csv_file)
        self.fs = sampling_freq
        self.data = None
        self.stats = {}

    def load_data(self):
        """Load CSV data from file"""
        try:
            self.data = pd.read_csv(self.csv_file)
            print(f"Loaded {len(self.data)} samples from {self.csv_file}")
            print(f"Columns: {list(self.data.columns)}")
            return True
        except Exception as e:
            print(f"Error loading CSV: {e}")
            return False

    def calculate_rms(self, signal_data):
        """Calculate RMS value of signal"""
        return np.sqrt(np.mean(signal_data**2))

    def calculate_thd(self, signal_data, fundamental_freq=50):
        """
        Calculate Total Harmonic Distortion (THD)

        Args:
            signal_data: Time-domain signal
            fundamental_freq: Fundamental frequency in Hz

        Returns:
            THD percentage, fundamental amplitude, harmonic amplitudes dict
        """
        # Perform FFT
        N = len(signal_data)
        yf = fft(signal_data)
        xf = fftfreq(N, 1/self.fs)[:N//2]
        magnitude = 2.0/N * np.abs(yf[0:N//2])

        # Find fundamental frequency bin
        fund_bin = int(fundamental_freq * N / self.fs)
        fund_amplitude = magnitude[fund_bin]

        # Calculate harmonics (2nd through 10th)
        harmonics = {}
        harmonic_power = 0
        for h in range(2, 11):
            h_bin = int(h * fundamental_freq * N / self.fs)
            if h_bin < len(magnitude):
                h_amp = magnitude[h_bin]
                harmonics[h] = h_amp
                harmonic_power += h_amp**2

        # THD calculation
        thd = 100 * np.sqrt(harmonic_power) / fund_amplitude if fund_amplitude > 0 else 0

        return thd, fund_amplitude, harmonics

    def analyze_current(self):
        """Analyze current waveform"""
        if 'current_A' not in self.data.columns:
            print("Warning: No current_A column found")
            return

        current = self.data['current_A'].values

        # RMS
        i_rms = self.calculate_rms(current)

        # Peak values
        i_peak = np.max(np.abs(current))
        i_max = np.max(current)
        i_min = np.min(current)

        # THD
        thd, fund_amp, harmonics = self.calculate_thd(current)

        self.stats['current'] = {
            'rms': i_rms,
            'peak': i_peak,
            'max': i_max,
            'min': i_min,
            'thd_percent': thd,
            'fundamental_amp': fund_amp,
            'harmonics': harmonics
        }

        print("\n=== Current Analysis ===")
        print(f"RMS:        {i_rms:.3f} A")
        print(f"Peak:       {i_peak:.3f} A")
        print(f"Range:      {i_min:.3f} to {i_max:.3f} A")
        print(f"THD:        {thd:.2f}%")
        print(f"Fundamental: {fund_amp:.3f} A")

    def analyze_voltage(self):
        """Analyze voltage waveform"""
        if 'voltage_V' not in self.data.columns:
            print("Warning: No voltage_V column found")
            return

        voltage = self.data['voltage_V'].values

        # RMS
        v_rms = self.calculate_rms(voltage)

        # Peak values
        v_peak = np.max(np.abs(voltage))
        v_max = np.max(voltage)
        v_min = np.min(voltage)

        # THD
        thd, fund_amp, harmonics = self.calculate_thd(voltage)

        self.stats['voltage'] = {
            'rms': v_rms,
            'peak': v_peak,
            'max': v_max,
            'min': v_min,
            'thd_percent': thd,
            'fundamental_amp': fund_amp,
            'harmonics': harmonics
        }

        print("\n=== Voltage Analysis ===")
        print(f"RMS:        {v_rms:.1f} V")
        print(f"Peak:       {v_peak:.1f} V")
        print(f"Range:      {v_min:.1f} to {v_max:.1f} V")
        print(f"THD:        {thd:.2f}%")
        print(f"Fundamental: {fund_amp:.1f} V")

    def analyze_power(self):
        """Calculate power metrics"""
        if 'current_A' not in self.data.columns or 'voltage_V' not in self.data.columns:
            print("Warning: Cannot calculate power - missing current or voltage data")
            return

        current = self.data['current_A'].values
        voltage = self.data['voltage_V'].values

        # Instantaneous power
        power = current * voltage

        # Average power (real power)
        p_avg = np.mean(power)

        # Apparent power
        s = self.stats['voltage']['rms'] * self.stats['current']['rms']

        # Power factor
        pf = p_avg / s if s > 0 else 0

        self.stats['power'] = {
            'real_W': p_avg,
            'apparent_VA': s,
            'power_factor': pf
        }

        print("\n=== Power Analysis ===")
        print(f"Real Power:     {p_avg:.1f} W")
        print(f"Apparent Power: {s:.1f} VA")
        print(f"Power Factor:   {pf:.3f}")

    def plot_waveforms(self, save_fig=None):
        """Plot waveforms"""
        if self.data is None:
            print("Error: No data loaded")
            return

        # Create time axis
        if 'time_ms' in self.data.columns:
            time = self.data['time_ms'].values / 1000  # Convert to seconds
        else:
            time = np.arange(len(self.data)) / self.fs

        # Create figure with subplots
        fig, axes = plt.subplots(3, 1, figsize=(12, 10))

        # Plot current
        if 'current_A' in self.data.columns:
            axes[0].plot(time, self.data['current_A'], 'b-', linewidth=0.8)
            axes[0].set_ylabel('Current (A)', fontsize=10)
            axes[0].grid(True, alpha=0.3)
            axes[0].set_title('Output Current Waveform', fontsize=12, fontweight='bold')
            if 'current' in self.stats:
                axes[0].axhline(y=self.stats['current']['rms'], color='r',
                               linestyle='--', label=f"RMS: {self.stats['current']['rms']:.2f}A")
                axes[0].legend(loc='upper right')

        # Plot voltage
        if 'voltage_V' in self.data.columns:
            axes[1].plot(time, self.data['voltage_V'], 'r-', linewidth=0.8)
            axes[1].set_ylabel('Voltage (V)', fontsize=10)
            axes[1].grid(True, alpha=0.3)
            axes[1].set_title('Output Voltage Waveform', fontsize=12, fontweight='bold')
            if 'voltage' in self.stats:
                axes[1].axhline(y=self.stats['voltage']['rms'], color='b',
                               linestyle='--', label=f"RMS: {self.stats['voltage']['rms']:.1f}V")
                axes[1].legend(loc='upper right')

        # Plot duty cycles
        if 'duty1' in self.data.columns and 'duty2' in self.data.columns:
            axes[2].plot(time, self.data['duty1'], 'g-', linewidth=0.8, label='Duty 1 (H-Bridge 1)')
            axes[2].plot(time, self.data['duty2'], 'm-', linewidth=0.8, label='Duty 2 (H-Bridge 2)')
            axes[2].set_ylabel('Duty Cycle', fontsize=10)
            axes[2].set_xlabel('Time (s)', fontsize=10)
            axes[2].grid(True, alpha=0.3)
            axes[2].set_title('PWM Duty Cycles', fontsize=12, fontweight='bold')
            axes[2].legend(loc='upper right')

        plt.tight_layout()

        if save_fig:
            plt.savefig(save_fig, dpi=300, bbox_inches='tight')
            print(f"\nFigure saved to {save_fig}")
        else:
            plt.show()

    def plot_fft(self, save_fig=None):
        """Plot FFT spectrum"""
        if self.data is None:
            print("Error: No data loaded")
            return

        fig, axes = plt.subplots(2, 1, figsize=(12, 8))

        # Current FFT
        if 'current_A' in self.data.columns:
            current = self.data['current_A'].values
            N = len(current)
            yf = fft(current)
            xf = fftfreq(N, 1/self.fs)[:N//2]
            magnitude = 2.0/N * np.abs(yf[0:N//2])

            axes[0].plot(xf, magnitude, 'b-', linewidth=0.8)
            axes[0].set_xlim(0, 1000)  # Show up to 1 kHz
            axes[0].set_ylabel('Magnitude (A)', fontsize=10)
            axes[0].set_title('Current Frequency Spectrum', fontsize=12, fontweight='bold')
            axes[0].grid(True, alpha=0.3)

            # Mark harmonics
            for h in range(1, 11):
                axes[0].axvline(x=h*50, color='r', linestyle='--', alpha=0.3, linewidth=0.5)

        # Voltage FFT
        if 'voltage_V' in self.data.columns:
            voltage = self.data['voltage_V'].values
            N = len(voltage)
            yf = fft(voltage)
            xf = fftfreq(N, 1/self.fs)[:N//2]
            magnitude = 2.0/N * np.abs(yf[0:N//2])

            axes[1].plot(xf, magnitude, 'r-', linewidth=0.8)
            axes[1].set_xlim(0, 1000)  # Show up to 1 kHz
            axes[1].set_xlabel('Frequency (Hz)', fontsize=10)
            axes[1].set_ylabel('Magnitude (V)', fontsize=10)
            axes[1].set_title('Voltage Frequency Spectrum', fontsize=12, fontweight='bold')
            axes[1].grid(True, alpha=0.3)

            # Mark harmonics
            for h in range(1, 11):
                axes[1].axvline(x=h*50, color='b', linestyle='--', alpha=0.3, linewidth=0.5)

        plt.tight_layout()

        if save_fig:
            plt.savefig(save_fig, dpi=300, bbox_inches='tight')
            print(f"\nFFT figure saved to {save_fig}")
        else:
            plt.show()

    def generate_report(self, output_file=None):
        """Generate analysis report"""
        report = []
        report.append("=" * 60)
        report.append("5-LEVEL INVERTER WAVEFORM ANALYSIS REPORT")
        report.append("=" * 60)
        report.append(f"\nData File: {self.csv_file}")
        report.append(f"Samples: {len(self.data)}")
        report.append(f"Sampling Frequency: {self.fs} Hz")
        report.append(f"Duration: {len(self.data)/self.fs:.2f} seconds")

        if 'current' in self.stats:
            report.append("\n--- CURRENT ANALYSIS ---")
            report.append(f"RMS:              {self.stats['current']['rms']:.3f} A")
            report.append(f"Peak:             {self.stats['current']['peak']:.3f} A")
            report.append(f"THD:              {self.stats['current']['thd_percent']:.2f}%")
            report.append(f"Fundamental Amp:  {self.stats['current']['fundamental_amp']:.3f} A")
            report.append("\nHarmonics:")
            for h, amp in self.stats['current']['harmonics'].items():
                percent = 100 * amp / self.stats['current']['fundamental_amp']
                report.append(f"  {h}th: {amp:.3f} A ({percent:.1f}%)")

        if 'voltage' in self.stats:
            report.append("\n--- VOLTAGE ANALYSIS ---")
            report.append(f"RMS:              {self.stats['voltage']['rms']:.1f} V")
            report.append(f"Peak:             {self.stats['voltage']['peak']:.1f} V")
            report.append(f"THD:              {self.stats['voltage']['thd_percent']:.2f}%")
            report.append(f"Fundamental Amp:  {self.stats['voltage']['fundamental_amp']:.1f} V")
            report.append("\nHarmonics:")
            for h, amp in self.stats['voltage']['harmonics'].items():
                percent = 100 * amp / self.stats['voltage']['fundamental_amp']
                report.append(f"  {h}th: {amp:.1f} V ({percent:.1f}%)")

        if 'power' in self.stats:
            report.append("\n--- POWER ANALYSIS ---")
            report.append(f"Real Power:       {self.stats['power']['real_W']:.1f} W")
            report.append(f"Apparent Power:   {self.stats['power']['apparent_VA']:.1f} VA")
            report.append(f"Power Factor:     {self.stats['power']['power_factor']:.3f}")

        report.append("\n" + "=" * 60)

        report_text = "\n".join(report)

        if output_file:
            with open(output_file, 'w') as f:
                f.write(report_text)
            print(f"\nReport saved to {output_file}")
        else:
            print("\n" + report_text)


def main():
    parser = argparse.ArgumentParser(description='Analyze 5-level inverter waveform data')
    parser.add_argument('csv_file', help='CSV file with waveform data')
    parser.add_argument('--fs', type=float, default=5000, help='Sampling frequency (Hz)')
    parser.add_argument('--plot', action='store_true', help='Show waveform plots')
    parser.add_argument('--fft', action='store_true', help='Show FFT plots')
    parser.add_argument('--save-fig', help='Save plot to file')
    parser.add_argument('--save-fft', help='Save FFT plot to file')
    parser.add_argument('--report', help='Save analysis report to file')

    args = parser.parse_args()

    # Check if file exists
    if not Path(args.csv_file).exists():
        print(f"Error: File '{args.csv_file}' not found")
        sys.exit(1)

    # Create analyzer
    analyzer = WaveformAnalyzer(args.csv_file, args.fs)

    # Load data
    if not analyzer.load_data():
        sys.exit(1)

    # Perform analysis
    analyzer.analyze_current()
    analyzer.analyze_voltage()
    analyzer.analyze_power()

    # Generate report
    analyzer.generate_report(args.report)

    # Plot if requested
    if args.plot or args.save_fig:
        analyzer.plot_waveforms(args.save_fig)

    if args.fft or args.save_fft:
        analyzer.plot_fft(args.save_fft)


if __name__ == '__main__':
    main()
