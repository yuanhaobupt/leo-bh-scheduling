% Huawei paper "Greedy Algorithm"
%%
function BHST_Method0(interface)
%% Get required parameters
% Need Earth radius (for distance calculation)
Radius = 6371.393e3;
% Some parameters
heightOfsat = interface.height;% Satellite orbit height
% Calculate beam footprint radius
AngleOf3dB = interface.AngleOf3dB;% Antenna 3dB beamwidth
Rb = tools.getEarthLength(AngleOf3dB, heightOfsat)/2;

% Maximum users per beam footprint
maxUsrPerBeam = 3;
% Center frequency (downlink) & wavelength
freq = interface.freqOfDownLink;% Frequency
lambdaDown = 3e8/freq;
% Subcarrier spacing
SCS = interface.SCS*1e3;% Unit is Hz
% Maximum RBs that can be transmitted in one slot for current full-bandwidth link
interface.UsrsObj(1) = interface.UsrsObj(1).getCurLinkNRB();
curRB = interface.UsrsObj(1).CurLinkNRB;

% Calculate thermal noise
BW = interface.BandOfLink*1e6; % Bandwidth, unit is Hz
T = 300;% Kelvin temperature, unit is K
k = 1.38e-23;% Boltzmann constant
N0 = k*T*BW;% Noise

% User receiving gain
type = 0;

% Parameters about beam hopping
bhLength = interface.SlotInSche; % Length of one beam hopping scheduling
lightTime = interface.timeInSlot;% Beam illumination time (slot duration), unit is s
NumOfBeam = interface.numOfServbeam; % Number of simultaneously operating beams

% Total number of scheduling periods
sche = interface.ScheInShot; 

%% Traverse by scheduling period
% for idx = 1 : sche
%     givenserv = zeros(1,numOfusrs);% Store all users' obtained traffic

%% Only need to consider current scheduling period
for idx = 1 : sche
% Current scheduled users
numOfusrs = length(find(interface.usersInLine(sche,:) ~= 0));
usersInThisSche = interface.usersInLine(sche,interface.usersInLine(sche,:)~=0);
% Total users
NumOfSelectedUsrs = interface.NumOfSelectedUsrs;
OrderOfSelectedUsrs = interface.OrderOfSelectedUsrs;

if sche == 1
    interface.tmp_UsrsTransPort = zeros(NumOfSelectedUsrs, interface.ScheInShot);% Need to update at the end
end

TransportedTraffic = zeros(interface.NumOfSelectedUsrs, 1);   % List of transported traffic

    %% Requested traffic statistics
    requestServAll = zeros(1, NumOfSelectedUsrs);% Store all user requested traffic (users not yet connected may not have traffic requests)
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
%         MAX_bf = max(interface.tmpSat(satIdx).NumOfBeamFoot);
%         interface.tmpSat(satIdx).BHST = zeros(MAX_bf, interface.SlotInSche * interface.ScheInShot);

        % Calculate satellite total power
        Pt_sat = interface.SatObj(satIdx).Pt_dBm_serv; % Total transmit power of satellite antenna
        Pt_sat = (10.^(Pt_sat/10))/1e3; % Unit is W

        numOfbeamfoot = interface.tmpSat(satIdx).NumOfBeamFoot(idx);% Total number of beam footprints
        servOfbeamfoot = zeros(numOfbeamfoot, 1); % Requested traffic for each beam footprint under satellite
        userInBeam = zeros(numOfbeamfoot,maxUsrPerBeam);% Store user IDs within each beam footprint
        positionOfbeamfoot = zeros(numOfbeamfoot, 2); % Longitude and latitude coordinates of each beam footprint center
          
        % Store data
        for bfIdx = 1 : numOfbeamfoot
            orderOfUsrs = interface.tmpSat(satIdx).beamfoot(idx, bfIdx).usrs;
            userInBeam(bfIdx,1:length(orderOfUsrs)) = orderOfUsrs;
            
            [~, interUsers] = intersect(interface.OrderOfSelectedUsrs, orderOfUsrs);
            servInBeam = requestServAll(interUsers);
%             servInBeam = requestServAll(interface.OrderOfSelectedUsrs==orderOfUsrs);
            servOfbeamfoot(bfIdx) = sum(servInBeam);
            positionOfbeamfoot(bfIdx, :) = interface.tmpSat(satIdx).beamfoot(idx, bfIdx).position;% Get longitude and latitude coordinates of beam footprint center
        end

        % If there are no beam footprints at all, return empty BHST directly
        if numOfbeamfoot == 0
            BHST = zeros(NumOfBeam, bhLength);
            interface.tmpSat(satIdx).BHST(:, ((idx-1)*bhLength+1):(idx*bhLength)) = BHST(:,:);           
            continue;
        end
        
        % Calculate channel capacity for each beam footprint C=Blog2(1+SNR), S=Pt*Gt*Gr*(lambdaDown.^2)/(((4*pi).^2)*(distance.^2));
        % Since the actual number of illuminated beam footprints is not necessarily NumOfBeam, cannot calculate Pt=Psat/illuminated count yet
        % First calculate the SNR part except Pt, N=KBT
        shannonPre = zeros(1,numOfbeamfoot);
    
        satCurPos = interface.SatObj(satIdx).position; % Current satellite sub-satellite point coordinates
        satCurnextPos = interface.SatObj(satIdx).nextpos; % Next step coordinates of current satellite sub-satellite point
        satPosInDescartes = LngLat2Descartes(satCurPos, heightOfsat);

        BeamPoint = zeros(1, 2);% Current beam pointing direction
%         UserAngle = zeros(1,2);% Angle between user and antenna
    
        for bb = 1 : numOfbeamfoot
            beamCurPos = positionOfbeamfoot(bb,:); % Current beam footprint center coordinates
            % The satellite beam points to the beam footprint center, so the beam pointing direction and elevation angle of the beam footprint center relative to the satellite are the same?
%             [beamTheta, beamPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, beamCurPos, heightOfsat);
%             UserAngle(1) = beamPhi;
%             UserAngle(2) = beamPhi;
            % Calculate beam pointing direction
            [outputTheta, outputPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, beamCurPos, heightOfsat);
            BeamPoint(1) = outputPhi;
            BeamPoint(2) = outputTheta;
            % Calculate satellite antenna gain
            G_sat = antenna.getSatAntennaServG(BeamPoint, BeamPoint, freq); % Antenna transmit gain
            % Calculate distance from current satellite to current beam footprint
            beamPosInDescartes = LngLat2Descartes(beamCurPos, 0);% Cartesian coordinates of beam footprint center
            distance = sqrt((satPosInDescartes(1)-beamPosInDescartes(1)).^2 + ...
                            (satPosInDescartes(2)-beamPosInDescartes(2)).^2 + ...
                            (satPosInDescartes(3)-beamPosInDescartes(3)).^2);
            
            % Calculate off-axis angle between beam footprint center and satellite
            beamWithHeight = LngLat2Descartes(beamCurPos, 1);
            vectorOfbeam = [ ...
                    beamWithHeight(1) - beamPosInDescartes(1), ...
                    beamWithHeight(2) - beamPosInDescartes(2), ...
                    beamWithHeight(3) - beamPosInDescartes(3) ...
                    ];
            vectorOfbeam2Sat = [ ...
                    satPosInDescartes(1) - beamPosInDescartes(1), ...
                    satPosInDescartes(2) - beamPosInDescartes(2), ...
                    satPosInDescartes(3) - beamPosInDescartes(3) ...
                    ];
            AgleOfInv = acos(abs(dot(vectorOfbeam, vectorOfbeam2Sat))/...
                    (sqrt(vectorOfbeam(1)^2 + vectorOfbeam(2)^2 + vectorOfbeam(3)^2) * ...
                    sqrt(vectorOfbeam2Sat(1)^2 + vectorOfbeam2Sat(2)^2 + vectorOfbeam2Sat(3)^2)));
            % Calculate user antenna gain
%             G_usr = antenna.getUsrAntennaServG(AgleOfInv, freq, type);
            G_usr = antenna.getUsrAntennaServG(0, freq, type);    
            % [Gt*Gr*(lambdaDown/(4*pi*distance))^2)]/N0;
            shannonPre(bb) = (G_sat * G_usr * (lambdaDown/(4*pi*distance))^2)/N0;
        end

        % Distance adjacency matrix, determine if greater than interference margin
        margin = 2 * Rb; % Separation greater than 1 beam footprint diameter (same as in the paper)
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
    %                 distanT(i, j) = 0;% Same one also set to 0
                end
            end
        end

        maxBeam = min(NumOfBeam,numOfbeamfoot);% If the satellite service area is small, the total number of beam footprints may be less than the set number of simultaneously operating beam footprints
        BHST = zeros(NumOfBeam, bhLength);% Store beam hopping schedule table
        serv_need = servOfbeamfoot;% Store the needed traffic again for subtraction
        for j = 1 : bhLength% Traverse each time slot
            if isempty(find(serv_need ~= 0))% If all have been allocated, end
                break;
            end
            [B,I] = sort(serv_need,'descend');
            I(find(B==0)) = [];% Prevent remaining traffic from being negative
            maxBeam = min(maxBeam,length(I));
%             tempBeam = I(1 : maxBeam);% Get the beam footprint IDs with the largest allocation in current time slot
            % Then check if interference avoidance is satisfied, using recursion
%             curBeam = judgeBeam(maxBeam,tempBeam,B,I,distanT,1);
            curBeam = judgeBeam(maxBeam,I,distanT);
            BHST(1:maxBeam,j) = curBeam.';
            % Then allocate traffic
            P = Pt_sat/length(curBeam(curBeam~=0));% Power allocated to each beam footprint (equal distribution)
            for cc = 1 : length(curBeam)
                SNR = P * shannonPre(curBeam(cc));                
                serv_given = curRB * (12*SCS) * log2(1+SNR)*lightTime;
                serv_need(curBeam(cc)) = serv_need(curBeam(cc)) - serv_given;
%                 if serv_need(curBeam(cc)) < 0
%                     serv_need(curBeam(cc)) = 0;% Prevent negative numbers
%                 end
            end       
        end

        %% Below is data storage
%         tmpBHST = zeros();
        interface.tmpSat(satIdx).BHST(:,((idx-1)*bhLength+1):(idx*bhLength)) = BHST(:,:);
%         % Capacity allocated to users
%         for nn = 1 : numOfbeamfoot
%             user = userInBeam(nn, userInBeam(nn,:)~=0);% User IDs in current beam footprint
%             if(serv_need(nn) == 0)% If current beam footprint has no traffic left
%                 for uu = 1 : length(user)% Then each user has been allocated the required traffic
%                     givenserv(user(uu)) = requestServAll(user(uu));
%                 end
%             else% If there is remaining traffic, store proportionally
%                 for uu = 1 : length(user)
%                     ratio = rnumOfusrsequestServAll(user(uu))/sum(requestServAll(user));
%                     givenserv(user(uu)) = ratio * (servOfbeamfoot(nn) - serv_need(nn));
%                 end
%             end
%         end
%         ExecutiveBHST = zeros(numOfbeamfoot, bhLength);
%         for idx_ii = 1 : bhLength
% %             if find(BHST(:,idx_ii) == 0)
% %                 1;
% %             end
%             ExecutiveBHST(BHST(BHST(:,idx_ii) ~= 0,idx_ii),idx_ii) = 1;
%         end        
%         TransportedTraffic = zeros(interface.NumOfSelectedUsrs, 1);   % List of transported traffic
%         TransportedTrafficOfBF = calculateTraffic(interface.OrderOfSelectedUsrs, satIdx, idx, bhLength, ExecutiveBHST, interface, 1); % Calculate transported traffic for each beam footprint in current decision   
%         TransportedTraffic_in_Sat = zeros(interface.SatObj(satIdx).numOfusrs(idx), 1);   % Transported traffic for users under satellite
%         UsrsIndex = interface.SatObj(satIdx).servUsr(idx, interface.SatObj(satIdx).servUsr(idx,:) ~= 0); % List of user IDs under satellite
%         RequiredTraffic = interface.UsrsTraffic(:, 1);  % List of requested traffic
%         [~,NewUsrsIdx,~] = intersect(OrderOfSelectedUsrs, UsrsIndex); % Index
% %         RequiredTraffic_in_Sat = RequiredTraffic(NewUsrsIdx);    % Remaining requested traffic for users under satellite
%         for tmpk = 1 : numOfbeamfoot
%             usrs = interface.tmpSat(satIdx).beamfoot(idx, tmpk).usrs;
%             NofU = length(usrs);
% %             [~,tmp_NewUsrs,~] = intersect(interface.OrderOfSelectedUsrs, usrs);
%             [~,tmp_UsrsIndex,~] = intersect(OrderOfSelectedUsrs, usrs);
%             r_traffic = RequiredTraffic(tmp_UsrsIndex);
%             [~, tmp_idx, ~] = intersect(UsrsIndex, usrs);
% %             if isempty(tmp_idx)
% %                 fprintf('aaa')
% %             end
%             for idx_ii = 1 : NofU
%                 TransportedTraffic_in_Sat(tmp_idx(idx_ii)) = sum(TransportedTrafficOfBF(tmpk)).*(r_traffic(idx_ii)./sum(r_traffic));
%             end
%         end 
%         TransportedTraffic(NewUsrsIdx) = TransportedTraffic_in_Sat;

        fprintf('Scheduling %d, satellite %d BHST formed\n', idx, satIdx); 
        
    end
%     interface.tmp_UsrsTransPort(:,idx) = TransportedTraffic;

    
%     interface.tmp_UsrsTransPort(:,idx) = givenserv;

end
end
% %% Based on interference avoidance, determine and find current time slot beam footprints
% function curBeam = judgeBeam(maxBeam,tempBeam,B,I,distanT,c)
% %c is used to record how many times to search backwards
% for k = 1 : maxBeam-1
%     for kk = k + 1 : maxBeam
%         if(~distanT(tempBeam(k),tempBeam(kk)))% Based on interference matrix, found interference between the two
%             % Then find the next highest traffic, replace, and perform interference judgment again until all satisfy interference avoidance
%             if c >= length(I) - maxBeam || ismember(I(maxBeam + c),tempBeam)% This means unable to find ones that satisfy interference avoidance
%                 break;
%             end
%             tempBeam(kk) = I(maxBeam + c);
%             c = c + 1;
%             tempBeam = judgeBeam(maxBeam,tempBeam,B,I,distanT,c);
%         end
%     end
%     if c >= length(I) - maxBeam || ismember(I(maxBeam + c),tempBeam)
%         break;
%     end
%     if k == maxBeam && kk == maxBeam% Already finished searching
%         break;
%     end
% end
% curBeam = tempBeam;
% end
%% Based on interference avoidance, determine and find current time slot beam footprints
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
            % All have been searched but still cannot fill
            % Then directly select from the unselected ones to fill
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
    flag=0;% Flag for whether interference appears
    for k = 1 : count - 1
        if distanT(curBeam(k),curBeam(count)) == 0% Based on interference matrix, found interference between the two
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



%% Calculate throughput
function TransportedTrafficOfBF = calculateTraffic(OrderOfSelectedUsrs, idxOfSat, idxOfSche, Num_slot, ExecutiveBHST, interface, Debug)
    numOfbeamfoot = length(ExecutiveBHST(:,1));
    TransportedTrafficOfBF = zeros(numOfbeamfoot, 1);
    for idxOfSlot = 1 : Num_slot
        lightedBf = find(ExecutiveBHST(:, idxOfSlot)==1);
        NumOfLightBeamfoot = length(lightedBf);
        PosOfBeam = zeros(NumOfLightBeamfoot, 2);    % Illuminated beam footprint center triangular coordinates
        for bidx = 1 : NumOfLightBeamfoot
            PosOfBeam(bidx, :) = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, lightedBf(bidx)).position; 
        end
        BeamPoint = zeros(NumOfLightBeamfoot, 2); % varphi(elevation, offset from x-axis),vartheta(direction, offset from xOy plane), antenna in zOy plane (right-handed)
        for j = 1 : NumOfLightBeamfoot
            [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
                interface.SatObj(idxOfSat).position, interface.SatObj(idxOfSat).nextpos, PosOfBeam(j, :), interface.height);
            BeamPoint(j,1) = outputPhi;
            BeamPoint(j,2) = outputTheta;
        end
%         NumOfExpressedGene = NumOfLightBeamfoot;
%         ExpressedGene = LightBeamfoot;
        SINR_Gene = zeros(NumOfLightBeamfoot, 1);
        for tmpI = 1 : NumOfLightBeamfoot
%             [SINR_Gene(tmpI), ~] = CaculateR(...
            [~, SINR_Gene(tmpI)] = CaculateR(...
                OrderOfSelectedUsrs, ...
                idxOfSat, idxOfSche, ...
                ExecutiveBHST(:, idxOfSlot),...
                lightedBf(tmpI), BeamPoint, interface);
        end
        for idxOfBf = 1 : NumOfLightBeamfoot
            TransportedTrafficOfBF(lightedBf(idxOfBf)) = TransportedTrafficOfBF(lightedBf(idxOfBf)) + ...
                interface.timeInSlot*interface.BandOfLink*1e6*log2(1+SINR_Gene(idxOfBf));
        end
    end          
end
%% Calculate SINR and SNR values for a base
function [SINR, SNR] = CaculateR(OrderOfSelectedUsrs, SatIdx, ScheIdx, Gene, i, BeamPoint, interface)
    % Interference received by the i-th base on the gene
    Pt = (10.^((interface.SatObj(SatIdx).Pt_dBm_serv)./10))./1e3./interface.numOfServbeam;   % W
    UsrIdx = interface.tmpSat(SatIdx).beamfoot(ScheIdx, i).usrs;
    T_noise = interface.UsrsObj(find(OrderOfSelectedUsrs==UsrIdx(1))).T_noise;
    F_noise_dB = interface.UsrsObj(find(OrderOfSelectedUsrs==UsrIdx(1))).F_noise;
    F_noise = 10.^(F_noise_dB./10);
    N0_noise = 1.380649e-23*(T_noise + (F_noise-1)*300);

%     BW = interface.BandOfLink*1e6; % Bandwidth, unit is Hz
%     T = 300;% Kelvin temperature, unit is K
%     k = 1.38e-23;% Boltzmann constant
%     N0 = k*T*BW;% Noise
    Bandwidth = interface.BandOfLink*1e6;
    ExpressedGene = find(Gene == 1);
    % Calculate pointing angle of current beam footprint center 
    usrCurPos = interface.tmpSat(SatIdx).beamfoot(ScheIdx, i).position; % Current user coordinates    
    satCurPos = interface.SatObj(SatIdx).position; % Current satellite sub-satellite point coordinates
    satCurnextPos = interface.SatObj(SatIdx).nextpos; % Next step coordinates of current satellite sub-satellite point
    [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrCurPos, interface.height);% Calculate azimuth and elevation angles
    % Calculate user receiving gain
    G_usrDown = antenna.getUsrAntennaServG(0, interface.freqOfDownLink, false);
    % Calculate distance from current satellite to current user
    usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
    satPosInDescartes = LngLat2Descartes(satCurPos, interface.height);
    distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
                    (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
                    (satPosInDescartes(3)-usrPosInDescartes(3)).^2);  
    InterfInSatDown = 0;
    lambdaDown = 3e8/interface.freqOfDownLink;
    for bfIdx = 1 : length(ExpressedGene)
        if bfIdx ~= find(ExpressedGene == i)
            poiBeta = BeamPoint(bfIdx,1);
            poiAlpha = BeamPoint(bfIdx,2);
            AgleOfInv = [UsrTheta, UsrPhi];
            AgleOfPoi = [poiAlpha, poiBeta];
            G_sat_interfDown = antenna.getSatAntennaServG(AgleOfInv, AgleOfPoi, interface.freqOfDownLink);
            InterfInSatDown = InterfInSatDown + ...
                Pt * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
        end
    end
    %%%%%%%%%%%%%%%%%%%%%
    bfIdx = find(ExpressedGene == i);
    poiBeta = BeamPoint(bfIdx,1);
    poiAlpha = BeamPoint(bfIdx,2);
    AgleOfInv = [UsrTheta, UsrPhi];
    AgleOfPoi = [poiAlpha, poiBeta];
    G_sat_down = antenna.getSatAntennaServG(AgleOfInv, AgleOfPoi, interface.freqOfDownLink);
    %%%%%%%%%%%%%%%%%%%%%
    Carrier_down = Pt * G_sat_down * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
    SINR = Carrier_down./(InterfInSatDown + Bandwidth*N0_noise);
    SNR = Carrier_down./(Bandwidth*N0_noise);
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



% %%
% function PosInDescartes = LngLat2Descartes(CurPos, h)
%     tmpPhi = CurPos(1) * pi / 180;
%     if tmpPhi < 0
%         tmpPhi = tmpPhi + 2*pi;
%     end
%     tmpTheta = (90 - CurPos(2)) * pi / 180;
%     R = 6371.393e3; % Earth radius
%     tmpX = (R+h) * sin(tmpTheta) * cos(tmpPhi);
%     tmpY = (R+h) * sin(tmpTheta) * sin(tmpPhi);
%     tmpZ = (R+h) * cos(tmpTheta); 
%     PosInDescartes = [tmpX, tmpY, tmpZ];    
% end