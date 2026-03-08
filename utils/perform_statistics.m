% utils/perform_statistics.m
% Comprehensive statistical analysis: Compare Tabu Search and DQN performance
% Generate detailed statistical reports and comparison tables

clear; clc;

fprintf('========================================================\n');
fprintf('  Comprehensive Statistical Analysis: Tabu Search vs DQN\n');
fprintf('========================================================\n\n');

% Load result files
try
    load('results/results_TabuSearch.mat');
    fprintf('[OK] Tabu Search results loaded\n');
catch
    fprintf('[ERROR] Tabu Search result file not found\n');
    fprintf('    Please run run_TabuSearch.m first\n');
    return;
end

try
    load('results/results_DQN.mat');
    fprintf('[OK] DQN results loaded\n');
catch
    fprintf('[ERROR] DQN result file not found\n');
    fprintf('    Please run run_DQN.m first\n');
    return;
end

fprintf('\n');

% Statistics of valid data
valid_Tabu = ~isnan(throughputs_Tabu) & ~isnan(satisfactions_Tabu);
valid_DQN = ~isnan(throughputs_DQN) & ~isnan(satisfactions_DQN);

num_valid_Tabu = sum(valid_Tabu);
num_valid_DQN = sum(valid_DQN);

fprintf('Valid data statistics:\n');
fprintf('  - Tabu Search: %d/%d\n', num_valid_Tabu, length(throughputs_Tabu));
fprintf('  - DQN: %d/%d\n\n', num_valid_DQN, length(throughputs_DQN));

if num_valid_Tabu == 0 || num_valid_DQN == 0
    fprintf('[ERROR] Insufficient valid data, unable to perform statistical analysis\n');
    return;
end

%% 1. Throughput Analysis
fprintf('========================================================\n');
fprintf('  1. System Throughput Analysis\n');
fprintf('========================================================\n\n');

mean_Thr_Tabu = mean(throughputs_Tabu(valid_Tabu));
std_Thr_Tabu = std(throughputs_Tabu(valid_Tabu));
ci_Thr_Tabu = 1.96 * std_Thr_Tabu / sqrt(num_valid_Tabu);
min_Thr_Tabu = min(throughputs_Tabu(valid_Tabu));
max_Thr_Tabu = max(throughputs_Tabu(valid_Tabu));

mean_Thr_DQN = mean(throughputs_DQN(valid_DQN));
std_Thr_DQN = std(throughputs_DQN(valid_DQN));
ci_Thr_DQN = 1.96 * std_Thr_DQN / sqrt(num_valid_DQN);
min_Thr_DQN = min(throughputs_DQN(valid_DQN));
max_Thr_DQN = max(throughputs_DQN(valid_DQN));

% Calculate improvement
improvement_Thr = (mean_Thr_Tabu - mean_Thr_DQN) / mean_Thr_DQN * 100;
ci_improvement_Thr = improvement_Thr * sqrt((std_Thr_Tabu/mean_Thr_Tabu)^2 + (std_Thr_DQN/mean_Thr_DQN)^2);

fprintf('Tabu Search:\n');
fprintf('  Mean: %.2f +/- %.2f Mbps\n', mean_Thr_Tabu, std_Thr_Tabu);
fprintf('  95%% CI: [%.2f, %.2f] Mbps\n', mean_Thr_Tabu - ci_Thr_Tabu, mean_Thr_Tabu + ci_Thr_Tabu);
fprintf('  Range: [%.2f, %.2f] Mbps\n\n', min_Thr_Tabu, max_Thr_Tabu);

fprintf('DQN:\n');
fprintf('  Mean: %.2f +/- %.2f Mbps\n', mean_Thr_DQN, std_Thr_DQN);
fprintf('  95%% CI: [%.2f, %.2f] Mbps\n', mean_Thr_DQN - ci_Thr_DQN, mean_Thr_DQN + ci_Thr_DQN);
fprintf('  Range: [%.2f, %.2f] Mbps\n\n', min_Thr_DQN, max_Thr_DQN);

fprintf('Comparison:\n');
fprintf('  Absolute improvement: %.2f +/- %.2f Mbps\n', mean_Thr_Tabu - mean_Thr_DQN, sqrt(std_Thr_Tabu^2 + std_Thr_DQN^2));
fprintf('  Relative improvement: %.2f +/- %.2f%%\n', improvement_Thr, ci_improvement_Thr);

% t-test
[h_Thr, p_Thr] = ttest2(throughputs_Tabu(valid_Tabu), throughputs_DQN(valid_DQN));
fprintf('  t-test: h=%d, p=%.4f\n', h_Thr, p_Thr);
if p_Thr < 0.01
    fprintf('  Conclusion: Difference is highly significant (p < 0.01)\n');
elseif p_Thr < 0.05
    fprintf('  Conclusion: Difference is significant (p < 0.05)\n');
else
    fprintf('  Conclusion: Difference is not significant (p >= 0.05)\n');
end
fprintf('\n');

%% 2. Service Satisfaction Rate Analysis
fprintf('========================================================\n');
fprintf('  2. Service Satisfaction Rate Analysis\n');
fprintf('========================================================\n\n');

mean_Sat_Tabu = mean(satisfactions_Tabu(valid_Tabu));
std_Sat_Tabu = std(satisfactions_Tabu(valid_Tabu));
ci_Sat_Tabu = 1.96 * std_Sat_Tabu / sqrt(num_valid_Tabu);

mean_Sat_DQN = mean(satisfactions_DQN(valid_DQN));
std_Sat_DQN = std(satisfactions_DQN(valid_DQN));
ci_Sat_DQN = 1.96 * std_Sat_DQN / sqrt(num_valid_DQN);

improvement_Sat = (mean_Sat_Tabu - mean_Sat_DQN) / mean_Sat_DQN * 100;

fprintf('Tabu Search:\n');
fprintf('  Mean: %.2f +/- %.2f%%\n', mean_Sat_Tabu * 100, std_Sat_Tabu * 100);
fprintf('  95%% CI: [%.2f%%, %.2f%%]\n\n', (mean_Sat_Tabu - ci_Sat_Tabu) * 100, (mean_Sat_Tabu + ci_Sat_Tabu) * 100);

fprintf('DQN:\n');
fprintf('  Mean: %.2f +/- %.2f%%\n', mean_Sat_DQN * 100, std_Sat_DQN * 100);
fprintf('  95%% CI: [%.2f%%, %.2f%%]\n\n', (mean_Sat_DQN - ci_Sat_DQN) * 100, (mean_Sat_DQN + ci_Sat_DQN) * 100);

fprintf('Comparison:\n');
fprintf('  Relative improvement: %.2f%%\n', improvement_Sat);

% t-test
[h_Sat, p_Sat] = ttest2(satisfactions_Tabu(valid_Tabu), satisfactions_DQN(valid_DQN));
fprintf('  t-test: h=%d, p=%.4f\n', h_Sat, p_Sat);
if p_Sat < 0.01
    fprintf('  Conclusion: Difference is highly significant (p < 0.01)\n');
elseif p_Sat < 0.05
    fprintf('  Conclusion: Difference is significant (p < 0.05)\n');
else
    fprintf('  Conclusion: Difference is not significant (p >= 0.05)\n');
end
fprintf('\n');

%% 3. Runtime Analysis
fprintf('========================================================\n');
fprintf('  3. Runtime Analysis\n');
fprintf('========================================================\n\n');

mean_Time_Tabu = mean(times_Tabu(valid_Tabu));
std_Time_Tabu = std(times_Tabu(valid_Tabu));

mean_Time_DQN = mean(times_DQN(valid_DQN));
std_Time_DQN = std(times_DQN(valid_DQN));

speedup = mean_Time_DQN / mean_Time_Tabu;

fprintf('Tabu Search:\n');
fprintf('  Mean time: %.2f +/- %.2f seconds\n\n', mean_Time_Tabu, std_Time_Tabu);

fprintf('DQN:\n');
fprintf('  Mean time: %.2f +/- %.2f seconds\n\n', mean_Time_DQN, std_Time_DQN);

fprintf('Comparison:\n');
fprintf('  Speed ratio: %.2fx\n', speedup);
if speedup > 1
    fprintf('  Tabu Search is %.2fx faster\n', speedup);
else
    fprintf('  DQN is %.2fx faster\n', 1/speedup);
end
fprintf('\n');

%% 4. Stability Analysis (Coefficient of Variation)
fprintf('========================================================\n');
fprintf('  4. Stability Analysis (Coefficient of Variation)\n');
fprintf('========================================================\n\n');

cv_Thr_Tabu = std_Thr_Tabu / mean_Thr_Tabu * 100;
cv_Thr_DQN = std_Thr_DQN / mean_Thr_DQN * 100;
cv_Sat_Tabu = std_Sat_Tabu / mean_Sat_Tabu * 100;
cv_Sat_DQN = std_Sat_DQN / mean_Sat_DQN * 100;

fprintf('Throughput coefficient of variation:\n');
fprintf('  Tabu Search: %.2f%%\n', cv_Thr_Tabu);
fprintf('  DQN: %.2f%%\n', cv_Thr_DQN);
fprintf('  Tabu Search is %.2fx more stable\n', cv_Thr_DQN / cv_Thr_Tabu);
fprintf('\n');

fprintf('Satisfaction rate coefficient of variation:\n');
fprintf('  Tabu Search: %.2f%%\n', cv_Sat_Tabu);
fprintf('  DQN: %.2f%%\n', cv_Sat_DQN);
fprintf('  Tabu Search is %.2fx more stable\n', cv_Sat_DQN / cv_Sat_Tabu);
fprintf('\n');

%% 5. Generate Comparison Table
fprintf('========================================================\n');
fprintf('  5. Detailed Comparison Table\n');
fprintf('========================================================\n\n');

fprintf('%-20s %-15s %-15s %-15s\n', 'Metric', 'Tabu Search', 'DQN', 'Improvement');
fprintf('%-20s %-15s %-15s %-15s\n', repmat('-', 1, 20), repmat('-', 1, 15), repmat('-', 1, 15), repmat('-', 1, 15));
fprintf('%-20s %-15s %-15s %-15s\n', 'Throughput (Mbps)', ...
    sprintf('%.2f+-%.2f', mean_Thr_Tabu, std_Thr_Tabu), ...
    sprintf('%.2f+-%.2f', mean_Thr_DQN, std_Thr_DQN), ...
    sprintf('+%.2f%%', improvement_Thr));
fprintf('%-20s %-15s %-15s %-15s\n', 'Satisfaction Rate (%)', ...
    sprintf('%.1f+-%.1f', mean_Sat_Tabu*100, std_Sat_Tabu*100), ...
    sprintf('%.1f+-%.1f', mean_Sat_DQN*100, std_Sat_DQN*100), ...
    sprintf('+%.2f%%', improvement_Sat));
fprintf('%-20s %-15s %-15s %-15s\n', 'Runtime (s)', ...
    sprintf('%.2f+-%.2f', mean_Time_Tabu, std_Time_Tabu), ...
    sprintf('%.2f+-%.2f', mean_Time_DQN, std_Time_DQN), ...
    sprintf('%.2fx', speedup));
fprintf('\n');

%% 6. Save Comprehensive Report
fprintf('========================================================\n');
fprintf('  6. Save Comprehensive Report\n');
fprintf('========================================================\n\n');

report = struct();
report.TabuSearch = struct(...
    'num_runs', num_valid_Tabu, ...
    'throughput', struct('mean', mean_Thr_Tabu, 'std', std_Thr_Tabu, 'ci', ci_Thr_Tabu), ...
    'satisfaction', struct('mean', mean_Sat_Tabu, 'std', std_Sat_Tabu, 'ci', ci_Sat_Tabu), ...
    'time', struct('mean', mean_Time_Tabu, 'std', std_Time_Tabu), ...
    'cv', struct('throughput', cv_Thr_Tabu, 'satisfaction', cv_Sat_Tabu));

report.DQN = struct(...
    'num_runs', num_valid_DQN, ...
    'throughput', struct('mean', mean_Thr_DQN, 'std', std_Thr_DQN, 'ci', ci_Thr_DQN), ...
    'satisfaction', struct('mean', mean_Sat_DQN, 'std', std_Sat_DQN, 'ci', ci_Sat_DQN), ...
    'time', struct('mean', mean_Time_DQN, 'std', std_Time_DQN), ...
    'cv', struct('throughput', cv_Thr_DQN, 'satisfaction', cv_Sat_DQN));

report.Comparison = struct(...
    'throughput_improvement', improvement_Thr, ...
    'satisfaction_improvement', improvement_Sat, ...
    'speedup', speedup, ...
    'ttest_throughput', struct('h', h_Thr, 'p', p_Thr), ...
    'ttest_satisfaction', struct('h', h_Sat, 'p', p_Sat), ...
    'stability_ratio', struct('throughput', cv_Thr_DQN/cv_Thr_Tabu, 'satisfaction', cv_Sat_DQN/cv_Sat_Tabu));

dateStr = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
report_filename = sprintf('results/Statistics_Report_%s.mat', dateStr);

try
    save(report_filename, 'report', '-v7.3');
    fprintf('[OK] Comprehensive report saved: %s\n', report_filename);
catch ME
    fprintf('[ERROR] Report save failed: %s\n', ME.message);
end

fprintf('\n========================================================\n');
fprintf('  Statistical Analysis Completed\n');
fprintf('========================================================\n');
