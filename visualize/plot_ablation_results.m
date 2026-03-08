function plot_ablation_results(results_file, save_to_file)
% Plot ablation experiment results comparison charts
% Input parameters:
%   results_file  - Experiment results MAT file path (optional, default: latest all_experiments_*.mat)
%   save_to_file  - Whether to save figures (optional, default: true)
% Output:
%   Generate and display the following charts:
%   1. SA ablation experiment comparison chart
%   2. L_tabu ablation experiment comparison chart
%   3. Comprehensive performance comparison radar chart
% Author: 2025-03-04
% Version: 1.0

%% Parameter handling
if nargin < 1 || isempty(results_file)
    % Find latest experiment results file
    files = dir('results/all_experiments_*.mat');
    if isempty(files)
        error('Experiment results file not found, please run experiments first');
    end
    [~, idx] = max([files.datenum]);
    results_file = fullfile('results', files(idx).name);
    fprintf('Using latest results file: %s\n', results_file);
end

if nargin < 2 || isempty(save_to_file)
    save_to_file = true;
end

%% Load experiment results
fprintf('\nLoading experiment results...\n');
load(results_file, 'all_results');

%% Check data integrity
if ~isfield(all_results, 'baseline') && ~isfield(all_results, 'SA_ablation') && ~isfield(all_results, 'Ltabu_ablation')
    error('Results file format incorrect, missing required data');
end

%% Create figure window
fig_main = figure('Position', [50, 50, 1400, 900], 'Color', 'w');

%% Plot 1: SA ablation experiment comparison
if isfield(all_results, 'SA_ablation')
    subplot(2, 2, 1);
    plot_SA_ablation(all_results.SA_ablation);
    title('SA Ablation Experiment Comparison', 'FontSize', 14, 'FontWeight', 'bold');
end

%% Plot 2: L_tabu ablation experiment comparison
if isfield(all_results, 'Ltabu_ablation')
    subplot(2, 2, 2);
    plot_Ltabu_ablation(all_results.Ltabu_ablation);
    title('L_{tabu} Ablation Experiment Comparison', 'FontSize', 14, 'FontWeight', 'bold');
end

%% Plot 3: Baseline comparison - throughput and satisfaction rate
if isfield(all_results, 'baseline')
    subplot(2, 2, 3);
    plot_baseline_comparison(all_results.baseline);
    title('Baseline Algorithm Comparison', 'FontSize', 14, 'FontWeight', 'bold');
end

%% Plot 4: Comprehensive performance radar chart
if isfield(all_results, 'baseline') && isfield(all_results, 'SA_ablation')
    subplot(2, 2, 4);
    plot_radar_chart(all_results);
    title('Comprehensive Performance Radar Chart', 'FontSize', 14, 'FontWeight', 'bold');
end

%% Save figure
if save_to_file
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    filename = sprintf('results/ablation_results_%s.png', timestamp);
    saveas(fig_main, filename);
    fprintf('\nFigure saved: %s\n', filename);
    
    % Also save in fig format
    filename_fig = sprintf('results/ablation_results_%s.fig', timestamp);
    saveas(fig_main, filename_fig);
    fprintf('FIG file saved: %s\n', filename_fig);
end

fprintf('\nAblation experiment results visualization completed!\n\n');

%% ==================== Helper Plotting Functions ====================

%% Plot SA ablation experiment comparison
function plot_SA_ablation(SA_data)
    configs = SA_data.configs;
    KPIs = SA_data.KPIs;
    
    % Extract data
    throughputs = zeros(1, length(KPIs));
    satisfactions = zeros(1, length(KPIs));
    
    for i = 1:length(KPIs)
        throughputs(i) = KPIs{i}.avg_throughput / 1e6;  % Mbps
        satisfactions(i) = KPIs{i}.SS_avg * 100;  %
    end
    
    % Plot bar chart
    x = 1:length(configs);
    width = 0.35;
    
    yyaxis left;
    b1 = bar(x - width/2, throughputs, width, 'FaceColor', [0.3, 0.6, 0.9]);
    ylabel('Throughput (Mbps)', 'FontSize', 11);
    
    yyaxis right;
    b2 = bar(x + width/2, satisfactions, width, 'FaceColor', [0.9, 0.5, 0.3]);
    ylabel('Service Satisfaction Rate (%)', 'FontSize', 11);
    
    set(gca, 'XTick', x, 'XTickLabel', configs, 'FontSize', 10);
    xlabel('Configuration', 'FontSize', 11);
    
    legend({'Throughput', 'Service Satisfaction Rate'}, 'Location', 'northwest', 'FontSize', 9);
    grid on;
    
    % Add value labels
    for i = 1:length(x)
        text(x(i) - width/2, throughputs(i) + max(throughputs)*0.02, ...
            sprintf('%.2f', throughputs(i)), 'HorizontalAlignment', 'center', 'FontSize', 9);
        text(x(i) + width/2, satisfactions(i) + max(satisfactions)*0.02, ...
            sprintf('%.2f%%', satisfactions(i)), 'HorizontalAlignment', 'center', 'FontSize', 9);
    end
end

%% Plot L_tabu ablation experiment comparison
function plot_Ltabu_ablation(Ltabu_data)
    configs = Ltabu_data.configs;
    KPIs = Ltabu_data.KPIs;
    
    % Extract data
    labels = cell(1, length(configs));
    throughputs = zeros(1, length(KPIs));
    satisfactions = zeros(1, length(KPIs));
    
    for i = 1:length(configs)
        labels{i} = configs{i}.label;
        throughputs(i) = KPIs{i}.avg_throughput / 1e6;  % Mbps
        satisfactions(i) = KPIs{i}.SS_avg * 100;  %
    end
    
    % Plot bar chart
    x = 1:length(configs);
    width = 0.35;
    
    yyaxis left;
    b1 = bar(x - width/2, throughputs, width, 'FaceColor', [0.4, 0.8, 0.4]);
    ylabel('Throughput (Mbps)', 'FontSize', 11);
    
    yyaxis right;
    b2 = bar(x + width/2, satisfactions, width, 'FaceColor', [0.8, 0.4, 0.8]);
    ylabel('Service Satisfaction Rate (%)', 'FontSize', 11);
    
    set(gca, 'XTick', x, 'XTickLabel', labels, 'FontSize', 9, 'XTickLabelRotation', 45);
    xlabel('Tabu Tenure Configuration', 'FontSize', 11);
    
    legend({'Throughput', 'Service Satisfaction Rate'}, 'Location', 'northwest', 'FontSize', 9);
    grid on;
    
    % Add value labels
    for i = 1:length(x)
        text(x(i) - width/2, throughputs(i) + max(throughputs)*0.02, ...
            sprintf('%.2f', throughputs(i)), 'HorizontalAlignment', 'center', 'FontSize', 8);
        text(x(i) + width/2, satisfactions(i) + max(satisfactions)*0.02, ...
            sprintf('%.2f%%', satisfactions(i)), 'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end

%% Plot baseline comparison
function plot_baseline_comparison(baseline_data)
    methods = baseline_data.methods;
    KPIs = baseline_data.KPIs;
    
    % Extract data
    throughputs = zeros(1, length(KPIs));
    satisfactions = zeros(1, length(KPIs));
    outage_rates = zeros(1, length(KPIs));
    
    for i = 1:length(KPIs)
        throughputs(i) = KPIs{i}.avg_throughput / 1e6;  % Mbps
        satisfactions(i) = KPIs{i}.SS_avg * 100;  %
        outage_rates(i) = KPIs{i}.outage_rate * 100;  %
    end
    
    % Plot grouped bar chart
    x = 1:length(methods);
    data = [throughputs; satisfactions; outage_rates]';
    
    bar(data);
    
    set(gca, 'XTick', x, 'XTickLabel', methods, 'FontSize', 10);
    xlabel('Algorithm', 'FontSize', 11);
    ylabel('Performance Metrics', 'FontSize', 11);
    
    legend({'Throughput (Mbps)', 'Service Satisfaction Rate (%)', 'Outage Rate (%)'}, ...
        'Location', 'northoutside', 'FontSize', 9);
    grid on;
end

%% Plot radar chart
function plot_radar_chart(all_results)
    % Select key metrics
    metrics = {'Throughput', 'Satisfaction Rate', 'Fairness', 'SINR', 'Outage Rate (Inv)'};
    num_metrics = length(metrics);
    
    % Normalize to [0, 1]
    % This needs to be calculated based on actual data
    % Simplified version: using placeholders
    
    % Tabu+SA
    if isfield(all_results, 'baseline') && isfield(all_results, 'SA_ablation')
        kpi_tabu = all_results.baseline.KPIs{1};  % Assume first is Tabu+SA
        kpi_sa_only = all_results.SA_ablation.KPIs{2};  % without SA
        
        % Normalize metrics
        values_tabu = normalize_kpis(kpi_tabu);
        values_sa_only = normalize_kpis(kpi_sa_only);
        
        % Close polygon
        values_tabu = [values_tabu, values_tabu(1)];
        values_sa_only = [values_sa_only, values_sa_only(1)];
        
        % Plot radar chart
        angles = linspace(0, 2*pi, num_metrics+1);
        
        polarplot(angles, values_tabu, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
        hold on;
        polarplot(angles, values_sa_only, 'r--s', 'LineWidth', 2, 'MarkerSize', 8);
        
        % Set ticks
        ax = gca;
        ax.ThetaTick = rad2deg(angles(1:end-1));
        ax.ThetaTickLabel = metrics;
        ax.RLim = [0, 1];
        
        legend({'Tabu + SA', 'Tabu only'}, 'Location', 'southoutside', 'FontSize', 9);
    else
        text(0.5, 0.5, 'Insufficient data', 'HorizontalAlignment', 'center', 'FontSize', 12);
    end
end

%% Normalize KPIs to [0, 1]
function normalized = normalize_kpis(kpi)
    % This uses a simplified normalization method
    % In practice, should use min-max normalization based on all experiment data
    
    normalized = [
        min(kpi.avg_throughput / 250e6, 1);  % Throughput, assume max 250 Mbps
        kpi.SS_avg;  % Service satisfaction rate, already [0, 1]
        kpi.fairness_index;  % Fairness index, already [0, 1]
        min((kpi.avg_SINR + 10) / 30, 1);  % SINR, assume range [-10, 20] dB
        1 - kpi.outage_rate;  % Outage rate (inverse), lower is better
    ];
end
