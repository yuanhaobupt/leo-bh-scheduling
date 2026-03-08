function BPAllocation_Average(interface)
% This function allocates frequency band and power to users within beam positions, proposed algorithm

%% Get data
OrderOfServSatCur = interface.OrderOfServSatCur; % List of serving satellites
NumOfServSatCur = length(OrderOfServSatCur); % Number of serving satellites
NumOfSche = interface.ScheInShot; % Number of scheduling periods per snapshot
Num_slot = interface.SlotInSche; % Number of slots per scheduling period
BW = interface.BandOfLink*1e6; % Bandwidth, unit is Hz
freqOfDownLink = interface.freqOfDownLink; % (Hz) Satellite downlink center frequency
startOfBand = freqOfDownLink - BW / 2;% (Hz) Satellite downlink start frequency
heightOfsat = interface.height;% Satellite orbit height
maxPower = 10^(interface.Pt_dBm_serv/10)/1000/interface.numOfServbeam;% Total power per beam, unit is w
K = 1.38e-23; % Boltzmann constant
Ta_usr = interface.Config.Usr_T_noise;
F_usr = interface.Config.Usr_F_noise;
% Do we need to consider that each beam's power is not average?
% If considered, it's also a convex optimization problem, can also use Lagrangian + water-filling, whether to consider can be two curve results
%% Traverse
for SatIdx = 1 : NumOfServSatCur % Traverse satellites
 
 BHST = interface.tmpSat(SatIdx).BHST;
 
 NumOfSlotPerShot = length(BHST(1,:));

 for slotIdx = 1 : NumOfSlotPerShot %Traversetime slot
 scheIdx = ceil(slotIdx / Num_slot);

 notzero = BHST(:, slotIdx) ~= 0;
 LightBeamfoot = BHST(notzero, slotIdx);
 
 for footIdx = 1 : length(LightBeamfoot)
 curFoot = LightBeamfoot(footIdx);

 orderOfUsrs = interface.tmpSat(SatIdx).beamfoot(scheIdx, curFoot).usrs;
 numOfUserInFoot = length(orderOfUsrs);
 subBandWidth = BW/numOfUserInFoot;% each 
 if numOfUserInFoot == 1
 % If only one user, no need to be complicated
 tmp = find(interface.OrderOfSelectedUsrs == orderOfUsrs);
 interface.UsrsObj(tmp).Band(slotIdx, :) = [startOfBand, startOfBand + BW];
 interface.UsrsObj(tmp).BandWidth(slotIdx) = BW;
 interface.UsrsObj(tmp).PowerPercent(slotIdx) = 1;
 else 
 % Calculate user matrix
 n = numOfUserInFoot;% Matrix dimension
% HungMat = zeros(n, n);
% for i = 1 : n % user
% curUser = orderOfUsrs(i);
% for j = 1 : n % band
% % Calculateaward
% tmpBand = [startOfBand + subBandWidth * (j - 1), startOfBand + subBandWidth * j];
% [SINR, ~] = CaculateR(SatIdx, scheIdx, slotIdx, curUser, curFoot, LightBeamfoot, LightPower, BeamPoint, tmpBand, interface, 0);
% HungMat(i,j) = SINR;
% end
% end
% NewHungMat = max(max(HungMat)) - HungMat;
% [assignment,~] = munkres(NewHungMat);

 assignment = randperm(n , n);
 % When
 allocBand = zeros(n,2);
 for i = 1 : n
 res = assignment(i);
 allocBand(i, 1) = startOfBand + (res - 1) * subBandWidth;
 allocBand(i, 2) = startOfBand + res * subBandWidth; 
 end

 for i = 1 : n
 % res = assignment(i);
 tmp = find(interface.OrderOfSelectedUsrs == orderOfUsrs(i));
 interface.UsrsObj(tmp).Band(slotIdx, :) = [allocBand(i,1), allocBand(i,2)];
 interface.UsrsObj(tmp).BandWidth(slotIdx) = allocBand(i,2) - allocBand(i,1);
 end


 %% Allocate power: average
 allocPercentage = 1 / n;
 % Store results
 for i = 1 : n
 tmp = find(interface.OrderOfSelectedUsrs == orderOfUsrs(i));
 interface.UsrsObj(tmp).PowerPercent(slotIdx) = allocPercentage;
 end
 

 end
 end
 

 fprintf('Satellite %d beam intra-resource scheduling completed %.1f%%\n',SatIdx,slotIdx * 100 /NumOfSlotPerShot);
 end
 
end
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


