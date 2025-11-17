# XSim batch run script
# This script runs the simulation and saves waveforms

# Open waveform database
open_vcd uart_vivado_test.vcd

# Add all signals to waveform
log_wave -recursive *

# Run simulation until $finish
run all

# Save waveform database
save_wave_config uart_vivado_test.wcfg

# Close and exit
close_vcd
quit
