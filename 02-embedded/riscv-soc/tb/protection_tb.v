/**
 * @file protection_tb.v
 * @brief Testbench for Protection/Fault Peripheral
 *
 * Tests overcurrent protection, overvoltage protection, e-stop, and watchdog.
 */

`timescale 1ns / 1ps

module protection_tb;

    parameter CLK_FREQ = 50_000_000;
    parameter CLK_PERIOD = 20;  // 50 MHz

    // Signals
    reg clk, rst_n;
    reg [7:0] wb_addr;
    reg [31:0] wb_dat_i;
    wire [31:0] wb_dat_o;
    reg wb_we, wb_stb;
    reg [3:0] wb_sel;
    wire wb_ack;
    reg fault_ocp, fault_ovp, estop_n;
    wire pwm_disable, irq;

    integer errors = 0;

    // DUT
    protection dut (
        .clk(clk),
        .rst_n(rst_n),
        .wb_addr(wb_addr),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_stb(wb_stb),
        .wb_ack(wb_ack),
        .fault_ocp(fault_ocp),
        .fault_ovp(fault_ovp),
        .estop_n(estop_n),
        .pwm_disable(pwm_disable),
        .irq(irq)
    );

    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Wishbone write
    task wb_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            wb_addr = addr;
            wb_dat_i = data;
            wb_we = 1'b1;
            wb_sel = 4'hF;
            wb_stb = 1'b1;
            @(posedge clk);
            while (!wb_ack) @(posedge clk);
            wb_stb = 1'b0;
            wb_we = 1'b0;
            @(posedge clk);
        end
    endtask

    // Wishbone read
    task wb_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            wb_addr = addr;
            wb_we = 1'b0;
            wb_sel = 4'hF;
            wb_stb = 1'b1;
            @(posedge clk);
            while (!wb_ack) @(posedge clk);
            data = wb_dat_o;
            wb_stb = 1'b0;
            @(posedge clk);
        end
    endtask

    // Main test
    initial begin
        $dumpfile("sim/protection_tb.vcd");
        $dumpvars(0, protection_tb);

        // Initialize
        rst_n = 0;
        fault_ocp = 0;
        fault_ovp = 0;
        estop_n = 1'b1;  // Not pressed
        wb_addr = 0;
        wb_dat_i = 0;
        wb_we = 0;
        wb_sel = 0;
        wb_stb = 0;

        #100 rst_n = 1;
        #100;

        $display("========================================");
        $display("Protection Peripheral Testbench");
        $display("========================================");

        // Test 1: Overcurrent protection
        $display("\nTest 1: Overcurrent Protection");
        fault_ocp = 1'b1;
        #100;
        if (pwm_disable && irq) begin
            $display("  [PASS] PWM disabled and IRQ asserted on OCP");
        end else begin
            $display("  [FAIL] PWM not disabled or IRQ not asserted");
            errors = errors + 1;
        end
        fault_ocp = 1'b0;
        #100;

        // Test 2: Overvoltage protection
        $display("\nTest 2: Overvoltage Protection");
        fault_ovp = 1'b1;
        #100;
        if (pwm_disable && irq) begin
            $display("  [PASS] PWM disabled and IRQ asserted on OVP");
        end else begin
            $display("  [FAIL] PWM not disabled or IRQ not asserted");
            errors = errors + 1;
        end
        fault_ovp = 1'b0;
        #100;

        // Test 3: Emergency stop
        $display("\nTest 3: Emergency Stop");
        estop_n = 1'b0;  // Press e-stop
        #100;
        if (pwm_disable) begin
            $display("  [PASS] PWM disabled on E-stop");
        end else begin
            $display("  [FAIL] PWM not disabled on E-stop");
            errors = errors + 1;
        end
        estop_n = 1'b1;  // Release e-stop
        #100;

        // Test 4: Watchdog timer
        $display("\nTest 4: Watchdog Timer");
        wb_write(8'h00, 32'h00000001);  // Enable watchdog
        wb_write(8'h04, 32'h00001000);  // Set timeout (small value for testing)

        // Don't kick watchdog - should timeout
        #100000;

        begin
            reg [31:0] status;
            wb_read(8'h0C, status);  // Read fault status
            if (status[3]) begin  // Watchdog fault bit
                $display("  [PASS] Watchdog timeout detected");
            end else begin
                $display("  [FAIL] Watchdog timeout not detected");
                errors = errors + 1;
            end
        end

        // Test 5: Watchdog kick
        $display("\nTest 5: Watchdog Kick");
        wb_write(8'h0C, 32'h00000000);  // Clear faults
        wb_write(8'h00, 32'h00000001);  // Enable watchdog
        wb_write(8'h04, 32'h00010000);  // Set longer timeout

        // Periodically kick watchdog
        repeat (10) begin
            #5000;
            wb_write(8'h08, 32'h00000001);  // Kick watchdog
        end

        begin
            reg [31:0] status;
            wb_read(8'h0C, status);
            if (!status[3]) begin
                $display("  [PASS] Watchdog kept alive by kicking");
            end else begin
                $display("  [FAIL] Watchdog timed out despite kicking");
                errors = errors + 1;
            end
        end

        #10000;

        $display("\n========================================");
        $display("Test Summary: %0d errors", errors);
        if (errors == 0)
            $display("  ✓ ALL TESTS PASSED!");
        else
            $display("  ✗ TESTS FAILED!");
        $display("========================================\n");

        $finish;
    end

    // Timeout
    initial begin
        #200_000_000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
