% 2023/03/07 stepOfSimuMove
% Test parameter configuration for simulation platform
%% Platform Parameters
durationOfTotalSimu = 1;   % (s) Total simulation duration
                            % Note: This value should not be less than stepOfSimuMove

stepOfSimuMove = 1;    % (s) Time interval for satellite constellation spatial state changes
                        % Note: This value should not be less than durationOfSimuStep

durationOfSimuStep = 40e-3;     % (s) Beam simulation duration under a specific satellite constellation state
                                % Note: This value should not be greater than stepOfSimuMove

rangeOfInves = [102, 108; ...  
                 26, 30];   % [longitude, longitude; latitude, latitude]
                            % User distribution investigation area
                            % Note: North latitude and east longitude are positive, south latitude and west longitude are negative. Longitude range is for the high-latitude edge

factorOfDiscr = 110;    % Area discretization factor
                        % Description: The investigation area is divided into many small triangles. This factor indicates how many rows of triangles can be divided per degree of latitude.

layerOfinterf = 1;      % Interference calculation factor
                        % Description: Number of adjacent satellite layers to consider when calculating inter-satellite interference

numOfMonteCarlo = 0;    % Number of Monte Carlo runs

ifAscendUp = 1;         % 1: Platform investigates northward-moving satellites
                        % 2: Platform investigates southward-moving satellites
                        
ifWrapAround = 0;       % Whether to consider simulation boundary effects (enable wrap-around)

WrapAroundLayer = 0;    % Number of wrap-around satellite layers (can only be 0 or 1)

WrapExtendValue = 6;   % Extended latitude/longitude degrees for wrap-around area


%% Scheduling Parameters
BhDispCycle = 40e-3;    % (s) Beam-hopping scheduling cycle length
                        % Note: This value should not be greater than durationOfSimuStep, and should preferably be an integer multiple of BhDispCycle

SubCarrierSpace = 30e3;  % (Hz) Subcarrier spacing
% SubCarrierSpace = 120e3;  % (Hz) Subcarrier spacing
                         % Description: This parameter affects slot length and bandwidth-to-PRB mapping

% maxUsrPerBeam = 1;      % Maximum number of users per traffic beam

ifFixedUsrsNum = true;  % Whether to fix the number of users
                        % Description: If fixed, generate a fixed number and position of users in the investigation area; if not fixed, regenerate users using SPPP every few spatial states

meanUsrsNum = 800;  % Average number of users in the investigation area
                    % Description: When using fixed distribution, this is the number of users; when using variable distribution, this is the mean of the Poisson process

intervalStep = 10;      % Regenerate users every intervalStep satellite spatial state updates

%-------New Parameters--------%
activePercent = 1;   % User activation rate

ifAdjustBHST = 0; % Whether to perform inter-satellite interference suppression

%% Satellite Parameters
heightOfSat = 508e3;    % (m) Constellation altitude

numOfServbeam = 10;     % Maximum number of traffic beams

Pt_dBm_serv = 10*log10(300e3);      % (dBm) Total transmit power for traffic beams

rangeOfbeam = [45*pi/180, 33*pi/180];  % Beam scanning range

% angleOfbeam = 6;% Beam opening angle

% IsoAgl_Serv = 3*pi/180; % Traffic beam isolation angle

numOfSigbeam = 0;       % Number of signaling beams

% ScheOfSig = 20e-3;     % Signaling beam scanning period

% LightTimeOfSig = 1e-3;   % Signaling beam illumination duration

Pt_dBm_signal = 10*log10(50e3);     % (dBm) Total transmit power for signaling beams

% SpaceOfSigbeam = 40e3;  % Spacing of square signaling beam area

% IsoAgl_Sig = 11*pi/180; % Signaling beam isolation angle
% IsoAgl_ServAndSig = 10*pi/180; % Isolation angle between traffic and signaling beams


%% Communication Conditions
% BandOfLink = 40e6; % (Hz) Carrier bandwidth

% freqOfDownLink = 3620e6; % (Hz) Downlink center frequency of satellite
% freqOfDownLink_ascend_DOWN = 3660e6; % (Hz) Downlink center frequency of southward-moving satellite
% freqOfUpLink = 5190e6; % (Hz) Uplink center frequency of satellite
% freqOfUpLink_ascend_DOWN = 5230e6; % (Hz) Uplink center frequency of southward-moving satellite

% Huawei paper frequency band
% BandOfLink = 30e6; % (Hz) Carrier bandwidth
% freqOfDownLink = 2e9; % (Hz) Downlink center frequency of satellite
% freqOfUpLink = 1995e6; % (Hz) Uplink center frequency of satellite

%S-band
BandOfLink = 40e6; % (Hz) Carrier bandwidth
freqOfDownLink = 3620e6; % (Hz) Downlink center frequency of satellite
freqOfUpLink = 1995e6; % (Hz) Uplink center frequency of satellite
%Ka-band
% BandOfLink = 200e6; % (Hz) Carrier bandwidth
% freqOfDownLink = 20e9; % (Hz) Downlink center frequency of satellite
% freqOfUpLink = 30e9; % (Hz) Uplink center frequency of satellite

SAT_T_noise = 0;  % Satellite antenna noise temperature (K)
Usr_T_noise = 150; % User antenna noise temperature (K)
SAT_F_noise = 0;    % Satellite receiver noise figure (dB)
Usr_F_noise = 7;    % User receiver noise figure (dB)

Pt_dBm_Usr = 23;    % User antenna transmit power

%% Scenario Parameters
ifattenuation = 0;% Whether to consider various attenuation models
scenario=0;    %0: Suburban and rural areas
               %1: Urban
               %2: Dense urban

ifSatAndGround = 0;% Whether to consider satellite-ground interference
Pt_dBm_BS = 38;    % Base station antenna transmit power
TerrestrialDuplexing = 1;   % Terrestrial network duplexing mode, 1 is FDD, 0 is TDD
Userdense = 1000;  % Terrestrial user density per square kilometer

% Traffic
diffTrafficUserRatio = [1; 0; 0]; % Proportion of different traffic types among total users,
                                      % diffTrafficUserRatio(1) is FTP user proportion
                                      % diffTrafficUserRatio(2) is video streaming user proportion
                                      % diffTrafficUserRatio(3) is VoIP user proportion

%% Algorithm Configuration (for ablation experiments)
enable_SA = true;         % Whether to enable simulated annealing (SA) mechanism
L_tabu_mode = 'adaptive'; % Tabu tenure mode: 'adaptive' or 'fixed'
fixed_L_tabu = 20;        % Fixed tabu tenure (used only when L_tabu_mode='fixed')

%% Traffic Distribution Configuration (for scenario extension experiments)
traffic_mode = 'uniform';    % Traffic distribution mode: 'uniform', 'light_skew', 'heavy_skew', 'pareto'
traffic_skew_factor = 2;     % Skew factor (for 'light_skew' and 'heavy_skew' modes)
pareto_alpha = 1.5;          % Pareto distribution parameter (for 'pareto' mode, approximately 1.36 for 80/20 rule)

%% Build Configuration Structure
Config = struct( ....
    'ifAdjustBHST', ifAdjustBHST, ...
    'intervalStep', intervalStep, ...
    'activePercent', activePercent, ...
    'ifWrapAround',     ifWrapAround, ...
    'WrapAroundLayer',  WrapAroundLayer, ...
    'WrapExtendValue',  WrapExtendValue, ...
    'height',   heightOfSat, ...
    'step',     stepOfSimuMove, ...
    'duration', durationOfSimuStep, ...
    'time',     durationOfTotalSimu, ...
    'rangeOfInves',     rangeOfInves, ...
    'factorOfDiscr',    factorOfDiscr, ...
    'layerOfinterf',    layerOfinterf, ...
    'numOfMonteCarlo',  numOfMonteCarlo, ...
    'ifFixedUsrsNum',  ifFixedUsrsNum, ...
    'scenario',    scenario,...
    'meanUsrsNum',  meanUsrsNum, ...
    'SCS',      SubCarrierSpace, ...
    'bhTime',   BhDispCycle, ...
    'Pt_dBm_serv',    Pt_dBm_serv, ... ...
    'numOfServbeam',    numOfServbeam, ...
    'Pt_dBm_signal',    Pt_dBm_signal, ...
    'numOfSigbeam',     numOfSigbeam, ...
    'rangeOfBeam',      rangeOfbeam, ...
    'BandOfLink',   BandOfLink, ...
    'ifAscendUp',   ifAscendUp, ...
    'freqOfDownLink',     freqOfDownLink, ...
    'freqOfUpLink',       freqOfUpLink, ...
    'SAT_T_noise',      SAT_T_noise, ...
    'Usr_T_noise',      Usr_T_noise, ...
    'SAT_F_noise',      SAT_F_noise, ...
    'Usr_F_noise',      Usr_F_noise, ...
    'Pt_dBm_Usr',   Pt_dBm_Usr, ...
    'Pt_dBm_BS',   Pt_dBm_BS, ...
    'TerrestrialDuplexing',   TerrestrialDuplexing, ...
    'Userdense',   Userdense, ...
    'diffTrafficUserRatio',   diffTrafficUserRatio, ...
    'ifattenuation', ifattenuation, ...
    'ifSatAndGround', ifSatAndGround, ...
    'enable_SA', enable_SA, ...
    'L_tabu_mode', L_tabu_mode, ...
    'fixed_L_tabu', fixed_L_tabu, ...
    'traffic_mode', traffic_mode, ...
    'traffic_skew_factor', traffic_skew_factor, ...
    'pareto_alpha', pareto_alpha ...
    );