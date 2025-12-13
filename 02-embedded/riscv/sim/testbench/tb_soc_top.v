// tb_soc_top.v
//
// Testbench for the complete soc_top module.
//
// 1. Instantiates the SoC.
// 2. Provides clock and reset.
// 3. Defines `SIMULATION` to enable behavioral memory.
// 4. Monitors the UART TX line for a "Hello World!" message.
// 5. Reports PASS or FAIL based on the UART output.

`define SIMULATION
`timescale 1ns/1ps

module tb_soc_top;

    // SoC Parameters
    localparam CLK_100MHZ_PERIOD = 10; // 100 MHz clock
    localparam UART_BAUD = 115200;
    localparam UART_BIT_PERIOD = 1_000_000_000 / UART_BAUD;

    // Signals
    reg clk_100mhz;
    reg rst_n;

    wire uart_tx;
    wire [7:0] pwm_out;
    wire [3:0] adc_dac_out;
    wire [15:0] gpio;
    wire [3:0] led;

    // Instantiate the DUT (Design Under Test)
    soc_top #(
        .CLK_FREQ(50_000_000), // soc_top generates 50MHz from 100MHz
        .UART_BAUD(UART_BAUD)
    ) dut (
        .clk_100mhz(clk_100mhz),
        .rst_n(rst_n),
        .uart_rx(1'b1), // Keep UART RX idle
        .uart_tx(uart_tx),
        .pwm_out(pwm_out),
        .adc_comp_in(4'b0),
        .adc_dac_out(adc_dac_out),
        .fault_ocp(1'b0),
        .fault_ovp(1'b0),
        .estop_n(1'b1),
        .gpio(gpio),
        .led(led)
    );

    // Clock generation
    initial begin
        clk_100mhz = 0;
        forever #(CLK_100MHZ_PERIOD / 2) clk_100mhz = ~clk_100mhz;
    end

    // Reset generation
    initial begin
        $display("INFO: Starting testbench for soc_top.");
        rst_n = 1'b0;
        #200;
        rst_n = 1'b1;
        $display("INFO: Reset released.");
    end

    // Test monitoring and UART receiver
    initial begin
        string expected_string = "Hello World!\n";
        integer byte_count = 0;
        integer bit_count;
        reg [7:0] byte_received;

        // Wait for reset to be released
        @(posedge rst_n);

        $display("INFO: Waiting for UART transmission...");

        // Wait for the start bit
        wait (uart_tx == 0);
        $display("INFO: UART Start bit detected.");

        while (byte_count < expected_string.len()) begin
            // Center of start bit
            #(UART_BIT_PERIOD);

            // Read 8 data bits
            byte_received = 0;
            for (bit_count = 0; bit_count < 8; bit_count = bit_count + 1) begin
                byte_received = {uart_tx, byte_received[7:1]};
                #(UART_BIT_PERIOD);
            end

            // Check stop bit
            if (uart_tx != 1) begin
                $error("FAIL: UART stop bit not found!");
                $finish;
            end

            // Check received character
            if (byte_received == expected_string[byte_count]) begin
                $display("INFO: Received char '%s' (0x%02h), matches expected '%s'.", byte_received, byte_received, expected_string[byte_count]);
            end else begin
                $error("FAIL: Received char '%s' (0x%02h), expected '%s'.", byte_received, byte_received, expected_string[byte_count]);
                $finish;
            end

            byte_count = byte_count + 1;
        end

        $display("----------------------------------------");
        $display("PASS: Successfully received 'Hello World!'.");
        $display("----------------------------------------");
        $finish;

    end

    // Timeout
    initial begin
        #5000000; // 5ms timeout
        $error("FAIL: Test timed out. No UART message received.");
        $finish;
    end

endmodule
