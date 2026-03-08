% Greedy without isolation
function BHST_greedyAndDist(interface)
% Get required parameters
Radius = 6371.393e3; % Earth radius
heightOfsat = interface.height;% Satellite orbit height
AngleOf3dB = interface.AngleOf3dB;% Antenna 3dB beamwidth
Rb = tools.getEarthLength(AngleOf3dB, heightOfsat)/2;% Beam position radius
freq = interface.freqOfDownLink;% Downlink center frequency
lambdaDown = 3e8/freq;% Wavelength
SCS = interface.SCS*1e3;% Subcarrier spacing, unit is Hz

% Calculate thermal noise
BW = interface.BandOfLink*1e6; % Bandwidth, unit is Hz
T = 300;% Kelvin temperature, unit is K
k = 1.38e-23;% Boltzmann constant
N0 = k*T*BW;% Noise

% User receiving gain
type = 0;

% Parameters about beam hopping
OrderOfServSatCur = interface.OrderOfServSatCur;    % List of serving satellites
NumOfServSatCur = length(OrderOfServSatCur);    % Number of serving satellites
NumOfBeam = interface.numOfServbeam; % Number of simultaneously operating beams
sche = interface.ScheInShot; % Total number of schedulings
Num_scheme = interface.ScheInShot;  % Number of scheduling periods per snapshot
bhLength = interface.SlotInSche; % Length of one beam hopping scheduling
lightTime = interface.timeInSlot;% Beam illumination time (slot duration), unit is s

%% Traverse by scheduling period
for idx = 1 : sche
% Current scheduled users
numOfusrs = length(find(interface.usersInLine(idx,:) ~= 0));
usersInThisSche = interface.usersInLine(idx,interface.usersInLine(idx,:)~=0);
% Total users
NumOfSelectedUsrs = interface.NumOfSelectedUsrs;
OrderOfSelectedUsrs = interface.OrderOfSelectedUsrs;

if idx == 1
    interface.tmp_UsrsTransPort = zeros(NumOfSelectedUsrs, interface.ScheInShot);% Need to update at the end
end

TransportedTraffic = zeros(interface.NumOfSelectedUsrs, 1);   % List of transported traffic
%% Requested traffic statistics
requestServAll = zeros(1, NumOfSelectedUsrs);% Store all user requested traffic (users not yet connected may not have traffic requests recorded)
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


    %% Traverse by satellite
    for satIdx = 1 : length(interface.OrderOfServSatCur)
        curSatPos = interface.SatObj(satIdx).position;
        curSatNextPos = interface.SatObj(satIdx).nextpos;
        % Calculate satellite total power
        Pt_sat = interface.SatObj(satIdx).Pt_dBm_serv; % Total transmit power of satellite antenna
        Pt_sat = (10.^(Pt_sat/10))/1e3; % Unit is W

        numOfbeamfoot = interface.tmpSat(satIdx).NumOfBeamFoot(idx);% Total number of beam positions
        servOfbeamfoot = zeros(numOfbeamfoot, 1); % Requested traffic for each beam position under satellite
%         userInBeam = zeros(numOfbeamfoot,maxUsrPerBeam);% Store user indices within each beam position
        positionOfbeamfoot = zeros(numOfbeamfoot, 2); % Longitude/latitude coordinates of each beam position center

        % Store data
        for bfIdx = 1 : numOfbeamfoot
            orderOfUsrs = interface.tmpSat(satIdx).beamfoot(idx, bfIdx).usrs;
%             userInBeam(bfIdx,1:length(orderOfUsrs)) = orderOfUsrs;
            
            [~, interUsers] = intersect(interface.OrderOfSelectedUsrs, orderOfUsrs);
            servInBeam = requestServAll(interUsers);
%             servInBeam = requestServAll(interface.OrderOfSelectedUsrs==orderOfUsrs);
            servOfbeamfoot(bfIdx) = sum(servInBeam);
            positionOfbeamfoot(bfIdx, :) = interface.tmpSat(satIdx).beamfoot(idx, bfIdx).position;% Get beam position center coordinates
        end

        % If there are no beam positions, return empty BHST directly
        if numOfbeamfoot == 0
            BHST = zeros(NumOfBeam, bhLength);
            interface.tmpSat(satIdx).BHST(:, ((idx-1)*bhLength+1):(idx*bhLength)) = BHST(:,:);           
            continue;
        end

%         maxBeam = min(NumOfBeam,numOfbeamfoot);% If satellite service area is small, total beam positions may be less than simultaneous active beams
        % If total beam positions are less than number of beams, no need to use algorithm
        if numOfbeamfoot <= NumOfBeam 
            BHST = zeros(NumOfBeam, bhLength);% Store beam-hopping schedule table
            for j = 1 : bhLength
                for jj = 1 : numOfbeamfoot
                    BHST(jj, j) = jj;
                end
            end
            continue;
        end

        % Distance adjacency matrix, determine if greater than interference margin
        margin = 2 * Rb; % Separation greater than 1 beam position diameter (as in paper)
        distanT = zeros(numOfbeamfoot, numOfbeamfoot);
        for i = 1 : numOfbeamfoot
            for j = 1 : i
                if i ~= j
                    deltaL = tools.LatLngCoordi2Length(positionOfbeamfoot(i, :), positionOfbeamfoot(j, :), Radius);
                    if deltaL >= margin  % If greater than isolation distance, store this distance, otherwise 0
    %                     distanT(i, j) = deltaL;
    %                     distanT(j, i) = deltaL;
                        distanT(i, j) = 1;
                        distanT(j, i) = 1;
                    end
    %             else
    %                 distanT(i, j) = 0;% Same position also set to 0
                end
            end
        end        

        % Need to use algorithm
        BHST = zeros(NumOfBeam, bhLength);% Store beam-hopping schedule table
        serv_need = servOfbeamfoot;% Store needed traffic again for subtraction
        %% Start BHST
        for slotIdx = 1 : bhLength% Traverse each time slot
            scheIdx = idx;
            if isempty(find(serv_need ~= 0))% If all allocations are complete, end
                break;
            end
            % Sort traffic demand for each time slot
            [B,I] = sort(serv_need,'descend');
            I(find(B==0)) = [];% Prevent negative remaining traffic
            NumOfBeam = min(NumOfBeam,length(I));
            lightPower = Pt_sat / NumOfBeam;
    
            curBeam = judgeBeam(NumOfBeam,I,distanT);
            BHST(1:NumOfBeam,slotIdx) = curBeam.';
            % Update traffic
%             P = Pt_sat/NumOfBeam;% Power allocated to each beam position (equal distribution)
            for cc = 1 : NumOfBeam
                curFoot = curBeam(cc);
                leftServ = calcuServ(satIdx, scheIdx, slotIdx, curBeam, curFoot, interface, serv_need, curSatPos, curSatNextPos, heightOfsat);
                serv_need(curFoot) = leftServ;
            end  
            fprintf('Satellite %d BHST formed %.1f%%\n',satIdx,slotIdx * 100 /bhLength);
        end
            %% Data storage below
%         tmpBHST = zeros();
        interface.tmpSat(satIdx).BHST(:,((idx-1)*bhLength+1):(idx*bhLength)) = BHST(:,:);
        fprintf('Scheduling %d Satellite %d BHST formed\n', idx, satIdx); 

    end
end

end

%% Determine current time slot beam positions based on interference avoidance
function curBeam = judgeBeam(maxBeam,I,distanT)
curBeam = zeros(1,maxBeam);
curBeam(1) = I(1);
II = I;% Store I again
II(1)=[];

count = 2;% Counter
while true       
    if isempty(II)
        % If II is already empty
        if count ~= maxBeam + 1
            % Searched all but still cannot fill
            % Then directly fill with unselected ones
            III = I;
            [~,ia,~]=intersect(III,curBeam);
            III(ia) = [];
            leftNum = maxBeam - (count - 1);
            if length(III) < leftNum
                curBeam(count:end) = III;
            else
                curBeam(count:end) = III(1:leftNum);
            end            
            return;
        else
            return;
        end        
    elseif count == maxBeam + 1 && ~isempty(II)
        % Finished searching
        return;       
    end
    curBeam(count) = II(1);
    flag=0;% Interference occurrence flag
    for k = 1 : count - 1
        if distanT(curBeam(k),curBeam(count)) == 0% Based on interference matrix, found interference between these two
            flag = 1;            
            break;
        end
    end
    if flag == 1
        II(1)=[];
        curBeam(count) = 0;
    else
        II(1)=[];
        count = count + 1;
    end
end

end


%% Calculate remaining traffic for a beam position
function leftServ = calcuServ(SatIdx, ScheIdx, slotIdx, lightFoot, curFoot, interface, serv_need, curSatPos, curSatNextPos, heightOfsat)
NumOfLightBeamfoot = length(lightFoot);
% SINRofBF = zeros(1, NumOfLightBeamfoot);
Pt_sat = interface.SatObj(SatIdx).Pt_dBm_serv; % Total transmit power of satellite antenna
Pt_sat = (10.^(Pt_sat/10))/1e3; % Unit is W
lightPower = Pt_sat / NumOfLightBeamfoot;
Band = interface.BandOfLink * 1e6;%Hz
freqOfDownLink = interface.freqOfDownLink; % (Hz) Downlink center frequency of satellite
startOfBand = freqOfDownLink - Band / 2;
lightTime = interface.timeInSlot;% Beam illumination time (slot length), unit is s

% Calculate all pointing directions
PosOfBeam = zeros(NumOfLightBeamfoot, 2);    % Illuminated beam position center triangle coordinates 
for bidx = 1 : NumOfLightBeamfoot
    PosOfBeam(bidx, :) = interface.tmpSat(SatIdx).beamfoot(ScheIdx, lightFoot(bidx)).position; 
end

BeamPoint = zeros(NumOfLightBeamfoot, 2); % varphi(elevation, deviation from x-axis),vartheta(direction, deviation from xOy plane), antenna in zOy plane(right-handed)
for j = 1 : NumOfLightBeamfoot
    [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
        curSatPos, curSatNextPos, PosOfBeam(j, :), heightOfsat);
    BeamPoint(j,1) = outputPhi;
    BeamPoint(j,2) = outputTheta;
end

% Calculate SINR for all beam positions
% for footIdx = 1 : NumOfLightBeamfoot
%     curFoot = lightFoot(footIdx);
    % Get users in current beam position
    orderOfUsrs = interface.tmpSat(SatIdx).beamfoot(ScheIdx, curFoot).usrs;
    % Then calculate h for these beam positions
    curSINR = 0;
    subBandWidth = Band / length(orderOfUsrs);
    for usrIdx = 1 : length(orderOfUsrs)
        curUser = orderOfUsrs(usrIdx);
    
        tmpBand = [startOfBand + (usrIdx - 1) * subBandWidth, startOfBand + usrIdx * subBandWidth];
    
        thisSINR = CaculateSINR(SatIdx, ScheIdx, slotIdx, curUser, curFoot, lightFoot, lightPower, BeamPoint, tmpBand, interface);
    
        curSINR = curSINR + thisSINR;            
    end
    SINRofBF = curSINR / length(orderOfUsrs);
% end

% Calculate how much these beam positions transmitted
given = Band * log2(1+SINRofBF)*lightTime;
footIdx = find(lightFoot == curFoot);
leftServ = serv_need(footIdx) - given;

end
%% Calculate fitness value
function fitValue = funcFit(SatIdx, ScheIdx, slotIdx, lightFoot, interface, serv_need, curSatPos, curSatNextPos, heightOfsat)
% Input: SatIdx satellite index; ScheIdx scheduling period index; userIdx current user index; footIdx current beam position index;
% lightFoot all illuminated beam position indices; lightPower power allocation indices for all illuminated beam positions; BeamPoint pointing direction;
% thisBand current frequency band
% Output: fitValue fitness value
% Calculation principle: sum(need - given)

NumOfLightBeamfoot = length(lightFoot);
SINRofBF = zeros(1, NumOfLightBeamfoot);
Pt_sat = interface.SatObj(SatIdx).Pt_dBm_serv; % Total transmit power of satellite antenna
Pt_sat = (10.^(Pt_sat/10))/1e3; % Unit is W
lightPower = Pt_sat / NumOfLightBeamfoot;
Band = interface.BandOfLink * 1e6;%Hz
freqOfDownLink = interface.freqOfDownLink; % (Hz) Downlink center frequency of satellite
startOfBand = freqOfDownLink - Band / 2;
lightTime = interface.timeInSlot;% Beam illumination time (slot length), unit is s

% Calculate all pointing directions
PosOfBeam = zeros(NumOfLightBeamfoot, 2);    % Illuminated beam position center triangle coordinates 
for bidx = 1 : NumOfLightBeamfoot
    PosOfBeam(bidx, :) = interface.tmpSat(SatIdx).beamfoot(ScheIdx, lightFoot(bidx)).position; 
end

BeamPoint = zeros(NumOfLightBeamfoot, 2); % varphi(elevation, deviation from x-axis),vartheta(direction, deviation from xOy plane), antenna in zOy plane(right-handed)
for j = 1 : NumOfLightBeamfoot
    [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
        curSatPos, curSatNextPos, PosOfBeam(j, :), heightOfsat);
    BeamPoint(j,1) = outputPhi;
    BeamPoint(j,2) = outputTheta;
end

% Calculate SINR for all beam positions
for footIdx = 1 : NumOfLightBeamfoot
    curFoot = lightFoot(footIdx);
    % Get users in current beam position
    orderOfUsrs = interface.tmpSat(SatIdx).beamfoot(ScheIdx, curFoot).usrs;
    % Then calculate h for these beam positions
    curSINR = 0;
    subBandWidth = Band / length(orderOfUsrs);
    for usrIdx = 1 : length(orderOfUsrs)
        curUser = orderOfUsrs(usrIdx);
    
        tmpBand = [startOfBand + (usrIdx - 1) * subBandWidth, startOfBand + usrIdx * subBandWidth];
    
        thisSINR = CaculateSINR(SatIdx, ScheIdx, slotIdx, curUser, curFoot, lightFoot, lightPower, BeamPoint, tmpBand, interface);
    
        curSINR = curSINR + thisSINR;            
    end
    SINRofBF(footIdx) = curSINR / length(orderOfUsrs);
end

% Calculate how much these beam positions transmitted
serv_left = serv_need;
for footIdx = 1 : NumOfLightBeamfoot
    % Note footIdx and curFoot here
    curFoot = lightFoot(footIdx);
    given = Band * log2(1+SINRofBF(footIdx))*lightTime;
    serv_left(curFoot) = serv_left(curFoot) - given;
end

fitValue = sum(serv_left);

end

%% Calculate SINR for a specific user
function SINR = CaculateSINR(SatIdx, ScheIdx, slotIdx, userIdx, curFoot, lightFoot, lightPower, BeamPoint, thisBand, interface)
% Input: SatIdx satellite index; ScheIdx scheduling period index; userIdx current user index; footIdx current beam position index;
% lightFoot all illuminated beam position indices; lightPower power allocation indices for all illuminated beam positions; BeamPoint pointing direction;
% thisBand current frequency band

%     userIdx = find(interface.OrderOfSelectedUsrs == userIdx);    
    Usrs = interface.tmpSat(SatIdx).beamfoot(ScheIdx, curFoot).usrs;% Users in beam position
    footIdx = find(lightFoot == curFoot);% Index of current beam position among all positions
    Pt = 1 / length(Usrs) * lightPower;   % Power allocated to each user
    Band = interface.BandOfLink * 1e6;% Hz
    
%     T_noise = interface.UsrsObj(1).T_noise;
% %     F_noise_dB = interface.UsrsObj(1).F_noise;
% %     F_noise = 10.^(F_noise_dB./10);
%     N0_noise = 1.380649e-23*T_noise*300;% kTB

    Bandwidth = Band / length(Usrs);
    freqOfDownLink = interface.freqOfDownLink; % (Hz) Downlink center frequency of satellite
    startOfBand = freqOfDownLink - Band / 2;
    userIdxInBeam = find(Usrs == userIdx);  
    thisBand = [startOfBand + (userIdxInBeam - 1) * Bandwidth, startOfBand + userIdxInBeam * Bandwidth];
    fc = mean(thisBand);

    % Calculate pointing angle for current user
    userCurPos = interface.UsrsObj(userIdx).position; % Current user coordinates    
    satCurPos = interface.SatObj(SatIdx).position; % Current satellite sub-satellite point coordinates
    satCurnextPos = interface.SatObj(SatIdx).nextpos; % Next step coordinates of current satellite sub-satellite point
    [userTheta, userPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, userCurPos, interface.height);% Calculate azimuth and elevation angles
    % Calculate user reception gain
    G_usrDown = antenna.getUsrAntennaServG(0, fc, false);
    % Calculate distance from current satellite to current user
    usrCurPos = interface.UsrsObj(userIdx).position;
    usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
    satPosInDescartes = LngLat2Descartes(satCurPos, interface.height);
    distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
                    (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
                    (satPosInDescartes(3)-usrPosInDescartes(3)).^2);  
    InterfInSatDown = 0;

    % Traverse interfering beam positions, in order of allocation, calculate interference
    for bfIdx = 1 : length(lightFoot)
        OrderOfbeam = lightFoot(bfIdx);% Actual index of beam position
        if OrderOfbeam == curFoot % Skip current beam position
            continue;
        else
            % User indices in interfering beam position
            interfUsrs = interface.tmpSat(SatIdx).beamfoot(ScheIdx, OrderOfbeam).usrs;
            % Power allocated to interfering beam position
            interfBeamPower = lightPower;
            poiBeta = BeamPoint(bfIdx,1);
            poiAlpha = BeamPoint(bfIdx,2);
            AgleOfInv = [userTheta, userPhi];
            AgleOfPoi = [poiAlpha, poiBeta];

            subBandWidth = Band / length(interfUsrs);
            for interfUsrIdx = 1 : length(interfUsrs) % Traverse interference from users in this beam position
                % Get power and frequency band for this interfering user
                thisInterfUser = interfUsrs(interfUsrIdx);
%                 thisInterfUser = find(interface.OrderOfSelectedUsrs == thisInterfUser);
                thisInterfUser_power = 1 / length(interfUsrs)  * interfBeamPower;
                thisInterfUser_band = [startOfBand + (interfUsrIdx - 1) * subBandWidth, startOfBand + interfUsrIdx * subBandWidth];

                % Check for frequency band overlap
                overlap = range_intersection(thisBand, thisInterfUser_band);% Note: check if f unit is Hz
                if length(overlap) == 2
                    lambdaDown = 3e8/mean(overlap);
                    G_sat_interfDown = antenna.getSatAntennaServG(AgleOfInv, AgleOfPoi, mean(overlap));
                    InterfInSatDown = InterfInSatDown + ...
                        thisInterfUser_power * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
                end

            end
        end

    end
    %%%%%%%%%%%%%%%%%%%%%
    bfIdx = find(lightFoot == curFoot);
    poiBeta = BeamPoint(bfIdx,1);
    poiAlpha = BeamPoint(bfIdx,2);
    AgleOfInv = [userTheta, userPhi];
    AgleOfPoi = [poiAlpha, poiBeta];
    lambda_c = 3e8/fc;

    G_sat_down = antenna.getSatAntennaServG(AgleOfInv, AgleOfPoi, fc);
    %%%%%%%%%%%%%%%%%%%%%
    Carrier_down = Pt * G_sat_down * G_usrDown * (lambda_c.^2) / (((4*pi).^2)*(distance.^2));
    SINR = Carrier_down./(InterfInSatDown + 1.380649e-23 * 300 * Bandwidth);

end

%% 
function PosInDescartes = LngLat2Descartes(CurPos, h)
    tmpPhi = CurPos(1) * pi / 180;
    if tmpPhi < 0
        tmpPhi = tmpPhi + 2*pi;
    end
    tmpTheta = (90 - CurPos(2)) * pi / 180;
    R = 6371.393e3; % Earth radius
    tmpX = (R+h) * sin(tmpTheta) * cos(tmpPhi);
    tmpY = (R+h) * sin(tmpTheta) * sin(tmpPhi);
    tmpZ = (R+h) * cos(tmpTheta); 
    PosInDescartes = [tmpX, tmpY, tmpZ];    
end

%% Calculate intersection
function [ Overlap ] = range_intersection( A,B )

%A and B is a vector 
%for example A = [1 2 3]; B = [2 2.5 3 4]; 

%find lower and upper limit for vector A and B
Lower_A = min(A); 
Upper_A = max(A); 

Lower_B = min(B); 
Upper_B = max(B); 

%check condition of lower and upper limit both vector
%this part is to determine lower limit 
if (Lower_A > Lower_B || Lower_A == Lower_B)
    Lower_Lim = Lower_A;    
else
    Lower_Lim = Lower_B; 
end

%this part is to determine upper limit
if (Upper_A > Upper_B || Upper_A == Upper_B)
    Upper_Lim = Upper_B;    
else
    Upper_Lim = Upper_A; 
end

%merge all vectors
input_vector = union(A,B); 

Overlap = input_vector(intersect(find(input_vector>=Lower_Lim),find(input_vector<=Upper_Lim)));

end


