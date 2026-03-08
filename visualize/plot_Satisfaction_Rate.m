% visualize/plot_Satisfaction_Rate.m
% Plot service satisfaction rate comparison: Tabu Search vs DQN

clear; clc;

fprintf('=== Service Satisfaction Rate Comparison Analysis ===\n\n');

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
valid_Tabu = ~isnan(satisfactions_Tabu);
valid_DQN = ~isnan(satisfactions_DQN);

num_valid_Tabu = sum(valid_Tabu);
num_valid_DQN = sum(valid_DQN);

fprintf('Valid data statistics:\n');
fprintf('  - Tabu Search: %d/%d\n', num_valid_Tabu, length(satisfactions_Tabu));
fprintf('  - DQN: %d/%d\n\n', num_valid_DQN, length(satisfactions_DQN));

if num_valid_Tabu == 0 || num_valid_DQN == 0
    fprintf('[✗] Insufficient valid data, unable to plot comparison chart\n');
    return;
end

% Convert to percentage
satisfaction_Tabu_pct = satisfactions_Tabu * 100;
satisfaction_DQN_pct = satisfactions_DQN * 100;

% Calculate statistics
mean_Tabu = mean(satisfaction_Tabu_pct(valid_Tabu));
std_Tabu = std(satisfaction_Tabu_pct(valid_Tabu));
mean_DQN = mean(satisfaction_DQN_pct(valid_DQN));
std_DQN = std(satisfaction_DQN_pct(valid_DQN));

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
    text(i, data(i) + errors(i), sprintf('%.2f%%', data(i)), ...
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
ylabel('Service Satisfaction Rate (%)', 'FontSize', 14, 'FontName', 'Times New Roman');
title('Service Satisfaction Rate Comparison: Tabu Search vs DQN', 'FontSize', 16, 'FontName', 'Times New Roman');
set(gca, 'XTickLabel', {'Tabu Search', 'DQN'}, 'FontSize', 12, 'FontName', 'Times New Roman');
set(gca, 'YGrid', 'on', 'XGrid', 'on', 'LineWidth', 1.5);
ylim([0, 100]);

% Add legend
legend('Average Value', 'Standard Deviation', 'Location', 'best', 'FontSize', 10);

% Save figure
dateStr = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
filename_fig = sprintf('visualize/Satisfaction_Rate_%s.fig', dateStr);
filename_png = sprintf('visualize/Satisfaction_Rate_%s.png', dateStr);

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
fprintf('  - Average satisfaction rate: %.2f ± %.2f%%\n', mean_Tabu, std_Tabu);
fprintf('  - Minimum: %.2f%%\n', min(satisfaction_Tabu_pct(valid_Tabu)));
fprintf('  - Maximum: %.2f%%\n', max(satisfaction_Tabu_pct(valid_Tabu)));
fprintf('\n');

fprintf('DQN:\n');
fprintf('  - Average satisfaction rate: %.2f ± %.2f%%\n', mean_DQN, std_DQN);
fprintf('  - Minimum: %.2f%%\n', min(satisfaction_DQN_pct(valid_DQN)));
fprintf('  - Maximum: %.2f%%\n', max(satisfaction_DQN_pct(valid_DQN)));
fprintf('\n');

fprintf('Performance Comparison:\n');
fprintf('  - Tabu Search improvement: %.2f%%\n', improvement);
fprintf('\n');

% Significance test (t-test)
try
    [h, p] = ttest2(satisfactions_Tabu(valid_Tabu), satisfactions_DQN(valid_DQN));
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
