function BHST_Method2(interface)
% MaxSINR
% First beam considers SINR/supported transmission capacity
%% Pre-configuration
Debug = 1;
OrderOfServSatCur = interface.OrderOfServSatCur; % List of serving satellites
NumOfServSatCur = length(OrderOfServSatCur); % Number of serving satellites
NumOfServBeam = interface.numOfServbeam; % Number of service beams
Num_scheme = interface.ScheInShot; % Number of scheduling periods per snapshot
Num_slot = interface.SlotInSche; % Number of slots per scheduling period
RequiredTraffic = interface.UsrsTraffic(:, 1); % List of requested traffic
TransportedTraffic = zeros(interface.NumOfInvesUsrs, Num_scheme); % List of transported traffic
%% Algorithm execution 
 %% Traverse all satellites
 for idxOfSat = 1 : NumOfServSatCur
 UsrsIndex = interface.SatObj(idxOfSat).servUsr; % List of user IDs under satellite
 RequiredTraffic_in_Sat = RequiredTraffic(UsrsIndex); % Remaining requested traffic for users under satellite
 TransportedTraffic_in_Sat = zeros(interface.SatObj(idxOfSat).numOfusrs, Num_scheme); % Transported traffic for users under satellite
 interface.tmpSat(idxOfSat).BHST = zeros(NumOfServBeam, Num_slot*Num_scheme);
 %% Traverse each scheduling period
 for idxOfSche = 1 : Num_scheme 
% TransportedTrafficOfBF = zeros(NumOfBeamfoot, 1); % Beam position traffic table for scheduling period
 if idxOfSche == 1
 RequiredTraffic_in_Sat = RequiredTraffic_in_Sat + ...
 interface.UsrsTraffic(UsrsIndex, idxOfSche+1); % Traffic to be scheduled in first scheduling period is initial traffic + traffic generated in first period
 else
 RequiredTraffic_in_Sat = RequiredTraffic_in_Sat + ...
 interface.UsrsTraffic(UsrsIndex, idxOfSche+1) - ...
 TransportedTraffic_in_Sat(:, idxOfSche-1); % Traffic to be scheduled in n-th scheduling period is initial traffic + traffic generated in n-th period - traffic transported in (n-1)th period
 end
 RequiredTraffic_in_Sat(RequiredTraffic_in_Sat<0) = 0; % Remaining traffic less than 0 is recorded as 0

 NumOfBeamfoot = interface.tmpSat(idxOfSat).NumOfBeamFoot(idxOfSche); % Total number of beam positions
 
 ExecutiveBHST = zeros(NumOfBeamfoot, Num_slot); % Decision schedule table

 RequiredTrafficOfBF = zeros(NumOfBeamfoot, 1); 
 for tmpk = 1 : NumOfBeamfoot
 [~, tmp_idx, ~] = intersect(UsrsIndex, interface.tmpSat(idxOfSat).beamfoot(idxOfSche, tmpk).usrs);
 RequiredTrafficOfBF(tmpk) = sum(RequiredTraffic_in_Sat(UsrsIndex(tmp_idx))); % Traffic requested by beam position in current scheduling period
 end
 
% standard_ExecutiveBHST = zeros(NumOfBeamfoot, 1);
% standard_ExecutiveBHST(1) = 1;
% standard_TransportedTrafficOfBF = calculateTraffic(idxOfSat, idxOfSche, 1, standard_ExecutiveBHST, interface, Debug);
% standard


 Distance = zeros(NumOfBeamfoot, NumOfBeamfoot); % Adjacency matrix recording beam position distances
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

 Distance_R = zeros(NumOfBeamfoot, 1);
 satCurPos = interface.SatObj(idxOfSat).position; % Current satellite sub-satellite point coordinates
 for idxOfB_3 = 1 : NumOfBeamfoot
 Distance_R(idxOfB_3) = tools.LatLngCoordi2Length( ...
 OrderOfBf(idxOfB_3).position, ...
 satCurPos, ...
 6371.393e3);
 end

 [~, RankOfBF] = sort((1./(Distance_R.^2)).*RequiredTrafficOfBF, 'descend');

 flagOfBHST = zeros(Num_slot, 1);
 RankOfBF_Backup = RankOfBF;
 flag_while = 1;
 tmp_i = 1;
 while(flag_while)
 if length(unique(flagOfBHST)) == 1
 if unique(flagOfBHST) == NumOfServBeam
 flag_while = 0;
 end
 end
 tmp_i = tmp_i + 1;
% if tmp_i > 1000
% 1;
% end
% if Debug == 1
% fprintf(
% end
 if Debug == 1
 fprintf('mSINR algorithm scheduling %d BHST table filling %6.3f%%\n', idxOfSche, sum(flagOfBHST)/(Num_slot*NumOfServBeam)*100);
 end
 if isempty(RankOfBF)
 RankOfBF = RankOfBF_Backup;
 end
 if (length(unique(flagOfBHST)) == 1)&&(unique(flagOfBHST) == 0)
 for idxOfSlot = 1 : Num_slot
 ExecutiveBHST(RankOfBF(idxOfSlot), idxOfSlot)= 1;
 flagOfBHST(idxOfSlot) = flagOfBHST(idxOfSlot) + 1;
 end
 RankOfBF(1 : Num_slot) = [];
 end
 ListOfSINR = zeros(Num_slot, 1);
 BeamIdx = RankOfBF(1);
 for idxOfSlot = 1 : Num_slot
 lightedBf = find(ExecutiveBHST(:, idxOfSlot)==1);
 New_lightedBf = [lightedBf; BeamIdx];
 NumOfLightBeamfoot = length(New_lightedBf);
 PosOfBeam = zeros(NumOfLightBeamfoot, 2); % Illuminated beam position center triangular coordinates
 for bidx = 1 : NumOfLightBeamfoot
 PosOfBeam(bidx, :) = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, New_lightedBf(bidx)).position; 
 end
 BeamPoint = zeros(NumOfLightBeamfoot, 2); % varphi(，x),vartheta(，xOy),inzOy()
 for j = 1 : NumOfLightBeamfoot
 [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
 interface.SatObj(idxOfSat).position, interface.SatObj(idxOfSat).nextpos, PosOfBeam(j, :), interface.height);
 BeamPoint(j,1) = outputPhi;
 BeamPoint(j,2) = outputTheta;
 end
 tmpExecutiveBHST = ExecutiveBHST;
 tmpExecutiveBHST(BeamIdx, idxOfSlot) = 1;
 [~, ListOfSINR(idxOfSlot)] = CaculateR(...
 idxOfSat, idxOfSche, ...
 tmpExecutiveBHST(:, idxOfSlot),...
 BeamIdx, BeamPoint, interface);
 end
 [ActiveSlotOrder, ~] = sort(intersect(find(flagOfBHST < NumOfServBeam).', find(ExecutiveBHST(BeamIdx, :) ~= 1)), 'descend');
 [~, RankOfSlot_sinr] = sort(ListOfSINR(ActiveSlotOrder), 'descend');
 ActiveSlotOrder = ActiveSlotOrder(RankOfSlot_sinr);
 if isempty(ActiveSlotOrder)
 RankOfBF(1) = [];
 continue
 else
 ExecutiveBHST(BeamIdx, ActiveSlotOrder(1)) = 1;
 RankOfBF(1) = [];
 flagOfBHST(ActiveSlotOrder(1)) = flagOfBHST(ActiveSlotOrder(1)) + 1;
 end
 end

% idx_tmp = 0;
% BFrank_tmp = [];
% flag_ooo = 1;
% while(flag_ooo)
% NumOfLightBeamfoot_tmp = zeros(Num_slot,1);
% if isempty(BFrank_tmp)
% BFrank_tmp = BFrank;
% end
% idx_tmp = idx_tmp + 1;
% if idx_tmp == 1
% for idxOfSlot = 1 : Num_slot
% ExecutiveBHST(BFrank_tmp(idxOfSlot), idxOfSlot)= 1;
% end
% BFrank_tmp(1 : Num_slot) = [];
% else
% sinrLink = zeros(Num_slot, 1);
% beam_idx = BFrank_tmp(1);

% for idxOfSlot = 1 : Num_slot
% lightedBf = find(ExecutiveBHST(:, idxOfSlot)==1);
% lightedBf = [lightedBf; beam_idx];
% NumOfLightBeamfoot = length(lightedBf);
% NumOfLightBeamfoot_tmp(idxOfSlot) = NumOfLightBeamfoot - 1;
% PosOfBeam = zeros(NumOfLightBeamfoot, 2); % Illuminated beam position center triangular coordinates 
% for bidx = 1 : NumOfLightBeamfoot
% PosOfBeam(bidx, :) = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, lightedBf(bidx)).position; 
% end
% BeamPoint = zeros(NumOfLightBeamfoot, 2); % varphi(elevation, offset from x-axis),vartheta(direction, offset from xOy plane), antenna in zOy plane(right-handed)
% for j = 1 : NumOfLightBeamfoot
% [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
% interface.SatObj(idxOfSat).position, interface.SatObj(idxOfSat).nextpos, PosOfBeam(j, :), interface.height);
% BeamPoint(j,1) = outputPhi;
% BeamPoint(j,2) = outputTheta;
% end
% ExecutiveBHST(beam_idx, idxOfSlot) = 1;
% [~, sinrLink(idxOfSlot)] = CaculateR(...
% idxOfSat, idxOfSche, ...
% ExecutiveBHST(:, idxOfSlot),...
% beam_idx, BeamPoint, interface);
% ExecutiveBHST(beam_idx, idxOfSlot) = 0;
% end
% [~, selectedSlotRank] = sort(sinrLink, 'descend');
% for idx_ooo = 1 : Num_slot 
% if length(find(ExecutiveBHST(:, selectedSlotRank(idx_ooo))==1)) < NumOfServBeam
% if ExecutiveBHST(beam_idx, selectedSlotRank(idx_ooo)) == 0 
% ExecutiveBHST(beam_idx, selectedSlotRank(idx_ooo)) = 1;
% BFrank_tmp(1) = [];
% break
% else
% if idx_ooo ~= Num_slot
% continue
% else
% BFrank_tmp(1) = [];
% break
% end
% end
% end
% if idx_ooo == Num_slot
% flag_ooo = 0;
% break
% end
% end
% end
% if Debug == 1
% % zzz = 0;
% % for idx_qqq = 1 : Num_slot
% % zzz = zzz + length(find(ExecutiveBHST(:,idx_qqq)==1));
% % end
% fprintf(
% end 
% end
% for idxOfSlot = 1 : Num_slot
% selectedBF = zeros(NumOfServBeam, 1);
% for idxOfBeam = 1 : NumOfServBeam
% if idxOfBeam == 1
% Score = (Distance_R.^2).*tmp_RequiredTrafficOfBF;
% idxOfBF = find(Score == max(Score), 1);
% selectedBF(idxOfBeam) = idxOfBF;
% ExecutiveBHST(idxOfBF, idxOfSlot)= 1;
% tmp_RequiredTrafficOfBF(idxOfBF) = tmp_RequiredTrafficOfBF(idxOfBF) - standard_TransportedTrafficOfBF;
% else
% for idx = 1 : idxOfBeam-1
% if idx == 1
% tmp_Distance = Distance(:, selectedBF(idx));
% else
% tmp_Distance = tmp_Distance.*Distance(:, selectedBF(idx));
% end
% end

% idxOfBF = find(tmp_Distance == max(tmp_Distance), 1);
% selectedBF(idxOfBeam) = idxOfBF;
% ExecutiveBHST(idxOfBF, idxOfSlot)= 1;
% tmp_RequiredTrafficOfBF(idxOfBF) = tmp_RequiredTrafficOfBF(idxOfBF) - standard_TransportedTrafficOfBF;
% end
% end
% end

 TransportedTrafficOfBF = calculateTraffic(idxOfSat, idxOfSche, Num_slot, ExecutiveBHST, interface, Debug); % Calculate transported traffic for each beam position in current decision 
 
 for tmpk = 1 : NumOfBeamfoot
 usrs = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, tmpk).usrs;
 NofU = length(usrs);
 r_traffic = RequiredTraffic_in_Sat(usrs);
 [~, tmp_idx, ~] = intersect(UsrsIndex, usrs);
 for idx = 1 : NofU
 TransportedTraffic_in_Sat(tmp_idx(idx), idxOfSche) = sum(TransportedTrafficOfBF(tmpk)).*(r_traffic(idx)./sum(r_traffic));
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
 if Debug == 1
 fprintf('mSINR algorithm scheduling %d calculation completed\n', idxOfSche);
 end
 end
 TransportedTraffic(UsrsIndex, :) = TransportedTraffic_in_Sat;
 
 end
 interface.tmp_UsrsTransPort = TransportedTraffic;
end

%% Calculate throughput
function TransportedTrafficOfBF = calculateTraffic(idxOfSat, idxOfSche, Num_slot, ExecutiveBHST, interface, Debug)
 numOfbeamfoot = length(ExecutiveBHST(:,1));
 TransportedTrafficOfBF = zeros(numOfbeamfoot, 1);
 for idxOfSlot = 1 : Num_slot
 lightedBf = find(ExecutiveBHST(:, idxOfSlot)==1);
 NumOfLightBeamfoot = length(lightedBf);
 PosOfBeam = zeros(NumOfLightBeamfoot, 2); % Illuminated beam position center triangular coordinates 
 for bidx = 1 : NumOfLightBeamfoot
 PosOfBeam(bidx, :) = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, lightedBf(bidx)).position; 
 end
 BeamPoint = zeros(NumOfLightBeamfoot, 2); % varphi(elevation, offset from x-axis),vartheta(direction, offset from xOy plane), antenna in zOy plane(right-handed)
 for j = 1 : NumOfLightBeamfoot
 [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
 interface.SatObj(idxOfSat).position, interface.SatObj(idxOfSat).nextpos, PosOfBeam(j, :), interface.height);
 BeamPoint(j,1) = outputPhi;
 BeamPoint(j,2) = outputTheta;
 end
% NumOfExpressedGene = NumOfLightBeamfoot;
% ExpressedGene = LightBeamfoot;
 SINR_Gene = zeros(NumOfLightBeamfoot, 1);
 for tmpI = 1 : NumOfLightBeamfoot
% [SINR_Gene(tmpI), ~] = CaculateR(...
 [~, SINR_Gene(tmpI)] = CaculateR(...
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
%% Calculate SINR and SNR values for a beam position
function [SINR, SNR] = CaculateR(SatIdx, ScheIdx, Gene, i, BeamPoint, interface)
 % Interference received by the i-th beam position on the gene
 Pt = (10.^((interface.SatObj(SatIdx).Pt_dBm_serv)./10))./1e3./interface.numOfServbeam; % W
 UsrIdx = interface.tmpSat(SatIdx).beamfoot(ScheIdx, i).usrs;
 T_noise = interface.UsrsObj(UsrIdx(1)).T_noise;
 F_noise_dB = interface.UsrsObj(UsrIdx(1)).F_noise;
 F_noise = 10.^(F_noise_dB./10);
 N0_noise = 1.380649e-23*(T_noise + (F_noise-1)*300);

% BW
% T
% k
% N0 = k*T*BW;%noise
 Bandwidth = interface.BandOfLink*1e6;
 ExpressedGene = find(Gene == 1);
 % Calculate pointing angle of current beam position center 
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


) 
) 
) 
