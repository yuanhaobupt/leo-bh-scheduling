function DataObj = calcuInterference(self, DataObj, IdxOfStep, MC_idx)
%CALCUINTERFERENCE Calculate interference
 ifDebug = self.ifDebug;

 NumOfSlotPerShot = self.slotInShot;
 NumOfSlotPerSche = self.subFInSche * self.slotInSubF;
 NumOfShot = length(self.SatPosition(1,:,1)) - 1; % Total number of simulation snapshots (last snapshot not calculated)

 NumOfSat = length(self.OrderOfServSatCur);
 NumOfInvesUsrs = self.numOfUsrs_inves;
 
 heightOfsat = self.Config.height;
 lightVelocity = self.vOfray;
 scenario=self.Config.scenario;
 % Downlink and uplink frequency bands
 freqOfDownLink = self.Config.freqOfDownLink;
 freqOfUpLink = self.Config.freqOfUpLink;
 Band = self.Config.BandOfLink; % Bandwidth
 UsrAntennaConfig = antenna.initialUsrAntenna();
 ifVSAT = UsrAntennaConfig.ifVSAT;
 IfRain=0;
 %% Traverse all algorithms
 for MethodIdx = 1 : self.numOfMethods_BeamGenerate * self.numOfMethods_BeamHopping

 %% Traverse all time slots
 for slotIdx = 1 : NumOfSlotPerShot
 %% Get current time slot satellite beam pointing
 self.getBeamPoint(slotIdx,MethodIdx);
 % self.SatObj(SatIdx).BeamPoint first NumOfLightBeamfoot are service beams, last NumOfLightSig are signaling beams
 %% Traverse all satellites
 dpIdx = ceil(slotIdx/NumOfSlotPerSche); % Which scheduling period
 for SatIdx = 1 : NumOfSat % Traverse satellites
 servUsr = self.SatObj(SatIdx).servUsr(dpIdx, self.SatObj(SatIdx).servUsr(dpIdx,:)~=0);
 tmpNo = find(servUsr <= NumOfInvesUsrs);
 UsrsOfSatCur = self.SatObj(SatIdx).servUsr(dpIdx, tmpNo); % Current set of users in investigation area under satellite
 NumOfUsrs = length(tmpNo); % Number of users under satellite

 Pt_SAT_dBm_serv = self.SatObj(SatIdx).Pt_dBm_serv;
 %%%%%%%%%%%%%%%%% Service beam power equal distribution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 Pt_SAT_serv = (10.^(Pt_SAT_dBm_serv/10))/1e3/self.Config.numOfServbeam; % W
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 if self.Config.numOfSigbeam > 0
 Pt_SAT_dBm_signal = self.SatObj(SatIdx).Pt_dBm_signal;
 Pt_SAT_signal = (10.^(Pt_SAT_dBm_signal/10))/1e3/self.Config.numOfSigbeam; % W
 end
 LightBeamfoot = self.SatObj(SatIdx).LightBeamfoot; % Currently lit beam footprint sequence numbers
% if MethodIdx == 2
% 1;
% end
 %% Traverse users under satellite
 for UsrIdx = 1 : NumOfUsrs % Traverse users
 UsrOrderCur = UsrsOfSatCur(UsrIdx); % WhenuserID/number
% BeamfootOrderOfUsrCur
 BeamfootOrderOfUsrCur = self.Usr2SatCur(UsrOrderCur, 1+ceil(MethodIdx/self.numOfMethods_BeamHopping), dpIdx); % Whenuserbeam position 
 Pt_Usr_dBm = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).Pt_dBm;
 Pt_Usr = (10.^(Pt_Usr_dBm/10))/1e3; % W

 InterfInSatDown = 0; % Intra-satellite downlink interference
 InterfWithSatDown = 0; % Inter-satellite downlink interference
 InterfInSatUp = 0; % Intra-satellite uplink interference
 InterfWithSatUp = 0; % Inter-satellite uplink interference
 % If Ka band, consider rain probability
 if freqOfDownLink>20e9
 ProbaofRain=0.4;
 probability=rand();
 if probability>ProbaofRain
 IfRain=1;
 IfMultiBandWidth=1;
 else
 IfRain=0;
 IfMultiBandWidth=0;
 end
 else
 IfMultiBandWidth=0;
 end
 % If raining then multi-band access, Ka band switches to S band
 if IfMultiBandWidth==1
 Band= 40e6; % (Hz) Carrier bandwidth
 freqOfDownLink = 2185e6; % (Hz) Satellite downlink center frequency
 freqOfUpLink = 1995e6; % (Hz) Satellite uplink center frequency
 end
 %% Determine if user is lit in current frame
 IdxInLightBeamfoot = find(LightBeamfoot == BeamfootOrderOfUsrCur);
 %% If lit, calculate interference
 if ~isempty(IdxInLightBeamfoot)
 % Calculate current user's pointing angle 
 usrCurPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).position; % Current user coordinates
 satCurPos = self.SatObj(SatIdx).position; % Current satellite sub-satellite point coordinates
 satCurnextPos = self.SatObj(SatIdx).nextpos; % Current satellite sub-satellite point next step coordinates
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrCurPos, heightOfsat);% Calculate azimuth and elevation angles
 
 % Calculate user receive gain
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usrDown = antenna.getUsrAntennaServG(tmp_angle, freqOfDownLink, false);
 else
 G_usrDown = antenna.getUsrAntennaServG(0, freqOfDownLink, false);
 end
 
 % Calculate distance from current satellite to current user
 usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
 satPosInDescartes = LngLat2Descartes(satCurPos, heightOfsat);
 distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrPosInDescartes(3)).^2); 

 %% Intra-satellite interference
 % Traverse all downlink interfering beam footprints
 interfLightBeamfoot = LightBeamfoot(LightBeamfoot~=BeamfootOrderOfUsrCur); % Set of interfering beam footprint sequence numbers
 NumOfInterfInSat = length(interfLightBeamfoot); % Number of interfering beam footprints
 interfUsrsOfSatCur = []; % Set of uplink interfering user sequence numbers

 %% Calculate downlink interference
 if ~isempty(self.SatObj(SatIdx).LightSig) 
 % If signaling beams exist 
 tmpOrderOfSig = self.SatObj(SatIdx).LightSig;
 % Calculate service beam footprint interference
 for interfIdx = 1 : NumOfInterfInSat 
 % Calculate
 tmpOrderOfbeam = find(LightBeamfoot == interfLightBeamfoot(interfIdx));
 G_sat_interfDown = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, tmpOrderOfbeam, freqOfDownLink); % transmitgain
								PL1_down= channel.PL_Sat_Ground(distance,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 InterfInSatDown = InterfInSatDown + ...
 Pt_SAT_serv * G_sat_interfDown * G_usrDown * (10^(-0.1*PL1_down));
 % Calculate all uplink interfering users
 if ~isempty(self.SatObj(SatIdx).beamfoot(dpIdx,:))
 interfUsrsOfSatCur = [interfUsrsOfSatCur self.SatObj(SatIdx).beamfoot(dpIdx, interfLightBeamfoot(interfIdx)).usrs];
 end
 end
 % Supplement calculation of signaling beam footprint interference
 for interfIdx = 1 : length(tmpOrderOfSig) 
 tmpOrderOfbeam = NumOfInterfInSat + interfIdx;
 G_sat_interfDown = self.SatObj(SatIdx).getSatSigServG(UsrTheta, UsrPhi, tmpOrderOfbeam, freqOfDownLink); % transmitgain
 PL1= channel.PL_Sat_Ground(distance,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 InterfInSatDown = InterfInSatDown + ...
 Pt_SAT_signal * G_sat_interfDown * G_usrDown * (10^(-0.1*PL1));
 end
 else
 % If no signaling beams 
 for interfIdx = 1 : NumOfInterfInSat 
 % Calculate downlink interference 
 tmpOrderOfbeam = find(LightBeamfoot == interfLightBeamfoot(interfIdx));
 G_sat_interfDown = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, tmpOrderOfbeam, freqOfDownLink); % Antenna transmit gain
 PL2_down= channel.PL_Sat_Ground(distance,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain); 
 InterfInSatDown = InterfInSatDown + ...
 Pt_SAT_serv * G_sat_interfDown * G_usrDown* (10^(-0.1*PL2_down));
 % Calculate all uplink interfering users
 if ~isempty(self.SatObj(SatIdx).beamfoot(dpIdx,:))
 interfUsrsOfSatCur = [interfUsrsOfSatCur self.SatObj(SatIdx).beamfoot(dpIdx, interfLightBeamfoot(interfIdx)).usrs];
 end
 end
 end
 
 %% Calculate uplink interference, traverse all uplink interfering users
 NumOfinterfUsrs = length(interfUsrsOfSatCur);
 for interfusrIdx = 1 : NumOfinterfUsrs 
 % Get pointing angle of interfering user
 usrInterfPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==interfUsrsOfSatCur(interfusrIdx))).position; % Interfering user coordinates
 [UsrInterfTheta, UsrInterfPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrInterfPos, heightOfsat);
 
 % Calculate interfering user's transmit gain
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrInterfPos, satCurPos, usrInterfPos, heightOfsat);
 G_usr_interfUp = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else
 G_usr_interfUp = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 
 % Calculate distance from interfering user to satellite
 usrInterfPosInDescartes = LngLat2Descartes(usrInterfPos, 0);
 distance_interf = sqrt((satPosInDescartes(1)-usrInterfPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrInterfPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrInterfPosInDescartes(3)).^2);
 
 % Calculate uplink interference
 G_sat_Up = self.SatObj(SatIdx).getAntennaServG(UsrInterfTheta, UsrInterfPhi, IdxInLightBeamfoot, freqOfUpLink); % Antenna receive gain
 PL_up= channel.PL_Sat_Ground(distance_interf,freqOfUpLink, heightOfsat,usrInterfPos(1,2),scenario,IfRain);
 InterfInSatUp = InterfInSatUp + ...
 Pt_Usr * G_usr_interfUp * G_sat_Up * (10^(-0.1*PL_up));
 end

 %% Inter-satellite interference, traverse all neighbor satellites 
 for NofLayer = 1 : self.Config.layerOfinterf
 % Traverse by layer
 OrderOfNeighborSat = self.SatObj(SatIdx).Neighbor(NofLayer, :);
 NofNeiSatCur = find(OrderOfNeighborSat == 0, 1) - 1; % Number of neighbor satellites in current layer
 OrderOfNeighborSat((NofNeiSatCur + 1) : length(self.OrderOfServSatCur)) = []; % Remove zeros
 for NoOfSat = 1 : NofNeiSatCur
 % Traverse neighbor satellites in same layer
 interfSatIdx = find(self.OrderOfServSatCur == OrderOfNeighborSat(NoOfSat));
 % Calculate user's pointing angle relative to interfering satellite
 satInterfPos = self.SatObj(interfSatIdx).position; % Interfering satellite coordinates
 satInterfnextPos = self.SatObj(interfSatIdx).nextpos;
 [UsrThetaInOtherSat, UsrPhiInOtherSat] = ...
 tools.getPointAngleOfUsr(satInterfPos, satInterfnextPos, usrCurPos, heightOfsat);
 
 % Calculate off-axis angle of interfering satellite relative to user antenna pointing
 interfsatPosInDescartes = LngLat2Descartes(satInterfPos, heightOfsat);
 vectorOfUsr2curSat = [ ...
 satPosInDescartes(1) - usrPosInDescartes(1), ...
 satPosInDescartes(2) - usrPosInDescartes(2), ...
 satPosInDescartes(3) - usrPosInDescartes(3) ...
 ];
 vectorOfUsr2interfSat = [ ...
 interfsatPosInDescartes(1) - usrPosInDescartes(1), ...
 interfsatPosInDescartes(2) - usrPosInDescartes(2), ...
 interfsatPosInDescartes(3) - usrPosInDescartes(3) ...
 ];
 OffAxisAngle = acos(abs(dot(vectorOfUsr2curSat, vectorOfUsr2interfSat))/...
 (sqrt(vectorOfUsr2curSat(1)^2 + vectorOfUsr2curSat(2)^2 + vectorOfUsr2curSat(3)^2) * ...
 sqrt(vectorOfUsr2interfSat(1)^2 + vectorOfUsr2interfSat(2)^2 + vectorOfUsr2interfSat(3)^2)));
 
 
 % Calculate distance from user to interfering satellite
 distance2InterfSat = sqrt((interfsatPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (interfsatPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (interfsatPosInDescartes(3)-usrPosInDescartes(3)).^2);
 
 %% Calculate downlink interference
 interfBeamf = self.SatObj(interfSatIdx).LightBeamfoot;
 NumOfinterfBeamf = length(interfBeamf);
 interfUsrsOfSatOther = []; % Set of uplink interfering user sequence numbers

 if ~isempty(self.SatObj(interfSatIdx).LightSig)
 % If signaling beams exist
 tmpOrderOfSig = self.SatObj(interfSatIdx).LightSig;
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satInterfPos, usrCurPos, heightOfsat);
 G_usr_interf = antenna.getUsrAntennaServG(tmp_angle, freqOfDownLink, false);
 else 
 G_usr_interf = antenna.getUsrAntennaServG(OffAxisAngle, freqOfDownLink, false);
 end
 % Calculate service beam footprint interference
 for interfBfidx = 1 : NumOfinterfBeamf
 % Traverse by interfering beam footprint
 % Calculate downlink interference
 G_othersat_interf = self.SatObj(interfSatIdx).getAntennaServG(UsrThetaInOtherSat, UsrPhiInOtherSat, interfBfidx, freqOfDownLink); % Antenna transmit gain
 PLIn1_down= channel.PL_Sat_Ground(distance2InterfSat,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain); 
 InterfWithSatDown = InterfWithSatDown + ...
 Pt_SAT_serv * G_othersat_interf * G_usr_interf *(10^(-0.1*PLIn1_down));
 % Calculate all uplink interfering users
 if ~isempty(self.SatObj(interfSatIdx).beamfoot)
 interfUsrsOfSatOther = [interfUsrsOfSatOther self.SatObj(interfSatIdx).beamfoot(dpIdx, interfBeamf(interfBfidx)).usrs];
 end
 end
 % Supplement calculation of signaling beam footprint interference
 for interfIdx = 1 : length(tmpOrderOfSig) 
 tmpOrderOfbeam = NumOfinterfBeamf + interfIdx;
 G_othersat_interf = self.SatObj(interfSatIdx).getSatSigServG(UsrThetaInOtherSat, UsrPhiInOtherSat, tmpOrderOfbeam, freqOfDownLink); % transmitgain
 PLIn2_down= channel.PL_Sat_Ground(distance2InterfSat,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain); 
 InterfWithSatDown = InterfWithSatDown + ...
 Pt_SAT_signal * G_othersat_interf * G_usr_interf *(10^(-0.1*PLIn2_down));
 end
 else
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satInterfPos, usrCurPos, heightOfsat);
 G_usr_interf = antenna.getUsrAntennaServG(tmp_angle, freqOfDownLink, false);
 else 
 G_usr_interf = antenna.getUsrAntennaServG(OffAxisAngle, freqOfDownLink, false);
 end
 for interfBfidx = 1 : NumOfinterfBeamf
 % Traverse by interfering beam footprint
 % Calculate downlink interference
 G_othersat_interf = self.SatObj(interfSatIdx).getAntennaServG(UsrThetaInOtherSat, UsrPhiInOtherSat, interfBfidx, freqOfDownLink); % Antenna transmit gain
 PLIn_down= channel.PL_Sat_Ground(distance2InterfSat,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain); 
 InterfWithSatDown = InterfWithSatDown + ...
 Pt_SAT_serv * G_othersat_interf * G_usr_interf *(10^(-0.1*PLIn_down));
 % Calculate all uplink interfering users
 if ~isempty(self.SatObj(interfSatIdx).beamfoot)
 interfUsrsOfSatOther = [interfUsrsOfSatOther self.SatObj(interfSatIdx).beamfoot(dpIdx, interfBeamf(interfBfidx)).usrs];
 end
 end
 end
 
 %% Calculate uplink interference, traverse all uplink interfering users
 NumOfinterfUsrsOther = length(interfUsrsOfSatOther);
 for interfusrOtherIdx = 1 : NumOfinterfUsrsOther
 % Calculate off-axis angle from interfering user to current satellite
 
 usrOtherInterfPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==interfUsrsOfSatOther(interfusrOtherIdx))).position; % Interfering user coordinates
 usrOtherInterfPosInDescartes = LngLat2Descartes(usrOtherInterfPos, 0);
 vectorOfcurSat2interfUsr = [ ...
 satPosInDescartes(1) - usrOtherInterfPosInDescartes(1), ...
 satPosInDescartes(2) - usrOtherInterfPosInDescartes(2), ...
 satPosInDescartes(3) - usrOtherInterfPosInDescartes(3) ...
 ];
 vectorOfinterfSat2interfUsr = [ ...
 interfsatPosInDescartes(1) - usrOtherInterfPosInDescartes(1), ...
 interfsatPosInDescartes(2) - usrOtherInterfPosInDescartes(2), ...
 interfsatPosInDescartes(3) - usrOtherInterfPosInDescartes(3) ...
 ];
 OffAxisAngleOther = acos(abs(dot(vectorOfcurSat2interfUsr, vectorOfinterfSat2interfUsr))/...
 (sqrt(vectorOfcurSat2interfUsr(1)^2 + vectorOfcurSat2interfUsr(2)^2 + vectorOfcurSat2interfUsr(3)^2) * ...
 sqrt(vectorOfinterfSat2interfUsr(1)^2 + vectorOfinterfSat2interfUsr(2)^2 + vectorOfinterfSat2interfUsr(3)^2)));
 
 % Calculate interfering user's transmit gain
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrOtherInterfPos, satCurPos, usrOtherInterfPos, heightOfsat);
 G_otherusr_interfUp = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_otherusr_interfUp = antenna.getUsrAntennaServG(OffAxisAngleOther, freqOfUpLink, true);
 end

 % Get pointing angle of interfering user
 [UsrOtherInterfTheta, UsrOtherInterfPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrOtherInterfPos, heightOfsat);
 
 % Calculate distance from interfering user to current satellite
 distance_Otherinterf = sqrt((satPosInDescartes(1)-usrOtherInterfPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrOtherInterfPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrOtherInterfPosInDescartes(3)).^2);
 
 % Calculate uplink interference
 G_Othersat_Up = self.SatObj(SatIdx).getAntennaServG(UsrOtherInterfTheta, UsrOtherInterfPhi, IdxInLightBeamfoot, freqOfUpLink); % Antenna receive gain
 PLIn_up=channel.PL_Sat_Ground(distance_Otherinterf,freqOfUpLink,heightOfsat,usrOtherInterfPos(1,2),scenario,IfRain); 
 InterfWithSatUp = InterfWithSatUp + ...
 Pt_Usr * G_otherusr_interfUp * G_Othersat_Up *(10^(-0.1*PLIn_up));
 end 
 end
 end
 %% C/I Signal to interference ratio
 if self.Config.numOfMonteCarlo == 0
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfDownLink); % Antenna transmit gain
 PL1 = channel.PL_Sat_Ground(distance,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 Carrier_down = Pt_SAT_serv * G_sat_down * G_usrDown *(10^(-0.1*PL1));
 DataObj(IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/(InterfWithSatDown+InterfInSatDown);
 DataObj(IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/InterfInSatDown;
 G_sat_up = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfUpLink); % transmitgain
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 PL2 = channel.PL_Sat_Ground(distance,freqOfUpLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (10^(-0.1*PL2));
 DataObj(IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/(InterfWithSatUp+InterfInSatUp);
 DataObj(IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/InterfInSatUp;
 else
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfDownLink); % transmitgain
 PL1 = channel.PL_Sat_Ground(distance,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 Carrier_down = Pt_SAT_serv * G_sat_down * G_usrDown *(10^(-0.1*PL1));
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/(InterfWithSatDown+InterfInSatDown);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/InterfInSatDown;
 G_sat_up = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfUpLink); % transmitgain
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 PL2 = channel.PL_Sat_Ground(distance,freqOfUpLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (10^(-0.1*PL2)); 
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/(InterfWithSatUp+InterfInSatUp);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/InterfInSatUp; 
 end
 %% C/(I+N) Signal to interference plus noise ratio
 K = 1.38e-23; % Boltzmann constant
 Ta_usr = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).T_noise;
 Ta_sat = self.SatObj(SatIdx).T_noise;
 F_usr = 10.^(self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).F_noise/10);
 F_sat = 10.^(self.SatObj(SatIdx).F_noise/10);
 N_noise_usr = Band*K*(Ta_usr+(F_usr-1)*300);
 N_noise_usr = Band*K*300;
 N_noise_sat = Band*K*(Ta_sat+(F_sat-1)*300);

 if self.Config.numOfMonteCarlo == 0
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfDownLink); % Antenna transmit gain
 PL1 = channel.PL_Sat_Ground(distance,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 Carrier_down = Pt_SAT_serv * G_sat_down * G_usrDown*(10^(-0.1*PL1));
 DataObj(IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfWithSatDown+InterfInSatDown+N_noise_usr);
 DataObj(IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfInSatDown+N_noise_usr);
 
 
 
 G_sat_up = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfUpLink); % Antenna transmit gain
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 PL2 = channel.PL_Sat_Ground(distance,freqOfUpLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (10^(-0.1*PL2)); 
 DataObj(IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfWithSatUp+InterfInSatUp+N_noise_sat);
 DataObj(IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfInSatUp+N_noise_sat);
 else
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfDownLink); % Antenna transmit gain
 PL1 = channel.PL_Sat_Ground(distance,freqOfDownLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 Carrier_down = Pt_SAT_serv * G_sat_down * G_usrDown*(10^(-0.1*PL1)); 
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfWithSatDown+InterfInSatDown+N_noise_usr);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfInSatDown+N_noise_usr);
 
 G_sat_up = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfUpLink); % Antenna transmit gain
 if ifVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 PL2 = channel.PL_Sat_Ground(distance,freqOfUpLink,heightOfsat,usrCurPos(1,2),scenario,IfRain);
 Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (10^(-0.1*PL2)); 
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfWithSatUp+InterfInSatUp+N_noise_sat);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfInSatUp+N_noise_sat); 
 end 
 end
 end
 end
 if ifDebug == 1
 if self.Config.numOfMonteCarlo == 0
 fprintf('Snapshot %d Algorithm %d interference calculation %.1f%%\n', IdxOfStep, MethodIdx, slotIdx*100/NumOfSlotPerShot); 
 else
 fprintf('Monte Carlo %d Snapshot %d Algorithm %d interference calculation %.1f%%\n', MC_idx, IdxOfStep, MethodIdx, slotIdx*100/NumOfSlotPerShot); 
 end
 end
 end
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

