%% compare_with_simulink.m
% Compare STM32 implementation results with MATLAB/Simulink simulation
%
% This script loads CSV data from STM32 and compares it with Simulink
% simulation results to validate the embedded implementation.
%
% Usage:
%   compare_with_simulink('stm32_data.csv', 'simulink_model.slx')
%   compare_with_simulink('stm32_data.csv')  % Uses default model
%
% Author: 5-Level Inverter Project
% Date: 2025-11-15

function compare_with_simulink(stm32_csv_file, simulink_model)
    %% Parse inputs
    if nargin < 1
        error('STM32 CSV file required');
    end

    if nargin < 2
        simulink_model = '../../01-simulation/inverter_1.slx';
    end

    %% Load STM32 data
    fprintf('Loading STM32 data from %s...\n', stm32_csv_file);
    stm32_data = readtable(stm32_csv_file);

    % Extract signals
    if ismember('time_ms', stm32_data.Properties.VariableNames)
        stm32_time = stm32_data.time_ms / 1000;  % Convert to seconds
    else
        % If no time column, create one assuming 5kHz sampling
        stm32_time = (0:height(stm32_data)-1)' / 5000;
    end

    stm32_current = stm32_data.current_A;
    stm32_voltage = stm32_data.voltage_V;

    fprintf('  Loaded %d samples (%.3f seconds)\n', ...
            length(stm32_time), max(stm32_time));

    %% Run Simulink simulation (if model exists)
    if exist(simulink_model, 'file')
        fprintf('\nRunning Simulink simulation...\n');

        try
            % Load model
            load_system(simulink_model);

            % Set simulation time to match STM32 data
            sim_time = max(stm32_time);
            set_param(simulink_model, 'StopTime', num2str(sim_time));

            % Run simulation
            sim_out = sim(simulink_model);

            % Extract simulation results
            % NOTE: Adjust these signal names based on your Simulink model
            sim_time_vec = sim_out.tout;
            sim_current = sim_out.current;  % Adjust signal name
            sim_voltage = sim_out.voltage;  % Adjust signal name

            fprintf('  Simulation complete\n');
            has_sim_data = true;

        catch ME
            warning('Simulink simulation failed: %s', ME.message);
            fprintf('  Continuing with STM32 data only...\n');
            has_sim_data = false;
        end
    else
        fprintf('\nSimulink model not found: %s\n', simulink_model);
        fprintf('  Analyzing STM32 data only...\n');
        has_sim_data = false;
    end

    %% Calculate metrics for STM32 data
    fprintf('\n=== STM32 Implementation Metrics ===\n');

    % RMS values
    stm32_current_rms = rms(stm32_current);
    stm32_voltage_rms = rms(stm32_voltage);

    fprintf('Current RMS:  %.3f A\n', stm32_current_rms);
    fprintf('Voltage RMS:  %.1f V\n', stm32_voltage_rms);

    % THD calculation
    [stm32_current_thd, stm32_current_harmonics] = calculate_thd(stm32_current, 5000, 50);
    [stm32_voltage_thd, stm32_voltage_harmonics] = calculate_thd(stm32_voltage, 5000, 50);

    fprintf('Current THD:  %.2f%%\n', stm32_current_thd);
    fprintf('Voltage THD:  %.2f%%\n', stm32_voltage_thd);

    %% Calculate metrics for Simulink (if available)
    if has_sim_data
        fprintf('\n=== Simulink Simulation Metrics ===\n');

        sim_current_rms = rms(sim_current);
        sim_voltage_rms = rms(sim_voltage);

        fprintf('Current RMS:  %.3f A\n', sim_current_rms);
        fprintf('Voltage RMS:  %.1f V\n', sim_voltage_rms);

        [sim_current_thd, sim_current_harmonics] = calculate_thd(sim_current, 5000, 50);
        [sim_voltage_thd, sim_voltage_harmonics] = calculate_thd(sim_voltage, 5000, 50);

        fprintf('Current THD:  %.2f%%\n', sim_current_thd);
        fprintf('Voltage THD:  %.2f%%\n', sim_voltage_thd);

        %% Comparison
        fprintf('\n=== Comparison (STM32 vs Simulink) ===\n');

        current_rms_error = abs(stm32_current_rms - sim_current_rms) / sim_current_rms * 100;
        voltage_rms_error = abs(stm32_voltage_rms - sim_voltage_rms) / sim_voltage_rms * 100;
        current_thd_diff = abs(stm32_current_thd - sim_current_thd);
        voltage_thd_diff = abs(stm32_voltage_thd - sim_voltage_thd);

        fprintf('Current RMS Error:   %.2f%%\n', current_rms_error);
        fprintf('Voltage RMS Error:   %.2f%%\n', voltage_rms_error);
        fprintf('Current THD Diff:    %.2f%% points\n', current_thd_diff);
        fprintf('Voltage THD Diff:    %.2f%% points\n', voltage_thd_diff);

        % Pass/fail criteria
        fprintf('\n=== Validation Status ===\n');
        if current_rms_error < 5 && voltage_rms_error < 5 && ...
           current_thd_diff < 2 && voltage_thd_diff < 2
            fprintf('✓ PASSED: STM32 matches Simulink within tolerance\n');
        else
            fprintf('✗ FAILED: STM32 differs significantly from Simulink\n');
        end
    end

    %% Plotting
    fprintf('\nGenerating plots...\n');

    % Create figure
    fig = figure('Position', [100, 100, 1200, 900]);

    % Current waveform comparison
    subplot(3, 2, 1);
    plot(stm32_time, stm32_current, 'b-', 'LineWidth', 1.5);
    hold on;
    if has_sim_data
        plot(sim_time_vec, sim_current, 'r--', 'LineWidth', 1.0);
        legend('STM32', 'Simulink');
    end
    grid on;
    xlabel('Time (s)');
    ylabel('Current (A)');
    title('Output Current Comparison', 'FontWeight', 'bold');

    % Voltage waveform comparison
    subplot(3, 2, 2);
    plot(stm32_time, stm32_voltage, 'b-', 'LineWidth', 1.5);
    hold on;
    if has_sim_data
        plot(sim_time_vec, sim_voltage, 'r--', 'LineWidth', 1.0);
        legend('STM32', 'Simulink');
    end
    grid on;
    xlabel('Time (s)');
    ylabel('Voltage (V)');
    title('Output Voltage Comparison', 'FontWeight', 'bold');

    % Current FFT comparison
    subplot(3, 2, 3);
    [f, P] = compute_fft(stm32_current, 5000);
    plot(f, P, 'b-', 'LineWidth', 1.5);
    hold on;
    if has_sim_data
        [f_sim, P_sim] = compute_fft(sim_current, 5000);
        plot(f_sim, P_sim, 'r--', 'LineWidth', 1.0);
        legend('STM32', 'Simulink');
    end
    grid on;
    xlim([0, 1000]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (A)');
    title('Current Spectrum', 'FontWeight', 'bold');

    % Voltage FFT comparison
    subplot(3, 2, 4);
    [f, P] = compute_fft(stm32_voltage, 5000);
    plot(f, P, 'b-', 'LineWidth', 1.5);
    hold on;
    if has_sim_data
        [f_sim, P_sim] = compute_fft(sim_voltage, 5000);
        plot(f_sim, P_sim, 'r--', 'LineWidth', 1.0);
        legend('STM32', 'Simulink');
    end
    grid on;
    xlim([0, 1000]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (V)');
    title('Voltage Spectrum', 'FontWeight', 'bold');

    % Harmonic comparison - Current
    subplot(3, 2, 5);
    harmonics_num = 2:10;
    bar(harmonics_num, stm32_current_harmonics(2:10));
    hold on;
    if has_sim_data
        bar(harmonics_num + 0.3, sim_current_harmonics(2:10));
        legend('STM32', 'Simulink');
    end
    grid on;
    xlabel('Harmonic Number');
    ylabel('Magnitude (A)');
    title('Current Harmonics', 'FontWeight', 'bold');

    % Harmonic comparison - Voltage
    subplot(3, 2, 6);
    bar(harmonics_num, stm32_voltage_harmonics(2:10));
    hold on;
    if has_sim_data
        bar(harmonics_num + 0.3, sim_voltage_harmonics(2:10));
        legend('STM32', 'Simulink');
    end
    grid on;
    xlabel('Harmonic Number');
    ylabel('Magnitude (V)');
    title('Voltage Harmonics', 'FontWeight', 'bold');

    % Overall title
    sgtitle('STM32 vs Simulink Comparison', 'FontSize', 14, 'FontWeight', 'bold');

    % Save figure
    saveas(fig, 'comparison_results.png');
    fprintf('Plot saved to comparison_results.png\n');
end

%% Helper function: Calculate THD
function [thd_percent, harmonics] = calculate_thd(signal, fs, f0)
    % Calculate Total Harmonic Distortion
    %
    % Inputs:
    %   signal - Time-domain signal
    %   fs - Sampling frequency
    %   f0 - Fundamental frequency
    %
    % Outputs:
    %   thd_percent - THD in percentage
    %   harmonics - Array of harmonic amplitudes (1st through 10th)

    N = length(signal);
    Y = fft(signal);
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = fs*(0:(N/2))/N;

    % Find harmonics
    harmonics = zeros(10, 1);
    for h = 1:10
        [~, idx] = min(abs(f - h*f0));
        harmonics(h) = P1(idx);
    end

    % Calculate THD
    fund_power = harmonics(1)^2;
    harmonic_power = sum(harmonics(2:10).^2);
    thd_percent = 100 * sqrt(harmonic_power / fund_power);
end

%% Helper function: Compute FFT for plotting
function [f, P] = compute_fft(signal, fs)
    % Compute single-sided spectrum for plotting
    N = length(signal);
    Y = fft(signal);
    P2 = abs(Y/N);
    P = P2(1:N/2+1);
    P(2:end-1) = 2*P(2:end-1);
    f = fs*(0:(N/2))/N;
end
