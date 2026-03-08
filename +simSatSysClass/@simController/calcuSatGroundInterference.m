 function DataObj = calcuSatGroundInterference(self,DataObj,IdxOfStep, MC_idx)
%CALCUSATGROUNDINTERFERENCE
% Calculate
%%
 NumOfSlotPerShot = self.slotInShot;
 NumOfSlotPerSche = self.subFInSche * self.slotInSubF; %schedulingperiodsubframe
 NumOfShot = length(self.SatPosition(1,:,1)) - 1; % simulationsnapshottotal(FinallysnapshotCalculate)

 NumOfSat = length(self.OrderOfServSatCur);
 NumOfInvesUsrs = self.numOfUsrs_inves;
 
 heightOfsat = self.Config.height; 
 numofBeam = self.Config.numOfServbeam;

 BSTx_dBm = self.Config.Pt_dBm_BS;
 BSTx = (10.^(BSTx_dBm/10))/1e3;%transmitpower，W
 BS_height = 15;%altitude

 Pt_TeUsr_dBm = self.UsrsObj(1).Pt_dBm;
 Pt_TeUsr = (10.^(Pt_TeUsr_dBm/10))/1e3; % W
 
% UserperBeam
 dense = self.Config.Userdense; %user

 %% satellitebeamParameter
 % satellitetrafficbeamtotalpower
 Pt_SAT_dBm_serv = self.SatObj(1).Pt_dBm_serv;

 Pt_SAT_serv = (10.^(Pt_SAT_dBm_serv/10))/1e3/numofBeam; % W
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 if self.Config.numOfSigbeam > 0
 Pt_SAT_dBm_signal = self.SatObj(1).Pt_dBm_signal;
 Pt_SAT_signal = (10.^(Pt_SAT_dBm_signal/10))/1e3/self.Config.numOfSigbeam; % W
 end

 Beam_radius = 10;%beamas/is10km

 %% satelliteuserParameter
 UsrAntennaConfig = antenna.initialUsrAntenna();
 IfUsrAntennaDeGravity = UsrAntennaConfig.ifDeGravity;
 IfUsrAntennaVSAT = UsrAntennaConfig.ifVSAT;%as/is1，as/isVSATterminal；as/is0，as/isterminal（）

 if IfUsrAntennaVSAT == 1
 Pt_Usr_dBm = 33;
 else
 Pt_Usr_dBm = self.UsrsObj(1).Pt_dBm;
 end
 Pt_Usr = (10.^(Pt_Usr_dBm/10))/1e3; % W %% Calculatenoise

 %% Calculatenoise
 K = 1.38e-23; % constant
 Band = self.Config.BandOfLink; % bandwidth
 Ta_usr = self.UsrsObj(1).T_noise;
 Ta_sat = self.SatObj(1).T_noise;
 if IfUsrAntennaVSAT == 1
 F_usr = 10.^((self.UsrsObj(1).F_noise-5.8)/10);
 else
 F_usr = 10.^(self.UsrsObj(1).F_noise/10);
 end
 F_sat = 10.^(self.SatObj(1).F_noise/10);
 N_noise_usr = Band*K*(Ta_usr+(F_usr-1)*300);
 N_noise_sat = Band*K*(Ta_sat+(F_sat-1)*300);

 
 Debug1 = 0; % f11FDD，，5G--satelliteUEreceive
 Debug2 = 0; % f12FDD，，UE--satellitereceive
 Debug3 = 0; % 5G--satellitereceive
 Debug4 = 0; % UE--satelliteUEreceive
 Debug5 = 0; % f21TDD，5G+UE--satellitereceive
 Debug6 = 0; % f22TDD，5G+UE--satelliteUEreceive

 if self.Config.TerrestrialDuplexing
 Debug1 = 1;Debug2 = 1;
 else
 Debug5 = 1;Debug6 = 1;
 end
 
 if Debug5
 Debug2 = 1; Debug3 = 1;
 end
 if Debug6 
 Debug1 = 1; Debug4 = 1;
 end
 if (Debug1 || Debug2 || Debug3 || Debug4) && (~Debug5 && ~Debug6)

 freqOfDL = 3560e6;
 freqOfUL = 3440e6;
 elseif Debug5 || Debug6

 freqOfDL = 4840e6;
 freqOfUL = 4840e6;
 end
 % corresponding
 theta3dB_UL = tools.find3dBAgle(freqOfUL);
 theta3dB_DL = tools.find3dBAgle(freqOfDL);

 % Generate
 self.generateBS(); 

 %% Traverseallalgorithm
 for MethodIdx = 1 : self.numOfMethods_BeamGenerate * self.numOfMethods_BeamHopping
 idxOfBG = ceil(MethodIdx/self.numOfMethods_BeamHopping);
 
 for slotIdx = 1 : NumOfSlotPerShot
 self.getBeamPoint(slotIdx,MethodIdx);
 dpIdx = ceil(slotIdx/NumOfSlotPerSche); % scheduling
 for SatIdx = 1 : NumOfSat %Traversesatellite
 eval(['numOfbeam = self.SatObj(SatIdx).numOfbeam_method',num2str(idxOfBG-1),';']);

 UserperBeam = numOfbeam(dpIdx);

 tmpNo = find(self.SatObj(SatIdx).servUsr <= NumOfInvesUsrs);
 UsrsOfSatCur = self.SatObj(SatIdx).servUsr(tmpNo); % Whenareauser
 NumOfUsrs = length(tmpNo); % usernumber

 LightBeamfoot = self.SatObj(SatIdx).LightBeamfoot; % When beam positionID/number
 LBF_BeamPoint = self.SatObj(SatIdx).BeamPoint; % When beam positionbeam,firstphi，secondtheta
 LBFnum = length(LightBeamfoot);
 Pos_Beam = zeros(LBFnum,2);%beamcentercoordinate
 for i = 1 : LBFnum
 Pos_Beam(i,:) = self.SatObj(SatIdx).beamfoot(dpIdx,LightBeamfoot(i)).position;
 end
 %sub
 satCurPos = self.SatObj(SatIdx).position; % Whensatellitesub-satellite pointcoordinate
 satPosInDescartes = LngLat2Descartes(satCurPos, heightOfsat);
 satCurnextPos = self.SatObj(SatIdx).nextpos; % Whensatellitesub-satellite pointstepcoordinate


 if Debug1
 nn = 40; %interferenceCalculaterange,satelliteUEas/iscenter，64km 
 for UsrIdx = 1 : NumOfUsrs %Traverseuser
 UsrOrderCur = UsrsOfSatCur(UsrIdx); % WhenuserID/number
 BeamfootOrderOfUsrCur = self.Usr2SatCur(UsrOrderCur, 1+ceil(MethodIdx/self.numOfMethods_BeamHopping), dpIdx); % Whenuserbeam position 
 
 % JudgeuserinWhen
 tmpOrderOfbeam = find(LightBeamfoot == BeamfootOrderOfUsrCur);
 % Judgeuseris
 usrCurPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).position; % Whenusercoordinate
 
 Areainv = self.BS_invArea;
 
 ifIn = (Areainv(1,1)<=usrCurPos(1))&&(usrCurPos(1)<=Areainv(1,2)) && ...
 (Areainv(2,1)<=usrCurPos(2))&&(usrCurPos(2)<=Areainv(2,2)); 
 
 % Ifuser
 if ~isempty(tmpOrderOfbeam) && ifIn
 % CalculateWhen
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrCurPos, heightOfsat);%Calculateand
 % Calculatesatellite
 G_sat_down1 = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, tmpOrderOfbeam, freqOfDL);
 % Calculateuserreceivegain
 if IfUsrAntennaDeGravity == 1
 u_s_distance = calcudistance(usrCurPos,satPosInDescartes);
 tmp_angle = getElevation(u_s_distance,heightOfsat);
 G_usrDown = antenna.getUsrAntennaServG(0.5*pi - tmp_angle, freqOfDL, 0);
 elseif IfUsrAntennaVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(usrCurPos, satCurPos, usrCurPos, heightOfsat);
 G_usrDown = antenna.getUsrAntennaServG(tmp_angle, freqOfDL, 0);
 else
 G_usrDown = antenna.getUsrAntennaServG(0, freqOfDL, 0);
 end
 
 % Calculatesatelliteuserreceivesatellite
 distance = calcudistance(usrCurPos,satPosInDescartes);
 PL1 = PL_Sat_Ground(distance,freqOfDL,pi,1);
 C_sat = Pt_SAT_serv * G_sat_down1 * G_usrDown * (10^(-0.1*PL1));
 

 tempBS = findClosestBS(self,usrCurPos);
 row = size(self.BS_array,1);col = size(self.BS_array,2);
 x1 = (tempBS(1)-nn>0)*(tempBS(1)-nn) + (tempBS(1)-nn<=0);
 y1 = (tempBS(2)-nn>0)*(tempBS(2)-nn) + (tempBS(2)-nn<=0);
 x2 = (tempBS(1)+nn<=row)*(tempBS(1)+nn) + (tempBS(1)+nn>row)*row;
 y2 = (tempBS(2)+nn<=col)*(tempBS(2)+nn) + (tempBS(2)+nn>col)*col;
 a = x2 - x1 + 1;
 b = y2 - y1 + 1;
 I1 = zeros(a,b);
 tempco1 = usrCurPos;
 if IfUsrAntennaDeGravity == 1
 tmp_angle = (rand()*10)*pi/180;
 G_usrDown_intf = antenna.getUsrAntennaServG(tmp_angle, freqOfDL, 0);
 elseif IfUsrAntennaVSAT == 1
 
 G_usrDown_intf = antenna.getUsrAntennaServG(0.5*pi, freqOfDL, false);
 else
 G_usrDown_intf = antenna.getUsrAntennaServG(0, freqOfDL, false);
 end
 for i = 1:a
 for j = 1:b
 tempco2 = self.BS_array(x1+i-1,y1+j-1,:);
 tempdist = tools.calcuDist(tempco1(1),tempco2(1),tempco1(2),tempco2(2));
 temptheta = abs((pi/18-atan(BS_height/tempdist))+(50+rand()*30)/180*pi);
 tempphi = (rand()*180)*pi/180;
 PL2 = PL_Ground_Ground(tempdist,freqOfDL);
 tempBSgain = antenna.getBSAntennaServG([temptheta,tempphi],[0,0],freqOfDL);
 I1(i,j) = BSTx * tempBSgain * G_usrDown_intf * (10^(-PL2/10));
 end
 end
 I_BS1 = sum(I1,'all');
 if ~MC_idx
 DataObj(IdxOfStep).Interf1(MethodIdx, slotIdx, UsrOrderCur, 1) = C_sat/ (N_noise_usr + I_BS1);
 DataObj(IdxOfStep).Interf1(MethodIdx, slotIdx, UsrOrderCur, 2) = I_BS1;
 DataObj(IdxOfStep).Interf1(MethodIdx, slotIdx, UsrOrderCur, 3) = C_sat/ I_BS1;
 else
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf1(MethodIdx, slotIdx, UsrOrderCur, 1) = C_sat/ (N_noise_usr + I_BS1);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf1(MethodIdx, slotIdx, UsrOrderCur, 2) = I_BS1;
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf1(MethodIdx, slotIdx, UsrOrderCur, 3) = C_sat/ I_BS1;
 end
 
 end
 end
 end

 if Debug2
 if ~isempty(self.SatObj(SatIdx).beamfoot)
 l = 100;
 for lbfidx = 1 : LBFnum
 tempinv = self.BS_invArea;
 ifIn = (tempinv(1,1)<=Pos_Beam(lbfidx,1))&&(Pos_Beam(lbfidx,1)<=tempinv(1,2)) && ...
 (tempinv(2,1)<=Pos_Beam(lbfidx,2))&&(Pos_Beam(lbfidx,2)<=tempinv(2,2)); 
 if ifIn 
 tempinv = [tools.d2Lon(Pos_Beam(lbfidx,2),Pos_Beam(lbfidx,1),-Beam_radius*1e3) , tools.d2Lon(Pos_Beam(lbfidx,2),Pos_Beam(lbfidx,1),Beam_radius*1e3);...
 Pos_Beam(lbfidx,2)-Beam_radius/110 , Pos_Beam(lbfidx,2)+Beam_radius/110];%first，second
 unitlon = abs(tempinv(1,2) - tempinv(1,1))/l;
 unitlat = abs(tempinv(2,2) - tempinv(2,1))/l;
 
 temppos = zeros(l,l,2);
 I2 = zeros(l,l);
 
 % Calculatesatelliteusertransmit
 G_satup = self.SatObj(SatIdx).getAntennaServG(LBF_BeamPoint(lbfidx,2), LBF_BeamPoint(lbfidx,1), lbfidx, freqOfUL);
 
 if IfUsrAntennaDeGravity == 1
 u_s_distance = calcudistance(Pos_Beam(lbfidx,:),satPosInDescartes);
 tmp_angle = getElevation(u_s_distance,heightOfsat);
 G_usrup = antenna.getUsrAntennaServG(0.5*pi - tmp_angle, freqOfUL, 1);
 elseif IfUsrAntennaVSAT == 1
 [tmp_angle, ~, ~] = simSatSysClass.tools.getAngleOfInterfSat(Pos_Beam(lbfidx,:), satCurPos, Pos_Beam(lbfidx,:), heightOfsat);
 G_usrup = antenna.getUsrAntennaServG(tmp_angle, freqOfUL, 1);
 else
 G_usrup = antenna.getUsrAntennaServG(1,freqOfUL,1);
 end

 distance = calcudistance(Pos_Beam(lbfidx,:),satPosInDescartes);
 PL = PL_Sat_Ground(distance,freqOfUL, pi,1);
 C_usr = UserperBeam * Pt_Usr * G_usrup * 10^(-0.1 * PL) * G_satup;
 
 % Calculate
 G_Teusr = 10^-0.35;
 for i = 1:l
 for j = 1:l
 temppos(i,j,1) = tempinv(1,1) + (i-0.5)*unitlon;
 temppos(i,j,2) = tempinv(2,2) - (j-0.5)*unitlat;
 tempdistance = calcudistance(temppos(i,j,:),satPosInDescartes);
 tempelevation = getElevation(tempdistance,heightOfsat);
 tempPL = PL_Sat_Ground(tempdistance,freqOfUL,tempelevation,1);
 %Calculate
 [temptheta,tempphi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, temppos(i,j,:), heightOfsat);
 G_sat_up1 = self.SatObj(SatIdx).getAntennaServG(temptheta, tempphi, lbfidx, freqOfUL);
 I2(i,j) = dense * (Beam_radius/l)^2 * Pt_TeUsr * G_Teusr * 10^(-0.1 * tempPL) * G_sat_up1;
 end
 end
 
 I_UE1 = sum(I2,'all');
 if ~MC_idx
 DataObj(IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, lbfidx, 1) = C_usr / (N_noise_sat + I_UE1);
 DataObj(IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, lbfidx, 2) = I_UE1;
 DataObj(IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, lbfidx, 3) = C_usr / I_UE1;
 else
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, lbfidx, 1) = C_usr / (N_noise_sat + I_UE1);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, lbfidx, 2) = I_UE1;
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, lbfidx, 3) = C_usr / I_UE1;
 end
 end
 end
 end
 end

 if Debug3 
 if ~isempty(self.SatObj(SatIdx).beamfoot)
 
 for idx = 1 : LBFnum
 
% tmptheta = abs(LBF_BeamPoint(idx,2));
% tmpbr = theta3dB_DL;
% tbr
 n = round(2*Beam_radius/0.8); 
 %Calculatesatelliteusertransmitpower
 distance = calcudistance(Pos_Beam(idx,:),satPosInDescartes);
 PL = PL_Sat_Ground(distance,freqOfDL, pi,1);
 G_satup = self.SatObj(SatIdx).getAntennaServG(LBF_BeamPoint(idx,2), LBF_BeamPoint(idx,1), idx, freqOfDL);
 
 if IfUsrAntennaDeGravity == 1
 u_s_distance = calcudistance(Pos_Beam(idx,:),satPosInDescartes);
 tmp_angle = getElevation(u_s_distance,heightOfsat);
 G_usrup = antenna.getUsrAntennaServG(0.5*pi - tmp_angle, freqOfDL, 1);
 elseif IfUsrAntennaVSAT == 1
 u_s_distance = calcudistance(Pos_Beam(idx,:),satPosInDescartes);
 tmp_angle = getElevation(u_s_distance,heightOfsat);
 G_usrup = antenna.getUsrAntennaServG(tmp_angle, freqOfDL, 1);
 else
 G_usrup = antenna.getUsrAntennaServG(1,freqOfDL,1);
 end
 
 C_usr = UserperBeam * Pt_Usr * G_usrup * 10^(-0.1 * PL) * G_satup;
 
 %IfbeaminGenerate
 tempinv = self.BS_invArea;
 ifIn = (tempinv(1,1)<=Pos_Beam(idx,1))&&(Pos_Beam(idx,1)<=tempinv(1,2)) && ...
 (tempinv(2,1)<=Pos_Beam(idx,2))&&(Pos_Beam(idx,2)<=tempinv(2,2)); 
 
 if ifIn
 tempBS = findClosestBS(self,Pos_Beam(idx,:));
 row = size(self.BS_array,1);col = size(self.BS_array,2);
 x1 = (tempBS(1)-n>0)*(tempBS(1)-n) + (tempBS(1)-n<=0);
 y1 = (tempBS(2)-n>0)*(tempBS(2)-n) + (tempBS(2)-n<=0);
 x2 = (tempBS(1)+n<=row)*(tempBS(1)+n) + (tempBS(1)+n>row)*row;
 y2 = (tempBS(2)+n<=col)*(tempBS(2)+n) + (tempBS(2)+n>col)*col;
 a = x2 - x1 + 1;
 b = y2 - y1 + 1;
 I3 = zeros(a,b);
 for i = 1:a
 for j = 1:b
 tempco1 = self.BS_array(x1+i-1,y1+j-1,:);
 tempdist = calcudistance(tempco1,satPosInDescartes);
 tempele = getElevation(tempdist,heightOfsat);
 flag1 = tempele + 32.5*pi/180 + rand()*25*pi/180;
 temptheta = (flag1<pi/2) * (pi/2 - flag1);
 tempphi = (rand()*180)*pi/180;
 tempPL = PL_Sat_Ground(tempdist,freqOfDL,tempele,1);
 while PL - tempPL > 5
 tempPL = PL_Sat_Ground(tempdist,freqOfDL,tempele,1);
 end
 tempBSgain = antenna.getBSAntennaServG([temptheta,tempphi],[0,0],freqOfDL);
 [tmptheta,tmpphi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, tempco1, heightOfsat);
 G_sat_up2 = self.SatObj(SatIdx).getAntennaServG(tmptheta, tmpphi, idx, freqOfDL);
 I3(i,j) = BSTx * tempBSgain * G_sat_up2 * (10^(-tempPL/10));
 end
 end
 I_BS2 = sum(I3,'all');
 if ~MC_idx
 DataObj(IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, idx, 1) = C_usr / (N_noise_sat + I_BS2);
 DataObj(IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, idx, 2) = I_BS2;
 DataObj(IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, idx, 3) = C_usr / I_BS2;
 else
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, idx, 1) = C_usr / (N_noise_sat + I_BS2);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, idx, 2) = I_BS2;
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, idx, 3) = C_usr / I_BS2;
 end
 end
 end 
 end
 
 end

 if Debug4
 for UsrIdx = 1 : NumOfUsrs %Traverseuser

 UsrOrderCur = UsrsOfSatCur(UsrIdx); % WhenuserID/number
 BeamfootOrderOfUsrCur = self.Usr2SatCur(UsrOrderCur, 1+ceil(MethodIdx/self.numOfMethods_BeamHopping), dpIdx); % Whenuserbeam position 
 % JudgeuserinWhen
 tmpOrderOfbeam = find(LightBeamfoot == BeamfootOrderOfUsrCur);

 % When
 usrCurPos = self.UsrsObj(find(self.OrderOfSelectedUsrs==UsrOrderCur)).position; 

 Areainv = self.BS_invArea;
 
 ifIn = (Areainv(1,1)<=usrCurPos(1))&&(usrCurPos(1)<=Areainv(1,2)) && ...
 (Areainv(2,1)<=usrCurPos(2))&&(usrCurPos(2)<=Areainv(2,2)); 

 % Ifuser
 if ~isempty(tmpOrderOfbeam) && ifIn 
 
 k = 50;
 tempinv = [tools.d2Lon(usrCurPos(2), usrCurPos(1), -Beam_radius*1e3), tools.d2Lon(usrCurPos(2), usrCurPos(1), Beam_radius*1e3);...
 usrCurPos(2) - Beam_radius/110, usrCurPos(2) + Beam_radius/110];
 unitlon = abs(tempinv(1,2) - tempinv(1,1))/k;
 unitlat = abs(tempinv(2,2) - tempinv(2,1))/k;
 temppos = zeros(k,k,2);
 I4 = zeros(k,k);
 tempdistance = I4;
 
 % CalculateWhen
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrCurPos, heightOfsat);%Calculateand
 % Calculatesatellite
 G_sat_down2 = self.SatObj(SatIdx).getAntennaServG(UsrTheta, UsrPhi, tmpOrderOfbeam, freqOfUL);
 % Calculateuserreceivegain
 if IfUsrAntennaDeGravity == 1
 u_s_distance = calcudistance(usrCurPos,satPosInDescartes);
 tmp_angle = getElevation(u_s_distance,heightOfsat);
 G_usrDown1 = antenna.getUsrAntennaServG(0.5*pi - tmp_angle, freqOfUL, 0);
 elseif IfUsrAntennaVSAT == 1
 u_s_distance = calcudistance(usrCurPos,satPosInDescartes);
 tmp_angle = getElevation(u_s_distance,heightOfsat);
 G_usrDown1 = antenna.getUsrAntennaServG(0.5*pi - tmp_angle, freqOfUL, 0);
 else
 G_usrDown1 = antenna.getUsrAntennaServG(0, freqOfUL, 0);
 end
 
 % CalculateWhen
 distance = calcudistance(usrCurPos,satPosInDescartes);
 PL1 = PL_Sat_Ground(distance,freqOfUL,pi,1);
 %CalculatesatelliteUEreceivepower
 C_sat = Pt_SAT_serv * G_sat_down2 * 10^(-0.1*PL1) * G_usrDown1;

 
 G_Teusr = 10^-0.35;
 if IfUsrAntennaDeGravity == 1
 tmp_angle = (rand()*10)*pi/180;
 G_usrDown2 = antenna.getUsrAntennaServG(tmp_angle, freqOfUL, 0);
 elseif IfUsrAntennaVSAT == 1
 
 G_usrDown2 = antenna.getUsrAntennaServG((65+25*rand())*pi/180, freqOfUL, 0);
 else
 G_usrDown2 = antenna.getUsrAntennaServG(0, freqOfUL, 0);
 end
 for i = 1:k
 for j = 1:k
 temppos(i,j,1) = tempinv(1,1) + (i-0.5)*unitlon;
 temppos(i,j,2) = tempinv(2,2) - (j-0.5)*unitlat;
 tempdistance(i,j) = tools.calcuDist(temppos(i,j,1), usrCurPos(1), temppos(i,j,2), usrCurPos(2));
 if tempdistance(i,j) < 200
 continue;
 end
 tempPL = PL_Ground_Ground(tempdistance(i,j),freqOfUL);
 I4(i,j) = dense * (Beam_radius/k)^2 * Pt_TeUsr * G_Teusr * 10^(-0.1 * tempPL) * G_usrDown2;
 end
 end
 I_UE2 = sum(I4,'all');
 if ~MC_idx
 DataObj(IdxOfStep).Interf4(MethodIdx, slotIdx, UsrOrderCur, 1) = C_sat / (I_UE2 + N_noise_usr);
 DataObj(IdxOfStep).Interf4(MethodIdx, slotIdx, UsrOrderCur, 2) = I_UE2;
 DataObj(IdxOfStep).Interf4(MethodIdx, slotIdx, UsrOrderCur, 3) = C_sat / I_UE2;
 else
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf4(MethodIdx, slotIdx, UsrOrderCur, 1) = C_sat / (I_UE2 + N_noise_usr);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf4(MethodIdx, slotIdx, UsrOrderCur, 2) = I_UE2;
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf4(MethodIdx, slotIdx, UsrOrderCur, 3) = C_sat / I_UE2;
 end
 end
 end
 end
%%
 if Debug5
 if ~MC_idx
 C1 = zeros(1,1,1,length(DataObj(IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, :, 1)));
 C2 = C1;
 C1(:) = DataObj(IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, :, 2) .*...
 DataObj(IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, :, 3);
 C2(:) = DataObj(IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, :, 2) .*...
 DataObj(IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, :, 3);
 C = min(C1,C2);
 DataObj(IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 2) = ...
 DataObj(IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, :, 2) + ...
 DataObj(IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, :, 2);
 DataObj(IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 1) = ...
 C./(DataObj(IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 2) + N_noise_sat);
 DataObj(IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 3) = ...
 C./DataObj(IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 2);
 else
 C1 = zeros(1,1,1,length(DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, :, 1)));
 C2 = C1;
 C1(:) = DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, :, 2) .*...
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, :, 3);
 C2(:) = DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, :, 2) .*...
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, :, 3);
 C = min(C1,C2);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 2) = ...
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf2(MethodIdx, slotIdx, SatIdx, :, 2) + ...
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf3(MethodIdx, slotIdx, SatIdx, :, 2);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 1) = ...
 C./(DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 2) + N_noise_sat);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 3) = ...
 C./DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf5(MethodIdx, slotIdx, SatIdx, :, 2);
 end
 end
%%
 if Debug6
 if ~MC_idx
 C1 = zeros(1,1,length(DataObj(IdxOfStep).Interf1(MethodIdx, slotIdx, :, 1)));
 C2 = C1;
 C1(:) = DataObj(IdxOfStep).Interf1(MethodIdx, slotIdx, :, 2) .* ...
 DataObj(IdxOfStep).Interf1(MethodIdx, slotIdx, :, 3);
 C2(:) = DataObj(IdxOfStep).Interf4(MethodIdx, slotIdx, :, 2) .* ...
 DataObj(IdxOfStep).Interf4(MethodIdx, slotIdx, :, 3);
 C = min(C1,C2);
 DataObj(IdxOfStep).Interf6(MethodIdx, slotIdx, :, 2) = ...
 DataObj(IdxOfStep).Interf1(MethodIdx, slotIdx, :, 2) + ...
 DataObj(IdxOfStep).Interf4(MethodIdx, slotIdx, :, 2);
 DataObj(IdxOfStep).Interf6(MethodIdx, slotIdx, :, 1) = ...
 C./(DataObj(IdxOfStep).Interf6(MethodIdx, slotIdx, :, 2) + N_noise_usr);
 DataObj(IdxOfStep).Interf6(MethodIdx, slotIdx, :, 3) = ...
 C./DataObj(IdxOfStep).Interf6(MethodIdx, slotIdx, :, 2);
 else
 C1 = zeros(1,1,length(DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf1(MethodIdx, slotIdx, :, 1)));
 C2 = C1;
 C1(:) = DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf1(MethodIdx, slotIdx, :, 2) .* ...
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf1(MethodIdx, slotIdx, :, 3);
 C2(:) = DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf4(MethodIdx, slotIdx, :, 2) .* ...
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf4(MethodIdx, slotIdx, :, 3);
 C = min(C1,C2);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf6(MethodIdx, slotIdx, :, 2) = ...
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf1(MethodIdx, slotIdx, :, 2) + ...
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf4(MethodIdx, slotIdx, :, 2);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf6(MethodIdx, slotIdx, :, 1) = ...
 C./(DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf6(MethodIdx, slotIdx, :, 2) + N_noise_usr);
 DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf6(MethodIdx, slotIdx, :, 3) = ...
 C./DataObj((MC_idx-1)*NumOfShot+IdxOfStep).Interf6(MethodIdx, slotIdx, :, 2);
 end
 end
 
 end
 fprintf('%dsnapshot%dalgorithminterferenceCalculate%f%%\n', IdxOfStep, MethodIdx, slotIdx*100/NumOfSlotPerShot); 
 end
 end
 end

 function distance = calcudistance(terrpos,SatposInDesc)
 terrposInDesc = LngLat2Descartes(terrpos,0);
 distance = norm(terrposInDesc - SatposInDesc);
 end

 function alpha = getElevation(distance,hofsat)
 R = 6371.393e3; % 
 alpha = acos((R^2 + distance^2 - (R+hofsat)^2) / (2 * distance * R)) - 0.5 * pi;
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
function PL = PL_Sat_Ground(d,fc,angle,scenario)
% based on3GPP TR38.811
 %scenarioas
 %sigma(1)isLOS
 %sigma(2)isNLOS
 %Probas


 %angle
 angle = ceil(angle*18/pi);

 lambda = 3e8/fc;
 PL_fs = fspl(d,lambda);

 if scenario == 1
 switch angle
 case {0,1}
 Prob = 0.246; sigma = [1.79,8.93]; CL = 19.52;
 case 2
 Prob = 0.386; sigma = [1.14,9.08]; CL = 18.17;
 case 3
 Prob = 0.493; sigma = [1.14,8.78]; CL = 18.42;
 case 4
 Prob = 0.613; sigma = [0.92,10.25]; CL = 18.28;
 case 5
 Prob = 0.726; sigma = [1.42,10.56]; CL = 18.63;
 case 6
 Prob = 0.805; sigma = [1.56,10.74]; CL = 17.68;
 case 7
 Prob = 0.919; sigma = [0.85,10.17]; CL = 16.50;
 case 8
 Prob = 0.968; sigma = [0.72,11.52]; CL = 16.30;
 case 9
 Prob = 0.992; sigma = [0.72,11.52]; CL = 16.30;
 case 18
 Prob = 1; sigma = [0.72,11.52]; CL = 16.30;
 end 
 a = rand();
 if a >= Prob
 %NLOS
 while 1
 SF = normrnd(0,sigma(2));
 if abs(SF) <= 20
 break;
 end
 end
 PL_b = PL_fs + SF + CL;
 else
 %LOS
 while 1
 SF = normrnd(0,sigma(1));
 if abs(SF) <= 10
 break;
 end
 end
 PL_b = PL_fs + SF;
 end
 elseif scenario == 2
 switch angle
 case {0,1}
 Prob = 0.782; sigma = [4,6]; CL = 34.3;
 case 2
 Prob = 0.869; sigma = [4,6]; CL = 30.9;
 case 3
 Prob = 0.919; sigma = [4,6]; CL = 29.0;
 case 4
 Prob = 0.929; sigma = [4,6]; CL = 27.7;
 case 5
 Prob = 0.935; sigma = [4,6]; CL = 26.8;
 case 6
 Prob = 0.94; sigma = [4,6]; CL = 26.2;
 case 7
 Prob = 0.949; sigma = [4,6]; CL = 25.8;
 case 8
 Prob = 0.952; sigma = [4,6]; CL = 25.5;
 case 9
 Prob = 0.998; sigma = [4,6]; CL = 25.5;
 case 18
 Prob = 1; sigma = [4,6]; CL = 25.5;
 end 
 a = rand();
 if a >= Prob
 %NLOS
 while 1
 SF = normrnd(0,sigma(2));
 if abs(SF) <= 12
 break;
 end
 end
 PL_b = PL_fs + SF + CL;
 else
 %LOS
 while 1
 SF = normrnd(0,sigma(1));
 if abs(SF) <= 8
 break;
 end
 end
 PL_b = PL_fs + SF;
 end
 end

 PL_g = 0.03;

 PL_s = 0;
 %%totalpathloss
 PL = PL_b + PL_g + PL_s;

end

function PL = PL_Ground_Ground(d,f)
% based onITU

 c = 3e8;
 lambda = c/f;

 PL_b = fspl(d,lambda);

 delta_l = 4;
 delta_s = 6;
 p = 50;
 d1 = d/1000;
	f1 = f/1e9;
 if d1 <= 2
 L_s = 32.98 + 23.9.*log10(d1)+3*log10(f1);
 L_l = -2*log10(10^(-5*log10(f1)-12.5)+10^(-16.5));
 delta_cb = sqrt((delta_l.^2.*10.^(-0.2.*L_l)+delta_s.^2.*10.^(-0.2.*L_s)) ...
 ./(10.^(-0.2.*L_l) + 10.^(-0.2.*L_s)));
 Lc = -5.*log10(10.^(-0.2.*L_l) + 10.^(-0.2.*L_s)) - delta_cb .* qfuncinv(p/100);
 else 
 L_s = 32.98 + 23.9.*log10(2)+3*log10(f1);
 L_l = -2*log10(10^(-5*log10(f1)-12.5)+10^(-16.5));
 delta_cb = sqrt((delta_l.^2*10^(-0.2.*L_l)+delta_s^2*10^(-0.2.*L_s)) ...
 ./(10^(-0.2*L_l) + 10^(-0.2.*L_s)));
 Lc = -5.*log10(10^(-0.2.*L_l) + 10^(-0.2.*L_s)) - delta_cb * qfuncinv(p/100);
 end
 %% totalpathloss
 PL = PL_b + Lc ;
end



