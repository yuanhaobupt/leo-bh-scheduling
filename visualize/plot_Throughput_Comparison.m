% visualize/plot_Throughput_Comparison.m
% Plot throughput comparison: Tabu Search vs DQN

clear; clc;

fprintf('=== Throughput Comparison Analysis ===\n\n');

% Load result files
try
    load('results/results_TabuSearch.mat');
    fprintf('[✓] Tabu Search results loaded\n');
catch
    fprintf('[✗] Tabu Search result file not found\n');
    fprintf('    Please run run_TabuSearch.m first\n');
    return;
end

try
    load('results/results_DQN.mat');
    fprintf('[✓] DQN results loaded\n');
catch
    fprintf('[✗] DQN result file not found\n');
    fprintf('    Please run run_DQN.m first\n');
    return;
end

fprintf('\n');

% Statistics of valid data
valid_Tabu = ~isnan(throughputs_Tabu);
valid_DQN = ~isnan(throughputs_DQN);

num_valid_Tabu = sum(valid_Tabu);
num_valid_DQN = sum(valid_DQN);

fprintf('Valid data statistics:\n');
fprintf('  - Tabu Search: %d/%d\n', num_valid_Tabu, length(throughputs_Tabu));
fprintf('  - DQN: %d/%d\n\n', num_valid_DQN, length(throughputs_DQN));

if num_valid_Tabu == 0 || num_valid_DQN == 0
    fprintf('[✗] Insufficient valid data, unable to plot comparison chart\n');
    return;
end

% Calculate statistics
mean_Tabu = mean(throughputs_Tabu(valid_Tabu));
std_Tabu = std(throughputs_Tabu(valid_Tabu));
mean_DQN = mean(throughputs_DQN(valid_DQN));
std_DQN = std(throughputs_DQN(valid_DQN));

% Calculate improvement percentage
improvement = (mean_Tabu - mean_DQN) / mean_DQN * 100;

% Plot bar chart
figure('Color', 'w', 'Position', [100, 100, 800, 500]);

data = [mean_Tabu, mean_DQN];
errors = [std_Tabu, std_DQN];

b = bar(data, 'FaceColor', 'flat', 'BarWidth', 0.6);
b.CData(1,:) = [0, 0.4470, 0.7410]; % Blue (Tabu Search)
b.CData(2,:) = [0.8500, 0.3250, 0.0980]; % Red (DQN)

hold on;

% Add error bars
errorbar(1:2, data, errors, 'k.', 'LineWidth', 2, 'CapSize', 10);

% Add value labels
for i = 1:length(data)
    text(i, data(i) + errors(i), sprintf('%.2f', data(i)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 12, ...
        'FontWeight', 'bold');
end

% Add improvement percentage marker
if improvement > 0
    text(2, data(2) + errors(2) * 2, ...
        sprintf('+%.2f%%', improvement), ...
        'HorizontalAlignment', 'center', ...
        'Color', [0, 0.5, 0], ...
        'FontSize', 14, ...
        'FontWeight', 'bold');
end

% Set figure properties
grid on;
xlabel('Algorithm', 'FontSize', 14, 'FontName', 'Times New Roman');
ylabel('System Throughput (Mbps)', 'FontSize', 14, 'FontName', 'Times New Roman');
title('System Throughput Comparison: Tabu Search vs DQN', 'FontSize', 16, 'FontName', 'Times New Roman');
set(gca, 'XTickLabel', {'Tabu Search', 'DQN'}, 'FontSize', 12, 'FontName', 'Times New Roman');
set(gca, 'YGrid', 'on', 'XGrid', 'on', 'LineWidth', 1.5);
ylim([0, max(data + errors) * 1.2]);

% Add legend
legend('Average Value', 'Standard Deviation', 'Location', 'best', 'FontSize', 10);

% Save figure
dateStr = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
filename_fig = sprintf('visualize/Throughput_Comparison_%s.fig', dateStr);
filename_png = sprintf('visualize/Throughput_Comparison_%s.png', dateStr);

try
    saveas(gcf, filename_fig);
    fprintf('[✓] FIG figure saved: %s\n', filename_fig);
catch ME
    fprintf('[✗] FIG figure save failed: %s\n', ME.message);
end

try
    saveas(gcf, filename_png);
    fprintf('[✓] PNG figure saved: %s\n', filename_png);
catch ME
    fprintf('[✗] PNG figure save failed: %s\n', ME.message);
end

% Print statistical results
fprintf('\n=== Statistical Results ===\n');
fprintf('Tabu Search:\n');
fprintf('  - Average throughput: %.2f ± %.2f Mbps\n', mean_Tabu, std_Tabu);
fprintf('  - Minimum: %.2f Mbps\n', min(throughputs_Tabu(valid_Tabu)));
fprintf('  - Maximum: %.2f Mbps\n', max(throughputs_Tabu(valid_Tabu)));
fprintf('\n');

fprintf('DQN:\n');
fprintf('  - Average throughput: %.2f ± %.2f Mbps\n', mean_DQN, std_DQN);
fprintf('  - Minimum: %.2f Mbps\n', min(throughputs_DQN(valid_DQN)));
fprintf('  - Maximum: %.2f Mbps\n', max(throughputs_DQN(valid_DQN)));
fprintf('\n');

fprintf('Performance Comparison:\n');
fprintf('  - Tabu Search improvement: %.2f%%\n', improvement);
fprintf('\n');

% Significance test (t-test)
try
    [h, p] = ttest2(throughputs_Tabu(valid_Tabu), throughputs_DQN(valid_DQN));
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
