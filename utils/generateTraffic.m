function traffic = generateTraffic(num_users, total_demand, mode, params)
% Generate traffic demands with different distribution patterns
% Input parameters:
%   num_users    - Number of users
%   total_demand - Total demand
%   mode         - Distribution pattern: 'uniform', 'light_skew', 'heavy_skew', 'pareto'
%   params       - Parameter struct:
%                  .skew_factor - Skew factor (for light/heavy skew)
%                  .alpha       - Pareto distribution parameter
% Output:
%   traffic - Traffic demand vector [num_users × 1]
% Author: 2026-03-04

%% Default parameters
if nargin < 4 || isempty(params)
    params = struct();
end

if ~isfield(params, 'skew_factor')
    params.skew_factor = 2;
end

if ~isfield(params, 'alpha')
    params.alpha = 1.5;
end

%% Generate traffic based on mode
switch lower(mode)
    case 'uniform'
        % Uniform distribution: all users have the same demand
        traffic = (total_demand / num_users) * ones(num_users, 1);
        
    case 'light_skew'
        % Light skew: use log-normal distribution
        skew = params.skew_factor;
        mu = log(total_demand / num_users) - 0.5 * log(1 + skew^2);
        sigma = sqrt(log(1 + skew^2));
        traffic = lognrnd(mu, sigma, num_users, 1);
        % Normalize to total demand
        traffic = traffic * (total_demand / sum(traffic));
        
    case 'heavy_skew'
        % Heavy skew: use more skewed log-normal distribution
        skew = params.skew_factor;
        mu = log(total_demand / num_users) - 0.5 * log(1 + skew^2);
        sigma = sqrt(log(1 + skew^2)) * 1.5;  % Increase variance
        traffic = lognrnd(mu, sigma, num_users, 1);
        % Normalize to total demand
        traffic = traffic * (total_demand / sum(traffic));
        
    case 'pareto'
        % Pareto distribution (80/20 rule)
        alpha = params.alpha;
        xm = total_demand / num_users * (alpha - 1) / alpha;  % Scale parameter
        traffic = (rand(num_users, 1) .^ (-1/alpha) - 1) * xm;
        % Normalize to total demand
        traffic = traffic * (total_demand / sum(traffic));
        
    otherwise
        warning('Unknown traffic pattern: %s, using uniform distribution', mode);
        traffic = (total_demand / num_users) * ones(num_users, 1);
end

%% Ensure all traffic values are positive
traffic = max(traffic, eps);

%% Print statistics
fprintf('Traffic generation [%s mode]:\n', upper(mode));
fprintf('  - Number of users: %d\n', num_users);
fprintf('  - Total demand: %.2f Mbps\n', total_demand/1e6);
fprintf('  - Average demand: %.2f Mbps\n', mean(traffic)/1e6);
fprintf('  - Minimum demand: %.2f Mbps\n', min(traffic)/1e6);
fprintf('  - Maximum demand: %.2f Mbps\n', max(traffic)/1e6);
fprintf('  - Standard deviation: %.2f Mbps\n', std(traffic)/1e6);
fprintf('  - Coefficient of variation: %.2f\n', std(traffic)/mean(traffic));

% For Pareto distribution, check 80/20 rule
if strcmpi(mode, 'pareto')
    sorted_traffic = sort(traffic, 'descend');
    top20_sum = sum(sorted_traffic(1:round(num_users*0.2)));
    total_sum = sum(sorted_traffic);
    ratio_80_20 = top20_sum / total_sum;
    fprintf('  - 80/20 ratio: %.2f%% (top 20%% users account for %.2f%% of total demand)\n', ...
        ratio_80_20*100, ratio_80_20*100);
end
fprintf('\n');

end
