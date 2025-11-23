# Quick PWM test using Vivado xsim
set proj_dir [pwd]
set rtl_dir "$proj_dir/rtl"
set tb_dir "$proj_dir/tb"

puts "================================"
puts "PWM Quick Test with Vivado xsim"
puts "================================"

# Create work library
exec xelab --help >@stdout 2>@stderr || true

# Compile RTL files
puts "\n[1/3] Compiling RTL files..."
exec xvlog -sv "$rtl_dir/utils/sine_generator.v" >@stdout 2>@stderr
exec xvlog -sv "$rtl_dir/utils/carrier_generator.v" >@stdout 2>@stderr
exec xvlog -sv "$rtl_dir/utils/pwm_comparator.v" >@stdout 2>@stderr
exec xvlog -sv "$rtl_dir/peripherals/pwm_accelerator.v" >@stdout 2>@stderr

# Compile testbench
puts "\n[2/3] Compiling testbench..."
exec xvlog -sv "$tb_dir/pwm_quick_test.v" >@stdout 2>@stderr

# Elaborate and simulate
puts "\n[3/3] Running simulation..."
exec xelab pwm_quick_test -debug typical -timescale 1ns/1ps -s pwm_test_sim >@stdout 2>@stderr
exec xsim pwm_test_sim -runall >@stdout 2>@stderr

puts "\n================================"
puts "Simulation Complete!"
puts "================================"
