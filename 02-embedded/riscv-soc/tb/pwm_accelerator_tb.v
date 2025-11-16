/**
 * @file pwm_accelerator_tb.v
 * @brief Testbench for PWM Accelerator Peripheral
 *
 * Tests:
 * - Wishbone register read/write
 * - PWM generation in auto sine mode
 * - PWM generation in manual mode
 * - Dead-time insertion
 * - Fault handling
 * - Carrier synchronization
 */

`timescale 1ns / 1ps

module pwm_accelerator_tb;

    //==========================================================================
    // Parameters
    //==========================================================================

    parameter CLK_FREQ = 50_000_000;
    parameter CLK_PERIOD = 1000_000_000 / CLK_FREQ;  // 20 ns
    parameter ADDR_WIDTH = 8;

    //==========================================================================
    // Signals
    //==========================================================================

    // Clock and reset
    reg clk;
    reg rst_n;

    // Wishbone signals
    reg  [ADDR_WIDTH-1:0] wb_addr;
    reg  [31:0]           wb_dat_i;
    wire [31:0]           wb_dat_o;
    reg                   wb_we;
    reg  [3:0]            wb_sel;
    reg                   wb_stb;
    wire                  wb_ack;

    // PWM outputs
    wire [7:0] pwm_out;

    // Fault input
    reg fault;

    // Test control
    integer errors = 0;
    integer test_num = 0;

    //==========================================================================
    // DUT Instantiation
    //==========================================================================

    pwm_accelerator #(
        .CLK_FREQ(CLK_FREQ),
        .PWM_FREQ(5000),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wb_addr(wb_addr),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_stb(wb_stb),
        .wb_ack(wb_ack),
        .pwm_out(pwm_out),
        .fault(fault)
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //==========================================================================
    // Wishbone Tasks
    //==========================================================================

    // Wishbone write task
    task wb_write;
        input [ADDR_WIDTH-1:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            wb_addr = addr;
            wb_dat_i = data;
            wb_we = 1'b1;
            wb_sel = 4'hF;
            wb_stb = 1'b1;

            // Wait for ack
            @(posedge clk);
            while (!wb_ack) @(posedge clk);

            wb_stb = 1'b0;
            wb_we = 1'b0;
            @(posedge clk);
        end
    endtask

    // Wishbone read task
    task wb_read;
        input  [ADDR_WIDTH-1:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            wb_addr = addr;
            wb_we = 1'b0;
            wb_sel = 4'hF;
            wb_stb = 1'b1;

            // Wait for ack
            @(posedge clk);
            while (!wb_ack) @(posedge clk);

            data = wb_dat_o;
            wb_stb = 1'b0;
            @(posedge clk);
        end
    endtask

    //==========================================================================
    // Test Tasks
    //==========================================================================

    task test_start;
        input [200*8:1] test_name;
        begin
            test_num = test_num + 1;
            $display("");
            $display("========================================");
            $display("Test %0d: %s", test_num, test_name);
            $display("========================================");
        end
    endtask

    task test_check;
        input condition;
        input [200*8:1] msg;
        begin
            if (!condition) begin
                $display("  [FAIL] %s", msg);
                errors = errors + 1;
            end else begin
                $display("  [PASS] %s", msg);
            end
        end
    endtask

    //==========================================================================
    // Test Stimulus
    //==========================================================================

    initial begin
        // Initialize waveform dump
        $dumpfile("sim/pwm_accelerator_tb.vcd");
        $dumpvars(0, pwm_accelerator_tb);

        // Initialize signals
        rst_n = 0;
        wb_addr = 0;
        wb_dat_i = 0;
        wb_we = 0;
        wb_sel = 0;
        wb_stb = 0;
        fault = 0;

        // Apply reset
        #100;
        rst_n = 1;
        #100;

        $display("");
        $display("========================================");
        $display("PWM Accelerator Testbench");
        $display("========================================");
        $display("Clock Frequency: %0d Hz", CLK_FREQ);
        $display("Clock Period: %0d ns", CLK_PERIOD);

        //======================================================================
        // Test 1: Register Read/Write
        //======================================================================
        test_start("Register Read/Write");

        begin
            reg [31:0] read_data;

            // Write CTRL register (enable = 0, mode = 0)
            wb_write(8'h00, 32'h00000000);
            wb_read(8'h00, read_data);
            test_check(read_data == 32'h00000000, "CTRL register write/read");

            // Write FREQ_DIV register
            wb_write(8'h04, 32'h00002710);  // 10000
            wb_read(8'h04, read_data);
            test_check(read_data == 32'h00002710, "FREQ_DIV register write/read");

            // Write MOD_INDEX register
            wb_write(8'h08, 32'h00008000);  // 50% modulation
            wb_read(8'h08, read_data);
            test_check(read_data == 32'h00008000, "MOD_INDEX register write/read");

            // Write DEADTIME register
            wb_write(8'h14, 32'h00000064);  // 100 cycles
            wb_read(8'h14, read_data);
            test_check(read_data == 32'h00000064, "DEADTIME register write/read");
        end

        //======================================================================
        // Test 2: PWM Enable/Disable
        //======================================================================
        test_start("PWM Enable/Disable");

        begin
            reg [31:0] read_data;

            // Initially disabled, PWM should be low
            #1000;
            test_check(pwm_out == 8'h00, "PWM outputs low when disabled");

            // Enable PWM (auto sine mode)
            wb_write(8'h00, 32'h00000001);  // enable = 1, mode = 0
            #1000;
            $display("  PWM outputs after enable: 0x%02h", pwm_out);

            // Disable PWM
            wb_write(8'h00, 32'h00000000);  // enable = 0
            #100;
            test_check(pwm_out == 8'h00, "PWM outputs low after disable");
        end

        //======================================================================
        // Test 3: Manual Mode PWM
        //======================================================================
        test_start("Manual Mode PWM Generation");

        begin
            // Set manual mode with positive reference
            wb_write(8'h00, 32'h00000003);  // enable = 1, mode = 1 (manual)
            wb_write(8'h20, 32'h00004000);  // CPU reference = +16384
            wb_write(8'h08, 32'h0000FFFF);  // Full modulation index

            // Wait for several PWM cycles
            #50000;
            $display("  PWM outputs in manual mode (ref=+16384): 0x%02h", pwm_out);
            test_check(pwm_out != 8'h00, "PWM outputs active in manual mode");

            // Set negative reference
            wb_write(8'h20, 32'hFFFFC000);  // CPU reference = -16384
            #50000;
            $display("  PWM outputs in manual mode (ref=-16384): 0x%02h", pwm_out);

            // Set zero reference
            wb_write(8'h20, 32'h00000000);  // CPU reference = 0
            #50000;
            $display("  PWM outputs in manual mode (ref=0): 0x%02h", pwm_out);
        end

        //======================================================================
        // Test 4: Auto Sine Mode
        //======================================================================
        test_start("Auto Sine Mode PWM Generation");

        begin
            reg [31:0] pwm_state [0:9];
            integer i;

            // Configure auto sine mode
            wb_write(8'h00, 32'h00000001);  // enable = 1, mode = 0 (auto sine)
            wb_write(8'h08, 32'h00008000);  // 50% modulation index
            wb_write(8'h10, 32'h00000520);  // Sine frequency (50 Hz approx)

            // Capture PWM states over time
            for (i = 0; i < 10; i = i + 1) begin
                #10000;
                pwm_state[i] = pwm_out;
                $display("  Time %0d us: PWM = 0x%02h", i, pwm_out);
            end

            test_check(pwm_state[0] != pwm_state[5], "PWM pattern changes over time");
        end

        //======================================================================
        // Test 5: Dead-Time Verification
        //======================================================================
        test_start("Dead-Time Insertion");

        begin
            integer deadtime_violations = 0;
            integer i;
            reg [7:0] prev_pwm;

            // Configure with small dead-time
            wb_write(8'h14, 32'h0000000A);  // 10 cycles dead-time
            wb_write(8'h00, 32'h00000001);  // Enable

            prev_pwm = pwm_out;

            // Monitor for complementary pairs being high simultaneously
            for (i = 0; i < 1000; i = i + 1) begin
                @(posedge clk);

                // Check complementary pairs
                if (pwm_out[0] && pwm_out[1]) deadtime_violations = deadtime_violations + 1;
                if (pwm_out[2] && pwm_out[3]) deadtime_violations = deadtime_violations + 1;
                if (pwm_out[4] && pwm_out[5]) deadtime_violations = deadtime_violations + 1;
                if (pwm_out[6] && pwm_out[7]) deadtime_violations = deadtime_violations + 1;
            end

            test_check(deadtime_violations == 0,
                       $sformatf("No complementary pairs high simultaneously (%0d violations)",
                       deadtime_violations));
        end

        //======================================================================
        // Test 6: Fault Handling
        //======================================================================
        test_start("Fault Handling");

        begin
            // Enable PWM
            wb_write(8'h00, 32'h00000001);
            #1000;
            test_check(pwm_out != 8'h00, "PWM active before fault");

            // Assert fault
            fault = 1;
            #100;
            test_check(pwm_out == 8'h00, "PWM disabled on fault");

            // De-assert fault
            fault = 0;
            #1000;
            $display("  PWM outputs after fault cleared: 0x%02h", pwm_out);
        end

        //======================================================================
        // Test 7: Carrier Synchronization
        //======================================================================
        test_start("Carrier Synchronization");

        begin
            reg [31:0] status;
            integer sync_count = 0;
            integer i;

            wb_write(8'h00, 32'h00000001);  // Enable

            // Count sync pulses
            for (i = 0; i < 100; i = i + 1) begin
                wb_read(8'h18, status);  // Read STATUS register
                if (status[0]) begin
                    sync_count = sync_count + 1;
                    $display("  Sync pulse detected at iteration %0d", i);
                end
                #1000;
            end

            test_check(sync_count > 0,
                       $sformatf("Carrier sync pulses detected (%0d pulses)", sync_count));
        end

        //======================================================================
        // Test Complete
        //======================================================================

        #10000;

        $display("");
        $display("========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_num);
        $display("Total Errors: %0d", errors);

        if (errors == 0) begin
            $display("");
            $display("  ✓ ALL TESTS PASSED!");
            $display("");
        end else begin
            $display("");
            $display("  ✗ TESTS FAILED!");
            $display("");
        end

        $finish;
    end

    //==========================================================================
    // Timeout Watchdog
    //==========================================================================

    initial begin
        #100_000_000;  // 100 ms timeout
        $display("");
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
