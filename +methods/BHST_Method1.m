%% proposed
function BHST_Method1(interface)
tic
%% Pre-configuration
Debug = 1;
OrderOfServSatCur = interface.OrderOfServSatCur;    % List of serving satellites
NumOfServSatCur = length(OrderOfServSatCur);    % Number of serving satellites
NumOfServBeam = interface.numOfServbeam;    % Number of service beams
Num_scheme = interface.ScheInShot;  % Number of scheduling periods in a snapshot
Num_slot = interface.SlotInSche;    % Number of slots in a scheduling period
RequiredTraffic = interface.UsrsTraffic(:, 1);  % List of requested traffic
TransportedTraffic = zeros(interface.NumOfSelectedUsrs, Num_scheme);   % List of transported traffic
AngleOf3dB = interface.AngleOf3dB;% Antenna 3dB beamwidth
Rb = tools.getEarthLength(AngleOf3dB, interface.height)/2; % Calculate beam footprint radius
%% Set genetic algorithm parameters
if_directional_mutation = true; % Whether directional mutation
convergence_ratio = 0.01;       % Maximum fitness differential fluctuation ratio at convergence
interf_isolate_factor = 3;      % Interference isolation factor, controls interference isolation distance as multiple of beam footprint radius
factorOfProbabilityChange = 0.1;% Probability change factor, range 0~1, crossover probability is 0.5+factorOfProbabilityChange*(rand()-0.5)
Num_population = 200;   % Population size
Length_chromosome = 10;  % Chromosome length
Num_decision = ceil(Num_slot/Length_chromosome);    % Number of decisions in scheduling period
Probability_mutation = 0.01;    % Probability of chromosome mutation
Num_mutation = 4;   % Number of mutated bases in gene
Num_iteration = 100; % Number of iterations
%% Algorithm execution
    %% Traverse all satellites
%     NumOfIteration = zeros(NumOfServSatCur, Num_scheme, Num_decision); % Store number of iterations for all decisions
    for idxOfSat = 1 : NumOfServSatCur
        UsrsIndex = interface.SatObj(idxOfSat).servUsr; % List of user IDs under satellite
        [~,NewUsrsIdx,~] = intersect(interface.OrderOfSelectedUsrs, UsrsIndex);
        RequiredTraffic_in_Sat = RequiredTraffic(NewUsrsIdx);    % Remaining requested traffic for users under satellite
        TransportedTraffic_in_Sat = zeros(interface.SatObj(idxOfSat).numOfusrs, Num_scheme);   % Transported traffic for users under satellite
        interface.tmpSat(idxOfSat).BHST = zeros(NumOfServBeam, Num_slot*Num_scheme);
        %% Traverse each scheduling period
        for idxOfSche = 1 : Num_scheme 
            if idxOfSche == 1
                RequiredTraffic_in_Sat = RequiredTraffic_in_Sat + ...
                                interface.UsrsTraffic(NewUsrsIdx, idxOfSche+1);  % Traffic to be scheduled in first scheduling period is initial traffic + traffic generated in first period
            else
                RequiredTraffic_in_Sat = RequiredTraffic_in_Sat + ...
                                interface.UsrsTraffic(NewUsrsIdx, idxOfSche+1) - ...
                                TransportedTraffic_in_Sat(:, idxOfSche-1);  % Traffic to be scheduled in n-th scheduling period is initial traffic + traffic generated in n-th period - traffic transported in (n-1)th period
            end
            RequiredTraffic_in_Sat(RequiredTraffic_in_Sat<0) = 0;   % Remaining traffic less than 0 is recorded as 0

            NumOfBeamfoot = interface.tmpSat(idxOfSat).NumOfBeamFoot(idxOfSche);    % Total number of beam footprints
                    
            ExecutiveBHST = zeros(NumOfBeamfoot, Num_slot); % Decision schedule table

            RequiredTrafficOfBF = zeros(NumOfBeamfoot, 1); 
            for tmpk = 1 : NumOfBeamfoot
                [~, tmp_idx, ~] = intersect(UsrsIndex, interface.tmpSat(idxOfSat).beamfoot(idxOfSche, tmpk).usrs);% tmp_idx is the index in users under satellite
                RequiredTrafficOfBF(tmpk) = sum(RequiredTraffic_in_Sat(tmp_idx)); % Traffic requested by beam footprint in current scheduling period
            end      
            %% Perform multiple decisions
            TransportedTrafficOfBF = zeros(Num_decision, NumOfBeamfoot); % Table of beam footprint traffic transported for multiple decisions
            % First calculate standard per-slot traffic transmission for users without interference
            standard_ExecutiveBHST = zeros(NumOfBeamfoot, 1);
            standard_ExecutiveBHST(1) = 1;
            standard_TransportedTrafficOfBF = calculateTraffic(interface.OrderOfSelectedUsrs, idxOfSat, idxOfSche, 1, 1, standard_ExecutiveBHST, interface, Debug);
            standard_TransportedTrafficOfBF = standard_TransportedTrafficOfBF(1);

            Distance = zeros(NumOfBeamfoot, NumOfBeamfoot);  % Adjacency matrix recording beam footprint distances, used to set illuminated beam footprint spacing
            OrderOfBf = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, 1:NumOfBeamfoot);
            for idxOfB_1 = 1 : NumOfBeamfoot-1
                for idxOfB_2 = idxOfB_1+1 : NumOfBeamfoot
                    Distance(idxOfB_1, idxOfB_2) = tools.LatLngCoordi2Length( ...
                                                        OrderOfBf(idxOfB_1).position, ...
                                                        OrderOfBf(idxOfB_2).position, ...
                                                        6371.393e3);
                    Distance(idxOfB_2, idxOfB_1) = Distance(idxOfB_1, idxOfB_2);
                end
            end

            for idxOfDeci = 1 : Num_decision
                % Remaining requested traffic for users in current decision
                if idxOfDeci ~= 1
                    RequiredTrafficOfBF = RequiredTrafficOfBF - TransportedTrafficOfBF(idxOfDeci-1, :).';
                end
                RequiredTrafficOfBF(RequiredTrafficOfBF<0)=0;
                % Calculate how many slots the remaining traffic can be transmitted based on standard transmission rate
                NumOfSlot_RequiredTrafficOfBF = zeros(NumOfBeamfoot, 1);
                for idx_tmp = 1 : NumOfBeamfoot
                    NumOfSlot_RequiredTrafficOfBF(idx_tmp) = ceil(RequiredTrafficOfBF(idx_tmp)./standard_TransportedTrafficOfBF);
                end
                have_assigned_slot = (idxOfDeci-1)*Length_chromosome;
                UsrIdx = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, 1).usrs;
                T_noise = interface.UsrsObj(find(interface.OrderOfSelectedUsrs==UsrIdx(1))).T_noise;
                F_noise_dB = interface.UsrsObj(find(interface.OrderOfSelectedUsrs==UsrIdx(1))).F_noise;
                F_noise = 10.^(F_noise_dB./10);
                N0_noise = 1.380649e-23*(T_noise + (F_noise-1)*300);

                functionOfgetPointAngle = @(BeamLightSeq)getPointAngle(BeamLightSeq, interface, idxOfSat, idxOfSche);                
                functionOfgetCarrierP = @(alpha, beta, angleOfusr, distance)getCarrierP(alpha, beta, angleOfusr, distance, interface);
                functionOfgetInterfP = @(alpha, beta, angleOfusr, distance)getInterfP(alpha, beta, angleOfusr, distance, interface);

                ExecutiveBHST(:, (idxOfDeci-1)*Length_chromosome+1:idxOfDeci*Length_chromosome) = ...
                    Evolution(...
                        Num_population, ...
                        Length_chromosome, ...
                        Probability_mutation, ...
                        if_directional_mutation, ...
                        Num_mutation, ...
                        Num_iteration, ...
                        convergence_ratio, ...
                        interf_isolate_factor, ...
                        Rb, ...
                        NumOfBeamfoot, ...
                        NumOfServBeam, ...
                        NumOfSlot_RequiredTrafficOfBF, ...
                        Distance, ...
                        factorOfProbabilityChange, ...
                        have_assigned_slot, ...
                        ExecutiveBHST, ...
                        RequiredTrafficOfBF, ...
                        N0_noise, ...
                        interface.BandOfLink*1e6, ...
                        functionOfgetPointAngle, ...
                        functionOfgetCarrierP, ...
                        functionOfgetInterfP ...
                        );

                TransportedTrafficOfBF(idxOfDeci, :) = calculateTraffic(interface.OrderOfSelectedUsrs, idxOfSat, idxOfSche, idxOfDeci, Length_chromosome, ExecutiveBHST, interface, Debug); % Calculate transported traffic for each beam footprint in current decision   
                if Debug == 1
                    fprintf('Satellite %d, scheduling %d, decision %d traffic calculation completed\n', idxOfSat, idxOfSche, idxOfDeci); 
                end            
            end % Traverse decisions
            %%
            for tmpk = 1 : NumOfBeamfoot
                usrs = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, tmpk).usrs;
                NofU = length(usrs);
                [~,tmp_UsrsIndex,~] = intersect(UsrsIndex, usrs);
                r_traffic = RequiredTraffic_in_Sat(tmp_UsrsIndex);
                for idx = 1 : NofU
                    TransportedTraffic_in_Sat(tmp_UsrsIndex(idx), idxOfSche) = TransportedTraffic_in_Sat(tmp_UsrsIndex(idx), idxOfSche) + ...
                        sum(TransportedTrafficOfBF(:,tmpk)).*(r_traffic(idx)./sum(r_traffic));
                end
            end
            end 
            for idx_BHST = 1 : Num_slot
                if length(find(ExecutiveBHST(:,idx_BHST)==1)) < NumOfServBeam
                    interface.tmpSat(idxOfSat).BHST(:, (idxOfSche-1)*Num_slot+idx_BHST) = ...
                            [find(ExecutiveBHST(:,idx_BHST)==1);zeros(NumOfServBeam-length(find(ExecutiveBHST(:,idx_BHST)==1)), 1)];
                else
                    interface.tmpSat(idxOfSat).BHST(:, (idxOfSche-1)*Num_slot+idx_BHST) = ...
                            find(ExecutiveBHST(:,idx_BHST)==1);
                end
            end
        end % Traverse scheduling periods
        TransportedTraffic(NewUsrsIdx, :) = TransportedTraffic(NewUsrsIdx, :) + ...
            TransportedTraffic_in_Sat;
    end % Traverse satellites 
    interface.tmp_UsrsTransPort = TransportedTraffic;
    toc;
    fprintf(['Genetic algorithm:',num2str(toc),'\n']); 
end

%% Calculate throughput
function TransportedTrafficOfBF = calculateTraffic(OrderOfSelectedUsrs,idxOfSat, idxOfSche, idxOfDeci, Length_chromosome, ExecutiveBHST, interface, Debug)
    numOfbeamfoot = length(ExecutiveBHST(:,1));
    TransportedTrafficOfBF = zeros(numOfbeamfoot, 1);
    for idxOfSlot = 1 : Length_chromosome
        lightedBf = find(ExecutiveBHST(:, (idxOfDeci-1)*Length_chromosome+idxOfSlot)==1);
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
        SINR_Gene = zeros(NumOfLightBeamfoot, 1);
        for tmpI = 1 : NumOfLightBeamfoot
            [SINR_Gene(tmpI), ~] = CaculateR(...
                OrderOfSelectedUsrs, ...
                idxOfSat, idxOfSche, ...
                ExecutiveBHST(:, (idxOfDeci-1)*Length_chromosome+idxOfSlot),...
                lightedBf(tmpI), BeamPoint, interface);
        end
        for idxOfBf = 1 : NumOfLightBeamfoot
            TransportedTrafficOfBF(lightedBf(idxOfBf)) = TransportedTrafficOfBF(lightedBf(idxOfBf)) + ...
                fix(interface.timeInSlot*interface.BandOfLink*1e6*log2(1+SINR_Gene(idxOfBf)));
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

%% Function parameters
% functionOfgetPointAngle = @getPointAngle;
% functionOfgetCarrierP = @getCarrierP;
% functionOfgetInterfP = @getInterfP
function [alpha, beta, angleOfusr, distance] = getPointAngle( ...
    BeamLightSeq, ...
    interface, ...
    idxOfSat, ...
    idxOfSche ...
    )
    UsrAntennaConfig = antenna.initialUsrAntenna();
    IfUsrAntennaDeGravity = UsrAntennaConfig.ifDeGravity;
    LightBeamfoot = find(BeamLightSeq == 1); % Illuminated beam footprint IDs
    NumOfLightBeamfoot = length(LightBeamfoot);
    PosOfBeam = zeros(NumOfLightBeamfoot, 2);    % Illuminated beam footprint center triangular coordinates
    for bidx = 1 : NumOfLightBeamfoot
        if ~isempty(interface.SatObj(SatIdx).beamfoot)
            PosOfBeam(bidx, :) = self.tmpSat(idxOfSat).beamfoot(idxOfSche, LightBeamfoot(bidx)).position; 
        end
    end
    alpha = zeros(NumOfLightBeamfoot, 1);
    beta = zeros(NumOfLightBeamfoot, 1);
    for idx = 1 : NumOfLightBeamfoot
        [alpha(idx), beta(idx)] = tools.getPointAngleOfUsr(...
            interface.SatObj(idxOfSat).position, interface.SatObj(idxOfSat).nextpos, PosOfBeam(idx, :), interface.height);
    end
    distance = zeros(NumOfLightBeamfoot, 1);
    angleOfusr = zeros(NumOfLightBeamfoot, 1);
    if IfUsrAntennaDeGravity == 1
        for idx_usr = 1 : NumOfLightBeamfoot
            UsrIdx = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, LightBeamfoot(idx_usr)).usrs;
            usrCurPos = interface.UsrsObj(find(interface.OrderOfSelectedUsrs==UsrIdx(1))).position;
            satCurPos = interface.SatObj(idxOfSat).position;
            [angleOfusr(idx_usr), ~, ~] = ...
                simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, interface.height);
            usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
            satPosInDescartes = LngLat2Descartes(satCurPos, interface.height);
            distance(idx_usr) = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
                            (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
                            (satPosInDescartes(3)-usrPosInDescartes(3)).^2);
        end
    else
        for idx_usr = 1 : NumOfLightBeamfoot
            UsrIdx = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, LightBeamfoot(idx_usr)).usrs;
            usrCurPos = interface.UsrsObj(find(interface.OrderOfSelectedUsrs==UsrIdx(1))).position;
            satCurPos = interface.SatObj(idxOfSat).position;
            usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
            satPosInDescartes = LngLat2Descartes(satCurPos, interface.height);
            distance(idx_usr) = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
                            (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
                            (satPosInDescartes(3)-usrPosInDescartes(3)).^2);
        end
    end
end
function CarrierP = getCarrierP(alpha, beta, angleOfusr, distance, interface)
    freqOfDownLink = interface.freqOfDownLink;
    CarrierP = zeros(length(alpha),1);
    Pt_SAT_dBm_serv = interface.SatObj(SatIdx).Pt_dBm_serv;
    %%%%%%%%%%%%%%%%% Service beam power equal distribution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Pt_SAT_serv = (10.^(Pt_SAT_dBm_serv/10))/1e3/interface.numOfServbeam; % W
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lambdaDown = 3e8/freqOfDownLink;
    for idx = 1 : length(alpha)
        % Calculate user receiving gain    
        G_usrDown = antenna.getUsrAntennaServG(angleOfusr(idx), freqOfDownLink, false);
        % Calculate satellite transmit gain
        G_sat_down = antenna.getSatAntennaServG([alpha(idx), beta(idx)], [alpha(idx), beta(idx)], freqOfDownLink);
  
        CarrierP(idx) = Pt_SAT_serv * G_sat_down * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance(idx).^2));
    end
end
function InterfP = getInterfP(alpha, beta, angleOfusr, distance, interface)
    freqOfDownLink = interface.freqOfDownLink;
    InterfP = zeros(length(alpha),1);
    Pt_SAT_dBm_serv = interface.SatObj(SatIdx).Pt_dBm_serv;
    %%%%%%%%%%%%%%%%% Service beam power equal distribution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Pt_SAT_serv = (10.^(Pt_SAT_dBm_serv/10))/1e3/interface.numOfServbeam; % W
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lambdaDown = 3e8/freqOfDownLink;
    for idx = 1 : length(alpha)
        G_usrDown = antenna.getUsrAntennaServG(angleOfusr(idx), freqOfDownLink, false);
        for idx_interf = 1 : length(alpha)
            G_sat_interfDown = antenna.getSatAntennaServG([alpha(idx), beta(idx)], [alpha(idx_interf), beta(idx_interf)], freqOfDownLink);
            if idx_interf ~= idx
                InterfP(idx) = InterfP(idx) + ...
                    Pt_SAT_serv * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance(idx).^2));
            end
        end
    end
end
%% Convert longitude and latitude to Cartesian coordinates
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