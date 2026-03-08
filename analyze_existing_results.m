%% Analyze Existing Experiment Results
% Extract performance metrics from saved result files

% Author: 2026-03-04

clear; clc; close all;

addpath(genpath('.'));

fprintf('========================================\n');
fprintf(' Analyze Existing Experiment Results\n');
fprintf('========================================\n\n');

%% Load TabuSearch results
fprintf('[1] Loading TabuSearch results...\n');
try
 load('results/results_TabuSearch.mat', 'results_Tabu', 'throughputs_Tabu', 'satisfactions_Tabu');
 fprintf(' OK TabuSearch results loaded successfully\n');
 
 if exist('throughputs_Tabu', 'var')
 fprintf(' - Throughput data: %d runs\n', length(throughputs_Tabu));
 fprintf(' - Average throughput: %.2f Mbps\n', mean(throughputs_Tabu(~isnan(throughputs_Tabu))));
 end
 if exist('satisfactions_Tabu', 'var')
 fprintf(' - Average satisfaction rate: %.2f%%\n', mean(satisfactions_Tabu(~isnan(satisfactions_Tabu)))*100);
 end
catch ME
 fprintf(' ERROR: %s\n', ME.message);
end

fprintf('\n');

%% Load DQN results
fprintf('[2] Loading DQN results...\n');
try
 load('results/results_DQN.mat', 'results_DQN', 'throughputs_DQN', 'satisfactions_DQN');
 fprintf(' OK DQN results loaded successfully\n');
 
 if exist('throughputs_DQN', 'var')
 fprintf(' - Throughput data: %d runs\n', length(throughputs_DQN));
 fprintf(' - Average throughput: %.2f Mbps\n', mean(throughputs_DQN(~isnan(throughputs_DQN))));
 end
 if exist('satisfactions_DQN', 'var')
 fprintf(' - Average satisfaction rate: %.2f%%\n', mean(satisfactions_DQN(~isnan(satisfactions_DQN)))*100);
 end
catch ME
 fprintf(' ERROR: %s\n', ME.message);
end

fprintf('\n');

%% Generate comparison charts
fprintf('[3] Generating comparison charts...\n');
figure('Position', [100, 100, 1000, 400]);

% Subplot 1: Throughput comparison
subplot(1, 2, 1);
if exist('throughputs_Tabu', 'var') && exist('throughputs_DQN', 'var')
 bar([mean(throughputs_Tabu(~isnan(throughputs_Tabu))), mean(throughputs_DQN(~isnan(throughputs_DQN)))]);
 set(gca, 'XTickLabel', {'Tabu Search', 'DQN'});
 ylabel('Throughput (Mbps)');
 title('Throughput Comparison');
 grid on;
else
 text(0.5, 0.5, 'Data not available', 'HorizontalAlignment', 'center');
end

% Subplot 2: Satisfaction rate comparison
subplot(1, 2, 2);
if exist('satisfactions_Tabu', 'var') && exist('satisfactions_DQN', 'var')
 bar([mean(satisfactions_Tabu(~isnan(satisfactions_Tabu)))*100, mean(satisfactions_DQN(~isnan(satisfactions_DQN)))*100]);
 set(gca, 'XTickLabel', {'Tabu Search', 'DQN'});
 ylabel('Satisfaction Rate (%)');
 title('Satisfaction Rate Comparison');
 grid on;
else
 text(0.5, 0.5, 'Data not available', 'HorizontalAlignment', 'center');
end

fprintf(' OK Charts generated\n\n');

fprintf('========================================\n');
fprintf(' Analysis Complete\n');
fprintf('========================================\n');
fprintf(' analysisexperimentresult\n');
fprintf('========================================\n\n');

%% LoadTabuSearchresult
fprintf('[1] LoadTabuSearchresult...\n');
try
 load('results/results_TabuSearch.mat', 'results_Tabu', 'throughputs_Tabu', 'satisfactions_Tabu');
 fprintf(' OK TabuSearchresultLoad\n');
 
 if exist('throughputs_Tabu', 'var')
 fprintf(' - throughputdata: %d \n', length(throughputs_Tabu));
 fprintf(' - throughput: %.2f Mbps\n', mean(throughputs_Tabu(~isnan(throughputs_Tabu))));
 end
 if exist('satisfactions_Tabu', 'var')
 fprintf(' - satisfaction rate: %.2f%%\n', mean(satisfactions_Tabu(~isnan(satisfactions_Tabu)))*100);
 end
catch ME
 fprintf(' ERROR: %s\n', ME.message);
end

fprintf('\n');

%% LoadDQNresult
fprintf('[2] LoadDQNresult...\n');
try
 load('results/results_DQN.mat', 'results_DQN', 'throughputs_DQN', 'satisfactions_DQN');
 fprintf(' OK DQNresultLoad\n');
 
 if exist('throughputs_DQN', 'var')
 fprintf(' - throughputdata: %d \n', length(throughputs_DQN));
 fprintf(' - throughput: %.2f Mbps\n', mean(throughputs_DQN(~isnan(throughputs_DQN))));
 end
 if exist('satisfactions_DQN', 'var')
 fprintf(' - satisfaction rate: %.2f%%\n', mean(satisfactions_DQN(~isnan(satisfactions_DQN)))*100);
 end
catch ME
 fprintf(' ERROR: %s\n', ME.message);
end

fprintf('\n');

%% LoadDataObjresult
fprintf('[3] LoadDataObjresult...\n');
try
 load('DataObj.mat', 'DataObj');
 fprintf(' OK DataObjLoad\n');
 
 % analysisDataObj
 if isfield(DataObj, 'InterfFromAll_Down')
 [num_methods, num_slots, num_users, ~] = size(DataObj.InterfFromAll_Down);
 fprintf(' - : %d\n', num_methods);
 fprintf(' - time slot: %d\n', num_slots);
 fprintf(' - user: %d\n', num_users);
 
 % Calculate
 sinr_data = squeeze(DataObj.InterfFromAll_Down(:, :, :, 2));
 avg_sinr = mean(sinr_data(:), 'omitnan');
 fprintf(' - SINR: %.2f dB\n', avg_sinr);
 end
 
 if isfield(DataObj, 'UsrsTraffic') && isfield(DataObj, 'UsrsTransPort')
 % Calculatetrafficsatisfaction rate
 demand = DataObj.UsrsTraffic(:, 1) + sum(DataObj.UsrsTraffic(:, 2:end), 2);
 transport = squeeze(sum(DataObj.UsrsTransPort, 3));
 
 if ~isempty(transport)
 satisfaction = mean(transport ./ demand', 'omitnan');
 fprintf(' - trafficsatisfaction rate: %.2f%%\n', satisfaction * 100);
 end
 end
 
catch ME
 fprintf(' ERROR: %s\n', ME.message);
end

fprintf('\n');

fprintf('[4] Generate...\n');

figure('Position', [100, 100, 1200, 400]);

subplot(1, 2, 1);
if exist('throughputs_Tabu', 'var') && exist('throughputs_DQN', 'var')
 bar_data = [mean(throughputs_Tabu(~isnan(throughputs_Tabu))), ...
 mean(throughputs_DQN(~isnan(throughputs_DQN)))];
 bar(bar_data);
 set(gca, 'XTickLabel', {'Tabu Search', 'DQN'});
 ylabel('throughput (Mbps)');
 title('throughput');
 grid on;
 
 % Add
 text(1, bar_data(1)*1.02, sprintf('%.2f', bar_data(1)), 'HorizontalAlignment', 'center');
 text(2, bar_data(2)*1.02, sprintf('%.2f', bar_data(2)), 'HorizontalAlignment', 'center');
else
 text(0.5, 0.5, 'data', 'HorizontalAlignment', 'center');
end

subplot(1, 2, 2);
if exist('satisfactions_Tabu', 'var') && exist('satisfactions_DQN', 'var')
 bar_data = [mean(satisfactions_Tabu(~isnan(satisfactions_Tabu)))*100, ...
 mean(satisfactions_DQN(~isnan(satisfactions_DQN)))*100];
 bar(bar_data, 'FaceColor', [0.8, 0.4, 0.4]);
 set(gca, 'XTickLabel', {'Tabu Search', 'DQN'});
 ylabel('servicesatisfaction rate (%)');
 title('servicesatisfaction rate');
 grid on;
 
 text(1, bar_data(1)*1.02, sprintf('%.2f%%', bar_data(1)), 'HorizontalAlignment', 'center');
 text(2, bar_data(2)*1.02, sprintf('%.2f%%', bar_data(2)), 'HorizontalAlignment', 'center');
else
 text(0.5, 0.5, 'data', 'HorizontalAlignment', 'center');
end

% Save
saveas(gcf, 'results/existing_results_comparison.png');
fprintf(' OK Save: results/existing_results_comparison.png\n');

fprintf('\n========================================\n');
fprintf(' analysis！\n');
fprintf('========================================\n\n');
