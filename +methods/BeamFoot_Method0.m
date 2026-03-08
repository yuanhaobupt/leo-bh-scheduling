function BeamFoot_Method0(interface)
%Draw beam positions using density clustering method
%Improvement: Sort density of each point, then change MinPts until all points are partitioned

%Get some parameters
Radius = 6371.393e3;
%Calculate beam position radius
AngleOf3dB = interface.AngleOf3dB;% Antenna 3dB beamwidth
Rb = tools.getEarthLength(AngleOf3dB, interface.height)/2;

hOfDiscr = tools.LatLngCoordi2Length([0 0], [0 1], Radius)/interface.factorOfDiscr;% Height of discrete triangular rows
NofRaw = 2 * ceil(Rb/(2*hOfDiscr/sqrt(3))); % Number of discrete triangular rows occupied by one beam position

NumOfSat = length(interface.OrderOfServSatCur);% Number of satellites

referDist = 2 * Rb; % Reference distance

% Satellite antenna
Pt_satAll = interface.SatObj(1).Pt_dBm_serv; % Total transmit power of satellite antenna
Pt_satAll = (10.^(Pt_satAll/10))/1e3; % Unit is W
Pt_sat = Pt_satAll/interface.numOfServbeam;
% P = 30;
% freq = mean(controller.Communication.freqOfServ(2,:));% Frequency
freq1 = interface.Config.freqOfDownLink - interface.Config.BandOfLink/2;
heightOfsat = interface.Config.height;

% User antenna
% User receiving gain
type = 0;
% Total number of scheduling periods
sche = interface.ScheInShot; 

% Noise power
BWDown = interface.Config.BandOfLink; % Bandwidth, unit is Hz
T = 300;% Kelvin temperature, unit is K
k = 1.38e-23;% Boltzmann constant
% N0 = k*T*BWDown;% Thermal noise

%% Traverse by scheduling period
for idx = 1 : sche
%% Traverse by satellite
for i = 1 : NumOfSat
 % Satellite information
 satCurPos = interface.SatObj(i).position; % Current satellite sub-satellite point coordinates
 satCurnextPos = interface.SatObj(i).nextpos; % Next step coordinates of current satellite sub-satellite point
 % Get current satellite user information
 numOfUsrs = interface.SatObj(i).numOfusrs(idx); 
 UsrsOrder = interface.SatObj(i).servUsr(idx,:); % Satellite serving user IDs

 if numOfUsrs == 0
 interface.tmpSat(i).NumOfBeamFoot(idx) = 0;
 continue;
 end

 % Coordinates of users under this satellite
 UsrsPosition = zeros(numOfUsrs, 2);
 for ii = 1 : numOfUsrs
 curUser = interface.SatObj(i).servUsr(ii);
 tmp = find(interface.OrderOfSelectedUsrs == curUser);
 UsrsPosition(ii, :) = interface.UsrsObj(tmp).position; 
 end

 % Get a distance matrix between each user and other users, if distance exceeds referDist set to 0
 % Note: If considering beam deformation, then this adjacency relationship is determined by the angle between two users and satellite and the size of beam 3dB angle
 bfT = zeros(numOfUsrs, numOfUsrs);
 for s = 1 : numOfUsrs
 for q = 1 : s
 if s ~= q% Adjacency relationship of same user is set to 0
 deltaL = tools.LatLngCoordi2Length(UsrsPosition(s, :), UsrsPosition(q, :), Radius);
 if deltaL <= referDist % Adjacency criterion is radius, because beam position center coordinates are not adjusted
 bfT(s, q) = 1;
 bfT(q, s) = 1;
 end
 else
 bfT(s, q) = 0;
 end
 end
 end

 % Partitioning situation
 sorted = zeros(1, numOfUsrs);% Non-zero indicates already partitioned, specific number is the beam position ID assigned to
 beamId = 1;% Beam position ID

 % Pre-allocate memory
 centerPos = zeros(numOfUsrs,2);% Maximum number of beam positions is same as number of users
 cetrTri = zeros(1,numOfUsrs);
 orderOfcetr = zeros(numOfUsrs,3);% order and ifUp
 userInBeam = zeros(numOfUsrs,numOfUsrs-1);% User IDs within beam position, no maximum user count constraint anymore

 % Method execution starts below
 adjOfUser = sum(bfT');
 MinPts = max(adjOfUser);
 while true 
 % End condition: if every point has no neighbors
 if MinPts == 0
 break;
 end

 % Get core point IDs
 Pts = find(adjOfUser == MinPts);
 sortedList = find(sorted);
 Pts = setdiff(Pts,sortedList);% Remove already partitioned ones
 if isempty(Pts)
 MinPts = MinPts - 1;
 continue;
 end
 % Traverse core points
 for Pt = Pts
 if sorted(Pt)
 continue;
 end
 % First draw a circle with core point as center
 center = UsrsPosition(Pt,:);
 curUsrInBeam = Pt;
 % Get users in current beam position
 for uu = 1 : numOfUsrs
 tempD = tools.LatLngCoordi2Length(UsrsPosition(uu, :), center, Radius);
 if tempD <= Rb && sorted(uu)==0 && uu ~= Pt
 curUsrInBeam = [curUsrInBeam uu];
 end
 end
 % Get current Ci
 Ci = 0;
 % Calculate beam pointing direction
 [outputTheta, outputPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, center, heightOfsat);
 BeamPoint(1) = outputPhi;
 BeamPoint(2) = outputTheta;
 for uuu = 1 : length(curUsrInBeam)
 uu = curUsrInBeam(uuu);
 % Change power calculation method
 P = Pt_sat / length(curUsrInBeam);
 BW = BWDown/length(curUsrInBeam);
 f = freq1 + (uuu-1)*BW + BW/2;
 lambdaDown = 3e8/f;

 
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, UsrsPosition(uu, :), heightOfsat);
 G_sat = antenna.getSatAntennaServG([UsrTheta, UsrPhi], BeamPoint, f); % Antenna transmit gain
 % Calculate distance from current satellite to current user
 usrPosInDescartes = LngLat2Descartes(UsrsPosition(uu, :), 0);
 satPosInDescartes = LngLat2Descartes(satCurPos, heightOfsat);
 distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrPosInDescartes(3)).^2);
 % User antenna gain
 G_usr = antenna.getUsrAntennaServG(0, f, type); 
 % Calculate transmission rate (bandwidth may not be needed)
 N0 = k*T*BW;
 Ci = Ci + BW*log2(1 + (P * G_sat * G_usr * (lambdaDown.^2)/(4*pi*distance).^2)/N0);
 end
% Ci = Ci/length(curUsrInBeam);
 lastUsrInBeam = curUsrInBeam;
 

 % Change
 count=0;
 while true
 newCenter(1) = mean(UsrsPosition(curUsrInBeam,1));
 newCenter(2) = mean(UsrsPosition(curUsrInBeam,2));
 
 newCurUsrInBeam = [];
 
 % Get users in current beam position 
 for uu = 1 : numOfUsrs
 tempD = tools.LatLngCoordi2Length(UsrsPosition(uu, :), newCenter, Radius);
 if tempD <= Rb && sorted(uu) == 0
 newCurUsrInBeam = [newCurUsrInBeam uu];
 end
 end

 if isempty(newCurUsrInBeam)% If empty after change, don't keep (can it become empty??
 break;
 end
 
 % Get current Ci
 newCi = 0;
 % Calculate beam pointing direction
 [outputTheta, outputPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, newCenter, heightOfsat);
 BeamPoint(1) = outputPhi;
 BeamPoint(2) = outputTheta;
 for uuu = 1:length(newCurUsrInBeam)
 uu = newCurUsrInBeam(uuu);
 % Change power calculation method
 P = Pt_sat / length(newCurUsrInBeam);
 BW = BWDown/length(newCurUsrInBeam);
 f = freq1 + (uuu-1)*BW + BW/2;
 lambdaDown = 3e8/f;
 
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, UsrsPosition(uu, :), heightOfsat);
 G_sat = antenna.getSatAntennaServG([UsrTheta, UsrPhi], BeamPoint, f); % Antenna transmit gain
 % Calculate distance from current satellite to current user
 usrPosInDescartes = LngLat2Descartes(UsrsPosition(uu, :), 0);
 satPosInDescartes = LngLat2Descartes(satCurPos, heightOfsat);
 distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrPosInDescartes(3)).^2);
 % User antenna gain
 G_usr = antenna.getUsrAntennaServG(0, f, type);
 % Calculate transmission rate (bandwidth may not be needed)
 N0 = k*T*BW;
 newCi = newCi + BW*log2(1 + (P * G_sat * G_usr * (lambdaDown.^2)/(4*pi*distance).^2)/N0);
 end
% newCi = newCi/length(newCurUsrInBeam);
 
 % Enter judgment
 if newCi > Ci
 % If there is improvement, keep the new one
 Ci = newCi;
 curUsrInBeam = newCurUsrInBeam;
 center = newCenter;
 else% If no improvement, continue
% if isequal(newCurUsrInBeam,lastUsrInBeam)
 break;
% else
% count = count + 1;
% end
% %
% if count == 10
% break;
% end
 end
 lastUsrInBeam = newCurUsrInBeam;
 
 end
 % Finished finding beam position for current pt, save partitioned
 sorted(curUsrInBeam) = beamId;

 userInBeam(beamId,1:length(curUsrInBeam)) = UsrsOrder(curUsrInBeam);
 centerPos(beamId,:) = center;
 [orderOfcetr(beamId,1),orderOfcetr(beamId,2), orderOfcetr(beamId,3)] = tools.findPointXY(interface, center(2), center(1));
 cetrTri(beamId) = simSatSysClass.tools.ij2Seq(orderOfcetr(beamId,1),orderOfcetr(beamId,2), interface.rowNum, interface.colNum); 

 beamId = beamId + 1;
 % Update bfT
 for uu = curUsrInBeam
 temp = setdiff(curUsrInBeam,uu);
 bfT(uu,temp) = 0;
 end
 end
 MinPts = MinPts - 1;
 end

% % Unpartitioned ones are in a beam position alone
 left = find(sorted == 0);
 for uu = left
 userInBeam(beamId,1) = UsrsOrder(uu); 

 centerPos(beamId,1) = (UsrsPosition(uu,1));
 centerPos(beamId,2) = (UsrsPosition(uu,2));

 [orderOfcetr(beamId,1),orderOfcetr(beamId,2), orderOfcetr(beamId,3)] = tools.findPointXY(interface, centerPos(beamId,2),centerPos(beamId,1));
 cetrTri(beamId) = simSatSysClass.tools.ij2Seq(orderOfcetr(beamId,1),orderOfcetr(beamId,2), interface.rowNum, interface.colNum);
 
 beamId = beamId + 1;
 end

 %% Data storage below
 if ~isempty(cetrTri)
 % Calculate total number of beam positions
 if cetrTri(length(cetrTri)) ~= 0 
 NumOfBeam = length(cetrTri(:,1));
 else
 NumOfBeam = min(find(cetrTri == 0)) - 1;
 end 
 interface.tmpSat(i).NumOfBeamFoot(idx) = NumOfBeam;

 for j = 1 : NumOfBeam
 interface.tmpSat(i).beamfoot(idx, j).position = centerPos(j,:);
 usr = userInBeam(j,userInBeam(j,:)~=0);
 interface.tmpSat(i).beamfoot(idx, j).usrs = usr;
 
 [orderOfcetr(1),orderOfcetr(2), orderOfcetr(3)] = tools.findPointXY(interface, centerPos(j,2),centerPos(j,1));
 interface.tmpSat(i).beamfoot(idx, j).servTri = ...
 simSatSysClass.tools.setBeamFoot(orderOfcetr(1:2), orderOfcetr(3), NofRaw, interface.rowNum, interface.colNum); 
 
 end

 else
 NumOfBeam = 0;
 interface.tmpSat(i).NumOfBeamFoot(idx) = NumOfBeam;
 % No beam positions
 
 end 
 fprintf('Scheduling %d satellite %d beam positions formed\n',idx,i); 
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
%% 
function G = getGofUsr(Gmax_dBi, l, lambda, theta)
 F = antenna.SymmetricalDipole(l, lambda, theta);
 G = (10.^(Gmax_dBi/10))*(F.^2);
end