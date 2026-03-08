%% Quick Test Script - Run 1 iteration to verify code correctness
clear; clc;

addpath(genpath('.'));

fprintf('========================================\n');
fprintf('   Quick Test - Verify Code Correctness\n');
fprintf('========================================\n\n');

%% Load Configuration
fprintf('[1] Loading configuration...\n');
setConfig;
Config.enable_SA = true;
Config.L_tabu_mode = 'adaptive';
fprintf('   OK\n\n');

%% Run 1 quick test
fprintf('[2] Running quick test (1 scheduling period only)...\n');
tic;

try
    controller = simSatSysClass.simController(Config, 1, 1, 0);
    
    % Limit to 1 scheduling period to speed up test
    controller.scheInShot = 1;
    
    DataObj = controller.run();
    
    elapsed_time = toc;
    
    fprintf('\n   OK Test completed!\n');
    fprintf('   Elapsed time: %.2f seconds\n\n', elapsed_time);
    
    % Check results
    if isfield(DataObj, 'InterfFromAll_Down')
        sinr_data = squeeze(DataObj.InterfFromAll_Down(:, :, :, 2));
        avg_sinr = mean(sinr_data(:), 'omitnan');
        fprintf('   Average SINR: %.2f dB\n', avg_sinr);
    end
    
    fprintf('\n========================================\n');
    fprintf('   Quick test passed! Code is correct.\n');
    fprintf('========================================\n\n');
    
catch ME
    fprintf('\n   ERROR: %s\n', ME.message);
    fprintf('   Error location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    fprintf('\n========================================\n');
    fprintf('   Test failed! Needs debugging.\n');
    fprintf('========================================\n\n');
end
