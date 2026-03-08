% run_TabuSearch.m
% Run Tabu Search algorithm baseline test
% Goal: Multiple runs to obtain stable statistical results

clear; clc;

fprintf('========================================\n');
fprintf('  Tabu Search Algorithm Baseline Test\n');
fprintf('========================================\n\n');

% Load configuration
setConfig;

% Configure for Tabu Search method (using BHST_MY)
Config.numOfMethods_BeamGenerate = 1;
Config.numOfMethods_BeamHopping = 1;

% Modify generateBHST.m to use Tabu Search
% Note: Need to call methods.BHST_MY in generateBHST.m

% Multiple runs
num_runs = 5;
results_Tabu = cell(num_runs, 1);
times_Tabu = zeros(num_runs, 1);
throughputs_Tabu = zeros(num_runs, 1);
satisfactions_Tabu = zeros(num_runs, 1);

fprintf('Run configuration:\n');
fprintf('  - Number of users: %d\n', Config.meanUsrsNum);
fprintf('  - Number of beams: %d\n', Config.numOfServbeam);
fprintf('  - Scheduling period: %.2f ms\n', Config.bhTime * 1000);
fprintf('  - Number of runs: %d\n\n', num_runs);

% Run experiments
for run = 1 : num_runs
    fprintf('===== Tabu Search Run %d/%d =====\n', run, num_runs);
    tic;
    
    try
        % Run simulation
        controller = simSatSysClass.simController(Config, 1, 1, 0);
        DataObj = controller.run();
        
        times_Tabu(run) = toc;
        results_Tabu{run} = DataObj;
        
        % Calculate performance metrics
        throughputs_Tabu(run) = calcuThroughput(DataObj);
        satisfactions_Tabu(run) = calcuSatis(DataObj);
        
        fprintf('Tabu Search run %d completed, elapsed time: %.2f seconds\n', run, times_Tabu(run));
        fprintf('  - Throughput: %.2f Mbps\n', throughputs_Tabu(run));
        fprintf('  - Satisfaction rate: %.2f%%\n', satisfactions_Tabu(run) * 100);
        fprintf('\n');
        
    catch ME
        fprintf(' Run %d failed: %s\n', run, ME.message);
        times_Tabu(run) = NaN;
        throughputs_Tabu(run) = NaN;
        satisfactions_Tabu(run) = NaN;
    end
end

% Statistical analysis
fprintf('========================================\n');
fprintf('  Tabu Search Statistical Results\n');
fprintf('========================================\n\n');

valid_runs = ~isnan(throughputs_Tabu);
num_valid = sum(valid_runs);

if num_valid == 0
    fprintf('[ERROR] All runs failed\n');
    return;
end

fprintf('Number of valid runs: %d/%d\n\n', num_valid, num_runs);

% Throughput statistics
mean_throughput = mean(throughputs_Tabu(valid_runs));
std_throughput = std(throughputs_Tabu(valid_runs));
ci_throughput = 1.96 * std_throughput / sqrt(num_valid);

fprintf('=== System Throughput ===\n');
fprintf('Mean: %.2f Mbps\n', mean_throughput);
fprintf('Std: %.2f Mbps\n', std_throughput);
fprintf('95%% CI: [%.2f, %.2f] Mbps\n', ...
    mean_throughput - ci_throughput, mean_throughput + ci_throughput);
fprintf('\n');

% Satisfaction rate statistics
mean_satisfaction = mean(satisfactions_Tabu(valid_runs));
std_satisfaction = std(satisfactions_Tabu(valid_runs));
ci_satisfaction = 1.96 * std_satisfaction / sqrt(num_valid);

fprintf('=== Service Satisfaction Rate ===\n');
fprintf('Mean: %.2f%%\n', mean_satisfaction * 100);
fprintf('Std: %.2f%%\n', std_satisfaction * 100);
fprintf('95%% CI: [%.2f%%, %.2f%%]\n', ...
    (mean_satisfaction - ci_satisfaction) * 100, ...
    (mean_satisfaction + ci_satisfaction) * 100);
fprintf('\n');

% Runtime statistics
mean_time = mean(times_Tabu(valid_runs));
std_time = std(times_Tabu(valid_runs));

fprintf('=== Runtime ===\n');
fprintf('Mean: %.2f seconds\n', mean_time);
fprintf('Std: %.2f seconds\n', std_time);
fprintf('\n');

% Save results
fprintf('Saving results...\n');
dateStr = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
results_filename = sprintf('results/results_TabuSearch_%s.mat', dateStr);

try
    save(results_filename, 'results_Tabu', 'times_Tabu', ...
        'throughputs_Tabu', 'satisfactions_Tabu', 'Config', '-v7.3');
    fprintf('[OK] Results saved to: %s\n', results_filename);
catch ME
    fprintf('[ERROR] Save failed: %s\n', ME.message);
end

fprintf('\n========================================\n');
fprintf('  Tabu Search Baseline Test Completed\n');
fprintf('========================================\n');
