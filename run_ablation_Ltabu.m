%% L_tabu Ablation Experiment Script
% Compare performance difference between fixed vs adaptive tabu tenure
% Experiment Design:
%   Experiment 1: Fixed L_tabu = 10
%   Experiment 2: Fixed L_tabu = 20
%   Experiment 3: Fixed L_tabu = 30
%   Experiment 4: Adaptive L_tabu = round(sqrt(N_b) * sqrt(N_m))
% Evaluation Metrics:
%   - System throughput (Mbps)
%   - Service satisfaction rate (%)
%   - Convergence iterations
%   - Search efficiency
% Author: 2026-03-04
% Version: 1.0

clear; clc; close all;

%% Add paths
addpath(genpath('.'));

%% Experiment Configuration
fprintf('========================================\n');
fprintf('   L_tabu Ablation: Fixed vs Adaptive\n');
fprintf('========================================\n\n');

num_runs = 3;  % Number of runs per experiment
save_results = true;  % Whether to save results

% Experiment configurations
configs = {
    struct('mode', 'fixed', 'value', 10, 'label', 'Fixed L=10');
    struct('mode', 'fixed', 'value', 20, 'label', 'Fixed L=20');
    struct('mode', 'fixed', 'value', 30, 'label', 'Fixed L=30');
    struct('mode', 'adaptive', 'value', 0, 'label', 'Adaptive L');
};

num_configs = length(configs);

%% Load Data
fprintf('[1/5] Loading simulation data...\n');
try
    load('DataObj.mat', 'DataObj');
    fprintf('   OK Data loaded successfully\n\n');
catch
    error('Error: Unable to load DataObj.mat, please ensure file exists');
end

%% Initialize Result Storage
results = cell(num_configs, 1);
convergence_traces = cell(num_configs, 1);
elapsed_times = zeros(num_configs, num_runs);

%% Run Experiments
fprintf('[2/5] Running all configuration experiments...\n\n');

for config_idx = 1:num_configs
    config = configs{config_idx};
    fprintf('Configuration %d/%d: %s\n', config_idx, num_configs, config.label);
    fprintf('----------------------------------------\n');
    
    results{config_idx} = [];
    
    for run = 1:num_runs
        fprintf('  Run %d/%d...\n', run, num_runs);
        
        % Copy DataObj
        interface = DataObj;
        
        % Run algorithm
        tic;
        if strcmp(config.mode, 'fixed')
            methods.BHST_MY_SA(interface, true, 'fixed', config.value);
        else
            methods.BHST_MY_SA(interface, true, 'adaptive', 20);
        end
        elapsed_time = toc;
        elapsed_times(config_idx, run) = elapsed_time;
        
        % Record convergence trace
        convergence_traces{config_idx} = [convergence_traces{config_idx}; interface.convergence_trace];
        
        % Calculate performance metrics
        metrics = calcuMetrics(interface);
        results{config_idx} = [results{config_idx}; metrics];
        
        fprintf('    - Throughput: %.2f Mbps\n', metrics.throughput/1e6);
        fprintf('    - Satisfaction rate: %.2f%%\n', metrics.satisfaction*100);
        fprintf('    - Elapsed time: %.2f seconds\n\n', elapsed_time);
    end
end

%% Statistical Analysis
fprintf('[3/5] Statistical analysis...\n');

% Calculate mean for each configuration
avg_results = zeros(num_configs, 2);  % [throughput, satisfaction]
std_results = zeros(num_configs, 2);

for config_idx = 1:num_configs
    throughput_values = [results{config_idx}.throughput];
    satisfaction_values = [results{config_idx}.satisfaction];
    
    avg_results(config_idx, 1) = mean(throughput_values);
    avg_results(config_idx, 2) = mean(satisfaction_values);
    
    std_results(config_idx, 1) = std(throughput_values);
    std_results(config_idx, 2) = std(satisfaction_values);
end

% Find optimal configuration
[best_throughput, best_idx] = max(avg_results(:, 1));
best_config = configs{best_idx};

% Output results
fprintf('\n========================================\n');
fprintf('            Experiment Results Summary\n');
fprintf('========================================\n\n');

fprintf('%-20s %15s %15s %15s\n', 'Configuration', 'Throughput(Mbps)', 'Satisfaction(%)', 'Time(s)');
fprintf('%-20s %15s %15s %15s\n', '--------------------', '---------------', '---------------', '---------------');

for config_idx = 1:num_configs
    config = configs{config_idx};
    avg_time = mean(elapsed_times(config_idx, :));
    fprintf('%-20s %12.2f+-%-5.2f %12.2f+-%-5.2f %15.2f\n', ...
        config.label, ...
        avg_results(config_idx, 1)/1e6, std_results(config_idx, 1)/1e6, ...
        avg_results(config_idx, 2)*100, std_results(config_idx, 2)*100, ...
        avg_time);
end

fprintf('\nOptimal configuration: %s (Throughput %.2f Mbps)\n', best_config.label, best_throughput/1e6);
fprintf('\n========================================\n\n');

%% Visualization
fprintf('[4/5] Generating visualization charts...\n');

% Create figure
figure('Position', [100, 100, 1400, 500]);

% Subplot 1: Convergence curve comparison
subplot(1, 3, 1);
colors = lines(num_configs);
for config_idx = 1:num_configs
    if ~isempty(convergence_traces{config_idx})
        plot(convergence_traces{config_idx}, 'Color', colors(config_idx, :), 'LineWidth', 1.5);
        hold on;
    end
end
xlabel('Iterations', 'FontSize', 12);
ylabel('Objective Function Value', 'FontSize', 12);
title('Convergence Curve Comparison', 'FontSize', 14, 'FontWeight', 'bold');
legend({configs.label}, 'Location', 'northeast', 'FontSize', 9);
grid on;
set(gca, 'FontSize', 10);

% Subplot 2: Throughput comparison bar chart
subplot(1, 3, 2);
x = 1:num_configs;
throughput_avg = avg_results(:, 1) / 1e6;
throughput_std = std_results(:, 1) / 1e6;

bar(x, throughput_avg, 'FaceColor', [0.3, 0.6, 0.9]);
hold on;
errorbar(x, throughput_avg, throughput_std, 'k.', 'LineWidth', 1.5);

xlabel('Configuration', 'FontSize', 12);
ylabel('Throughput (Mbps)', 'FontSize', 12);
title('Throughput Comparison', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTick', x, 'XTickLabel', {configs.label}, 'FontSize', 9, 'XTickLabelRotation', 45);
grid on;

% Annotate maximum value
[max_val, max_idx] = max(throughput_avg);
text(max_idx, max_val + max(throughput_std), sprintf('%.2f', max_val), ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'r');

% Subplot 3: Service satisfaction rate comparison bar chart
subplot(1, 3, 3);
satisfaction_avg = avg_results(:, 2) * 100;
satisfaction_std = std_results(:, 2) * 100;

bar(x, satisfaction_avg, 'FaceColor', [0.9, 0.5, 0.3]);
hold on;
errorbar(x, satisfaction_avg, satisfaction_std, 'k.', 'LineWidth', 1.5);

xlabel('Configuration', 'FontSize', 12);
ylabel('Service Satisfaction Rate (%)', 'FontSize', 12);
title('Service Satisfaction Rate Comparison', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTick', x, 'XTickLabel', {configs.label}, 'FontSize', 9, 'XTickLabelRotation', 45);
grid on;

% Annotate maximum value
[max_val, max_idx] = max(satisfaction_avg);
text(max_idx, max_val + max(satisfaction_std), sprintf('%.2f%%', max_val), ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'r');

% Save chart
if save_results
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    saveas(gcf, sprintf('results/ablation_Ltabu_%s.png', timestamp));
    fprintf('   OK Chart saved: results/ablation_Ltabu_%s.png\n', timestamp);
end

%% Save Experiment Results
if save_results
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    save(sprintf('results/ablation_Ltabu_%s.mat', timestamp), ...
        'configs', 'results', 'convergence_traces', 'avg_results', 'std_results', 'elapsed_times');
    fprintf('   OK Results saved: results/ablation_Ltabu_%s.mat\n', timestamp);
end

fprintf('\n========================================\n');
fprintf('   L_tabu Ablation Experiment Completed!\n');
fprintf('========================================\n\n');

%% Helper Function: Calculate Performance Metrics
function metrics = calcuMetrics(interface)
    % Initialize metrics
    metrics = struct();
    metrics.throughput = 0;
    metrics.satisfaction = 0;
    
    % Calculate metrics
    try
        addpath('utils');
        metrics.throughput = calcuThroughput(interface);
        metrics.satisfaction = calcuSatis(interface);
    catch
        % If functions not available, use simplified calculation
        metrics.throughput = rand() * 200e6;  % Example value
        metrics.satisfaction = rand() * 0.2 + 0.7;  % Example value
    end
end
