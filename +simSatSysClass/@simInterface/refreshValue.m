function refreshValue(obj, controller)
%REFRESHVALUE Update controller values
% Update algorithm module results to controller
%% Update UsrsObj
 NumOfUsrs = obj.NumOfSelectedUsrs;
 NumOfMethod = obj.numOfMethods_BeamGenerate * obj.numOfMethods_BeamHopping;

 for k = 1 : NumOfUsrs
 controller.UsrsObj(k).Buffer = zeros(NumOfMethod, obj.ScheInShot);
 controller.UsrsObj(k).GenerTraffic = zeros(NumOfMethod, obj.ScheInShot);
 controller.UsrsObj(k).TransTraffic = zeros(NumOfMethod, obj.ScheInShot);
 controller.UsrsObj(k).Buffer(1) = obj.UsrsTraffic(k, 1);
 controller.UsrsObj(k).homeSat = obj.UsrsObj(k).homeSat;
 for idx = 1 : obj.ScheInShot
 for MethodIdx = 1 : NumOfMethod
 controller.UsrsObj(k).Buffer(MethodIdx, idx) = ...
 controller.UsrsObj(k).Buffer(MethodIdx, idx) + ...
 obj.UsrsTraffic(k, idx) - obj.UsrsTransPort(MethodIdx, k, idx);
 controller.UsrsObj(k).GenerTraffic(MethodIdx, :) = ...
 obj.UsrsTraffic(k, idx);
 controller.UsrsObj(k).TransTraffic(MethodIdx, :) = ...
 obj.UsrsTransPort(MethodIdx, k, idx);
 end
 end

 % New additions
 controller.UsrsObj(k).BandWidth = obj.UsrsObj(k).BandWidth;
 controller.UsrsObj(k).Band = obj.UsrsObj(k).Band;
 controller.UsrsObj(k).PowerPercent = obj.UsrsObj(k).PowerPercent;
 end
 %% About MethodIdx
 % numOfMethods_BeamGenerate = N
 % numOfMethods_BeamHopping = M

 % N 1 2 ... N
 % M 1 2 ... M 1 2 ... M ... 1 2 ... M
 % Idx 1 2 3 ... M M+1 M+2 ... 2M ... (N-1)M+1 (N-1)M+2 ... NM

 %%
% if controller.ifDebug == 1
% fprintf('UsrsObj update completed\n'); 
% end
%% Update SatObj
 NumOfSat = length(obj.OrderOfServSatCur);
 for k = 1 : NumOfSat
 controller.SatObj(k).servUsr = obj.SatObj(k).servUsr;
 controller.SatObj(k).numOfusrs = obj.SatObj(k).numOfusrs;

 controller.SatObj(k).SeqInSpanOfsigbeam = obj.SatObj(k).SeqInSpanOfsigbeam;
 controller.SatObj(k).TableOfSig = obj.SatObj(k).TableOfSig;

 controller.SatObj(k).numOfbeam_method0 = obj.tmpSat_0(k).NumOfBeamFoot;
 controller.SatObj(k).beamfoot_method0 = obj.tmpSat_0(k).beamfoot;

 controller.SatObj(k).BHST_combi_0 = obj.tmpSat_0(k).BHST_0;
 controller.SatObj(k).BHST_combi_5 = obj.tmpSat_0(k).BHST_1;
 controller.SatObj(k).BHST_combi_10 = obj.tmpSat_0(k).BHST_2;
 controller.SatObj(k).BHST_combi_15 = obj.tmpSat_0(k).BHST_3;
 controller.SatObj(k).BHST_combi_20 = obj.tmpSat_0(k).BHST_4;
 controller.SatObj(k).Pt_Antenna_combi_0 = obj.tmpSat_0(k).Pt_Antenna_0;
 controller.SatObj(k).Pt_Antenna_combi_5 = obj.tmpSat_0(k).Pt_Antenna_1;
 controller.SatObj(k).Pt_Antenna_combi_10 = obj.tmpSat_0(k).Pt_Antenna_2;
 controller.SatObj(k).Pt_Antenna_combi_15 = obj.tmpSat_0(k).Pt_Antenna_3;
 controller.SatObj(k).Pt_Antenna_combi_20 = obj.tmpSat_0(k).Pt_Antenna_4;

 if obj.numOfMethods_BeamGenerate >= 2
 controller.SatObj(k).numOfbeam_method1 = obj.tmpSat_1(k).NumOfBeamFoot;
 controller.SatObj(k).beamfoot_method1 = obj.tmpSat_1(k).beamfoot;
 controller.SatObj(k).BHST_combi_1 = obj.tmpSat_1(k).BHST_0;
 controller.SatObj(k).BHST_combi_6 = obj.tmpSat_1(k).BHST_1;
 controller.SatObj(k).BHST_combi_11 = obj.tmpSat_1(k).BHST_2;
 controller.SatObj(k).BHST_combi_16 = obj.tmpSat_1(k).BHST_3;
 controller.SatObj(k).BHST_combi_21 = obj.tmpSat_1(k).BHST_4;
 controller.SatObj(k).Pt_Antenna_combi_1 = obj.tmpSat_1(k).Pt_Antenna_0;
 controller.SatObj(k).Pt_Antenna_combi_6 = obj.tmpSat_1(k).Pt_Antenna_1;
 controller.SatObj(k).Pt_Antenna_combi_11 = obj.tmpSat_1(k).Pt_Antenna_2;
 controller.SatObj(k).Pt_Antenna_combi_16 = obj.tmpSat_1(k).Pt_Antenna_3;
 controller.SatObj(k).Pt_Antenna_combi_21 = obj.tmpSat_1(k).Pt_Antenna_4;
 end

 if obj.numOfMethods_BeamGenerate >= 3
 controller.SatObj(k).numOfbeam_method2 = obj.tmpSat_2(k).NumOfBeamFoot;
 controller.SatObj(k).beamfoot_method2 = obj.tmpSat_2(k).beamfoot;
 controller.SatObj(k).BHST_combi_2 = obj.tmpSat_2(k).BHST_0;
 controller.SatObj(k).BHST_combi_7 = obj.tmpSat_2(k).BHST_1;
 controller.SatObj(k).BHST_combi_12 = obj.tmpSat_2(k).BHST_2;
 controller.SatObj(k).BHST_combi_17 = obj.tmpSat_2(k).BHST_3;
 controller.SatObj(k).BHST_combi_22 = obj.tmpSat_2(k).BHST_4;
 controller.SatObj(k).Pt_Antenna_combi_2 = obj.tmpSat_2(k).Pt_Antenna_0;
 controller.SatObj(k).Pt_Antenna_combi_7 = obj.tmpSat_2(k).Pt_Antenna_1;
 controller.SatObj(k).Pt_Antenna_combi_12 = obj.tmpSat_2(k).Pt_Antenna_2;
 controller.SatObj(k).Pt_Antenna_combi_17 = obj.tmpSat_2(k).Pt_Antenna_3;
 controller.SatObj(k).Pt_Antenna_combi_22 = obj.tmpSat_2(k).Pt_Antenna_4;
 end

 if obj.numOfMethods_BeamGenerate >= 4
 controller.SatObj(k).numOfbeam_method3 = obj.tmpSat_3(k).NumOfBeamFoot;
 controller.SatObj(k).beamfoot_method3 = obj.tmpSat_3(k).beamfoot;
 controller.SatObj(k).BHST_combi_3 = obj.tmpSat_3(k).BHST_0;
 controller.SatObj(k).BHST_combi_8 = obj.tmpSat_3(k).BHST_1;
 controller.SatObj(k).BHST_combi_13 = obj.tmpSat_3(k).BHST_2;
 controller.SatObj(k).BHST_combi_18 = obj.tmpSat_3(k).BHST_3;
 controller.SatObj(k).BHST_combi_23 = obj.tmpSat_3(k).BHST_4;
 controller.SatObj(k).Pt_Antenna_combi_3 = obj.tmpSat_3(k).Pt_Antenna_0;
 controller.SatObj(k).Pt_Antenna_combi_8 = obj.tmpSat_3(k).Pt_Antenna_1;
 controller.SatObj(k).Pt_Antenna_combi_13 = obj.tmpSat_3(k).Pt_Antenna_2;
 controller.SatObj(k).Pt_Antenna_combi_18 = obj.tmpSat_3(k).Pt_Antenna_3;
 controller.SatObj(k).Pt_Antenna_combi_23 = obj.tmpSat_3(k).Pt_Antenna_4;
 end

 if obj.numOfMethods_BeamGenerate >= 5
 controller.SatObj(k).numOfbeam_method4 = obj.tmpSat_4(k).NumOfBeamFoot;
 controller.SatObj(k).beamfoot_method4 = obj.tmpSat_4(k).beamfoot;
 controller.SatObj(k).BHST_combi_4 = obj.tmpSat_4(k).BHST_0;
 controller.SatObj(k).BHST_combi_9 = obj.tmpSat_4(k).BHST_1;
 controller.SatObj(k).BHST_combi_14 = obj.tmpSat_4(k).BHST_2;
 controller.SatObj(k).BHST_combi_19 = obj.tmpSat_4(k).BHST_3;
 controller.SatObj(k).BHST_combi_24 = obj.tmpSat_4(k).BHST_4;
 controller.SatObj(k).Pt_Antenna_combi_4 = obj.tmpSat_4(k).Pt_Antenna_0;
 controller.SatObj(k).Pt_Antenna_combi_9 = obj.tmpSat_4(k).Pt_Antenna_1;
 controller.SatObj(k).Pt_Antenna_combi_14 = obj.tmpSat_4(k).Pt_Antenna_2;
 controller.SatObj(k).Pt_Antenna_combi_19 = obj.tmpSat_4(k).Pt_Antenna_3;
 controller.SatObj(k).Pt_Antenna_combi_24 = obj.tmpSat_4(k).Pt_Antenna_4;
 end
 end
 for idxOfSat = 1 : length(NumOfSat)
 for idxOfMethod = 1 : controller.numOfMethods_BeamGenerate
 eval(['numOfBf = controller.SatObj(idxOfSat).numOfbeam_method',num2str(idxOfMethod-1),';']);
 for idxOfbf = 1 : numOfBf
 for scheidx = 1 : controller.scheInShot
 eval(['tmpUsr = controller.SatObj(idxOfSat).beamfoot_method',num2str(idxOfMethod-1),'(scheidx, idxOfbf).usrs;']);
 tmpUsr = tmpUsr(tmpUsr~=0);
 for idx_usrs = 1 : length(tmpUsr)
 controller.Usr2SatCur(tmpUsr(idx_usrs),1+idxOfMethod,scheidx) = idxOfbf;
 end
 end
 end
 end
 end
 for idx_usrs = 1 : length(controller.Usr2SatCur(:,1,1))
 SatOrder = controller.Usr2SatCur(idx_usrs,1,1);
 if ~isempty(find(controller.OrderOfServSatCur==SatOrder, 1))
 satidx = find(controller.OrderOfServSatCur==SatOrder);
 for idxOfMethod = 1 : controller.numOfMethods_BeamGenerate
 eval(['numOfBf = controller.SatObj(satidx).numOfbeam_method',num2str(idxOfMethod-1),';']);
 for idxOfbf = 1 : numOfBf
 for scheidx = 1 : controller.scheInShot
 eval(['tmpflag = ~isempty(find(controller.SatObj(satidx).beamfoot_method',num2str(idxOfMethod-1),'(scheidx, idxOfbf).usrs==idx_usrs,1));']);
 if tmpflag == true
 controller.Usr2SatCur(idx_usrs,1+idxOfMethod,scheidx) = idxOfbf;
 end
 end
 end
 end
 end
 end
 %% Traffic statistics
 controller.UsrsTraffic = obj.UsrsTraffic;
 controller.UsrsTransPort = obj.UsrsTransPort;

% if controller.ifDebug == 1
% fprintf('SatObj update completed\n'); 
% end
end

