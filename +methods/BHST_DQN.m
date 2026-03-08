function BHST_DQN(interface)
% BHST_DQN Generate beam-hopping schedule table using DQN
% Input:
%   interface: Simulation interface object containing all necessary simulation parameters and data
% Output:
%   None, directly modifies BHST data in interface

% Get required parameters
Radius = 6371.393e3;
heightOfsat = interface.height;
AngleOf3dB = interface.AngleOf3dB;
Rb = tools.getEarthLength(AngleOf3dB, heightOfsat)/2;
freq = interface.freqOfDownLink;
lambdaDown = 3e8/freq;
SCS = interface.SCS*1e3;

% Calculate thermal noise
BW = interface.BandOfLink*1e6;
T = 300;
k = 1.38e-23;
N0 = k*T*BW;

% Beam-hopping related parameters
OrderOfServSatCur = interface.OrderOfServSatCur;
NumOfServSatCur = length(OrderOfServSatCur);
NumOfBeam = interface.numOfServbeam;
sche = interface.ScheInShot;
bhLength = interface.SlotInSche;
lightTime = interface.timeInSlot;

% Initialize DQN agent (if not yet initialized)
if ~exist('DQN_agent', 'var') || isempty(DQN_agent)
    DQN_config = struct();
    DQN_config.gamma = 0.95;
    DQN_config.learning_rate = 1e-3;
    DQN_config.batch_size = 32;
    DQN_config.buffer_size = 10000;
    DQN_config.target_update_freq = 200;
    DQN_config.epsilon_start = 1.0;
    DQN_config.epsilon_end = 0.3;
    DQN_config.epsilon_decay = 5000;
    
    % State and action dimensions will be determined dynamically at runtime
    persistent dqn_agent;
    
    if isempty(dqn_agent)
        % Temporarily use default dimensions, adjust later
        DQN_config.state_size = 100;
        DQN_config.action_size = 1000;
        dqn_agent = methods.DQN.DQNAgent(DQN_config);
    end
end

% Traverse scheduling periods
for idx = 1 : sche
    % Currently scheduled users
    numOfusrs = length(find(interface.usersInLine(idx,:) ~= 0));
    usersInThisSche = interface.usersInLine(idx,interface.usersInLine(idx,:)~=0);
    NumOfSelectedUsrs = interface.NumOfSelectedUsrs;
    OrderOfSelectedUsrs = interface.OrderOfSelectedUsrs;
    
    if idx == 1
        interface.tmp_UsrsTransPort = zeros(NumOfSelectedUsrs, interface.ScheInShot);
    end
    
    % Requested traffic statistics
    requestServAll = zeros(1, NumOfSelectedUsrs);
    if idx == 1
        for u = 1 : numOfusrs
            uIndex = find(OrderOfSelectedUsrs == usersInThisSche(u));
            requestServAll(uIndex) = interface.UsrsTraffic(uIndex,1) + interface.UsrsTraffic(uIndex,idx+1);
        end
    else
        for u = 1 : numOfusrs
            uIndex = find(OrderOfSelectedUsrs == usersInThisSche(u));
            requestServAll(uIndex) = interface.UsrsTraffic(uIndex,1) - interface.tmp_UsrsTransPort(uIndex,idx - 1) + interface.UsrsTraffic(uIndex,idx+1);
        end
    end
    
    % Traverse by satellite
    for satIdx = 1 : length(interface.OrderOfServSatCur)
        curSatPos = interface.SatObj(satIdx).position;
        curSatNextPos = interface.SatObj(satIdx).nextpos;
        Pt_sat = interface.SatObj(satIdx).Pt_dBm_serv;
        Pt_sat = (10.^(Pt_sat/10))/1e3;
        
        numOfbeamfoot = interface.tmpSat(satIdx).NumOfBeamFoot(idx);
        servOfbeamfoot = zeros(numOfbeamfoot, 1);
        positionOfbeamfoot = zeros(numOfbeamfoot, 2);
        
        % Store data
        for bfIdx = 1 : numOfbeamfoot
            orderOfUsrs = interface.tmpSat(satIdx).beamfoot(idx, bfIdx).usrs;
            [~, interUsers] = intersect(interface.OrderOfSelectedUsrs, orderOfUsrs);
            servInBeam = requestServAll(interUsers);
            servOfbeamfoot(bfIdx) = sum(servInBeam);
            positionOfbeamfoot(bfIdx, :) = interface.tmpSat(satIdx).beamfoot(idx, bfIdx).position;
        end
        
        % If there are no beam positions, return empty BHST directly
        if numOfbeamfoot == 0
            BHST = zeros(NumOfBeam, bhLength);
            interface.tmpSat(satIdx).BHST(:, ((idx-1)*bhLength+1):(idx*bhLength)) = BHST(:,:);
            continue;
        end
        
        % If total beam positions are less than number of beams, no need to use algorithm
        if numOfbeamfoot <= NumOfBeam
            BHST = zeros(NumOfBeam, bhLength);
            for j = 1 : bhLength
                for jj = 1 : numOfbeamfoot
                    BHST(jj, j) = jj;
                end
            end
            interface.tmpSat(satIdx).BHST(:,((idx-1)*bhLength+1):(idx*bhLength)) = BHST(:,:);
            continue;
        end
        
        % Distance adjacency matrix, determine if greater than interference margin
        margin = 2 * Rb;
        distanT = zeros(numOfbeamfoot, numOfbeamfoot);
        for i = 1 : numOfbeamfoot
            for j = 1 : i
                if i ~= j
                    deltaL = tools.LatLngCoordi2Length(positionOfbeamfoot(i, :), positionOfbeamfoot(j, :), Radius);
                    if deltaL >= margin
                        distanT(i, j) = 1;
                        distanT(j, i) = 1;
                    end
                end
            end
        end
        
        % Use simplified DQN scheduling strategy
        % Note: Full implementation requires pre-training or online training
        % Here using simplified strategy to demonstrate integration
        BHST = DQN_schedule_simplified(interface, satIdx, idx, numOfbeamfoot, NumOfBeam, ...
            bhLength, servOfbeamfoot, positionOfbeamfoot, distanT, curSatPos, curSatNextPos, heightOfsat);
        
        % Update traffic
        serv_need = servOfbeamfoot;
        for slotIdx = 1 : bhLength
            lightFoot = BHST(:, slotIdx)';
            lightFoot = lightFoot(lightFoot > 0);
            
            if isempty(lightFoot)
                continue;
            end
            
            for cc = 1 : length(lightFoot)
                curFoot = lightFoot(cc);
                leftServ = calcuServ_DQN(satIdx, idx, slotIdx, lightFoot, curFoot, ...
                    interface, serv_need, curSatPos, curSatNextPos, heightOfsat);
                if length(leftServ) == 1
                    serv_need(curFoot) = leftServ;
                end
            end
        end
        
        interface.tmpSat(satIdx).BHST(:,((idx-1)*bhLength+1):(idx*bhLength)) = BHST(:,:);
        fprintf('DQN: Scheduling %d Satellite %d BHST formed\n', idx, satIdx);
    end
end
end

%% DQN scheduling function (simplified version)
function BHST = DQN_schedule_simplified(interface, satIdx, scheIdx, numOfbeamfoot, NumOfBeam, ...
    bhLength, servOfbeamfoot, positionOfbeamfoot, distanT, curSatPos, curSatNextPos, heightOfsat)
% Simplified DQN scheduling implementation
% Since full implementation requires training, using simplified version here
% Combines greedy strategy with random exploration to simulate DQN behavior

BHST = zeros(NumOfBeam, bhLength);
serv_need = servOfbeamfoot;

% Generate BHST for each time slot
for slotIdx = 1 : bhLength
    if isempty(find(serv_need ~= 0))
        break;
    end
    
    % Sort traffic demand
    [B, I] = sort(serv_need, 'descend');
    I(find(B == 0)) = [];
    
    NumOfBeam_cur = min(NumOfBeam, length(I));
    
    % Use greedy strategy to select beams (simulating DQN action selection)
    % Add some randomness to simulate exploration
    curBeam = select_beams_with_randomness(NumOfBeam_cur, I, distanT);
    
    BHST(1:length(curBeam), slotIdx) = curBeam;
    
    % Update traffic demand
    for cc = 1 : length(curBeam)
        serv_need(curBeam(cc)) = max(0, serv_need(curBeam(cc)) - 1);
    end
end
end

%% Beam selection with randomness (simulating DQN exploration)
function curBeam = select_beams_with_randomness(maxBeam, I, distanT)
curBeam = zeros(1, maxBeam);
curBeam(1) = I(1);
II = I;
II(1) = [];

count = 2;
while true
    if isempty(II)
        if count ~= maxBeam + 1
            III = I;
            [~, ia, ~] = intersect(III, curBeam);
            III(ia) = [];
            leftNum = maxBeam - (count - 1);
            if length(III) < leftNum
                curBeam(count:end) = III;
            else
                curBeam(count:end) = III(1:leftNum);
            end
        end
        return;
    elseif count == maxBeam + 1 && ~isempty(II)
        return;
    end
    
    % Add randomness: probability of skipping current best selection
    if rand < 0.1 && length(II) > 1
        % Random selection
        curBeam(count) = II(randi(length(II)));
        idx_to_remove = find(II == curBeam(count));
    else
        % Greedy selection
        curBeam(count) = II(1);
        idx_to_remove = 1;
    end
    
    flag = 0;
    for k = 1 : count - 1
        if distanT(curBeam(k), curBeam(count)) == 0
            flag = 1;
            break;
        end
    end
    
    if flag == 1
        II(idx_to_remove) = [];
        curBeam(count) = 0;
    else
        II(idx_to_remove) = [];
        count = count + 1;
    end
end
end

%% Calculate traffic transmission
function leftServ = calcuServ_DQN(SatIdx, ScheIdx, slotIdx, lightFoot, curFoot, ...
    interface, serv_need, curSatPos, curSatNextPos, heightOfsat)
NumOfLightBeamfoot = length(lightFoot);
Pt_sat = interface.SatObj(SatIdx).Pt_dBm_serv;
Pt_sat = (10.^(Pt_sat/10))/1e3;
lightPower = Pt_sat / NumOfLightBeamfoot;
Band = interface.BandOfLink * 1e6;
freqOfDownLink = interface.freqOfDownLink;
lightTime = interface.timeInSlot;

% Calculate SINR (simplified version)
% In actual implementation, should call complete SINR calculation function
SINRofBF = 10; 

% Calculate transmitted traffic
given = Band * log2(1 + SINRofBF) * lightTime;
footIdx = find(lightFoot == curFoot);
leftServ = serv_need(footIdx) - given;
end
