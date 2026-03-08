%% SA Ablation Experiment Script - Complete Version
% Compare performance difference with/without Simulated Annealing (SA) mechanism
% Usage:
%   1. Run this script directly
%   2. Script will automatically modify Config and run simulation
%   3. Results saved in results directory
% Author: 2026-03-04
% Version: 3.0

clear; clc; close all;

addpath(genpath('.'));

fprintf('========================================\n');
fprintf('   SA Ablation Experiment: Tabu+SA vs Tabu-only\n');
fprintf('========================================\n\n');

%% Experiment Configuration
num_runs = 2;  % Number of runs per experiment (recommended: 2-5)
save_results = true;

%% Experiment 1: Tabu + SA
fprintf('====================================\n');
fprintf('Experiment 1: Tabu + SA (Simulated Annealing enabled)\n');
fprintf('====================================\n\n');

results_with_SA = [];
times_with_SA = [];

for run = 1:num_runs
    fprintf('Run %d/%d...\n', run, num_runs);
    
    % Clear workspace
    clearvars -except num_runs save_results results_with_SA times_with_SA results_without_SA times_without_SA
    addpath(genpath('.'));
    
    % Load and modify configuration
    setConfig;
    Config.enable_SA = true;        % Enable SA
    Config.L_tabu_mode = 'adaptive'; % Adaptive tabu tenure
    
    tic;
    try
        % Run simulation
        controller = simSatSysClass.simController(Config, 1, 1, 0);
        DataObj = controller.run();
        
        elapsed_time = toc;
        
        % Calculate performance metrics
        throughput = calcuThroughput(DataObj);
        satisfaction = calcuSatis(DataObj);
        
        results_with_SA = [results_with_SA; struct('throughput', throughput, 'satisfaction', satisfaction, 'time', elapsed_time)];
        times_with_SA = [times_with_SA; elapsed_time];
        
        fprintf('  OK Completed\n');
        fprintf('    - Throughput: %.2f Mbps\n', throughput/1e6);
        fprintf('    - Satisfaction rate: %.2f%%\n', satisfaction*100);
        fprintf('    - Time elapsed: %.2f seconds\n\n', elapsed_time);
        
    catch ME
        fprintf('  ERROR: %s\n\n', ME.message);
        results_with_SA = [results_with_SA; struct('throughput', NaN, 'satisfaction', NaN, 'time', NaN)];
        times_with_SA = [times_with_SA; NaN];
    end
end

%% Experiment 2: Tabu only (without SA)
fprintf('====================================\n');
fprintf('Experiment 2: Tabu only (without Simulated Annealing)\n');
fprintf('====================================\n\n');

results_without_SA = [];
times_without_SA = [];

for run = 1:num_runs
    fprintf('Run %d/%d...\n', run, num_runs);
    
    % Clear workspace
    clearvars -except num_runs save_results results_with_SA times_with_SA results_without_SA times_without_SA
    addpath(genpath('.'));
    
    % Load and modify configuration
    setConfig;
    Config.enable_SA = false;       % Disable SA
    Config.L_tabu_mode = 'adaptive'; % Adaptive tabu tenure
    
    tic;
    try
        % Run simulation
        controller = simSatSysClass.simController(Config, 1, 1, 0);
        DataObj = controller.run();
        
        elapsed_time = toc;
        
        % Calculate performance metrics
        throughput = calcuThroughput(DataObj);
        satisfaction = calcuSatis(DataObj);
        
        results_without_SA = [results_without_SA; struct('throughput', throughput, 'satisfaction', satisfaction, 'time', elapsed_time)];
        times_without_SA = [times_without_SA; elapsed_time];
        
        fprintf('  OK Completed\n');
        fprintf('    - Throughput: %.2f Mbps\n', throughput/1e6);
        fprintf('    - Satisfaction rate: %.2f%%\n', satisfaction*100);
        fprintf('    - Time elapsed: %.2f seconds\n\n', elapsed_time);
        
    catch ME
        fprintf('  ERROR: %s\n\n', ME.message);
        results_without_SA = [results_without_SA; struct('throughput', NaN, 'satisfaction', NaN, 'time', NaN)];
        times_without_SA = [times_without_SA; NaN];
    end
end

%% Statistical Analysis
fprintf('========================================\n');
fprintf('          Results Summary\n');
fprintf('========================================\n\n');

% Filter valid data
valid_with_SA = ~isnan([results_with_SA.throughput]);
valid_without_SA = ~isnan([results_without_SA.throughput]);

if sum(valid_with_SA) > 0 && sum(valid_without_SA) > 0
    avg_throughput_with_SA = mean([results_with_SA(valid_with_SA).throughput]);
    avg_throughput_without_SA = mean([results_without_SA(valid_without_SA).throughput]);
    avg_satisfaction_with_SA = mean([results_with_SA(valid_with_SA).satisfaction]);
    avg_satisfaction_without_SA = mean([results_without_SA(valid_without_SA).satisfaction]);
    
    improvement_throughput = (avg_throughput_with_SA - avg_throughput_without_SA) / avg_throughput_without_SA * 100;
    improvement_satisfaction = (avg_satisfaction_with_SA - avg_satisfaction_without_SA) / avg_satisfaction_without_SA * 100;
    
    fprintf('%-25s %15s %15s %15s\n', 'Metric', 'Tabu+SA', 'Tabu-only', 'Improvement');
    fprintf('%-25s %15s %15s %15s\n', '----------------------', '---------------', '---------------', '---------------');
    fprintf('%-25s %12.2f Mbps %12.2f Mbps %+14.2f%%\n', 'Avg Throughput', ...
        avg_throughput_with_SA/1e6, avg_throughput_without_SA/1e6, improvement_throughput);
    fprintf('%-25s %14.2f%% %14.2f%% %+14.2f%%\n', 'Avg Satisfaction Rate', ...
        avg_satisfaction_with_SA*100, avg_satisfaction_without_SA*100, improvement_satisfaction);
    fprintf('\n');
    
    % Generate comparison plots
    figure('Position', [100, 100, 1000, 400]);
    
    subplot(1, 2, 1);
    bar([avg_throughput_with_SA/1e6, avg_throughput_without_SA/1e6]);
    set(gca, 'XTickLabel', {'Tabu + SA', 'Tabu only'});
    ylabel('Throughput (Mbps)');
    title('Throughput Comparison');
    grid on;
    text(1, avg_throughput_with_SA/1e6*1.02, sprintf('%.2f', avg_throughput_with_SA/1e6), 'HorizontalAlignment', 'center');
    text(2, avg_throughput_without_SA/1e6*1.02, sprintf('%.2f', avg_throughput_without_SA/1e6), 'HorizontalAlignment', 'center');
    
    subplot(1, 2, 2);
    bar([avg_satisfaction_with_SA*100, avg_satisfaction_without_SA*100], 'FaceColor', [0.8, 0.4, 0.4]);
    set(gca, 'XTickLabel', {'Tabu + SA', 'Tabu only'});
    ylabel('Satisfaction Rate (%)');
    title('Satisfaction Rate Comparison');
    grid on;
    text(1, avg_satisfaction_with_SA*100*1.02, sprintf('%.2f%%', avg_satisfaction_with_SA*100), 'HorizontalAlignment', 'center');
    text(2, avg_satisfaction_without_SA*100*1.02, sprintf('%.2f%%', avg_satisfaction_without_SA*100), 'HorizontalAlignment', 'center');
    
    % Save figure
    if save_results
        timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
        saveas(gcf, sprintf('results/ablation_SA_%s.png', timestamp));
        fprintf('Figure saved: results/ablation_SA_%s.png\n', timestamp);
    end
else
    fprintf('[Warning] Incomplete experiment data, unable to perform statistical analysis\n');
end

%% Save Results
if save_results
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    results_filename = sprintf('results/ablation_SA_%s.mat', timestamp);
    save(results_filename, 'results_with_SA', 'results_without_SA', 'times_with_SA', 'times_without_SA');
    fprintf('\nResults saved: %s\n', results_filename);
end

fprintf('\n========================================\n');
fprintf('   SA Ablation Experiment Completed!\n');
fprintf('========================================\n');
