function DataObj = calcuInterferenceForDiffBand(self, DataObj, IdxOfStep, MC_idx)
% drm:
 ifDebug = self.ifDebug;

 NumOfSlotPerShot = self.slotInShot;
 NumOfSlotPerSche = self.subFInSche * self.slotInSubF;
 NumOfShot = length(self.SatPosition(1,:,1)) - 1; % simulationtotal(Calculate)

 NumOfSat = length(self.OrderOfServSatCur);
% NumOfInvesUsrs = self.numOfUsrs_inves;
 NumOfInvesUsrs = self.numOfUsrs_selected;

 heightOfsat = self.Config.height;
 lightVelocity = self.vOfray;

 freqOfDownLink = self.Config.freqOfDownLink;
% lambdaDown = lightVelocity/freqOfDownLink;
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
% servUsr = self.SatObj(SatIdx).servUsr(dpIdx, self.SatObj(SatIdx).servUsr(dpIdx,:)~=0);
% tmpNo = find(servUsr <= NumOfInvesUsrs);
% UsrsOfSatCur
 UsrsOfSatCur = self.SatObj(SatIdx).servUsr(dpIdx, self.SatObj(SatIdx).servUsr(dpIdx,:)~=0);
 NumOfUsrs = length(UsrsOfSatCur); % usernumber

% Pt_SAT_dBm_serv = self.SatObj(SatIdx).Pt_dBm_serv;
% Pt_SAT_serv = (10.^(Pt_SAT_dBm_serv/10))/1e3/self.Config.numOfServbeam; % W

 if self.Config.numOfSigbeam > 0
 Pt_SAT_dBm_signal = self.SatObj(SatIdx).Pt_dBm_signal;
 Pt_SAT_signal = (10.^(Pt_SAT_dBm_signal/10))/1e3/self.Config.numOfSigbeam; % W
 end
 LightBeamfoot = self.SatObj(SatIdx).LightBeamfoot; % When beam positionID/number
 LightPower = self.SatObj(SatIdx).LightPower;% Whenbeam position power

 for UsrIdx = 1 : NumOfUsrs %Traverseuser
 UsrOrderCur = UsrsOfSatCur(UsrIdx); % WhenuserID/number
% BeamfootOrderOfUsrCur
 BeamfootOrderOfUsrCur = self.Usr2SatCur(UsrOrderCur, 1+ceil(MethodIdx/self.numOfMethods_BeamHopping), dpIdx); % Whenuserbeam position 

 UsrOrderCur = find(self.OrderOfSelectedUsrs == UsrOrderCur);
% Pt_Usr_dBm = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).Pt_dBm;
% Pt_Usr = (10.^(Pt_Usr_dBm/10))/1e3; % W

 InterfInSatDown = 0; % interference
 InterfWithSatDown = 0; % interference
 InterfInSatUp = 0; % interference
 InterfWithSatUp = 0; % interference

 IdxInLightBeamfoot = find(LightBeamfoot == BeamfootOrderOfUsrCur);

 if ~isempty(IdxInLightBeamfoot)
 % When
 %%%%%%%%%%%%%%%%%%
% Pt_Usr = LightPower(IdxInLightBeamfoot) * self.UsrsObj(UsrOrderCur).PowerPercent; % 
% Band_Usr = self.UsrsObj(UsrOrderCur).Band;
 %%%%%%%%%%%%%%%%
 Pt_Usr = LightPower(IdxInLightBeamfoot) * self.UsrsObj(UsrOrderCur).PowerPercent(slotIdx); % W
 Band_Usr = self.UsrsObj(UsrOrderCur).Band(slotIdx, :);
 fc_Usr = mean(Band_Usr);
 
 
 % CalculateWhen
 usrCurPos = self.UsrsObj(UsrOrderCur).position; % Whenusercoordinate
 satCurPos = self.SatObj(SatIdx).position; % Whensatellitesub-satellite pointcoordinate
 satCurnextPos = self.SatObj(SatIdx).nextpos; % Whensatellitesub-satellite pointstepcoordinate
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrCurPos, heightOfsat);%Calculateand
 
 % Calculateuserreceivegain
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usrDown = antenna.getUsrAntennaServG(tmp_angle, fc_Usr, false);
 else
 G_usrDown = antenna.getUsrAntennaServG(0, fc_Usr, false);
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

% if ~isempty(self.SatObj(SatIdx).LightSig) 
% tmpOrderOfSig = self.SatObj(SatIdx).LightSig;
% % Calculatetrafficbeam position interference
% for interfIdx = 1 : NumOfInterfInSat 
% tmpOrderOfbeam = find(LightBeamfoot == interfLightBeamfoot(interfIdx));
% G
% InterfInSatDown = InterfInSatDown + ...
% Pt_SAT_serv * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
% if ~isempty(self.SatObj(SatIdx).beamfoot(dpIdx,:))
% interfUsrsOfSatCur = [interfUsrsOfSatCur self.SatObj(SatIdx).beamfoot(dpIdx, interfLightBeamfoot(interfIdx)).usrs];
% end
% end
% for interfIdx = 1 : length(tmpOrderOfSig) 
% tmpOrderOfbeam = NumOfInterfInSat + interfIdx;
% G
% InterfInSatDown = InterfInSatDown + ...
% Pt_SAT_signal * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
% end
% else
 %If
 for interfIdx = 1 : NumOfInterfInSat % Traversesub-satellite pointbeam
 % Calculate

 tmpOrderOfbeam = find(LightBeamfoot == interfLightBeamfoot(interfIdx));% inWhenbeam position ID/number
 OrderOfbeam = interfLightBeamfoot(interfIdx);% beam position ID/number
 %interferencebeam position
 interfUsrs = self.SatObj(SatIdx).beamfoot(OrderOfbeam).usrs;
 % interferencebeam position
 interfBeamPower = LightPower(tmpOrderOfbeam);
 
 for interfUsrIdx = 1 : length(interfUsrs) % Traversebeam positionuser interference

 thisInterfUser = interfUsrs(interfUsrIdx);

 thisInterfUser = find(self.OrderOfSelectedUsrs == thisInterfUser);
 %%%%%%%%%%%%%%%%
% thisInterfUser_power = self.UsrsObj(thisInterfUser).PowerPercent * interfBeamPower;
% thisInterfUser_band = self.UsrsObj(thisInterfUser).Band;
 %%%%%%%%%%%%%%%%
 thisInterfUser_power = self.UsrsObj(thisInterfUser).PowerPercent(slotIdx) * interfBeamPower;
 thisInterfUser_band = self.UsrsObj(thisInterfUser).Band(slotIdx, :);

 % Judgeis
 overlap = range_intersection(Band_Usr,thisInterfUser_band);% NoteCheckf isisHz
 if length(overlap) == 2
 lambdaDown = 3e8/mean(overlap);
 G_sat_interfDown = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, tmpOrderOfbeam, mean(overlap)); % transmitgain
 InterfInSatDown = InterfInSatDown + ...
 thisInterfUser_power * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 end

 end
 
 
 
% if ~isempty(self.SatObj(SatIdx).beamfoot(dpIdx,:))
% interfUsrsOfSatCur = [interfUsrsOfSatCur self.SatObj(SatIdx).beamfoot(dpIdx, interfLightBeamfoot(interfIdx)).usrs];
% end
 end
% end
 
% NumOfinterfUsrs = length(interfUsrsOfSatCur);
% for interfusrIdx = 1 : NumOfinterfUsrs 
% usrInterfPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==interfUsrsOfSatCur(interfusrIdx))).position; % interferenceusercoordinate
% [UsrInterfTheta, UsrInterfPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrInterfPos, heightOfsat);

% % Calculateinterferenceuser transmitgain
% if IfUsrAntennaDeGravity == 1
% [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrInterfPos, satCurPos, usrInterfPos, heightOfsat);
% G_usr_interfUp = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
% else
% G_usr_interfUp = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
% end

% usrInterfPosInDescartes = LngLat2Descartes(usrInterfPos, 0);
% distance_interf = sqrt((satPosInDescartes(1)-usrInterfPosInDescartes(1)).^2 + ...
% (satPosInDescartes(2)-usrInterfPosInDescartes(2)).^2 + ...
% (satPosInDescartes(3)-usrInterfPosInDescartes(3)).^2);

% G
% InterfInSatUp = InterfInSatUp + ...
% Pt_Usr * G_usr_interfUp * G_sat_Up * (lambdaUp.^2) / (((4*pi).^2)*(distance_interf.^2));
% end

 for NofLayer = 1 : self.Config.layerOfinterf

 OrderOfNeighborSat = self.SatObj(SatIdx).Neighbor(NofLayer, :);
 NofNeiSatCur = find(OrderOfNeighborSat == 0, 1) - 1; % When satellite
 OrderOfNeighborSat((NofNeiSatCur + 1) : length(self.OrderOfServSatCur)) = []; % Delete0
 for NoOfSat = 1 : NofNeiSatCur% Traverse
 interfSatIdx = find(self.OrderOfServSatCur == OrderOfNeighborSat(NoOfSat));

 LightPowerf = self.SatObj(interfSatIdx).LightPower;
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

% if ~isempty(self.SatObj(interfSatIdx).LightSig)
% tmpOrderOfSig = self.SatObj(interfSatIdx).LightSig;
% if IfUsrAntennaDeGravity == 1
% [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satInterfPos, usrCurPos, heightOfsat);
% G_usr_interf = antenna.getUsrAntennaServG(tmp_angle, freqOfDownLink, false);
% else 
% G_usr_interf = antenna.getUsrAntennaServG(OffAxisAngle, freqOfDownLink, false);
% end
% % Calculatetrafficbeam position interference
% for interfBfidx = 1 : NumOfinterfBeamf
% G
% InterfWithSatDown = InterfWithSatDown + ...
% Pt_SAT_serv * G_othersat_interf * G_usr_interf * (lambdaDown.^2) / (((4*pi).^2)*(distance2InterfSat.^2));
% if ~isempty(self.SatObj(interfSatIdx).beamfoot)
% interfUsrsOfSatOther = [interfUsrsOfSatOther self.SatObj(interfSatIdx).beamfoot(dpIdx, interfBeamf(interfBfidx)).usrs];
% end
% end
% for interfIdx = 1 : length(tmpOrderOfSig) 
% tmpOrderOfbeam = NumOfinterfBeamf + interfIdx;
% G
% InterfWithSatDown = InterfWithSatDown + ...
% Pt_SAT_signal * G_othersat_interf * G_usr_interf * (lambdaDown.^2) / (((4*pi).^2)*(distance2InterfSat.^2));
% end
% else
 if IfUsrAntennaDeGravity == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satInterfPos, usrCurPos, heightOfsat);
 G_usr_interf = antenna.getUsrAntennaServG(tmp_angle, freqOfDownLink, false);
 else 
 G_usr_interf = antenna.getUsrAntennaServG(OffAxisAngle, freqOfDownLink, false);
 end
 for interfBfidx = 1 : NumOfinterfBeamf% interferencebeam positionTraverse

 OrderOfbeam = interfBeamf(interfBfidx);
 %interferencebeam position
 interfUsrs = self.SatObj(interfSatIdx).beamfoot(OrderOfbeam).usrs;
 % interferencebeam position
 interfBeamPower = LightPowerf(interfBfidx);

 for interfUsrIdx = 1 : length(interfUsrs) % Traversebeam positionuser interference

 thisInterfUser = interfUsrs(interfUsrIdx);

 thisInterfUser = find(self.OrderOfSelectedUsrs == thisInterfUser);
 %%%%%%%%%%%%%%%%%%%%
% thisInterfUser_power = self.UsrsObj(thisInterfUser).PowerPercent * interfBeamPower;
% thisInterfUser_band = self.UsrsObj(thisInterfUser).Band;
 %%%%%%%%%%%%%%%%%%%%
 thisInterfUser_power = self.UsrsObj(thisInterfUser).PowerPercent(slotIdx) * interfBeamPower;
 thisInterfUser_band = self.UsrsObj(thisInterfUser).Band(slotIdx, :);
 thisInterfUser_f = mean(thisInterfUser_band); % NoteCheckf isisHz
 % Judgeis
 overlap = range_intersection(Band_Usr,thisInterfUser_band);% NoteCheckf isisHz
 % Calculate
 if length(overlap) == 2
 lambdaDown = 3e8/mean(overlap);
 G_othersat_interf = self.SatObj(interfSatIdx).getAntennaServG(UsrThetaInOtherSat, UsrPhiInOtherSat, interfBfidx, mean(overlap)); % transmitgain
 InterfWithSatDown = InterfWithSatDown + ...
 thisInterfUser_power * G_othersat_interf * G_usr_interf * (lambdaDown.^2) / (((4*pi).^2)*(distance2InterfSat.^2));
 end 
 end
 
% if ~isempty(self.SatObj(interfSatIdx).beamfoot)
% interfUsrsOfSatOther = [interfUsrsOfSatOther self.SatObj(interfSatIdx).beamfoot(dpIdx, interfBeamf(interfBfidx)).usrs];
% end
 end
% end
 
% NumOfinterfUsrsOther = length(interfUsrsOfSatOther);
% for interfusrOtherIdx = 1 : NumOfinterfUsrsOther

% usrOtherInterfPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==interfUsrsOfSatOther(interfusrOtherIdx))).position; % interferenceusercoordinate
% usrOtherInterfPosInDescartes = LngLat2Descartes(usrOtherInterfPos, 0);
% vectorOfcurSat2interfUsr = [ ...
% satPosInDescartes(1) - usrOtherInterfPosInDescartes(1), ...
% satPosInDescartes(2) - usrOtherInterfPosInDescartes(2), ...
% satPosInDescartes(3) - usrOtherInterfPosInDescartes(3) ...
% ];
% vectorOfinterfSat2interfUsr = [ ...
% interfsatPosInDescartes(1) - usrOtherInterfPosInDescartes(1), ...
% interfsatPosInDescartes(2) - usrOtherInterfPosInDescartes(2), ...
% interfsatPosInDescartes(3) - usrOtherInterfPosInDescartes(3) ...
% ];
% OffAxisAngleOther = acos(abs(dot(vectorOfcurSat2interfUsr, vectorOfinterfSat2interfUsr))/...
% (sqrt(vectorOfcurSat2interfUsr(1)^2 + vectorOfcurSat2interfUsr(2)^2 + vectorOfcurSat2interfUsr(3)^2) * ...
% sqrt(vectorOfinterfSat2interfUsr(1)^2 + vectorOfinterfSat2interfUsr(2)^2 + vectorOfinterfSat2interfUsr(3)^2)));

% % Calculateinterferenceuser transmitgain
% if IfUsrAntennaDeGravity == 1
% [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrOtherInterfPos, satCurPos, usrOtherInterfPos, heightOfsat);
% G_otherusr_interfUp = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
% else 
% G_otherusr_interfUp = antenna.getUsrAntennaServG(OffAxisAngleOther, freqOfUpLink, true);
% end

% [UsrOtherInterfTheta, UsrOtherInterfPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrOtherInterfPos, heightOfsat);

% distance_Otherinterf = sqrt((satPosInDescartes(1)-usrOtherInterfPosInDescartes(1)).^2 + ...
% (satPosInDescartes(2)-usrOtherInterfPosInDescartes(2)).^2 + ...
% (satPosInDescartes(3)-usrOtherInterfPosInDescartes(3)).^2);

% G
% InterfWithSatUp = InterfWithSatUp + ...
% Pt_Usr * G_otherusr_interfUp * G_Othersat_Up * (lambdaUp.^2) / (((4*pi).^2)*(distance_Otherinterf.^2));
% end 
 end
 end
 %% C/I
 if self.Config.numOfMonteCarlo == 0
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, fc_Usr); % transmitgain
 lambda = 3e8/fc_Usr;
 Carrier_down = Pt_Usr * G_sat_down * G_usrDown * (lambda.^2) / (((4*pi).^2)*(distance.^2));
 DataObj(IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/(InterfWithSatDown+InterfInSatDown);
 DataObj(IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/InterfInSatDown;
% G
% if IfUsrAntennaDeGravity == 1
% [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
% G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
% else 
% G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
% end
% Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (lambdaUp.^2) / (((4*pi).^2)*(distance.^2));
% DataObj(IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/(InterfWithSatUp+InterfInSatUp);
% DataObj(IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/InterfInSatUp;
 else
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, fc_Usr); % transmitgain
 lambda = 3e8/fc_Usr;
 Carrier_down = Pt_Usr * G_sat_down * G_usrDown * (lambda.^2) / (((4*pi).^2)*(distance.^2));
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/(InterfWithSatDown+InterfInSatDown);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_down/InterfInSatDown;
% G
% if IfUsrAntennaDeGravity == 1
% [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
% G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
% else 
% G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
% end
% Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (lambdaUp.^2) / (((4*pi).^2)*(distance.^2));
% DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/(InterfWithSatUp+InterfInSatUp);
% DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 1) = Carrier_up/InterfInSatUp; 
 end
 %% C/(I+N)
 K = 1.38e-23; % 
 %%%%%%%%%%%%%%%
% Band = self.UsrsObj(UsrOrderCur).BandWidth;
 %%%%%%%%%%%%%%%
 Band = self.UsrsObj(UsrOrderCur).BandWidth(slotIdx);
 Ta_usr = self.UsrsObj(UsrOrderCur).T_noise;
 Ta_sat = self.SatObj(SatIdx).T_noise;
 F_usr = 10.^(self.UsrsObj(UsrOrderCur).F_noise/10);
 F_sat = 10.^(self.SatObj(SatIdx).F_noise/10);
 N_noise_usr = Band*K*(Ta_usr+(F_usr-1)*300);
% N_noise_sat = Band*K*(Ta_sat+(F_sat-1)*300);
% N_noise_usr = 6.9183e-21 * Band;
% N_noise_usr = K * 300 * Band;

 if self.Config.numOfMonteCarlo == 0
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, fc_Usr); % transmitgain
 lambda = 3e8/fc_Usr;
 Carrier_down = Pt_Usr * G_sat_down * G_usrDown * (lambda.^2) / (((4*pi).^2)*(distance.^2));
 DataObj(IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfWithSatDown+InterfInSatDown+N_noise_usr);
 DataObj(IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfInSatDown+N_noise_usr);
 
% G
% if IfUsrAntennaDeGravity == 1
% [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
% G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
% else 
% G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
% end
% Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (lambdaUp.^2) / (((4*pi).^2)*(distance.^2));
% DataObj(IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfWithSatUp+InterfInSatUp+N_noise_sat);
% DataObj(IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfInSatUp+N_noise_sat);
 else
 G_sat_down = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, IdxInLightBeamfoot, fc_Usr); % transmitgain
 lambda = 3e8/fc_Usr;
 Carrier_down = Pt_Usr * G_sat_down * G_usrDown * (lambda.^2) / (((4*pi).^2)*(distance.^2));
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfWithSatDown+InterfInSatDown+N_noise_usr);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Down(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_down/(InterfInSatDown+N_noise_usr);
 
% G
% if IfUsrAntennaDeGravity == 1
% [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
% G_usr_up = antenna.getUsrAntennaServG(tmp_angle, freqOfUpLink, true);
% else 
% G_usr_up = antenna.getUsrAntennaServG(0, freqOfUpLink, true);
% end
% Carrier_up = Pt_Usr * G_sat_up * G_usr_up * (lambdaUp.^2) / (((4*pi).^2)*(distance.^2));
% DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromAll_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfWithSatUp+InterfInSatUp+N_noise_sat);
% DataObj((MC_idx-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Up(MethodIdx, slotIdx, UsrOrderCur, 2) = Carrier_up/(InterfInSatUp+N_noise_sat); 
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
