% Core function for simulation platform operation
% All simulation modules run attached to this Method
%%
function DataObj = run(self)
 NumOfShot = length(self.SatPosition(1,:,1)) - 1; % Total number of simulation snapshots (last snapshot not calculated)
 %% Consider edge effects, perform wrapAround
 if self.Config.ifWrapAround == 1
 self.findWrap();
 if self.ifDebug == 1
 fprintf('wrapAround extension completed\n'); 
 end
 end
 %% Discretize the input rectangular area range into equilateral triangles
 % Get center point and vertex coordinates of each equilateral triangle
 self.DiscrInvesArea();
 if self.ifDebug == 1
 fprintf('Area discretization completed\n');
 end
 
 %% Get sequence numbers of triangles in core investigation area (under wrapAround)
 if self.Config.ifWrapAround == 1
 self.getDiscrInNonWrap();
 if self.ifDebug == 1
 fprintf('Core area discretization completed\n');
 end
 end
 
 %% CP type and slot configuration
 % Normal CP type: one slot contains 14 OFDM symbols
 % Extended CP type: one slot contains 12 OFDM symbols
 % One Frame = 10 Subframes, one Subframe = 1ms
 
 % Subcarrier spacing configuration
 switch self.Config.SCS
 case 15e3
 self.slotInSubF = 1; % Time slots per subframe
 self.timeInSlot = 1e-3; % Each time slot length
 case 30e3
 self.slotInSubF = 2; % Time slots per subframe
 self.timeInSlot = 0.5e-3; % Each time slot length
 case 60e3
 self.slotInSubF = 4; % Time slots per subframe
 self.timeInSlot = 0.25e-3; % Each time slot length
 case 120e3
 self.slotInSubF = 8; % Time slots per subframe
 self.timeInSlot = 0.125e-3; % Each time slot length
 case 240e3
 self.slotInSubF = 16; % Time slots per subframe
 self.timeInSlot = 0.0625e-3;% Each time slot length
 end
 
 %---------------------------------------------------------------------- 
 % Subframes per snapshot
 NumOfSubFramePerShot = floor(self.Config.duration/(self.timeInSlot*self.slotInSubF)); 
 % Subframes per beam scheduling period
 NumOfSubFramePerSche = floor(self.Config.bhTime/self.timeInSlot/self.slotInSubF); 
 % Beam scheduling periods per snapshot
 NumOfSchePerShot = floor(NumOfSubFramePerShot/NumOfSubFramePerSche); 
 % Recalculate subframes per snapshot based on scheduling periods
 NumOfSubFramePerShot = NumOfSubFramePerSche * NumOfSchePerShot; 
 % Time slots per snapshot
 NumOfSlotPerShot = NumOfSubFramePerShot * self.slotInSubF;
 %---------------------------------------------------------------------- 
 self.scheInShot = NumOfSchePerShot;
 self.subFInSche = NumOfSubFramePerSche;
 self.subFInShot = NumOfSubFramePerShot;
 self.slotInShot = NumOfSlotPerShot;
 %---------------------------------------------------------------------- 
 % Create class instances for storing simulation data
 DataObj = simSatSysClass.dataObj.empty(NumOfShot, 0);
 %% Whether Monte Carlo
 if self.Config.numOfMonteCarlo == 0
 numOfMethods = (self.numOfMethods_BeamGenerate) * (self.numOfMethods_BeamHopping);
 %% Traverse all snapshots
 for IdxOfStep = 1 : NumOfShot
 %% User coordinates self.UsrsPosition generation
 if self.Config.ifFixedUsrsNum == true % Generate fixed number and location of users
% if IdxOfStep == 1
 if self.Config.ifWrapAround == 1
 self.numOfUsrs_inves = self.Config.meanUsrsNum; % Number of users in investigation area
 % Get user distribution density
 HeightOfArea = tools.LatLngCoordi2Length( ...
 [0, self.Config.rangeOfInves(2,1)], ...
 [0, self.Config.rangeOfInves(2,2)], ...
 self.rOfearth);
 LengthOfArea = self.rOfearth * ...
 cos(self.Config.rangeOfInves(2,2)*pi/180) * ...
 abs(self.Config.rangeOfInves(1,1)-self.Config.rangeOfInves(1,2))*pi/180;
 AreaOfInves = HeightOfArea * LengthOfArea;
 DensOfUsrs = self.numOfUsrs_inves/AreaOfInves;
 % Get total number of users in area considering wrapAround
 HeightOfAreaInAll = tools.LatLngCoordi2Length( ...
 [0, self.wrapRange(2,1)], ...
 [0, self.wrapRange(2,2)], ...
 self.rOfearth);
 LengthOfAreaInAll = self.rOfearth * ...
 cos(self.wrapRange(2,2)*pi/180) * ...
 abs(self.wrapRange(1,1)-self.wrapRange(1,2))*pi/180;
 AreaOfAll = HeightOfAreaInAll * LengthOfAreaInAll;
 self.numOfUsrs_all = fix(DensOfUsrs * AreaOfAll); 
 % Get UsrsPosition
 NumOfSeqInves = length(self.SeqDiscrInNonWrap); % Total number of discrete triangles in investigation area
 NumOfSeqAll = length(self.SeqDiscrArea(:,1)); % Total number of discrete triangles in entire area
 selectedTriInves = sort(randperm(NumOfSeqInves, self.numOfUsrs_inves)); % Sampling in investigation area
 selectedTriWrap = sort(randperm(NumOfSeqAll, self.numOfUsrs_all)); % Sampling in entire wrap area
 [~, PosInselectedAll, ~] = intersect(selectedTriWrap,self.SeqDiscrInNonWrap); % Find virtual users in investigation area
 selectedTriWrap(PosInselectedAll) = []; % Remove virtual users in investigation area
 self.numOfUsrs_all = length(selectedTriWrap) + length(selectedTriInves);
 self.UsrsPosition = zeros(self.numOfUsrs_all, 3);
 for k = 1 : self.numOfUsrs_all
 if k <= self.numOfUsrs_inves
 self.UsrsPosition(k, 3) = self.SeqDiscrInNonWrap(selectedTriInves(k)); % Sequence number of this user's triangle in full wrap area
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 else
 self.UsrsPosition(k, 3) = selectedTriWrap(k-self.numOfUsrs_inves);
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 end
 end
 else
 self.numOfUsrs_inves = self.Config.meanUsrsNum;
 self.numOfUsrs_all = self.numOfUsrs_inves;
 % Get UsrsPosition
 NumOfSeqAll = length(self.SeqDiscrArea(:,1)); % Total number of discrete triangles in entire area
 selectedTriInves = sort(randperm(NumOfSeqAll, self.numOfUsrs_inves)); % Sampling in investigation area
 self.UsrsPosition = zeros(self.numOfUsrs_inves, 3);
 for k = 1 : self.numOfUsrs_inves
 self.UsrsPosition(k, 3) = selectedTriInves(k);
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 end
 end
 if self.ifDebug == 1
 fprintf('User location generation completed\n'); 
 end
% end
 else % Regenerate users every intervalStep satellite spatial state update steps
 if mod((IdxOfStep-1),self.Config.intervalStep) == 0
 self.getUsrsPositionInPossion();
 if self.ifDebug == 1
 fprintf('Snapshot %d user location generation completed\n',IdxOfStep); 
 end 
 end
 end
 %% Pre-calculation
 % NumOfVisibleSat Number of visible satellites in current snapshot 
 % OrderOfVisibleSat Set of visible satellite sequence numbers in current snapshot

 VisibleSatSet = self.VisibleSat(:,IdxOfStep,:); 
 % Calculate number of visible satellites in current snapshot
 NumOfSat = length(self.VisibleSat(:,1,1));
 NumOfVisibleSat = NumOfSat; 
 for i = 1 : NumOfSat
 if VisibleSatSet(i, 1) == 500
 NumOfVisibleSat = NumOfVisibleSat - 1; 
 end
 end
 % CalculateWhen
 OrderOfVisibleSat = zeros(NumOfVisibleSat,1);
 tmpN = 1;
 for i = 1 : NumOfSat
 if VisibleSatSet(i, 1) ~= 500
 OrderOfVisibleSat(tmpN) = i; 
 tmpN = tmpN + 1;
 end
 end 
 %% Calculate visible satellite service coverage in investigation area and determine user assignments, create service satellite object instances
 self.calcuSatServArea(OrderOfVisibleSat, IdxOfStep, 0);
 if self.ifDebug == 1
 fprintf('Snapshot %d satellite service coverage calculation completed\n', IdxOfStep); 
 end
 %% Calculate adjacent NumOfAdjaLayer layer satellite sequence numbers for each satellite
 self.getNeighborSat(IdxOfStep, 0); 
 if self.ifDebug == 1
 fprintf('Snapshot %d satellite neighbor calculation completed\n', IdxOfStep); 
 end
 %% When considering edge effects, remove incomplete area satellites
 if self.Config.ifWrapAround == 1
 self.removeSomeSat(IdxOfStep, 0)
 if self.ifDebug == 1
 fprintf('Snapshot %d removal of incomplete satellites in wrapAround area completed\n', IdxOfStep); 
 end
 end
 %% Add signaling beam footprints for each satellite
 if self.Config.numOfSigbeam > 0
 self.getSignalOfSat(IdxOfStep, 0);
 if self.ifDebug == 1
 fprintf('Snapshot %d satellite signaling beam footprint loading completed\n', IdxOfStep); 
 end
 end
 %% Generate self.UsrsObj
 % Generate UsrsObj for sub-satellite users based on modified SatObj
 if self.Config.ifWrapAround == 1
 NumOfSat = length(self.OrderOfServSatCur);
 NumOfUsrs = 0;
 OrderOfUsrs = [];
 for idx_sat = 1 : NumOfSat
 NumOfUsrs = NumOfUsrs + self.SatObj(idx_sat).numOfusrs;
 OrderOfUsrs = [OrderOfUsrs, self.SatObj(idx_sat).servUsr];
 end
 OrderOfUsrs = sort(OrderOfUsrs,'ascend');
 self.SelectedUsrsPosition = self.UsrsPosition(OrderOfUsrs,:);
 self.numOfUsrs_selected = NumOfUsrs;
 self.UsrsObj = simSatSysClass.simUsrs.empty(self.numOfUsrs_selected, 0);
 if self.Config.numOfSigbeam > 0
 self.UsrMapptoSig = zeros(self.numOfUsrs_selected, length(self.signalOfArea(:,1)));
 end
 self.OrderOfSelectedUsrs = OrderOfUsrs;
 for k = 1 : self.numOfUsrs_selected
 self.UsrsObj(k).ordOfDiscr = self.SelectedUsrsPosition(k, 3);
 self.UsrsObj(k).position = self.SelectedUsrsPosition(k, 1:2);
 self.UsrsObj(k).homeSat = self.Usr2SatCur(OrderOfUsrs(k),1,1);
 [DiscrArea_i,DiscrArea_j] = simSatSysClass.tools.Seq2ij(self.UsrsObj(k).ordOfDiscr, length(self.DiscrArea(:,1,1)));
 if self.Config.numOfSigbeam > 0
 self.UsrsObj(k).homeSig = self.SignalOfDiscrArea(DiscrArea_i,DiscrArea_j,1);
 self.UsrMapptoSig(k, self.UsrsObj(k).homeSig) = 1;
 
 end
 self.UsrsObj(k).SCS = self.Config.SCS/1e3;
 self.UsrsObj(k).BandWidth = self.Config.BandOfLink/1e6;
 self.UsrsObj(k).SlotInSche = self.slotInSubF * self.subFInSche;
 self.UsrsObj(k).timeInSlot = self.timeInSlot;
 self.UsrsObj(k).T_noise = self.Config.Usr_T_noise;
 self.UsrsObj(k).F_noise = self.Config.Usr_F_noise;
 self.UsrsObj(k).Pt_dBm = self.Config.Pt_dBm_Usr;
 end
 else
 self.SelectedUsrsPosition = self.UsrsPosition;
 self.numOfUsrs_selected = self.numOfUsrs_inves;
 self.UsrsObj = simSatSysClass.simUsrs.empty(self.numOfUsrs_inves, 0);
 if self.Config.numOfSigbeam > 0
 self.UsrMapptoSig = zeros(self.numOfUsrs_selected, length(self.signalOfArea(:,1)));
 end
 self.OrderOfSelectedUsrs = 1 : self.numOfUsrs_selected;
 for k = 1 : self.numOfUsrs_inves
 self.UsrsObj(k).ordOfDiscr = self.UsrsPosition(k, 3);
 self.UsrsObj(k).position = self.UsrsPosition(k, 1:2);
 self.UsrsObj(k).homeSat = self.Usr2SatCur(k,1,1);
 [DiscrArea_i,DiscrArea_j] = simSatSysClass.tools.Seq2ij(self.UsrsObj(k).ordOfDiscr, length(self.DiscrArea(:,1,1)));
 if self.Config.numOfSigbeam > 0
 self.UsrsObj(k).homeSig = self.SignalOfDiscrArea(DiscrArea_i,DiscrArea_j,1);
 self.UsrMapptoSig(k, self.UsrsObj(k).homeSig) = 1;
 end
 self.UsrsObj(k).SCS = self.Config.SCS/1e3;
 self.UsrsObj(k).BandWidth = self.Config.BandOfLink/1e6; 
 self.UsrsObj(k).SlotInSche = self.slotInSubF * self.subFInSche;
 self.UsrsObj(k).timeInSlot = self.timeInSlot; 
 self.UsrsObj(k).T_noise = self.Config.Usr_T_noise;
 self.UsrsObj(k).F_noise = self.Config.Usr_F_noise;
 self.UsrsObj(k).Pt_dBm = self.Config.Pt_dBm_Usr;
 end
 end 
 %% Pre-allocate space for result statistics

 % Inter-satellite/intra-satellite interference calculation
 DataObj(IdxOfStep).InterfFromAll_Down = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 2 ...
 );
 DataObj(IdxOfStep).InterfFromAll_Up = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 2 ...
 );
 DataObj(IdxOfStep).InterfFromSingleSat_Down = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 2 ...
 );
 DataObj(IdxOfStep).InterfFromSingleSat_Up = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 2 ...
 );
 DataObj(IdxOfStep).InterSat_UsrsTransPort = ...
 zeros(numOfMethods, self.numOfUsrs_inves, self.scheInShot);

 % Satellite-ground co-frequency interference calculation
 DataObj(IdxOfStep).Interf1 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 3);

 DataObj(IdxOfStep).Interf2 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 length(self.OrderOfServSatCur),...
 self.Config.numOfSigbeam + self.Config.numOfServbeam,...
 3);


 DataObj(IdxOfStep).Interf3 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 length(self.OrderOfServSatCur),...
 self.Config.numOfSigbeam + self.Config.numOfServbeam,...
 3);

 DataObj(IdxOfStep).Interf4 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 3);

 DataObj(IdxOfStep).Interf5 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 length(self.OrderOfServSatCur),...
 self.Config.numOfSigbeam + self.Config.numOfServbeam,...
 3);
 
 DataObj(IdxOfStep).Interf6 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 3);

 if self.ifDebug == 1
 fprintf('Snapshot %d interference data statistics memory pre-allocation completed\n',IdxOfStep); 
 end 
 %% Beam hopping scheduling
 % Interface generation
 interface = simSatSysClass.simInterface(self);
 scheduler.getinterface(interface); % Import interface class @simInterface parameter data into class @schedulerObj
 if self.ifDebug == 1
 fprintf('Snapshot %d data interface generation completed\n', IdxOfStep); 
 end 
 % User traffic generation
 scheduler.generateUsrsTraffic();
 if self.ifDebug == 1
 fprintf('Snapshot %d user traffic generation completed\n', IdxOfStep); 
 end
 % Signaling beam footprint scanning timing generation
 if self.Config.numOfSigbeam > 0
 scheduler.generateSigSpan();
 if self.ifDebug == 1
 fprintf('Snapshot %d signaling beam footprint scanning timing generation completed\n', IdxOfStep); 
 end
 end
 
 % Signaling beams + Service beams
 for sche = 1 : self.scheInShot
 % At the start of each scheduling cycle, count current users
 scheduler.getCurUsers(sche); 
 end
 
 if self.Config.ifAdjustBHST == 1
 % New edge user determination and service competition
 scheduler.judgeEdgeUsr();
 if self.ifDebug == 1
 fprintf('Snapshot %d edge user determination and service competition completed\n', IdxOfStep); 
 end
 end

 % Beam footprint generation
 scheduler.generateBeamFoot();
 if self.ifDebug == 1
 fprintf('Snapshot %d beam footprint generation completed\n', IdxOfStep); 
 end

% % Inter-beam power average allocation
% scheduler.generateBeamPower(IdxOfStep, NumOfShot);
% if self.ifDebug == 1
% fprintf('Snapshot %d inter-beam power allocation completed\n', IdxOfStep); 
% end

 % BHST generation
 scheduler.generateBHST(IdxOfStep, NumOfShot);
 if self.ifDebug == 1
 fprintf('Snapshot %d BHST completed\n', IdxOfStep); 
 end

 % Inter-beam power allocation
 scheduler.generateBeamPower(IdxOfStep, NumOfShot);
 if self.ifDebug == 1
 fprintf('Snapshot %d inter-beam power allocation completed\n', IdxOfStep); 
 end

 % Intra-beam frequency and power allocation
 scheduler.generateBPAllocation(IdxOfStep, NumOfShot);
 if self.ifDebug == 1
 fprintf('Snapshot %d resource allocation completed\n', IdxOfStep); 
 end

 % Interface update 
 interface.refreshValue(self);
 if self.ifDebug == 1
 fprintf('Snapshot %d data update completed\n', IdxOfStep); 
 end 

 %% Interference calculation
 % Inter-satellite/intra-satellite interference calculation
 DataObj = self.calcuInterferenceForDiffBand(DataObj, IdxOfStep, 0);
% DataObj = self.calcuInterference(DataObj, IdxOfStep, 0);

% if self.Config.ifattenuation == 1
% % 
% DataObj = self.calcuInterference(DataObj, IdxOfStep, 0);
% else
% % 
% DataObj = self.calcuInterferenceFSPL(DataObj, IdxOfStep, 0);
% end
% if self.ifDebug == 1
% fprintf('Snapshot %d interference calculation completed\n', IdxOfStep); 
% end

 % Satellite-ground co-frequency interference calculation
% if self.Config.ifSatAndGround == 1
% DataObj = self.calcuSatGroundInterference(DataObj, IdxOfStep, 0);
% if self.ifDebug == 1
% fprintf('Snapshot %d satellite-ground interference calculation completed\n', IdxOfStep); 
% end
% end
 %% Store data
 %------------------------Plotting data--------------------------------%
 DataObj(IdxOfStep).forPlot.CoordiTri = self.CoordiTri;
 DataObj(IdxOfStep).forPlot.factorOfDiscr = self.Config.factorOfDiscr;
 DataObj(IdxOfStep).forPlot.rangeOfInves = self.Config.rangeOfInves;
 DataObj(IdxOfStep).forPlot.ifWrapAround = self.Config.ifWrapAround;
 DataObj(IdxOfStep).forPlot.wrapRange = self.wrapRange;
 DataObj(IdxOfStep).forPlot.numOfMethods_BeamGenerate = self.numOfMethods_BeamGenerate;
 DataObj(IdxOfStep).forPlot.numOfMethods_BeamHopping = self.numOfMethods_BeamHopping;
 DataObj(IdxOfStep).forPlot.NumOfSchePerShot = NumOfSchePerShot;
 DataObj(IdxOfStep).forPlot.stepOfSimuMove = self.Config.step;
 DataObj(IdxOfStep).forPlot.Config = self.Config;

 %--------------------------------------------------%
 DataObj(IdxOfStep).UsrsTraffic = self.UsrsTraffic;
 DataObj(IdxOfStep).UsrsTransPort = self.UsrsTransPort;
 DataObj(IdxOfStep).NumOfInvesUsrs = self.numOfUsrs_inves;
 DataObj(IdxOfStep).OrderOfSelectedUsrs = self.OrderOfSelectedUsrs;
 DataObj(IdxOfStep).UsrsObj = self.UsrsObj;
 DataObj(IdxOfStep).ServSatOfDiscrAreaCur = self.ServSatOfDiscrAreaCur;
 DataObj(IdxOfStep).OrderOfServSatCur = self.OrderOfServSatCur;
 DataObj(IdxOfStep).SatObj = self.SatObj;
 DataObj(IdxOfStep).Usr2SatCur = self.Usr2SatCur;
 DataObj(IdxOfStep).TerrestrialDuplexing = self.Config.TerrestrialDuplexing;
 if self.ifDebug == 1
 fprintf('Snapshot %d data storage completed\n', IdxOfStep); 
 end
 %% Delete satellite and user objects
 self.delSatObj(); 
 end
 else
 numOfMethods = (self.numOfMethods_BeamGenerate) * (self.numOfMethods_BeamHopping);
 %% Monte Carlo repetition
 for IdxOfMonte = 1 : self.Config.numOfMonteCarlo
 %% Traverse all snapshots
 for IdxOfStep = 1 : NumOfShot
 %% User coordinates self.UsrsPosition generation
 if self.Config.ifFixedUsrsNum == true % Generate fixed number and location of users
 if IdxOfStep == 1
 if self.Config.ifWrapAround == 1
 self.numOfUsrs_inves = self.Config.meanUsrsNum; % Number of users in investigation area
 % Get user distribution density
 HeightOfArea = tools.LatLngCoordi2Length( ...
 [0, self.Config.rangeOfInves(2,1)], ...
 [0, self.Config.rangeOfInves(2,2)], ...
 self.rOfearth);
 LengthOfArea = self.rOfearth * ...
 cos(self.Config.rangeOfInves(2,2)*pi/180) * ...
 abs(self.Config.rangeOfInves(1,1)-self.Config.rangeOfInves(1,2))*pi/180;
 AreaOfInves = HeightOfArea * LengthOfArea;
 DensOfUsrs = self.numOfUsrs_inves/AreaOfInves;

 HeightOfAreaInAll = tools.LatLngCoordi2Length( ...
 [0, self.wrapRange(2,1)], ...
 [0, self.wrapRange(2,2)], ...
 self.rOfearth);
 LengthOfAreaInAll = self.rOfearth * ...
 cos(self.wrapRange(2,2)*pi/180) * ...
 abs(self.wrapRange(1,1)-self.wrapRange(1,2))*pi/180;
 AreaOfAll = HeightOfAreaInAll * LengthOfAreaInAll;
 self.numOfUsrs_all = DensOfUsrs * AreaOfAll; 

 NumOfSeqInves = length(self.SeqDiscrInNonWrap); % area total
 NumOfSeqAll = length(self.SeqDiscrArea(:,1)); % area total
 selectedTriInves = sort(randperm(NumOfSeqInves, self.numOfUsrs_inves)); % area
 selectedTriWrap = sort(randperm(NumOfSeqAll, self.numOfUsrs_all)); % area
 [~, PosInselectedAll, ~] = intersect(selectedTriWrap,self.SeqDiscrInNonWrap); % toarea user
 selectedTriWrap(PosInselectedAll) = []; % Deletearea user
 self.numOfUsrs_all = length(selectedTriWrap) + length(selectedTriInves);
 self.UsrsPosition = zeros(self.numOfUsrs_all, 3);
 for k = 1 : self.numOfUsrs_all
 if k <= self.numOfUsrs_inves
 self.UsrsPosition(k, 3) = self.SeqDiscrInNonWrap(selectedTriInves(k)); % user inwraparea ID/number
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 else
 self.UsrsPosition(k, 3) = selectedTriWrap(k-self.numOfUsrs_inves);
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 end
 end
 else
 self.numOfUsrs_inves = self.Config.meanUsrsNum;
 self.numOfUsrs_all = self.numOfUsrs_inves;

 NumOfSeqAll = length(self.SeqDiscrArea(:,1)); % area total
 selectedTriInves = sort(randperm(NumOfSeqAll, self.numOfUsrs_inves)); % area
 self.UsrsPosition = zeros(self.numOfUsrs_inves, 3);
 for k = 1 : self.numOfUsrs_inves
 self.UsrsPosition(k, 3) = selectedTriInves(k);
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 end
 end
 if self.ifDebug == 1
 fprintf('%duserpositionGenerate\n',IdxOfMonte); 
 end
 end
 else % intervalStepsatelliteUpdatestep，Generateuser
 if mod((IdxOfStep-1),self.Config.intervalStep) == 0
 self.getUsrsPositionInPossion();
 if self.ifDebug == 1
 fprintf('%d%duserpositionGenerate\n',IdxOfMonte,IdxOfStep); 
 end 
 end
 end

 % NumOfVisibleSat When
 % OrderOfVisibleSat When
 VisibleSatSet = self.VisibleSat(:,IdxOfStep,:); 
 % CalculateWhen
 NumOfSat = length(self.VisibleSat(:,1,1));
 NumOfVisibleSat = NumOfSat; 
 for i = 1 : NumOfSat
 if VisibleSatSet(i, 1) == 500
 NumOfVisibleSat = NumOfVisibleSat - 1; 
 end
 end
 % CalculateWhen
 OrderOfVisibleSat = zeros(NumOfVisibleSat,1);
 tmpN = 1;
 for i = 1 : NumOfSat
 if VisibleSatSet(i, 1) ~= 500
 OrderOfVisibleSat(tmpN) = i; 
 tmpN = tmpN + 1;
 end
 end 

 self.calcuSatServArea(OrderOfVisibleSat, IdxOfStep, IdxOfMonte);
 if self.ifDebug == 1
 fprintf('%d%dsatelliteservicerangeCalculate\n', IdxOfMonte,IdxOfStep); 
 end

 self.getNeighborSat(IdxOfStep, IdxOfMonte); 
 if self.ifDebug == 1
 fprintf('%d%dsatelliteCalculate\n', IdxOfMonte,IdxOfStep); 
 end

 if self.Config.numOfSigbeam > 0
 self.getSignalOfSat(self, IdxOfStep, IdxOfMonte);
 if self.ifDebug == 1
 fprintf('%d%dsatellitebeam positionLoad\n', IdxOfMonte,IdxOfStep); 
 end
 end

 if self.Config.ifWrapAround == 1
 self.removeSomeSat(IdxOfStep, IdxOfMonte)
 if self.ifDebug == 1
 fprintf('%d%dwrapAroundareasatellite\n', IdxOfMonte,IdxOfStep); 
 end
 end
 %% Generateself.UsrsObj

 if self.Config.ifWrapAround == 1
 NumOfSat = length(self.OrderOfServSatCur);
 NumOfUsrs = 0;
 OrderOfUsrs = [];
 for idx_sat = 1 : NumOfSat
 NumOfUsrs = NumOfUsrs + self.SatObj(idx_sat).numOfusrs;
 OrderOfUsrs = [OrderOfUsrs, self.SatObj(idx_sat).servUsr];
 end
 OrderOfUsrs = sort(OrderOfUsrs,'ascend');
 self.SelectedUsrsPosition = self.UsrsPosition(OrderOfUsrs,:);
 self.numOfUsrs_selected = NumOfUsrs;
 self.UsrsObj = simSatSysClass.simUsrs.empty(self.numOfUsrs_selected, 0);
 self.UsrMapptoSig = zeros(self.numOfUsrs_selected, length(self.signalOfArea(:,1)));
 self.OrderOfSelectedUsrs = OrderOfUsrs;
 for k = 1 : self.numOfUsrs_selected
 self.UsrsObj(k).ordOfDiscr = self.SelectedUsrsPosition(k, 3);
 self.UsrsObj(k).position = self.SelectedUsrsPosition(k, 1:2);
 self.UsrsObj(k).homeSat = self.Usr2SatCur(OrderOfUsrs(k),1,1);
 [DiscrArea_i,DiscrArea_j] = simSatSysClass.tools.Seq2ij(self.UsrsObj(k).ordOfDiscr, length(self.DiscrArea(:,1,1)));
 self.UsrsObj(k).homeSig = self.SignalOfDiscrArea(DiscrArea_i,DiscrArea_j,1);
 self.UsrMapptoSig(k, self.UsrsObj(k).homeSig) = 1;
 self.UsrsObj(k).SCS = self.Config.SCS/1e3;
 self.UsrsObj(k).BandWidth = self.Config.BandOfLink/1e6;
 self.UsrsObj(k).SlotInSche = self.slotInSubF * self.subFInSche;
 self.UsrsObj(k).timeInSlot = self.timeInSlot;
 self.UsrsObj(k).T_noise = self.Config.Usr_T_noise;
 self.UsrsObj(k).F_noise = self.Config.Usr_F_noise;
 self.UsrsObj(k).Pt_dBm = self.Config.Pt_dBm_Usr;
 end
 else
 self.SelectedUsrsPosition = self.UsrsPosition;
 self.numOfUsrs_selected = self.numOfUsrs_inves;
 self.UsrsObj = simSatSysClass.simUsrs.empty(self.numOfUsrs_inves, 0);
 if self.Config.numOfSigbeam > 0
 self.UsrMapptoSig = zeros(self.numOfUsrs_selected, length(self.signalOfArea(:,1)));
 end
 self.OrderOfSelectedUsrs = 1 : self.numOfUsrs_selected;
 for k = 1 : self.numOfUsrs_inves
 self.UsrsObj(k).ordOfDiscr = self.UsrsPosition(k, 3);
 self.UsrsObj(k).position = self.UsrsPosition(k, 1:2);
 self.UsrsObj(k).homeSat = self.Usr2SatCur(k,1,1);
 [DiscrArea_i,DiscrArea_j] = simSatSysClass.tools.Seq2ij(self.UsrsObj(k).ordOfDiscr, length(self.DiscrArea(:,1,1)));
 if self.Config.numOfSigbeam > 0
 self.UsrsObj(k).homeSig = self.SignalOfDiscrArea(DiscrArea_i,DiscrArea_j,1);
 self.UsrMapptoSig(k, self.UsrsObj(k).homeSig) = 1;
 end
 self.UsrsObj(k).SCS = self.Config.SCS/1e3;
 self.UsrsObj(k).BandWidth = self.Config.BandOfLink/1e6; 
 self.UsrsObj(k).SlotInSche = self.slotInSubF * self.subFInSche;
 self.UsrsObj(k).timeInSlot = self.timeInSlot; 
 self.UsrsObj(k).T_noise = self.Config.Usr_T_noise;
 self.UsrsObj(k).F_noise = self.Config.Usr_F_noise;
 self.UsrsObj(k).Pt_dBm = self.Config.Pt_dBm_Usr;
 end
 end
 if self.ifDebug == 1
 fprintf('%d%dUsrObjGenerate\n', IdxOfMonte,IdxOfStep); 
 end


 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).InterfFromAll_Down = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 2 ...
 );
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).InterfFromAll_Up = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 2 ...
 );
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Down = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 2 ...
 );
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).InterfFromSingleSat_Up = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 2 ...
 );
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).InterSat_UsrsTransPort = ...
 zeros(numOfMethods, self.numOfUsrs_inves, self.scheInShot);

 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).Interf1 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 3);
 
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).Interf2 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 length(self.OrderOfServSatCur),...
 self.Config.numOfSigbeam + self.Config.numOfServbeam,...
 3);
 
 
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).Interf3 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 length(self.OrderOfServSatCur),...
 self.Config.numOfSigbeam + self.Config.numOfServbeam,...
 3);
 
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).Interf4 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 3);
 
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).Interf5 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 length(self.OrderOfServSatCur),...
 self.Config.numOfSigbeam + self.Config.numOfServbeam,...
 3);
 
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).Interf6 = ...
 zeros( ...
 numOfMethods, ...
 self.slotInShot, ...
 self.numOfUsrs_inves, ...
 3);

 if self.ifDebug == 1
 fprintf('%d%dinterferencedatastatistics\n',IdxOfMonte,IdxOfStep); 
 end 


 interface = simSatSysClass.simInterface(self);
 scheduler.getinterface(interface); % @simInterface Parameterdatainterface@schedulerObjin
 if self.ifDebug == 1
 fprintf('%d%ddataGenerate\n', IdxOfMonte,IdxOfStep); 
 end 
 % usertrafficGenerate
 scheduler.generateUsrsTraffic();
 if self.ifDebug == 1
 fprintf('%d%dusertrafficGenerate\n', IdxOfMonte,IdxOfStep); 
 end

 if self.Config.numOfSigbeam > 0
 scheduler.generateSigSpan();
 if self.ifDebug == 1
 fprintf('%d%dbeam positionGenerate\n', IdxOfMonte,IdxOfStep); 
 end
 end

 for sche = 1 : self.scheInShot

 scheduler.getCurUsers(sche); 
 end
 
 if self.Config.ifAdjustBHST == 1

 scheduler.judgeEdgeUsr();
 if self.ifDebug == 1
 fprintf('%d%duserservice\n', IdxOfMonte,IdxOfStep); 
 end
 end

 % beam positionGenerate
 scheduler.generateBeamFoot();
 if self.ifDebug == 1
 fprintf('%d%dbeam positionGenerate\n', IdxOfMonte,IdxOfStep); 
 end
 % BHSTGenerate
 scheduler.generateBHST();
 if self.ifDebug == 1
 fprintf('%d%dBHSTGenerate\n', IdxOfMonte,IdxOfStep); 
 end

 interface.refreshValue(self);
 if self.ifDebug == 1
 fprintf('%d%ddataUpdate\n', IdxOfMonte,IdxOfStep); 
 end 
 %% interferenceCalculate

 DataObj = self.calcuInterference(DataObj, IdxOfStep, IdxOfMonte);
 if self.ifDebug == 1
 fprintf('%d%dinterferenceCalculate\n', IdxOfMonte,IdxOfStep); 
 end

 DataObj = self.calcuSatGroundInterference(DataObj, IdxOfStep, IdxOfMonte);
 if self.ifDebug == 1
 fprintf('%d%dinterferenceCalculate\n', IdxOfMonte,IdxOfStep); 
 end

 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).UsrsTraffic = self.UsrsTraffic;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).UsrsTransPort = self.UsrsTransPort;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).NumOfInvesUsrs = self.numOfUsrs_inves;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).OrderOfSelectedUsrs = self.OrderOfSelectedUsrs;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).UsrsObj = self.UsrsObj;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).ServSatOfDiscrAreaCur = self.ServSatOfDiscrAreaCur;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).OrderOfServSatCur = self.OrderOfServSatCur;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).SatObj = self.SatObj;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).Usr2SatCur = self.Usr2SatCur;
 DataObj((IdxOfMonte-1)*NumOfShot+IdxOfStep).TerrestrialDuplexing = self.Config.TerrestrialDuplexing;
 if self.ifDebug == 1
 fprintf('%d%ddataStore\n', IdxOfMonte,IdxOfStep); 
 end

 self.delSatObj(); 
 end
 end
 end
end




















