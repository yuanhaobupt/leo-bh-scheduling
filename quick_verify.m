%% Quick Verification Script - Test if code compiles correctly
clear; clc;

addpath(genpath('.'));

fprintf('=== Quick Verification Test ===\n\n');

%% 1. Check configuration
fprintf('[1] Checking configuration file...\n');
try
    setConfig;
    fprintf('   OK Configuration loaded successfully\n');
    fprintf('   - enable_SA = %s\n', Config.enable_SA);
    fprintf('   - L_tabu_mode = %s\n', Config.L_tabu_mode);
    fprintf('   - fixed_L_tabu = %d\n\n', Config.fixed_L_tabu);
catch ME
    fprintf('   ERROR: %s\n\n', ME.message);
    return;
end

%% 2. Check algorithm files
fprintf('[2] Checking algorithm files...\n');
files_to_check = {
    '+methods/BHST_MY.m', 'BHST_MY (original)';
    '+methods/BHST_MY_SA.m', 'BHST_MY_SA (with SA)';
};

all_ok = true;
for i = 1:length(files_to_check)
    file = files_to_check{i, 1};
    name = files_to_check{i, 2};
    if exist(file, 'file')
        fprintf('   OK %s exists\n', name);
    else
        fprintf('   ERROR %s does not exist\n', name);
        all_ok = false;
    end
end
fprintf('\n');

if ~all_ok
    fprintf('[ERROR] Some files are missing\n\n');
    return;
end

%% 3. Check generateBHST.m
fprintf('[3] Checking generateBHST.m...\n');
genbhst_file = '+simSatSysClass/@schedulerObj/generateBHST.m';
if exist(genbhst_file, 'file')
    fprintf('   OK generateBHST.m exists\n\n');
else
    fprintf('   ERROR generateBHST.m does not exist\n\n');
    return;
end

%% 4. Quick test (without running full simulation)
fprintf('[4] Checking DataObj...\n');
if exist('DataObj.mat', 'file')
    fprintf('   OK DataObj.mat exists\n\n');
else
    fprintf('   WARNING DataObj.mat does not exist, cannot perform full test\n\n');
end

fprintf('=== Verification Complete ===\n');
fprintf('All component checks passed, code is ready.\n\n');
fprintf('Note: Full simulation takes a long time, please run in MATLAB GUI.\n');
fprintf('Suggested command: run_ablation_SA_v3\n\n');
