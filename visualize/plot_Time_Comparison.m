% visualize/plot_Time_Comparison.m
% Plot runtime comparison: Tabu Search vs DQN

clear; clc;

fprintf('=== Runtime Comparison Analysis ===\n\n');

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
valid_Tabu = ~isnan(times_Tabu);
valid_DQN = ~isnan(times_DQN);

num_valid_Tabu = sum(valid_Tabu);
num_valid_DQN = sum(valid_DQN);

fprintf('Valid data statistics:\n');
fprintf('  - Tabu Search: %d/%d\n', num_valid_Tabu, length(times_Tabu));
fprintf('  - DQN: %d/%d\n\n', num_valid_DQN, length(times_DQN));

if num_valid_Tabu == 0 || num_valid_DQN == 0
    fprintf('[ERROR] Insufficient valid data, unable to plot comparison chart\n');
    return;
end

% Calculate statistics
mean_Tabu = mean(times_Tabu(valid_Tabu));
std_Tabu = std(times_Tabu(valid_Tabu));
median_Tabu = median(times_Tabu(valid_Tabu));
min_Tabu = min(times_Tabu(valid_Tabu));
max_Tabu = max(times_Tabu(valid_Tabu));

mean_DQN = mean(times_DQN(valid_DQN));
std_DQN = std(times_DQN(valid_DQN));
median_DQN = median(times_DQN(valid_DQN));
min_DQN = min(times_DQN(valid_DQN));
max_DQN = max(times_DQN(valid_DQN));

% Calculate speed ratio
speedup = mean_DQN / mean_Tabu;

% Plot bar chart
figure('Color', 'w', 'Position', [100, 100, 800, 500]);

% Subplot 1: Average runtime
subplot(2, 1, 1);

data_mean = [mean_Tabu, mean_DQN];
errors_mean = [std_Tabu, std_DQN];

b_mean = bar(data_mean, 'FaceColor', 'flat', 'BarWidth', 0.6);
b_mean.CData(1,:) = [0, 0.4470, 0.7410]; % Blue (Tabu Search)
b_mean.CData(2,:) = [0.8500, 0.3250, 0.0980]; % Red (DQN)

hold on;
errorbar(1:2, data_mean, errors_mean, 'k.', 'LineWidth', 2, 'CapSize', 10);

% Add value labels
for i = 1:length(data_mean)
    text(i, data_mean(i) + errors_mean(i), sprintf('%.2f', data_mean(i)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 11, ...
        'FontWeight', 'bold');
end

% Add speed ratio marker
if speedup > 1
    text(1, data_mean(1) + errors_mean(1) * 2, ...
        sprintf('%.2fx faster', speedup), ...
        'HorizontalAlignment', 'center', ...
        'Color', [0, 0.5, 0], ...
        'FontSize', 12, ...
        'FontWeight', 'bold');
end

grid on;
ylabel('Runtime (seconds)', 'FontSize', 12, 'FontName', 'Times New Roman');
title('Average Runtime Comparison', 'FontSize', 14, 'FontName', 'Times New Roman');
set(gca, 'XTickLabel', {'Tabu Search', 'DQN'}, 'FontSize', 11, 'FontName', 'Times New Roman');
set(gca, 'YGrid', 'on', 'XGrid', 'on', 'LineWidth', 1.5);
legend('Mean', 'Std', 'Location', 'best', 'FontSize', 10);

% Subplot 2: Single run time distribution (boxplot)
subplot(2, 1, 2);

data_boxplot = [times_Tabu(valid_Tabu); times_DQN(valid_DQN)];
group = [ones(num_valid_Tabu, 1); 2 * ones(num_valid_DQN, 1)];

boxplot(data_boxplot, group, 'Colors', [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980]);
set(gca, 'XTick', [1, 2], 'XTickLabel', {'Tabu Search', 'DQN'}, ...
    'FontSize', 11, 'FontName', 'Times New Roman');
ylabel('Runtime (seconds)', 'FontSize', 12, 'FontName', 'Times New Roman');
title('Single Run Time Distribution', 'FontSize', 14, 'FontName', 'Times New Roman');
grid on;

% Save figure
dateStr = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
filename_fig = sprintf('visualize/Time_Comparison_%s.fig', dateStr);
filename_png = sprintf('visualize/Time_Comparison_%s.png', dateStr);

try
    saveas(gcf, filename_fig);
    fprintf('[OK] FIG figure saved: %s\n', filename_fig);
catch ME
    fprintf('[ERROR] FIG figure save failed: %s\n', ME.message);
end

try
    saveas(gcf, filename_png);
    fprintf('[OK] PNG figure saved: %s\n', filename_png);
catch ME
    fprintf('[ERROR] PNG figure save failed: %s\n', ME.message);
end

% Print statistical results
fprintf('\n=== Statistical Results ===\n');
fprintf('Tabu Search:\n');
fprintf('  - Mean time: %.2f +/- %.2f seconds\n', mean_Tabu, std_Tabu);
fprintf('  - Median: %.2f seconds\n', median_Tabu);
fprintf('  - Minimum: %.2f seconds\n', min_Tabu);
fprintf('  - Maximum: %.2f seconds\n', max_Tabu);
fprintf('\n');

fprintf('DQN:\n');
fprintf('  - Mean time: %.2f +/- %.2f seconds\n', mean_DQN, std_DQN);
fprintf('  - Median: %.2f seconds\n', median_DQN);
fprintf('  - Minimum: %.2f seconds\n', min_DQN);
fprintf('  - Maximum: %.2f seconds\n', max_DQN);
fprintf('\n');

fprintf('Performance Comparison:\n');
fprintf('  - Speed ratio (DQN/Tabu): %.2fx\n', speedup);
if speedup > 1
    fprintf('  - Tabu Search is %.2fx faster\n', speedup);
else
    fprintf('  - DQN is %.2fx faster\n', 1/speedup);
end
fprintf('\n');

% Significance test (t-test)
try
    [h, p] = ttest2(times_Tabu(valid_Tabu), times_DQN(valid_DQN));
    fprintf('t-test results:\n');
    fprintf('  - h = %d (h=1 indicates significant difference)\n', h);
    fprintf('  - p = %.4f\n', p);
    if p < 0.01
        fprintf('  - Conclusion: Difference is highly significant (p < 0.01)\n');
    elseif p < 0.05
        fprintf('  - Conclusion: Difference is significant (p < 0.05)\n');
    else
        fprintf('  - Conclusion: Difference is not significant (p >= 0.05)\n');
    end
catch ME
    fprintf('Significance test failed: %s\n', ME.message);
end

fprintf('\n=== Analysis Complete ===\n');
