% Tabu Search algorithm for maximizing service satisfaction
function BHST_MY(interface)
% Get required parameters
Radius = 6371.393e3; % Earth radius
heightOfsat = interface.height;% Satellite orbital altitude
AngleOf3dB = interface.AngleOf3dB;% Antenna 3dB opening angle
Rb = tools.getEarthLength(AngleOf3dB, heightOfsat)/2;% Beam radius
freq = interface.freqOfDownLink;% Downlink center frequency
lambdaDown = 3e8/freq;% Wavelength
SCS = interface.SCS*1e3;% Subcarrier spacing in Hz

% Calculate thermal noise
BW = interface.BandOfLink*1e6; % Bandwidth in Hz
T = 300;% Kelvin temperature in K
k = 1.38e-23;% Boltzmann constant
N0 = k*T*BW;% Noise

% User reception gain
type = 0;

% Beam-hopping related parameters
OrderOfServSatCur = interface.OrderOfServSatCur;    % List of serving satellites
NumOfServSatCur = length(OrderOfServSatCur);    % Number of serving satellites
NumOfBeam = interface.numOfServbeam; % Number of simultaneously active beams
sche = interface.ScheInShot; % Total number of scheduling periods
Num_scheme = interface.ScheInShot;  % Number of scheduling periods per snapshot
bhLength = interface.SlotInSche; % Length of one beam-hopping scheduling period
lightTime = interface.timeInSlot;% Beam illumination time (slot length) in seconds

%% Traverse scheduling periods
for idx = 1 : sche
% Currently scheduled users
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
requestServAll = zeros(1, NumOfSelectedUsrs);% Store all users' requested traffic (users not yet connected may not have traffic requests recorded)
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
        % Calculate total satellite power
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
            interface.tmpSat(satIdx).BHST(:,((idx-1)*bhLength+1):(idx*bhLength)) = BHST(:,:);
            fprintf('Satellite %d BHST formed\n', satIdx); 
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
        %% Start tabu search
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

            % Related parameters
            tabu = zeros(NumOfBeam); % Tabu list
            L = round((NumOfBeam * (numOfbeamfoot - 1) / 2)^0.5);% Tabu list length
            Ca = NumOfBeam;% Number of candidates/neighborhood solutions (self-configured, consider beam count*10?)
            CaNum = zeros(Ca, NumOfBeam); % Candidate set
    
            % Initial solution generated using greedy approach
            x0 = judgeBeam(NumOfBeam,I,distanT);
%             x0 = I(1 : NumOfBeam);
            bestsofar = sort(x0);
            xnow = [];
            xnow(1,:) = sort(x0);
            bestsofarValue = funcFit(satIdx, scheIdx, slotIdx, bestsofar, interface, serv_need,curSatPos,curSatNextPos,heightOfsat);
            xnowValue(1,:) = funcFit(satIdx, scheIdx, slotIdx, xnow, interface, serv_need,curSatPos,curSatNextPos,heightOfsat);

            G = 50;% Maximum iterations
            g = 1;
%             ALong = zeros(1, G);

            %% Start iteration
            while g < G
                % Generate Ca neighborhood solutions
                x_near = zeros(Ca, NumOfBeam);
                for q = 1 : Ca
                    % Rule: first randomly generate a replacement count, then randomly generate that many beam indices, and randomly replace
                    randN = randperm(min(numOfbeamfoot - NumOfBeam, NumOfBeam), 1);
                    % Generate positions to replace
                    ranpPlace = randperm(NumOfBeam, randN);
                    % Then replace these positions
                    randBeam = randperm(numOfbeamfoot - NumOfBeam, randN);
                    % Start replacement
                    x_near(q, :) = x0;
                    for qq = 1 : randN
                        while true
                            randBeam = randperm(numOfbeamfoot, 1);
                            if isempty(find(x_near(q,:) == randBeam))
                                x_near(q, ranpPlace(qq)) = randBeam;
                                break;
                            end
                        end
                    end


%                     for qq = 1 : randN
%                         x_near(q, ranpPlace(qq)) = I(randBeam(qq) + NumOfBeam);
%                     end
                    % Prevent duplicates, need sorting
                    x_near(q, :) = sort(x_near(q, :));
                    fitvalue_near(q) = funcFit(satIdx, scheIdx, slotIdx, x_near(q,:), interface, serv_need,curSatPos,curSatNextPos,heightOfsat);
                end
                %%%%%%%%%%%%%%%%%%%%Best neighborhood solution as candidate%%%%%%%%%%%%%%%%%%%
                temp=find(fitvalue_near==min(fitvalue_near));
                candidate(g,:)=x_near(temp(1),:);
                candidateValue(g)=fitvalue_near(temp(1));
                %%%%%%%%%%%%%%Fitness difference between candidate and current solution%%%%%%%%%%%%%%%%%%
                delta1=candidateValue(g)-xnowValue(g); 
                %%%%%%%%%%%%%%Fitness difference between candidate and best solution so far%%%%%%%%%%%%%%%
                delta2=candidateValue(g)-bestsofarValue;  
                %%%%%Candidate solution does not improve, assign candidate to next iteration's current solution%%%%%%
                if delta1>=0
                    xnow(g+1, :) = candidate(g, :);
                    xnowValue(g+1) = xnowValue(g);
                    %%%%%%%%%%%%%%%%%%%%%Update tabu list%%%%%%%%%%%%%%%%%%%%%%%
                    tabu=[tabu;xnow(g+1, :)];
                    if size(tabu,1)>L  
                        tabu(1,:)=[];
                    end
                    g=g+1;                 % After updating tabu list, increment iteration count
                else
                    if delta2<0            % Candidate solution is better than best so far
                        %%%%%%%%%%Assign improved solution to next iteration's current solution%%%%%%%%%%%%
                        xnow(g+1, :)=candidate(g,:);
                        xnowValue(g+1)=candidateValue(g);
                        %%%%%%%%%%%%%%%%%%%%Update tabu list%%%%%%%%%%%%%%%%%%%%%
                        tabu=[tabu;xnow(g+1, :)];
                        if size(tabu,1)>L 
                            tabu(1,:)=[];
                        end 
                        %%%%%%%%Assign improved solution to next iteration's best solution%%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%Includes aspiration criterion%%%%%%%%%%%%%%%%%%%%%%%
                        bestsofar=candidate(g,:);
                        bestsofarValue=candidateValue(g);
                        g=g+1;                % After updating tabu list, increment iteration count
                    else
                        %%%%%%%%%%%%%%%Check if improved solution is in tabu list%%%%%%%%%%%%%%%
                        [M,N]=size(tabu);
                        r=0;
                        for m=1:M
                            if candidate(g,:)==tabu(m,:)
                                r=1;
                            end
                        end
                        if  r==0
                            %% Improved solution not in tabu list, assign to next iteration's current solution
                            xnow(g+1, :)=candidate(g, :);
                            xnowValue(g+1) = candidateValue(g);
                            %%%%%%%%%%%%%%%%%%%%%Update tabu list%%%%%%%%%%%%%%%%%%
                            tabu=[tabu;xnow(g,:)];
                            if size(tabu,1)>L
                                tabu(1,:)=[];
                            end
                            g=g+1;               % After updating tabu list, increment iteration count
                        else
                            %%% If improved solution is in tabu list, regenerate neighborhood solutions from current solution%%%%%
                            xnow(g,:)=xnow(g,:);
                            xnowValue(g,:)=funcFit(satIdx, scheIdx, slotIdx, xnow(g), interface, serv_need,curSatPos,curSatNextPos,heightOfsat);
                        end
                    end
                end
                trace(g)=bestsofarValue;
                traceFoot(g, :) = bestsofar;
                if length(trace) > 10 && g > 10 && all(traceFoot(g, :) == traceFoot(g - 10,:))
                    break;
                end
            end
            % Record results
            BHST(:,slotIdx) = bestsofar';
            % Update traffic
%             P = Pt_sat/NumOfBeam;% Power allocated to each beam position (equal distribution)
            for cc = 1 : NumOfBeam
                curFoot = bestsofar(cc);
                leftServ = calcuServ(satIdx, scheIdx, slotIdx, bestsofar, curFoot, interface, serv_need, curSatPos, curSatNextPos, heightOfsat);
                if length(leftServ) == 1
                    serv_need(curFoot) = leftServ;
                end
            end  
            fprintf('Satellite %d BHST formed %.1f%%\n',satIdx,slotIdx * 100 /bhLength);
        end
            %% Store data
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
        if distanT(curBeam(k),curBeam(count)) == 0% Found interference between these two based on interference matrix
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


