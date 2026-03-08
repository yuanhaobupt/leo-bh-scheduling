function DataObj = calcuInterference(self, DataObj, IdxOfStep, MC_idx)
%CALCUINTERFERENCE Calculateinterference
 ifDebug = self.ifDebug;

 NumOfSlotPerShot = self.slotInShot;
 NumOfSlotPerSche = self.subFInSche * self.slotInSubF;
 NumOfShot = length(self.SatPosition(1,:,1)) - 1; % simulationtotal(Calculate)

 NumOfSat = length(self.OrderOfServSatCur);
 NumOfInvesUsrs = self.numOfUsrs_inves;

 heightOfsat = self.Config.height;
 lightVelocity = self.vOfray;

 freqOfDownLink = self.Config.freqOfDownLink;
 lambdaDown = lightVelocity/freqOfDownLink;
 freqOfUpLink = self.Config.freqOfUpLink;
 lambdaUp = lightVelocity/freqOfUpLink;

 UsrAntennaConfig = antenna.initialUsrAntenna();
 IfUsrAntennaDeGravity = UsrAntennaConfig.ifDeGravity;

 for MethodIdx = 1 : self.numOfMethods_BeamGenerate * self.numOfMethods_BeamHopping

 %% Traversealltime slot
 for slotIdx = 1 : NumOfSlotPerShot

 self.getBeamPoint(slotIdx,MethodIdx);
 % self.SatObj(SatIdx).BeamPoint
 %% Traverseallsatellite
 dpIdx = ceil(slotIdx/NumOfSlotPerSche); % scheduling
 for SatIdx = 1 : NumOfSat %Traversesatellite
 servUsr = self.SatObj(SatIdx).servUsr(dpIdx, self.SatObj(SatIdx).servUsr(dpIdx,:)~=0);
 tmpNo = find(servUsr <= NumOfInvesUsrs);
 UsrsOfSatCur = self.SatObj(SatIdx).servUsr(dpIdx, tmpNo); % Whenareauser
 NumOfUsrs = length(tmpNo); % usernumber

 Pt_SAT_dBm_serv = self.SatObj(SatIdx).Pt_dBm_serv;

 Pt_SAT_serv = (10.^(Pt_SAT_dBm_serv/10))/1e3/self.Config.numOfServbeam; % W
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 if self.Config.numOfSigbeam > 0
 Pt_SAT_dBm_signal = self.SatObj(SatIdx).Pt_dBm_signal;
 Pt_SAT_signal = (10.^(Pt_SAT_dBm_signal/10))/1e3/self.Config.numOfSigbeam; % W
 end
 LightBeamfoot = self.SatObj(SatIdx).LightBeamfoot; % When beam positionID/number
% if MethodIdx == 2
% 1;
% end

 for UsrIdx = 1 : NumOfUsrs %Traverseuser
 UsrOrderCur = UsrsOfSatCur(UsrIdx); % WhenuserID/number
% BeamfootOrderOfUsrCur
 BeamfootOrderOfUsrCur = self.Usr2SatCur(UsrOrderCur, 1+ceil(MethodIdx/self.numOfMethods_BeamHopping), dpIdx); % Whenuserbeam position 
 Pt_Usr_dBm = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).Pt_dBm;
 Pt_Usr = (10.^(Pt_Usr_dBm/10))/1e3; % W

 InterfInSatDown = 0; % interference
 InterfWithSatDown = 0; % interference
 InterfInSatUp = 0; % interference
 InterfWithSatUp = 0; % interference

 IdxInLightBeamfoot = find(LightBeamfoot == BeamfootOrderOfUsrCur);

 if ~isempty(IdxInLightBeamfoot)
 % CalculateWhen
 usrCurPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).position; % Whenusercoordinate
 satCurPos = self.SatObj(SatIdx).position; % Whensatellitesub-satellite pointcoordinate
 satCurnextPos = self.SatObj(SatIdx).nextpos; % Whensatellitesub-satellite pointstepcoordinate
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrCurPos, heightOfsat);%Calculateand
 
 % Calculateuserreceivegain
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usrDown = antenna.getUsrAntennaServG(tmp_angle, freqOfDownLink, false);
 else
 G_usrDown = antenna.getUsrAntennaServG(0, freqOfDownLink, false);
 end
 
 % CalculateWhen
 usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
 satPosInDescartes = LngLat2Descartes(satCurPos, heightOfsat);
 distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrPosInDescartes(3)).^2); 

 % Traverseall
 interfLightBeamfoot = LightBeamfoot(LightBeamfoot~=BeamfootOrderOfUsrCur); % interferencebeam position ID/number
 NumOfInterfInSat = length(interfLightBeamfoot); % interferencebeam position number
 interfUsrsOfSatCur = []; % interferenceuser ID/number

 if ~isempty(self.SatObj(SatIdx).LightSig) 
 % If
 tmpOrderOfSig = self.SatObj(SatIdx).LightSig;
 % Calculatetrafficbeam position interference
 for interfIdx = 1 : NumOfInterfInSat 
 % Calculate
 tmpOrderOfbeam = find(LightBeamfoot == interfLightBeamfoot(interfIdx));
 G_sat_interfDown = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, tmpOrderOfbeam, freqOfDownLink); % transmitgain
 InterfInSatDown = InterfInSatDown + ...
 Pt_SAT_serv * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 % Calculateall
 if ~isempty(self.SatObj(SatIdx).beamfoot(dpIdx,:))
 interfUsrsOfSatCur = [interfUsrsOfSatCur self.SatObj(SatIdx).beamfoot(dpIdx, interfLightBeamfoot(interfIdx)).usrs];
 end
 end

 for interfIdx = 1 : length(tmpOrderOfSig) 
 tmpOrderOfbeam = NumOfInterfInSat + interfIdx;
 G_sat_interfDown = self.SatObj(SatIdx).getSatSigServG(UsrTheta, UsrPhi, tmpOrderOfbeam, freqOfDownLink); % transmitgain
 InterfInSatDown = InterfInSatDown + ...
 Pt_SAT_signal * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 end
 else
 %If
 for interfIdx = 1 : NumOfInterfInSat 
 % Calculate
 tmpOrderOfbeam = find(LightBeamfoot == interfLightBeamfoot(interfIdx));
 G_sat_interfDown = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, tmpOrderOfbeam, freqOfDownLink); % transmitgain
 InterfInSatDown = InterfInSatDown + ...
 Pt_SAT_serv * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 % Calculateall
 if ~isempty(self.SatObj(SatIdx).beamfoot(dpIdx,:))
 interfUsrsOfSatCur = [interfUsrsOfSatCur self.SatObj(SatIdx).beamfoot(dpIdx, interfLightBeamfoot(interfIdx)).usrs];
 end
 end
 end

 NumOfinterfUsrs = length(interfUsrsOfSatCur);
 for interfusrIdx = 1 : NumOfinterfUsrs 

 usrInterfPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==interfUsrsOfSatCur(interfusrIdx))).position; % interferenceusercoordinate
 [UsrInterfTheta, UsrInterfPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrInterfPos, heightOfsat);
 
 % Calculateinterferenceuser transmitgain
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrInterfPos, satCurPos, usrInterfPos, heightOfsat);
 G_usr_interfUp = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else
 G_usr_interfUp = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 
 % Calculateinterferenceusertosatellite
 usrInterfPosInDescartes = LngLat2Descartes(usrInterfPos, 0);
 distance_interf = sqrt((satPosInDescartes(1)-usrInterfPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrInterfPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrInterfPosInDescartes(3)).^2);
 
 % Calculate
 G_sat_Up = self.SatObj(SatIdx).getAntennaServG(UsrInterfTheta, UsrInterfPhi, IdxInLightBeamfoot, freqOfUpLink); % receivegain
 InterfInSatUp = InterfInSatUp + ...
 Pt_Usr * G_usr_interfUp * G_sat_Up * (lambdaUp.^2) / (((4*pi).^2)*(distance_interf.^2));
 end

 for NofLayer = 1 : self.Config.layerOfinterf

 OrderOfNeighborSat = self.SatObj(SatIdx).Neighbor(NofLayer, :);
 NofNeiSatCur = find(OrderOfNeighborSat == 0, 1) - 1; % When satellite
 OrderOfNeighborSat((NofNeiSatCur + 1) : length(self.OrderOfServSatCur)) = []; % Delete0
 for NoOfSat = 1 : NofNeiSatCur

 interfSatIdx = find(self.OrderOfServSatCur == OrderOfNeighborSat(NoOfSat));
 % Calculateuser
 satInterfPos = self.SatObj(interfSatIdx).position; % interferencecoordinate
 satInterfnextPos = self.SatObj(interfSatIdx).nextpos;
 [UsrThetaInOtherSat, UsrPhiInOtherSat] = ...
 tools.getPointAngleOfUsr(satInterfPos, satInterfnextPos, usrCurPos, heightOfsat);
 
 % Calculateinterference
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
 
 
 % Calculateusertointerference
 distance2InterfSat = sqrt((interfsatPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (interfsatPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (interfsatPosInDescartes(3)-usrPosInDescartes(3)).^2);

 interfBeamf = self.SatObj(interfSatIdx).LightBeamfoot;
 NumOfinterfBeamf = length(interfBeamf);
 interfUsrsOfSatOther = []; % interferenceuser ID/number

 if ~isempty(self.SatObj(interfSatIdx).LightSig)
 %If
 tmpOrderOfSig = self.SatObj(interfSatIdx).LightSig;
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satInterfPos, usrCurPos, heightOfsat);
 G_usr_interf = antenna.getUsrAntennaServG(tmp_angle, freqOfDownLink, false);
 else 
 G_usr_interf = antenna.getUsrAntennaServG(OffAxisAngle, freqOfDownLink, false);
 end
 % Calculatetrafficbeam position interference
 for interfBfidx = 1 : NumOfinterfBeamf

 % Calculate
 G_othersat_interf = self.SatObj(interfSatIdx).getAntennaServG(UsrThetaInOtherSat, UsrPhiInOtherSat, interfBfidx, freqOfDownLink); % transmitgain
 InterfWithSatDown = InterfWithSatDown + ...
 Pt_SAT_serv * G_othersat_interf * G_usr_interf * (lambdaDown.^2) / (((4*pi).^2)*(distance2InterfSat.^2));
 % Calculateall
 if ~isempty(self.SatObj(interfSatIdx).beamfoot)
 interfUsrsOfSatOther = [interfUsrsOfSatOther self.SatObj(interfSatIdx).beamfoot(dpIdx, interfBeamf(interfBfidx)).usrs];
 end
 end

 for interfIdx = 1 : length(tmpOrderOfSig) 
 tmpOrderOfbeam = NumOfinterfBeamf + interfIdx;
 G_othersat_interf = self.SatObj(interfSatIdx).getSatSigServG(UsrThetaInOtherSat, UsrPhiInOtherSat, tmpOrderOfbeam, freqOfDownLink); % transmitgain
 InterfWithSatDown = InterfWithSatDown + ...
 Pt_SAT_signal * G_othersat_interf * G_usr_interf * (lambdaDown.^2) / (((4*pi).^2)*(distance2InterfSat.^2));
 end
 else
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satInterfPos, usrCurPos, heightOfsat);
 G_usr_interf = antenna.getUsrAntennaServG(tmp_angle, freqOfDownLink, false);
 else 
 G_usr_interf = antenna.getUsrAntennaServG(OffAxisAngle, freqOfDownLink, false);
 end
 for interfBfidx = 1 : NumOfinterfBeamf

 % Calculate
 G_othersat_interf = self.SatObj(interfSatIdx).getAntennaServG(UsrThetaInOtherSat, UsrPhiInOtherSat, interfBfidx, freqOfDownLink); % transmitgain
 InterfWithSatDown = InterfWithSatDown + ...
 Pt_SAT_serv * G_othersat_interf * G_usr_interf * (lambdaDown.^2) / (((4*pi).^2)*(distance2InterfSat.^2));
 % Calculateall
 if ~isempty(self.SatObj(interfSatIdx).beamfoot)
 interfUsrsOfSatOther = [interfUsrsOfSatOther self.SatObj(interfSatIdx).beamfoot(dpIdx, interfBeamf(interfBfidx)).usrs];
 end
 end
 end

 NumOfinterfUsrsOther = length(interfUsrsOfSatOther);
 for interfusrOtherIdx = 1 : NumOfinterfUsrsOther
 % CalculateinterferenceusertoWhen
 
 usrOtherInterfPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==interfUsrsOfSatOther(interfusrOtherIdx))).position; % interferenceusercoordinate
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
 
 % Calculateinterferenceuser transmitgain
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrOtherInterfPos, satCurPos, usrOtherInterfPos, heightOfsat);
 G_otherusr_interfUp = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_otherusr_interfUp = antenna.getUsrAntennaServG(OffAxisAngleOther, freqOfUpLink, true);
 end

 [UsrOtherInterfTheta, UsrOtherInterfPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrOtherInterfPos, heightOfsat);
 
 % CalculateinterferenceusertoWhen
 distance_Otherinterf = sqrt((satPosInDescartes(1)-usrOtherInterfPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrOtherInterfPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrOtherInterfPosInDescartes(3)).^2);
 
 % Calculate
 G_Othersat_Up = self.SatObj(SatIdx).getAntennaServG(UsrOtherInterfTheta, UsrOtherInterfPhi, IdxInLightBeamfoot, freqOfUpLink); % receivegain
 InterfWithSatUp = InterfWithSatUp + ...
 Pt_Usr * G_otherusr_interfUp * G_Othersat_Up * (lambdaUp.^2) / (((4*pi).^2)*(distance_Otherinterf.^2));
 end 
 end
 end
 %% C/I
 if self.Config.numOfMonteCarlo == 0
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfDownLink); % transmitgain
 Carrier_down = Pt_SAT_serv * G_sat_down * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 DataObj(IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/(InterfWithSatDown+InterfInSatDown);
 DataObj(IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/InterfInSatDown;
 G_sat_up = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfUpLink); % transmitgain
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (lambdaUp.^2) / (((4*pi).^2)*(distance.^2));
 DataObj(IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/(InterfWithSatUp+InterfInSatUp);
 DataObj(IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/InterfInSatUp;
 else
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfDownLink); % transmitgain
 Carrier_down = Pt_SAT_serv * G_sat_down * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/(InterfWithSatDown+InterfInSatDown);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/InterfInSatDown;
 G_sat_up = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfUpLink); % transmitgain
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (lambdaUp.^2) / (((4*pi).^2)*(distance.^2));
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/(InterfWithSatUp+InterfInSatUp);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/InterfInSatUp; 
 end
 %% C/(I+N)
 K = 1.38e-23; % 
 Band = self.Config.BandOfLink; % bandwidth
 Ta_usr = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).T_noise;
 Ta_sat = self.SatObj(SatIdx).T_noise;
 F_usr = 10.^(self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).F_noise/10);
 F_sat = 10.^(self.SatObj(SatIdx).F_noise/10);
 N_noise_usr = Band*K*(Ta_usr+(F_usr-1)*300);
 N_noise_sat = Band*K*(Ta_sat+(F_sat-1)*300);

 if self.Config.numOfMonteCarlo == 0
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfDownLink); % transmitgain
 Carrier_down = Pt_SAT_serv * G_sat_down * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 DataObj(IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfWithSatDown+InterfInSatDown+N_noise_usr);
 DataObj(IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfInSatDown+N_noise_usr);
 
 G_sat_up = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfUpLink); % transmitgain
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (lambdaUp.^2) / (((4*pi).^2)*(distance.^2));
 DataObj(IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfWithSatUp+InterfInSatUp+N_noise_sat);
 DataObj(IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfInSatUp+N_noise_sat);

 DataObj(IdxOfStep).InterSat_UsrsTransPort(MethodIdx, UsrOrderCur, dpIdx) = ...
 DataObj(IdxOfStep).InterSat_UsrsTransPort(MethodIdx, UsrOrderCur, dpIdx) + ...
 self.timeInSlot*self.Config.BandOfLink*log2(1+Carrier_up/(InterfWithSatUp+InterfInSatUp+N_noise_sat));
 else
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfDownLink); % transmitgain
 Carrier_down = Pt_SAT_serv * G_sat_down * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfWithSatDown+InterfInSatDown+N_noise_usr);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfInSatDown+N_noise_usr);
 
 G_sat_up = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, freqOfUpLink); % transmitgain
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
 else 
 G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
 end
 Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (lambdaUp.^2) / (((4*pi).^2)*(distance.^2));
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfWithSatUp+InterfInSatUp+N_noise_sat);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfInSatUp+N_noise_sat);
 
 
 end 
 end
 end
 end
 if ifDebug == 1
 if self.Config.numOfMonteCarlo == 0
 fprintf('%d%dinterferenceCalculate%f%%\n', IdxOfStep, MethodIdx, slotIdx*100/NumOfSlotPerShot); 
 else
 fprintf('%d%d%dinterferenceCalculate%f%%\n', MC_idx, IdxOfStep, MethodIdx, frmIdx*100/NumOfSlotPerShot); 
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
 R = 6371.393e3; % 
 tmpX = (R+h) * sin(tmpTheta) * cos(tmpPhi);
 tmpY = (R+h) * sin(tmpTheta) * sin(tmpPhi);
 tmpZ = (R+h) * cos(tmpTheta); 
 PosInDescartes = [tmpX, tmpY, tmpZ]; 
end

