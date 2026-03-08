%% Traffic Skew Experiment Script
% Compare algorithm performance under different traffic distribution patterns
% Experiment Design:
%   - Uniform: All users have the same demand
%   - Light Skew: 2x demand difference
%   - Heavy Skew: 5x demand difference
%   - Pareto (80/20): 20% of users account for 80% of demand
% Author: 2026-03-04
% Version: 1.0

clear; clc; close all;

addpath(genpath('.'));

fprintf('========================================\n');
fprintf('   Traffic Skew Experiment\n');
fprintf('========================================\n\n');

%% Experiment Configuration
traffic_modes = {'uniform', 'light_skew', 'heavy_skew', 'pareto'};
num_modes = length(traffic_modes);
num_runs = 2;  % Number of runs per experiment
save_results = true;

%% Initialize Result Storage
results = struct();
for i = 1:num_modes
    results.(traffic_modes{i}) = [];
end

%% Run Experiments
for mode_idx = 1:num_modes
    traffic_mode = traffic_modes{mode_idx};
    
    fprintf('====================================\n');
    fprintf('Experiment: %s traffic distribution\n', traffic_mode);
    fprintf('====================================\n\n');
    
    for run = 1:num_runs
        fprintf('  Run %d/%d...\n', run, num_runs);
        
        % Clear workspace
        clearvars -except traffic_modes num_modes num_runs save_results results traffic_mode mode_idx run
        addpath(genpath('.'));
        
        % Load and modify configuration
        setConfig;
        Config.enable_SA = true;
        Config.L_tabu_mode = 'adaptive';
        Config.traffic_mode = traffic_mode;
        
        switch traffic_mode
            case 'uniform'
                Config.traffic_skew_factor = 1;
            case 'light_skew'
                Config.traffic_skew_factor = 2;
            case 'heavy_skew'
                Config.traffic_skew_factor = 5;
            case 'pareto'
                Config.pareto_alpha = 1.5;
        end
        
        tic;
        try
            % Run simulation
            controller = simSatSysClass.simController(Config, 1, 1, 0);
            DataObj = controller.run();
            
            elapsed_time = toc;
            
            % Calculate performance metrics
            throughput = calcuThroughput(DataObj);
            satisfaction = calcuSatis(DataObj);
            
            metrics = struct();
            metrics.throughput = throughput;
            metrics.satisfaction = satisfaction;
            metrics.time = elapsed_time;
            
            results.(traffic_mode) = [results.(traffic_mode); metrics];
            
            fprintf('    - Throughput: %.2f Mbps\n', throughput/1e6);
            fprintf('    - Satisfaction rate: %.2f%%\n', satisfaction*100);
            fprintf('    - Elapsed time: %.2f seconds\n\n', elapsed_time);
            
        catch ME
            fprintf('    ERROR: %s\n\n', ME.message);
            results.(traffic_mode) = [results.(traffic_mode); struct('throughput', NaN, 'satisfaction', NaN, 'time', NaN)];
        end
    end
end

%% Statistical Analysis
fprintf('========================================\n');
fprintf('          Experiment Results Summary\n');
fprintf('========================================\n\n');

fprintf('%-15s %15s %15s\n', 'Traffic Mode', 'Throughput(Mbps)', 'Satisfaction(%)');
fprintf('%-15s %15s %15s\n', '---------------', '---------------', '---------------');

avg_results = struct();
for mode_idx = 1:num_modes
    traffic_mode = traffic_modes{mode_idx};
    
    valid_data = results.(traffic_mode);
    if ~isempty(valid_data) && any(~isnan([valid_data.throughput]))
        avg_throughput = mean([valid_data.throughput], 'omitnan');
        avg_satisfaction = mean([valid_data.satisfaction], 'omitnan');
        
        avg_results.(traffic_mode) = struct('throughput', avg_throughput, 'satisfaction', avg_satisfaction);
        
        fprintf('%-15s %12.2f Mbps %14.2f%%\n', traffic_mode, avg_throughput/1e6, avg_satisfaction*100);
    else
        fprintf('%-15s %15s %15s\n', traffic_mode, 'N/A', 'N/A');
    end
end

fprintf('\n');

%% Generate Comparison Charts
fprintf('[5] Generating comparison charts...\n');

figure('Position', [100, 100, 1000, 400]);

% Subplot 1: Throughput comparison
subplot(1, 2, 1);
throughput_data = zeros(1, num_modes);
for mode_idx = 1:num_modes
    traffic_mode = traffic_modes{mode_idx};
    if isfield(avg_results, traffic_mode)
        throughput_data(mode_idx) = avg_results.(traffic_mode).throughput / 1e6;
    else
        throughput_data(mode_idx) = NaN;
    end
end

bar(throughput_data, 'FaceColor', [0.3, 0.6, 0.9]);
set(gca, 'XTick', 1:num_modes, 'XTickLabel', {'Uniform', 'Light Skew', 'Heavy Skew', 'Pareto'}, 'FontSize', 10);
ylabel('Throughput (Mbps)', 'FontSize', 11);
title('Throughput Under Different Traffic Distributions', 'FontSize', 12);
grid on;

% Add value labels
for i = 1:num_modes
    if ~isnan(throughput_data(i))
        text(i, throughput_data(i)*1.02, sprintf('%.2f', throughput_data(i)), 'HorizontalAlignment', 'center', 'FontSize', 9);
    end
end

% Subplot 2: Service satisfaction rate comparison
subplot(1, 2, 2);
satisfaction_data = zeros(1, num_modes);
for mode_idx = 1:num_modes
    traffic_mode = traffic_modes{mode_idx};
    if isfield(avg_results, traffic_mode)
        satisfaction_data(mode_idx) = avg_results.(traffic_mode).satisfaction * 100;
    else
        satisfaction_data(mode_idx) = NaN;
    end
end

bar(satisfaction_data, 'FaceColor', [0.9, 0.5, 0.3]);
set(gca, 'XTick', 1:num_modes, 'XTickLabel', {'Uniform', 'Light Skew', 'Heavy Skew', 'Pareto'}, 'FontSize', 10);
ylabel('Service Satisfaction Rate (%)', 'FontSize', 11);
title('Service Satisfaction Rate Under Different Traffic Distributions', 'FontSize', 12);
grid on;

% Add value labels
for i = 1:num_modes
    if ~isnan(satisfaction_data(i))
        text(i, satisfaction_data(i)*1.02, sprintf('%.2f%%', satisfaction_data(i)), 'HorizontalAlignment', 'center', 'FontSize', 9);
    end
end

% Save chart
if save_results
    if ~exist('results', 'dir')
        mkdir('results');
    end
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    saveas(gcf, sprintf('results/traffic_skew_experiment_%s.png', timestamp));
    fprintf('   OK Chart saved\n');
    
    % Save result data
    save(sprintf('results/traffic_skew_experiment_%s.mat', timestamp), 'results', 'avg_results', 'traffic_modes');
    fprintf('   OK Results saved\n');
end

fprintf('\n========================================\n');
fprintf('   Traffic Skew Experiment Completed!\n');
fprintf('========================================\n\n');

fprintf('Note: Complete experiment results saved, can be imported into paper Table IV\n');
