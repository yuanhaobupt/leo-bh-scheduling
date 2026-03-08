function PowerAllocation_Method(interface)
% This function allocates power among beams using water-filling based on BHST
bhLength = interface.SlotInSche; % Length of one beam hopping scheduling
heightOfsat = interface.height;% Satellite orbit height
BW = interface.BandOfLink*1e6; % Bandwidth, unit is Hz
freqOfDownLink = interface.freqOfDownLink; % (Hz) Satellite downlink center frequency, full frequency reuse between beams
startOfBand = freqOfDownLink - BW / 2;% (Hz) Satellite downlink start frequency
K = 1.38e-23; % Boltzmann constant
Ta_usr = interface.Config.Usr_T_noise;
F_usr = interface.Config.Usr_F_noise;
for satIdx = 1 : length(interface.OrderOfServSatCur)
 % Satellite position
 curSatPos = interface.SatObj(satIdx).position;
 satPosInDescartes = LngLat2Descartes(curSatPos, heightOfsat);
 curSatNextPos = interface.SatObj(satIdx).nextpos;
 % Calculate satellite total power
 Pt_sat = interface.SatObj(satIdx).Pt_dBm_serv; % Total transmit power of satellite antenna
 Pt_sat = (10.^(Pt_sat/10))/1e3; % Unit is W

 BHST = interface.tmpSat(satIdx).BHST;
 totalSlots = length(BHST(1,:));
 maxBeam = length(BHST(:,1));

 PtTable = zeros(maxBeam, totalSlots);

 for slotIdx = 1 : totalSlots
 % Current scheduling period ID
 scheIdx = ceil(slotIdx / bhLength);
 % Check which beam positions are illuminated
 allBeamfoot = (BHST(: , slotIdx) ~= 0);
 allBeamfoot = BHST(allBeamfoot , slotIdx);
 NumOfLightBeamfoot = length(allBeamfoot);
 if ~isempty(allBeamfoot)
 h = zeros(1, NumOfLightBeamfoot);
 lightPower = Pt_sat / NumOfLightBeamfoot;

 % Calculate all pointing directions
 PosOfBeam = zeros(NumOfLightBeamfoot, 2); % Illuminated beam position center triangle coordinates 
 for bidx = 1 : NumOfLightBeamfoot
 PosOfBeam(bidx, :) = interface.tmpSat(satIdx).beamfoot(scheIdx, allBeamfoot(bidx)).position; 
 end

 BeamPoint = zeros(NumOfLightBeamfoot, 2); % varphi(elevation, offset from x-axis),vartheta(direction, offset from xOy plane), antenna in zOy plane (right-handed)
 for j = 1 : NumOfLightBeamfoot
 [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
 curSatPos, curSatNextPos, PosOfBeam(j, :), heightOfsat);
 BeamPoint(j,1) = outputPhi;
 BeamPoint(j,2) = outputTheta;
 end

 for footIdx = 1 : length(allBeamfoot)
 curFoot = allBeamfoot(footIdx);
 % Get users in current beam position
 orderOfUsrs = interface.tmpSat(satIdx).beamfoot(scheIdx, curFoot).usrs;
 % Then calculate h for these beam positions
 curH = 0;
 for usrIdx = 1 : length(orderOfUsrs)
 curUser = orderOfUsrs(usrIdx);

 tmpBand = interface.UsrsObj(find(interface.OrderOfSelectedUsrs == curUser)).Band(slotIdx, :);

 [~, thisH] = CaculateR(satIdx, scheIdx, slotIdx, curUser, curFoot, allBeamfoot, lightPower, BeamPoint, tmpBand, interface);

 curH = curH + thisH; 
 end
 h(footIdx) = curH / length(orderOfUsrs);
 end

% for footIdx = 1 : length(allBeamfoot)
% curFoot = allBeamfoot(footIdx);
% orderOfUsrs = interface.tmpSat(satIdx).beamfoot(scheIdx, curFoot).usrs;
% BeamPoint = zeros(1,2);
% curBeamPos = interface.tmpSat(satIdx).beamfoot(scheIdx, curFoot).position;
% [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
% curSatPos, curSatNextPos, curBeamPos, heightOfsat);
% BeamPoint(1) = outputPhi;
% BeamPoint(2) = outputTheta;
% curH = 0;
% subBandWidth
% for usrIdx = 1 : length(orderOfUsrs)
% curUser = orderOfUsrs(usrIdx);
% curUserPos = interface.UsrsObj(curUser).position;
% usrPosInDescartes = LngLat2Descartes(curUserPos, 0);
% distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
% (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
% (satPosInDescartes(3)-usrPosInDescartes(3)).^2);

% tmpBand = interface.UsrsObj(curUser).Band(slotIdx, :);
% % tmpBand = [startOfBand + subBandWidth * (usrIdx - 1), startOfBand + subBandWidth * usrIdx];
% tmpFc = mean(tmpBand(1,:));

% [UsrTheta, UsrPhi]
% Gsat = antenna.getSatAntennaServG([UsrTheta, UsrPhi], [BeamPoint(2), BeamPoint(1)], tmpFc);
% Gusr = antenna.getUsrAntennaServG(0, tmpFc, false); 

% tempLambda = 3e8/tmpFc;
% N_noise_usr = (tmpBand(2) - tmpBand(1))*K*(Ta_usr+(F_usr-1)*300); 
% curH = curH + Gsat * Gusr * (tempLambda/(4*pi*distance))^2 / N_noise_usr;% Gt*Gr*(lambda/(4*pi*d))^2/N 
% end
% h(footIdx) = curH / length(orderOfUsrs);
% end
%% Water-filling
function [palloc_matrix, allocPercentage] = water_filling1(loss, P)
% loss, Kx1 vector, i.e., L
% P, Total power to allocate
% A, Diagonal matrix, i.e., weight alpha
% palloc_matrix, Diagonal matrix, power allocation result, trace equals P

	K = length(loss); % Number of users

 w = log(2) + zeros(1, K);
 
% 	w = diag(A); % width, step width
	h = loss./w; % height, step height
% h = loss;
	
 allo_set = 1:K; % Initialize index set of users to water-fill
 level = (P+sum(loss(allo_set>0)))/sum(w(allo_set>0)); % "Virtual" water level
 [h_hat, k_hat] = max(h(allo_set>0));
 
 while h_hat>=level
 
 allo_set(k_hat) = -1;
 level = (P+sum(loss(allo_set>0)))/sum(w(allo_set>0)); % "Virtual" water level
 [h_hat, k_hat] = max(h(allo_set>0));
 
 end
 
 palloc_matrix = zeros(K);
 for k = 1:K
 if allo_set(k)>0
 palloc_matrix(k, k) = (level - h(k))*w(k);
 end
 end

 % I want to get the ratio
 allocPercentage = zeros(1, K);
 for k = 1 : K
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end
 
end

function [palloc_matrix, allocPercentage] = water_filling2(loss, P)
% loss, Kx1 vector, i.e., L
% P, Total power to allocate
% A, Diagonal matrix, i.e., weight alpha
% palloc_matrix, Diagonal matrix, power allocation result, trace equals P

	K = length(loss);
 
	w = 1/log(2) + zeros(1, K); % Step width
	h = loss./w; % Step height
	
	[h_sorted, h_idx] = sort(h); % Sort in ascending order by step height
	w_sorted = w(h_idx);
 
 % Linear search, determine the last step that needs water-filling from back to front
 for i = K:-1:1
 
 w_tmp = sum(w_sorted(1:i-1)); % Sum of widths of all steps before the current step
 h_tmp = h_sorted(i); % Height of the current step
 
 % If there is still water remaining after filling steps before the current step to the same height
 if w_tmp*h_tmp-sum(h_sorted(1:i-1).*w_sorted(1:i-1))<P
 idx = i;
 break;
 end
 
 end
 
 w_filled = sum(w_sorted(1:idx)); % Total width of all steps that need water-filling
 h_filled = (P+sum(h_sorted(1:idx).*w_sorted(1:idx)))/w_filled; % Final water level
	
	p_allocate = zeros(1, K);
 p_allocate(1:idx) = w_sorted(1:idx).*(h_filled-h_sorted(1:idx));
	
 % Restore original order
 [~, back_idx] = sort(h_idx);
 p_allocate = p_allocate(back_idx);
 
 palloc_matrix = diag(p_allocate);

 % I want to get the ratio
 allocPercentage = zeros(1, K);
 for k = 1 : K
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end
 
end

function [palloc_matrix, allocPercentage] = water_filling3(loss, P)
 %% Initialization
 N= length(loss) ; % Number of channels
 [noise_sorted,index]=sort(loss); 
 for p=length(noise_sorted):-1:1 
 T_P=(P+sum(noise_sorted(1:p)))/p; 
 Input_Power=T_P-noise_sorted; 
 Pt=Input_Power(1:p); 
 if(Pt(:)>=0)
 break 
 end 
 end 
 power_alloc=zeros(1,N); 
 power_alloc(index(1:p))=Pt; % Allocated power
 
 palloc_matrix = diag(power_alloc);

 % I want to get the ratio
 allocPercentage = zeros(1, N);
 for k = 1 : N
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end

end

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

%% Calculate SINR value and h value
function [SINR, h] = CaculateR(SatIdx, ScheIdx, slotIdx, userIdx, curFoot, lightFoot, lightPower, BeamPoint, thisBand, interface)
% Input: SatIdx satellite ID; ScheIdx scheduling period ID; userIdx current user ID; footIdx current beam position ID;
% lightFoot all illuminated beam position IDs; lightPower power allocation IDs for all illuminated beam positions; BeamPoint pointing direction;
% thisBand current frequency band
 userIdx = find(interface.OrderOfSelectedUsrs == userIdx);
 
 Usrs = interface.tmpSat(SatIdx).beamfoot(ScheIdx, curFoot).usrs;% Users in beam position
 footIdx = find(lightFoot == curFoot);
 Pt = interface.UsrsObj(userIdx).PowerPercent(slotIdx) * lightPower; % Power allocated to each user

 T_noise = interface.UsrsObj(1).T_noise;
 F_noise_dB = interface.UsrsObj(1).F_noise;
 F_noise = 10.^(F_noise_dB./10);
 N0_noise = 1.380649e-23*(T_noise + (F_noise-1)*300);

 Bandwidth = thisBand(2) - thisBand(1);
 fc = mean(thisBand);

 % Calculate pointing angle of current user 
 userCurPos = interface.UsrsObj(userIdx).position; % Current user coordinates 
 satCurPos = interface.SatObj(SatIdx).position; % Current satellite sub-satellite point coordinates
 satCurnextPos = interface.SatObj(SatIdx).nextpos; % Next step coordinates of current satellite sub-satellite point
 [userTheta, userPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, userCurPos, interface.height);% Calculate azimuth and elevation angles
 % Calculate user receiving gain
 G_usrDown = antenna.getUsrAntennaServG(0, fc, false);
 % Calculate distance from current satellite to current user
 usrCurPos = interface.UsrsObj(userIdx).position;
 usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
 satPosInDescartes = LngLat2Descartes(satCurPos, interface.height);
 distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrPosInDescartes(3)).^2); 
 InterfInSatDown = 0;

 % Traverse interfering beam positions, in the order of allocation, calculate interference
 for bfIdx = 1 : length(lightFoot)
 OrderOfbeam = lightFoot(bfIdx);% Actual ID of beam position
 if OrderOfbeam == curFoot % Skip current beam position
 continue;
 else
 % User IDs in interfering beam position
 interfUsrs = interface.tmpSat(SatIdx).beamfoot(ScheIdx, OrderOfbeam).usrs;
 % Power allocated to interfering beam position
 interfBeamPower = lightPower;
 poiBeta = BeamPoint(bfIdx,1);
 poiAlpha = BeamPoint(bfIdx,2);
 AgleOfInv = [userTheta, userPhi];
 AgleOfPoi = [poiAlpha, poiBeta];
 for interfUsrIdx = 1 : length(interfUsrs) % Traverse interference from users in this beam position
 % Get power and frequency band of this interfering user
 thisInterfUser = interfUsrs(interfUsrIdx);
 thisInterfUser = find(interface.OrderOfSelectedUsrs == thisInterfUser);
 thisInterfUser_power = interface.UsrsObj(thisInterfUser).PowerPercent(slotIdx) * interfBeamPower;
 thisInterfUser_band = interface.UsrsObj(thisInterfUser).Band(slotIdx, :);

 % Determine if there is frequency band overlap
 overlap = range_intersection(thisBand, thisInterfUser_band);% Note: check if unit of f is Hz
 if length(overlap) == 2
 lambdaDown = 3e8/mean(overlap);
 G_sat_interfDown = antenna.getSatAntennaServG(AgleOfInv, AgleOfPoi, mean(overlap));
 InterfInSatDown = InterfInSatDown + ...
 thisInterfUser_power * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 end

 end
 end

 end
 
 end
 fprintf('Satellite %d beam intra-resource scheduling completed %.1f%%\n',satIdx,slotIdx * 100 /totalSlots);
 end
 
 end
 fprintf('Satellite %d beam resource scheduling completed %.0f%%\n',satIdx,slotIdx * 100 /totalSlots);
 end

 interface.tmpSat(satIdx).Pt_Antenna = PtTable;

 

end



end


%% Water-filling
function [palloc_matrix, allocPercentage] = water_filling1(loss, P)
% loss, Kx1 vector, i.e., L
% P, Total power to allocate
% A, Diagonal matrix, i.e., weight alpha
% palloc_matrix, Diagonal matrix, power allocation result, trace equals P

	K = length(loss); % Number of users

 w = log(2) + zeros(1, K);
 
% 	w = diag(A); % width, step width
	h = loss./w; % height, step height
% h = loss;
	
 allo_set = 1:K; % Initialize the set of user indices for water-filling
 level = (P+sum(loss(allo_set>0)))/sum(w(allo_set>0)); % "Virtual" water level
 [h_hat, k_hat] = max(h(allo_set>0));
 
 while h_hat>=level
 
 allo_set(k_hat) = -1;
 level = (P+sum(loss(allo_set>0)))/sum(w(allo_set>0)); % “”
 [h_hat, k_hat] = max(h(allo_set>0));
 
 end
 
 palloc_matrix = zeros(K);
 for k = 1:K
 if allo_set(k)>0
 palloc_matrix(k, k) = (level - h(k))*w(k);
 end
 end

 % I want to get the ratio
 allocPercentage = zeros(1, K);
 for k = 1 : K
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end
 
end

function [palloc_matrix, allocPercentage] = water_filling2(loss, P)
% loss, Kx1 vector, i.e., L
% P, Total power to allocate
% A, Diagonal matrix, i.e., weight alpha
% palloc_matrix, Diagonal matrix, power allocation result, trace equals P

	K = length(loss);
 
	w = 1/log(2) + zeros(1, K); % Step width
	h = loss./w; % Step height
	
	[h_sorted, h_idx] = sort(h); % Sort in ascending order by step height
	w_sorted = w(h_idx);
 
 % Linear search, determine the last step that needs water-filling from back to front
 for i = K:-1:1
 
 w_tmp = sum(w_sorted(1:i-1)); % Sum of widths of all steps before the current step
 h_tmp = h_sorted(i); % Height of the current step
 
 % If there is still water remaining after filling steps before the current step to the same height
 if w_tmp*h_tmp-sum(h_sorted(1:i-1).*w_sorted(1:i-1))<P
 idx = i;
 break;
 end
 
 end
 
 w_filled = sum(w_sorted(1:idx)); % Total width of all steps that need water-filling
 h_filled = (P+sum(h_sorted(1:idx).*w_sorted(1:idx)))/w_filled; % Final water level
	
	p_allocate = zeros(1, K);
 p_allocate(1:idx) = w_sorted(1:idx).*(h_filled-h_sorted(1:idx));
	
 % Restore original order
 [~, back_idx] = sort(h_idx);
 p_allocate = p_allocate(back_idx);
 
 palloc_matrix = diag(p_allocate);

 % I want to get the ratio
 allocPercentage = zeros(1, K);
 for k = 1 : K
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end
 
end

function [palloc_matrix, allocPercentage] = water_filling3(loss, P)
 %% Initialization
 N= length(loss) ; % Number of channels
 [noise_sorted,index]=sort(loss); 
 for p=length(noise_sorted):-1:1 
 T_P=(P+sum(noise_sorted(1:p)))/p; 
 Input_Power=T_P-noise_sorted; 
 Pt=Input_Power(1:p); 
 if(Pt(:)>=0)
 break 
 end 
 end 
 power_alloc=zeros(1,N); 
 power_alloc(index(1:p))=Pt; % Allocated power
 
 palloc_matrix = diag(power_alloc);

 % I want to get the ratio
 allocPercentage = zeros(1, N);
 for k = 1 : N
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end

end

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

%% Calculate SINR value and h value
function [SINR, h] = CaculateR(SatIdx, ScheIdx, slotIdx, userIdx, curFoot, lightFoot, lightPower, BeamPoint, thisBand, interface)
% Input: SatIdx satellite ID; ScheIdx scheduling period ID; userIdx current user ID; footIdx current beam position ID;
% lightFoot all illuminated beam position IDs; lightPower power allocation IDs for all illuminated beam positions; BeamPoint pointing direction;
% thisBand current frequency band
 userIdx = find(interface.OrderOfSelectedUsrs == userIdx);
 
 Usrs = interface.tmpSat(SatIdx).beamfoot(ScheIdx, curFoot).usrs;% Users in beam position
 footIdx = find(lightFoot == curFoot);
 Pt = interface.UsrsObj(userIdx).PowerPercent(slotIdx) * lightPower; % Power allocated to each user

 T_noise = interface.UsrsObj(1).T_noise;
 F_noise_dB = interface.UsrsObj(1).F_noise;
 F_noise = 10.^(F_noise_dB./10);
 N0_noise = 1.380649e-23*(T_noise + (F_noise-1)*300);

 Bandwidth = thisBand(2) - thisBand(1);
 fc = mean(thisBand);

 % Calculate pointing angle of current user 
 userCurPos = interface.UsrsObj(userIdx).position; % Current user coordinates 
 satCurPos = interface.SatObj(SatIdx).position; % Current satellite sub-satellite point coordinates
 satCurnextPos = interface.SatObj(SatIdx).nextpos; % Next step coordinates of current satellite sub-satellite point
 [userTheta, userPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, userCurPos, interface.height);% Calculate azimuth and elevation angles
 % Calculate user receiving gain
 G_usrDown = antenna.getUsrAntennaServG(0, fc, false);
 % Calculate distance from current satellite to current user
 usrCurPos = interface.UsrsObj(userIdx).position;
 usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
 satPosInDescartes = LngLat2Descartes(satCurPos, interface.height);
 distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrPosInDescartes(3)).^2); 
 InterfInSatDown = 0;

 % Traverse interfering beam positions, in the order of allocation, calculate interference
 for bfIdx = 1 : length(lightFoot)
 OrderOfbeam = lightFoot(bfIdx);% Actual ID of beam position
 if OrderOfbeam == curFoot % Skip current beam position
 continue;
 else
 % User IDs in interfering beam position
 interfUsrs = interface.tmpSat(SatIdx).beamfoot(ScheIdx, OrderOfbeam).usrs;
 % Power allocated to interfering beam position
 interfBeamPower = lightPower;
 poiBeta = BeamPoint(bfIdx,1);
 poiAlpha = BeamPoint(bfIdx,2);
 AgleOfInv = [userTheta, userPhi];
 AgleOfPoi = [poiAlpha, poiBeta];
 for interfUsrIdx = 1 : length(interfUsrs) % Traverse interference from users in this beam position
 % Get power and frequency band of this interfering user
 thisInterfUser = interfUsrs(interfUsrIdx);
 thisInterfUser = find(interface.OrderOfSelectedUsrs == thisInterfUser);
 thisInterfUser_power = interface.UsrsObj(thisInterfUser).PowerPercent(slotIdx) * interfBeamPower;
 thisInterfUser_band = interface.UsrsObj(thisInterfUser).Band(slotIdx, :);

 % Determine if there is frequency band overlap
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
 SINR = Carrier_down./(InterfInSatDown + Bandwidth*N0_noise);
 h = SINR/Pt;
% SNR = Carrier_down./(Bandwidth*N0_noise);
end

%% 
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


