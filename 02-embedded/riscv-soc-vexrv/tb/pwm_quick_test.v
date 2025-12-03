`timescale 1ns / 1ps

module pwm_quick_test;

    reg clk;
    reg rst_n;
    reg [7:0] wb_addr;
    reg [31:0] wb_dat_i;
    wire [31:0] wb_dat_o;
    reg wb_we;
    reg [3:0] wb_sel;
    reg wb_stb;
    wire wb_ack;
    wire [7:0] pwm_out;
    reg fault;

    // Instantiate PWM accelerator
    pwm_accelerator #(
        .CLK_FREQ(50_000_000),
        .PWM_FREQ(5_000)
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

    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk;  // 50 MHz

    // Track PWM transitions
    reg [7:0] pwm_prev;
    integer transitions [0:7];
    integer i;

    always @(posedge clk) begin
        if (rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                if (pwm_out[i] != pwm_prev[i]) begin
                    transitions[i] = transitions[i] + 1;
                end
            end
            pwm_prev <= pwm_out;
        end
    end

    // Test sequence
    initial begin
        $display("================================================================================");
        $display("PWM ACCELERATOR QUICK TEST - Using Fixed Firmware Values");
        $display("================================================================================");

        // Initialize
        rst_n = 0;
        wb_addr = 0;
        wb_dat_i = 0;
        wb_we = 0;
        wb_sel = 4'b1111;
        wb_stb = 0;
        fault = 0;
        pwm_prev = 0;

        for (i = 0; i < 8; i = i + 1) begin
            transitions[i] = 0;
        end

        #100;
        rst_n = 1;
        #100;

        $display("\n[1/5] Configuring PWM with fixed firmware values...");

        // Write CTRL = 0 (disable)
        write_reg(8'h00, 32'h00000000);

        // Write FREQ_DIV = 5000 (0x1388)
        write_reg(8'h04, 32'h00001388);
        $display("  FREQ_DIV = 5000 (5 kHz carrier)");

        // Write SINE_FREQ = 17 (0x11) for 50 Hz AC output
        write_reg(8'h10, 32'h00000011);
        $display("  SINE_FREQ = 17 (50.664 Hz modulation)");

        // Write DEADTIME = 50 (0x32)
        write_reg(8'h14, 32'h00000032);
        $display("  DEADTIME = 50 cycles (1 us)");

        // Write MOD_INDEX = 32767 (0x7FFF) for 100% - needed for 4-carrier 5-level operation
        // With 4 carriers spanning -32768 to +32767, we need full-range sine modulation
        write_reg(8'h08, 32'h00007FFF);
        $display("  MOD_INDEX = 32767 (100%% - full range for 4 carriers)");

        // Write CTRL = 1 (enable, auto sine mode)
        // mode=0 for auto sine, mode=1 for manual CPU reference
        write_reg(8'h00, 32'h00000001);
        $display("  CTRL = 1 (enabled, auto sine mode)");

        // Read back registers to verify
        $display("\n[VERIFY] Reading back registers:");
        read_reg(8'h00); $display("  CTRL = 0x%08X", wb_dat_o);
        read_reg(8'h04); $display("  FREQ_DIV = 0x%08X (%0d)", wb_dat_o, wb_dat_o);
        read_reg(8'h08); $display("  MOD_INDEX = 0x%08X (%0d signed)", wb_dat_o, $signed(wb_dat_o[15:0]));
        read_reg(8'h10); $display("  SINE_FREQ = 0x%08X (%0d)", wb_dat_o, wb_dat_o);
        read_reg(8'h14); $display("  DEADTIME = 0x%08X (%0d)", wb_dat_o, wb_dat_o);

        $display("\n[2/5] Running for 2,000,000 clock cycles (100 carrier periods, ~2 sine cycles)...");
        // Add periodic sampling - show PWM state every 100k cycles
        repeat (20) begin
            #2000000;  // 100,000 cycles at a time
            $display("    PWM state: 0x%02X", pwm_out);
        end

        $display("\n[3/5] Checking PWM outputs...");
        $display("  Initial PWM: 0x%02X", pwm_prev);
        $display("  Current PWM: 0x%02X", pwm_out);

        $display("\n[4/5] Counting transitions per channel:");
        for (i = 0; i < 8; i = i + 1) begin
            $display("  CH%0d: %0d transitions", i, transitions[i]);
        end

        $display("\n[5/5] Verification:");
        if (transitions[0] > 5 && transitions[1] > 5 &&
            transitions[2] > 5 && transitions[3] > 5 &&
            transitions[4] > 5 && transitions[5] > 5 &&
            transitions[6] > 5 && transitions[7] > 5) begin
            $display("  [PASS] All channels switching!");
            $display("  [PASS] PWM is WORKING with fixed firmware values!");
        end else begin
            $display("  [FAIL] Some channels not switching");
            $display("  [FAIL] Problem detected!");
        end

        // Check complementary pairs
        if (pwm_out[0] != pwm_out[1]) begin
            $display("  [PASS] CH0/CH1 complementary");
        end else begin
            $display("  [FAIL] CH0/CH1 NOT complementary");
        end

        $display("\n================================================================================");
        $display("TEST COMPLETE");
        $display("================================================================================");

        $finish;
    end

    // Task to write register
    task write_reg;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            wb_addr = addr;
            wb_dat_i = data;
            wb_we = 1;
            wb_stb = 1;
            @(posedge clk);
            while (!wb_ack) @(posedge clk);
            @(posedge clk);
            wb_stb = 0;
            wb_we = 0;
        end
    endtask

    // Task to read register
    task read_reg;
        input [7:0] addr;
        begin
            @(posedge clk);
            wb_addr = addr;
            wb_we = 0;
            wb_stb = 1;
            @(posedge clk);
            while (!wb_ack) @(posedge clk);
            @(posedge clk);
            wb_stb = 0;
        end
    endtask

endmodule
