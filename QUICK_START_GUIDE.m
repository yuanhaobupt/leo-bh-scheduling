% QUICK_START_GUIDE.m
% Quick Start Guide: Tabu Search vs DQN Comparison Experiment
% This script guides you through the entire experiment workflow

clear; clc;

fprintf('============================================================\n');
fprintf('  Tabu Search vs DQN: Performance Comparison - Quick Start\n');
fprintf('============================================================\n\n');

%% Step 1: Environment Check
fprintf('Step 1/5: Checking environment...\n');
fprintf('----------------------------------------\n');
try
    check_environment;
    fprintf('[OK] Environment check completed\n\n');
catch ME
    fprintf('[ERROR] Environment check failed: %s\n\n', ME.message);
    return;
end

%% Step 2: Run Tabu Search Baseline
fprintf('Step 2/5: Running Tabu Search algorithm (5 runs)...\n');
fprintf('----------------------------------------\n');
fprintf('Note: This may take several minutes\n');
fprintf('Continue? (y/n): ');

choice = input('', 's');
if lower(choice) == 'y'
    try
        run_TabuSearch;
        fprintf('[OK] Tabu Search baseline test completed\n\n');
    catch ME
        fprintf('[ERROR] Tabu Search run failed: %s\n\n', ME.message);
        return;
    end
else
    fprintf('[INFO] Skipping Tabu Search test\n\n');
end

%% Step 3: Run DQN Comparison
fprintf('Step 3/5: Running DQN algorithm (10 runs)...\n');
fprintf('----------------------------------------\n');
fprintf('Note: This may take longer\n');
fprintf('Continue? (y/n): ');

choice = input('', 's');
if lower(choice) == 'y'
    try
        run_DQN;
        fprintf('[OK] DQN comparison test completed\n\n');
    catch ME
        fprintf('[ERROR] DQN run failed: %s\n\n', ME.message);
        return;
    end
else
    fprintf('[INFO] Skipping DQN test\n\n');
end

%% Step 4: Generate Comparison Charts
fprintf('Step 4/5: Generating comparison charts...\n');
fprintf('----------------------------------------\n');

% Throughput comparison
fprintf('Generating throughput comparison chart...\n');
try
    visualize.plot_Throughput_Comparison;
    fprintf('[OK] Throughput comparison chart generated\n');
catch ME
    fprintf('[ERROR] Throughput chart generation failed: %s\n', ME.message);
end

% Satisfaction rate comparison
fprintf('Generating satisfaction rate comparison chart...\n');
try
    visualize.plot_Satisfaction_Rate;
    fprintf('[OK] Satisfaction rate chart generated\n');
catch ME
    fprintf('[ERROR] Satisfaction rate chart generation failed: %s\n', ME.message);
end

% SINR CDF comparison
fprintf('Generating SINR CDF comparison chart...\n');
try
    visualize.plot_SINR_CDF;
    fprintf('[OK] SINR CDF comparison chart generated\n');
catch ME
    fprintf('[ERROR] SINR CDF chart generation failed: %s\n', ME.message);
end

% Time comparison
fprintf('Generating runtime comparison chart...\n');
try
    visualize.plot_Time_Comparison;
    fprintf('[OK] Runtime comparison chart generated\n');
catch ME
    fprintf('[ERROR] Runtime chart generation failed: %s\n', ME.message);
end

fprintf('\n');

%% Step 5: Comprehensive Statistical Analysis
fprintf('Step 5/5: Comprehensive statistical analysis...\n');
fprintf('----------------------------------------\n');
try
    utils.perform_statistics;
    fprintf('[OK] Comprehensive statistical analysis completed\n\n');
catch ME
    fprintf('[ERROR] Statistical analysis failed: %s\n\n', ME.message);
    return;
end

%% Complete
fprintf('============================================================\n');
fprintf('  Experiment workflow completed!\n');
fprintf('============================================================\n\n');

fprintf('Generated files:\n');
fprintf('  - results/results_TabuSearch_*.mat\n');
fprintf('  - results/results_DQN_*.mat\n');
fprintf('  - results/Statistics_Report_*.mat\n');
fprintf('  - visualize/*.png\n');
fprintf('  - visualize/*.fig\n');
fprintf('  - docs/Comparison_Report.md\n');
fprintf('\n');

fprintf('Next steps:\n');
fprintf('  1. View the generated visualization charts\n');
fprintf('  2. Read docs/Comparison_Report.md for detailed analysis\n');
fprintf('  3. Adjust parameters and re-run experiments as needed\n');
fprintf('\n');

fprintf('Tips:\n');
fprintf('  - Use "type filename.m" to view script content\n');
fprintf('  - Use "help functionname" to view function help\n');
fprintf('  - Use "open filename.m" to open file in editor\n');
fprintf('\n');
