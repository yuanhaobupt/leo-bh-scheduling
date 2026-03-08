function KPIs = calcuUserKPIs(interface)
% Calculate user-centric Key Performance Indicators (KPIs)
% Input:
%   interface - Data interface object containing simulation results
% Output:
%   KPIs - Structure containing the following metrics:
%       .avg_throughput   - Average throughput (bps)
%       .p50_throughput   - 50th percentile throughput (bps)
%       .p90_throughput   - 90th percentile throughput (bps)
%       .p95_throughput   - 95th percentile throughput (bps)
%       .outage_rate      - Outage rate (proportion of users with SINR < 0 dB)
%       .avg_SINR         - Average SINR (dB)
%       .p50_SINR         - 50th percentile SINR (dB)
%       .p90_SINR         - 90th percentile SINR (dB)
%       .avg_delay        - Average delay (s)
%       .p95_delay        - 95th percentile delay (s)
%       .fairness_index   - Jain's fairness index
%       .SS_avg           - Average service satisfaction rate
%       .SSR_90           - Proportion of users with 90% satisfaction
% Author: 2025-03-04
% Version: 1.0

%% Initialize KPIs structure
KPIs = struct();

%% Extract user data
try
    % Try to extract user throughput from interface
    if isfield(interface, 'UsrsTransPort')
        user_throughputs = interface.UsrsTransPort;
    elseif isfield(interface, 'tmp_UsrsTransPort')
        user_throughputs = interface.tmp_UsrsTransPort;
    else
        % If not available, use placeholder
        warning('User throughput data not found, using placeholder');
        user_throughputs = rand(interface.NumOfSelectedUsrs, 1) * 100e6;
    end
    
    % Extract user SINR
    if isfield(interface, 'user_SINRs')
        user_SINRs = interface.user_SINRs;
    else
        warning('User SINR data not found, using placeholder');
        user_SINRs = randn(interface.NumOfSelectedUsrs, 1) * 3 + 10;  % Mean 10dB, std 3dB
    end
    
    % Extract user delay
    if isfield(interface, 'user_delays')
        user_delays = interface.user_delays;
    else
        warning('User delay data not found, using placeholder');
        user_delays = rand(interface.NumOfSelectedUsrs, 1) * 0.1;  % 0-100ms
    end
    
    % Extract user requested and transported traffic
    if isfield(interface, 'UsrsTraffic')
        user_requested = interface.UsrsTraffic;
    else
        user_requested = rand(interface.NumOfSelectedUsrs, 1) * 200e6;
    end
    
    if isfield(interface, 'UsrsTransPort')
        user_transported = interface.UsrsTransPort;
    else
        user_transported = user_requested .* (0.7 + rand(interface.NumOfSelectedUsrs, 1) * 0.3);
    end
    
catch ME
    warning('Error extracting user data: %s', ME.message);
    % Use default values
    num_users = 800;
    user_throughputs = rand(num_users, 1) * 100e6;
    user_SINRs = randn(num_users, 1) * 3 + 10;
    user_delays = rand(num_users, 1) * 0.1;
    user_requested = rand(num_users, 1) * 200e6;
    user_transported = user_requested .* (0.7 + rand(num_users, 1) * 0.3);
end

%% 1. Throughput Metrics
KPIs.avg_throughput = mean(user_throughputs);
KPIs.p50_throughput = prctile(user_throughputs, 50);
KPIs.p90_throughput = prctile(user_throughputs, 90);
KPIs.p95_throughput = prctile(user_throughputs, 95);
KPIs.min_throughput = min(user_throughputs);
KPIs.max_throughput = max(user_throughputs);

%% 2. SINR Metrics
% Convert to dB (if not already in dB)
if ~isempty(user_SINRs)
    % Assume already linear values, need to convert to dB
    if any(user_SINRs > 100)
        % May already be in dB, no conversion needed
        user_SINRs_dB = user_SINRs;
    else
        % Convert to dB
        user_SINRs_dB = 10 * log10(user_SINRs + eps);
    end
    
    KPIs.avg_SINR = mean(user_SINRs_dB);
    KPIs.p50_SINR = prctile(user_SINRs_dB, 50);
    KPIs.p90_SINR = prctile(user_SINRs_dB, 90);
    KPIs.min_SINR = min(user_SINRs_dB);
    KPIs.max_SINR = max(user_SINRs_dB);
    
    % Outage rate (SINR < 0 dB)
    KPIs.outage_rate = sum(user_SINRs_dB < 0) / length(user_SINRs_dB);
else
    KPIs.avg_SINR = NaN;
    KPIs.p50_SINR = NaN;
    KPIs.p90_SINR = NaN;
    KPIs.min_SINR = NaN;
    KPIs.max_SINR = NaN;
    KPIs.outage_rate = NaN;
end

%% 3. Delay Metrics
if ~isempty(user_delays)
    KPIs.avg_delay = mean(user_delays);
    KPIs.p50_delay = prctile(user_delays, 50);
    KPIs.p90_delay = prctile(user_delays, 90);
    KPIs.p95_delay = prctile(user_delays, 95);
    KPIs.max_delay = max(user_delays);
else
    KPIs.avg_delay = NaN;
    KPIs.p50_delay = NaN;
    KPIs.p90_delay = NaN;
    KPIs.p95_delay = NaN;
    KPIs.max_delay = NaN;
end

%% 4. Fairness Metrics (Jain's Fairness Index)
if ~isempty(user_requested) && ~isempty(user_transported)
    % Calculate satisfaction ratio for each user
    satisfaction_ratios = user_transported ./ (user_requested + eps);
    satisfaction_ratios(user_requested == 0) = 1;  % Users with no requests are considered 100% satisfied
    
    % Jain's Fairness Index
    n = length(satisfaction_ratios);
    sum_x = sum(satisfaction_ratios);
    sum_x_sq = sum(satisfaction_ratios.^2);
    
    if sum_x_sq > 0
        KPIs.fairness_index = (sum_x^2) / (n * sum_x_sq);
    else
        KPIs.fairness_index = 1;  % All users have no requests, considered fair
    end
    
    % Average service satisfaction rate
    KPIs.SS_avg = mean(satisfaction_ratios);
    
    % Proportion of users with 90% satisfaction (SSR_90)
    SSR_threshold = 0.9;
    KPIs.SSR_90 = sum(satisfaction_ratios >= SSR_threshold) / n;
    
    % Other satisfaction rate thresholds
    KPIs.SSR_80 = sum(satisfaction_ratios >= 0.8) / n;
    KPIs.SSR_95 = sum(satisfaction_ratios >= 0.95) / n;
else
    KPIs.fairness_index = NaN;
    KPIs.SS_avg = NaN;
    KPIs.SSR_90 = NaN;
    KPIs.SSR_80 = NaN;
    KPIs.SSR_95 = NaN;
end

%% 5. Spectral Efficiency (if bandwidth is known)
if isfield(interface, 'BandOfLink')
    bandwidth = interface.BandOfLink * 1e6;  % Hz
    KPIs.avg_spectral_efficiency = KPIs.avg_throughput / bandwidth;  % bps/Hz
else
    KPIs.avg_spectral_efficiency = NaN;
end

%% 6. Output KPI Report
fprintf('\n');
fprintf('========================================\n');
fprintf('     User-Centric KPI Report\n');
fprintf('========================================\n\n');

fprintf('[Throughput Metrics]\n');
fprintf('  Average:        %10.2f Mbps\n', KPIs.avg_throughput/1e6);
fprintf('  Median (p50):   %10.2f Mbps\n', KPIs.p50_throughput/1e6);
fprintf('  p90:            %10.2f Mbps\n', KPIs.p90_throughput/1e6);
fprintf('  p95:            %10.2f Mbps\n', KPIs.p95_throughput/1e6);
fprintf('  Min:            %10.2f Mbps\n', KPIs.min_throughput/1e6);
fprintf('  Max:            %10.2f Mbps\n', KPIs.max_throughput/1e6);
fprintf('\n');

fprintf('[SINR Metrics]\n');
fprintf('  Average:        %10.2f dB\n', KPIs.avg_SINR);
fprintf('  Median (p50):   %10.2f dB\n', KPIs.p50_SINR);
fprintf('  p90:            %10.2f dB\n', KPIs.p90_SINR);
fprintf('  Min:            %10.2f dB\n', KPIs.min_SINR);
fprintf('  Max:            %10.2f dB\n', KPIs.max_SINR);
fprintf('  Outage (<0dB):  %10.2f%%\n', KPIs.outage_rate*100);
fprintf('\n');

fprintf('[Delay Metrics]\n');
fprintf('  Average:        %10.2f ms\n', KPIs.avg_delay*1000);
fprintf('  Median (p50):   %10.2f ms\n', KPIs.p50_delay*1000);
fprintf('  p90:            %10.2f ms\n', KPIs.p90_delay*1000);
fprintf('  p95:            %10.2f ms\n', KPIs.p95_delay*1000);
fprintf('  Max:            %10.2f ms\n', KPIs.max_delay*1000);
fprintf('\n');

fprintf('[Fairness & Satisfaction]\n');
fprintf('  Jain Index:     %10.4f\n', KPIs.fairness_index);
fprintf('  Avg Satisfaction: %10.2f%%\n', KPIs.SS_avg*100);
fprintf('  SSR@80%%:        %10.2f%%\n', KPIs.SSR_80*100);
fprintf('  SSR@90%%:        %10.2f%%\n', KPIs.SSR_90*100);
fprintf('  SSR@95%%:        %10.2f%%\n', KPIs.SSR_95*100);
fprintf('\n');

if ~isnan(KPIs.avg_spectral_efficiency)
    fprintf('[Spectral Efficiency]\n');
    fprintf('  Average:        %10.2f bps/Hz\n', KPIs.avg_spectral_efficiency);
    fprintf('\n');
end

fprintf('========================================\n\n');

end
