%% Comprehensive Experiment Runner Script
% Includes: Baseline comparison + Ablation experiments + Result visualization
% Experiment Contents:
%   1. Baseline comparison: Tabu+SA, Greedy, DQN, GA
%   2. SA ablation: Tabu+SA vs Tabu-only
%   3. L_tabu ablation: Fixed vs Adaptive
%   4. Generate all comparison charts
%   5. Save all experiment results
% Author: 2026-03-04
% Version: 1.0

clear; clc; close all;

%% Add paths
addpath(genpath('.'));

%% Experiment Configuration
fprintf('========================================\n');
fprintf('   LEO Satellite Beam-Hopping Scheduling - Comprehensive Experiments\n');
fprintf('========================================\n\n');

config = struct();
config.num_runs = 3;  % Number of runs per experiment
config.save_results = true;  % Whether to save results
config.run_baseline = true;  % Whether to run baseline comparison
config.run_ablation_SA = true;  % Whether to run SA ablation
config.run_ablation_Ltabu = true;  % Whether to run L_tabu ablation

%% Load Data
fprintf('[Step 1/6] Loading simulation data...\n');
try
    load('DataObj.mat', 'DataObj');
    fprintf('   OK Data loaded successfully\n');
    fprintf('   - Number of users: %d\n', DataObj.NumOfSelectedUsrs);
    fprintf('   - Number of scheduling periods: %d\n', DataObj.ScheInShot);
    fprintf('   - Slots per period: %d\n\n', DataObj.SlotInSche);
catch
    error('Error: Unable to load DataObj.mat, please ensure file exists');
end

%% Initialize Result Storage
all_results = struct();
all_timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');

%% Baseline Comparison Experiment
if config.run_baseline
    fprintf('[Step 2/6] Running baseline comparison experiment...\n');
    fprintf('========================================\n');
    
    methods_list = {'TabuSA', 'Greedy'};
    num_methods = length(methods_list);
    
    baseline_results = cell(num_methods, 1);
    baseline_KPIs = cell(num_methods, 1);
    baseline_times = zeros(num_methods, config.num_runs);
    
    for method_idx = 1:num_methods
        method_name = methods_list{method_idx};
        fprintf('\nMethod %d/%d: %s\n', method_idx, num_methods, method_name);
        fprintf('----------------------------------------\n');
        
        baseline_results{method_idx} = [];
        
        for run = 1:config.num_runs
            fprintf('  Run %d/%d...\n', run, config.num_runs);
            
            % Copy data
            interface = DataObj;
            
            % Run corresponding method
            tic;
            switch method_name
                case 'TabuSA'
                    methods.BHST_MY_SA(interface, true, 'adaptive', 20);
                case 'Greedy'
                    methods.BHST_greedyAndDist(interface);
                case 'DQN'
                    methods.BHST_DQN(interface);
                otherwise
                    warning('Unknown method: %s, skipping', method_name);
                    continue;
            end
            elapsed_time = toc;
            baseline_times(method_idx, run) = elapsed_time;
            
            % Calculate KPIs
            KPIs = calcuUserKPIs(interface);
            baseline_results{method_idx} = [baseline_results{method_idx}; KPIs];
            
            fprintf('    - Average throughput: %.2f Mbps\n', KPIs.avg_throughput/1e6);
            fprintf('    - Average SINR: %.2f dB\n', KPIs.avg_SINR);
            fprintf('    - Outage rate: %.2f%%\n', KPIs.outage_rate*100);
            fprintf('    - Average satisfaction rate: %.2f%%\n', KPIs.SS_avg*100);
            fprintf('    - Elapsed time: %.2f seconds\n', elapsed_time);
        end
        
        % Calculate average KPIs
        baseline_KPIs{method_idx} = averageKPIs(baseline_results{method_idx});
    end
    
    % Save baseline comparison results
    all_results.baseline = struct(...
        'methods', methods_list, ...
        'results', baseline_results, ...
        'KPIs', baseline_KPIs, ...
        'times', baseline_times ...
    );
    
    fprintf('\nBaseline comparison experiment completed!\n\n');
else
    fprintf('[Step 2/6] Skipping baseline comparison experiment\n\n');
end

%% SA Ablation Experiment
if config.run_ablation_SA
    fprintf('[Step 3/6] Running SA ablation experiment...\n');
    fprintf('========================================\n');
    
    SA_configs = {'with_SA', 'without_SA'};
    num_SA_configs = length(SA_configs);
    
    SA_results = cell(num_SA_configs, 1);
    SA_KPIs = cell(num_SA_configs, 1);
    SA_times = zeros(num_SA_configs, config.num_runs);
    
    for config_idx = 1:num_SA_configs
        config_name = SA_configs{config_idx};
        fprintf('\nConfiguration %d/%d: %s\n', config_idx, num_SA_configs, config_name);
        fprintf('----------------------------------------\n');
        
        SA_results{config_idx} = [];
        
        for run = 1:config.num_runs
            fprintf('  Run %d/%d...\n', run, config.num_runs);
            
            interface = DataObj;
            
            tic;
            if strcmp(config_name, 'with_SA')
                methods.BHST_MY_SA(interface, true, 'adaptive', 20);
            else
                methods.BHST_MY_SA(interface, false, 'adaptive', 20);
            end
            elapsed_time = toc;
            SA_times(config_idx, run) = elapsed_time;
            
            KPIs = calcuUserKPIs(interface);
            SA_results{config_idx} = [SA_results{config_idx}; KPIs];
            
            fprintf('    - Average throughput: %.2f Mbps\n', KPIs.avg_throughput/1e6);
            fprintf('    - Average satisfaction rate: %.2f%%\n', KPIs.SS_avg*100);
            fprintf('    - Elapsed time: %.2f seconds\n', elapsed_time);
        end
        
        SA_KPIs{config_idx} = averageKPIs(SA_results{config_idx});
    end
    
    % Save SA ablation results
    all_results.SA_ablation = struct(...
        'configs', SA_configs, ...
        'results', SA_results, ...
        'KPIs', SA_KPIs, ...
        'times', SA_times ...
    );
    
    fprintf('\nSA ablation experiment completed!\n\n');
else
    fprintf('[Step 3/6] Skipping SA ablation experiment\n\n');
end

%% L_tabu Ablation Experiment
if config.run_ablation_Ltabu
    fprintf('[Step 4/6] Running L_tabu ablation experiment...\n');
    fprintf('========================================\n');
    
    Ltabu_configs = {
        struct('mode', 'fixed', 'value', 10, 'label', 'Fixed L=10');
        struct('mode', 'fixed', 'value', 20, 'label', 'Fixed L=20');
        struct('mode', 'fixed', 'value', 30, 'label', 'Fixed L=30');
        struct('mode', 'adaptive', 'value', 0, 'label', 'Adaptive L');
    };
    num_Ltabu_configs = length(Ltabu_configs);
    
    Ltabu_results = cell(num_Ltabu_configs, 1);
    Ltabu_KPIs = cell(num_Ltabu_configs, 1);
    Ltabu_times = zeros(num_Ltabu_configs, config.num_runs);
    
    for config_idx = 1:num_Ltabu_configs
        config_struct = Ltabu_configs{config_idx};
        fprintf('\nConfiguration %d/%d: %s\n', config_idx, num_Ltabu_configs, config_struct.label);
        fprintf('----------------------------------------\n');
        
        Ltabu_results{config_idx} = [];
        
        for run = 1:config.num_runs
            fprintf('  Run %d/%d...\n', run, config.num_runs);
            
            interface = DataObj;
            
            tic;
            if strcmp(config_struct.mode, 'fixed')
                methods.BHST_MY_SA(interface, true, 'fixed', config_struct.value);
            else
                methods.BHST_MY_SA(interface, true, 'adaptive', 20);
            end
            elapsed_time = toc;
            Ltabu_times(config_idx, run) = elapsed_time;
            
            KPIs = calcuUserKPIs(interface);
            Ltabu_results{config_idx} = [Ltabu_results{config_idx}; KPIs];
            
            fprintf('    - Average throughput: %.2f Mbps\n', KPIs.avg_throughput/1e6);
            fprintf('    - Average satisfaction rate: %.2f%%\n', KPIs.SS_avg*100);
            fprintf('    - Elapsed time: %.2f seconds\n', elapsed_time);
        end
        
        Ltabu_KPIs{config_idx} = averageKPIs(Ltabu_results{config_idx});
    end
    
    % Save L_tabu ablation results
    all_results.Ltabu_ablation = struct(...
        'configs', Ltabu_configs, ...
        'results', Ltabu_results, ...
        'KPIs', Ltabu_KPIs, ...
        'times', Ltabu_times ...
    );
    
    fprintf('\nL_tabu ablation experiment completed!\n\n');
else
    fprintf('[Step 4/6] Skipping L_tabu ablation experiment\n\n');
end

%% Generate Summary Report
fprintf('[Step 5/6] Generating summary report...\n');
fprintf('========================================\n\n');

fprintf('==================== Comprehensive Experiment Results Summary ====================\n\n');

if config.run_baseline
    fprintf('[Baseline Comparison Results]\n');
    fprintf('%-15s %12s %12s %12s %12s\n', 'Method', 'Throughput(Mbps)', 'SINR(dB)', 'Outage(%)', 'Satisfaction(%)');
    fprintf('%-15s %12s %12s %12s %12s\n', '---------------', '------------', '------------', '------------', '------------');
    for i = 1:length(baseline_KPIs)
        kpi = baseline_KPIs{i};
        fprintf('%-15s %12.2f %12.2f %12.2f %12.2f\n', ...
            methods_list{i}, kpi.avg_throughput/1e6, kpi.avg_SINR, kpi.outage_rate*100, kpi.SS_avg*100);
    end
    fprintf('\n');
end

if config.run_ablation_SA
    fprintf('[SA Ablation Results]\n');
    fprintf('%-15s %12s %12s\n', 'Configuration', 'Throughput(Mbps)', 'Satisfaction(%)');
    fprintf('%-15s %12s %12s\n', '---------------', '------------', '------------');
    for i = 1:length(SA_KPIs)
        kpi = SA_KPIs{i};
        fprintf('%-15s %12.2f %12.2f\n', SA_configs{i}, kpi.avg_throughput/1e6, kpi.SS_avg*100);
    end
    fprintf('\n');
end

if config.run_ablation_Ltabu
    fprintf('[L_tabu Ablation Results]\n');
    fprintf('%-15s %12s %12s\n', 'Configuration', 'Throughput(Mbps)', 'Satisfaction(%)');
    fprintf('%-15s %12s %12s\n', '---------------', '------------', '------------');
    for i = 1:length(Ltabu_KPIs)
        kpi = Ltabu_KPIs{i};
        fprintf('%-15s %12.2f %12.2f\n', Ltabu_configs{i}.label, kpi.avg_throughput/1e6, kpi.SS_avg*100);
    end
    fprintf('\n');
end

fprintf('==========================================================\n\n');

%% Save All Results
if config.save_results
    fprintf('[Step 6/6] Saving experiment results...\n');
    
    % Create results directory (if not exists)
    if ~exist('results', 'dir')
        mkdir('results');
    end
    
    % Save MAT file
    save_filename = sprintf('results/all_experiments_%s.mat', all_timestamp);
    save(save_filename, 'all_results', 'config', 'all_timestamp');
    fprintf('   OK Results saved: %s\n', save_filename);
end

fprintf('\n========================================\n');
fprintf('   Comprehensive Experiment Completed!\n');
fprintf('========================================\n\n');

%% Helper Function: Calculate Average KPIs
function avg_KPIs = averageKPIs(KPIs_cell)
    % Average multiple KPIs structures
    
    if isempty(KPIs_cell)
        avg_KPIs = struct();
        return;
    end
    
    % Get all field names
    field_names = fieldnames(KPIs_cell(1));
    
    % Initialize average KPIs
    avg_KPIs = struct();
    
    % Average each field
    for i = 1:length(field_names)
        field = field_names{i};
        values = [KPIs_cell.(field)];
        
        % Filter out NaN values
        valid_values = values(~isnan(values));
        
        if ~isempty(valid_values)
            avg_KPIs.(field) = mean(valid_values);
        else
            avg_KPIs.(field) = NaN;
        end
    end
end
