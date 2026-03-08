function getSignalOfSat(self, IdxOfStep, MC_idx)
 %Get signaling beam position and satellite association relationship, this changes with step, needs to be placed in loop below
 %Need to pass current step sequence number, total scheduling periods per beam hopping step
 ifDebug = self.ifDebug;
 
% signalOfArea = self.signalOfArea;
 OrderOfSat = self.OrderOfServSatCur;
 NumOfSat = length(OrderOfSat);

% tempSignalInfo = zeros(length(signalOfArea(1,:)),3);
% tempSignalInfo(:,1:2)


 %% Statistics of signaling beam position to satellite mapping relationship
 ServSatOfDiscrAreaCur = self.ServSatOfDiscrAreaCur;
 % From self.calcuSatServArea()
 % Current step investigation area triangle satellite ID assignment, stores satellite service range
 % Matrix, format is "DiscrArea rows × DiscrArea columns"
 % ServSatOfDiscrAreaCur(i, j) indicates satellite ID of triangle at row i column j
 SignalOfDiscrArea = self.SignalOfDiscrArea;
 % From self.getSignal(), stores triangle to signaling beam position mapping relationship
 % Matrix, format is "area total rows × area total columns × 2"
 % SignalOfDiscrArea(i, j, 1) indicates signaling beam position ID in signalOfArea for triangle at row i column j
 % SignalOfDiscrArea(i, j, 2) indicates global original ID of signaling beam position for triangle at row i column j
 NumOfSignalBeam = length(self.signalOfArea(:, 1));
 tempMapping = zeros(NumOfSignalBeam, NumOfSat);
 colNum = length(self.DiscrArea(1,:,1));
 rawNum = length(self.DiscrArea(:,1,1));
 for j = 1 : colNum
 for i = 1 : rawNum
 % if isempty(fing(findingsSignal
 satSeq = ServSatOfDiscrAreaCur(i, j);
 satIdx = find(self.OrderOfServSatCur == satSeq);
 % end
 BeamIdx = SignalOfDiscrArea(i, j, 1);
% tempMapping(BeamIdx, satIdx)
 if tempMapping(BeamIdx, satIdx) == 0
 tempMapping(BeamIdx, satIdx) = 1;
 end
% if ifDebug == 1
% fprintf(
% end 
 end
 end
 self.SigBeamMapptoSat = tempMapping;
 %% Fill satellite instance properties
 for k = 1 : NumOfSat
 self.SatObj(k).SignalBeamfoot = struct( ...
 'servTri', zeros(), ...
 'centerTri', 0, ...
 'usrs', zeros() ...
 );
 end
 tmpUsrsSeq = self.UsrsPosition(:, 3);
% tmpUsrsSeq = self.SelectedUsrsPosition(:, 3);
 for k = 1 : NumOfSat
 tempSignalIdxSet = find(tempMapping(:, k) == 1);
 self.SatObj(k).numOfsigbeam = length(tempSignalIdxSet);
 self.SatObj(k).IdxOfsigbeam = tempSignalIdxSet;
 self.SatObj(k).SeqOfsigbeam = self.signalOfArea(tempSignalIdxSet, 4);
 self.SatObj(k).egdeSig = zeros(NumOfSat, length(tempSignalIdxSet));
 for beamIdx = 1 : self.SatObj(k).numOfsigbeam
 self.SatObj(k).SignalBeamfoot(beamIdx).centerTri = ...
 self.signalOfArea(self.SatObj(k).IdxOfsigbeam(beamIdx), 3); 
 tmpServTriSeq = find(SignalOfDiscrArea(:, :, 1) == self.SatObj(k).IdxOfsigbeam(beamIdx));
 self.SatObj(k).SignalBeamfoot(beamIdx).servTri = tmpServTriSeq;
 [~, idxOftmpUsrsSeq, ~] = intersect(tmpUsrsSeq, tmpServTriSeq);
 self.SatObj(k).SignalBeamfoot(beamIdx).usrs = idxOftmpUsrsSeq;
 end
% if ifDebug == 1
% fprintf(
% end 
 self.SatObj(k).egdeSigSeq = [];
 tempTex = self.SigBeamMapptoSat(tempSignalIdxSet, :);
 for ti = 1 : length(tempSignalIdxSet)
 tmpSat = find(tempTex(ti, :)==1);
 tmpSat(tmpSat==k) = [];
 if ~isempty(tmpSat)
 self.SatObj(k).egdeSig(tmpSat, tempSignalIdxSet(ti)) = 1;
 self.SatObj(k).egdeSigSeq = [self.SatObj(k).egdeSigSeq, tempSignalIdxSet(ti)];
 end
 end

 end
 %% Signaling beam position scanning sorting
 % Sort signaling beam positions and form signaling beam position for each satellite
 for i = 1 : NumOfSat
 A = zeros(self.SatObj(i).numOfsigbeam,2);%iseachbeam position 
 for si = 1 : self.SatObj(i).numOfsigbeam
 triNo = self.SatObj(i).SignalBeamfoot(si).centerTri;
 A(si,1:2) = self.SeqDiscrArea(triNo,:); 
 end
 if self.Config.rangeOfInves(1,1) < self.Config.rangeOfInves(1,2) %Ifis 

% A = tempSignalInfo(A,1:2);
 B = zeros();
 for tt = 1 : length(A(:,1))
 B(tt) = A(tt,1) - A(tt,2);
 end
 [~,I] = sort(B);
 % A(I,:);
 self.SatObj(i).SpanIDXOfsigbeam = I;%Sort resultvalue
 else%If180，Sort 
% A = tempSignalInfo(A,1:2);
 AA = A;
 B=zeros();
 for tt = 1 : length(AA(:,1))
 if AA(tt,1) < 0
 AA(tt,1) = 360 + AA(tt,1); 
 end
 B(tt) = AA(tt,1) - AA(tt,2);
 end
 [~,I] = sort(B);
 % A(I,:);
 self.SatObj(i).SpanIDXOfsigbeam = I;%Sort resultvalue
 end


% B=zeros();
% for tt = 1 : length(A)
% B(tt) = A(tt,1) - A(tt,2);
% end
% [
% self.SatObj(i).SpanIDXOfsigbeam
 end


end
% %% 
% function getSignalOfSat(self, IdxOfStep, MC_idx)
% ifDebug = self.ifDebug;

% signalOfArea = self.signalOfArea;
% OrderOfSat = self.OrderOfServSatCur;
% NumOfSat = length(OrderOfSat);

% tempSatCoord

% tempSignalInfo = zeros(length(signalOfArea),3);
% tempSignalInfo(:,1:2) = signalOfArea(:,1:2);

% for i = 1 : length(signalOfArea)
% tempSignalInfo(i,3) = findShortest(...
% tempSignalInfo(i,1:2),...
% tempSatCoord(:, 1:2)...
% );
% end

% Rb
% Radius = self.radiusOfearth;
% hOfDiscr = tools.LatLngCoordi2Length([0 0], [0 1], Radius)/self.SimConfig.factorOfdiscr;
% NofRaw
% rawNum = length(self.DiscrArea(:,1,1));
% colNum = length(self.DiscrArea(1,:,1));

% totalslot
% signalNum
% interval

% for i = 1 : NumOfOfSat
% if ismember(i,tempSignalInfo(:,3))
% A
% else
% self.SatObj(i).signaltable = zeros(totalslot,signalNum); 
% fprintf(
% continue;
% end
% A = tempSignalInfo(A,1:2);
% B=zeros();
% for tt = 1 : length(A)
% B(tt) = A(tt,1) - A(tt,2);
% end
% [~,I] = sort(B);
% A(I,:);
% self.SatObj(i).signalbeam = struct( ...
% 'coord', [0,0], ...
% 'servTri', 0 ...
% );
% for j = 1 : length(A(:,1))
% self.SatObj(i).signalbeam(j).coord
% [Ordpos(1),Ordpos(2), ifUpTri] = tools.findPointXY(self, A(j,2),A(j,1));
% servTri = setBeamFoot(Ordpos, ifUpTri, NofRaw, rawNum, colNum); 
% self.SatObj(i).signalbeam(j).servTri = servTri;
% end
% signaltable
% totalSerial = length(A(:,1));%total beam positionnumber
% signaltable(1,1) = 1;
% c
% while(c <= totalslot)
% signaltable(c,1) = signaltable(c - 1,1) + 1;
% c = c + 1;
% if mod(signaltable(c
% for ii
% signaltable(c,1) = 0;
% c = c + 1;
% end
% signaltable(c,1) = 1;
% c = c + 1;
% end
% end
% signaltable(1,2) = floor(length(A)/2) + 1;
% cc
% while(cc <= totalslot)
% signaltable(cc,2) = signaltable(cc - 1,2) + 1;
% cc = cc + 1;
% if mod(signaltable(cc
% for ii
% signaltable(cc,2) = 0;
% cc = cc + 1;
% end
% signaltable(cc,2) = 1;
% cc = cc + 1;
% end
% end 

% self.SatObj(i).signaltable = signaltable; 
% fprintf(
% end


% end

% function Satpos = findShortest(pos, SatposSet)
% R

% lngA = pos(1);
% alpha1 = lngA * pi / 180;
% latA = pos(2);
% beta1 = latA * pi / 180;

% num = length(SatposSet(:,1));
% len
% for i = 1 : num
% lngB = SatposSet(i, 1);
% alpha2 = lngB * pi / 180;
% latB = SatposSet(i, 2);
% beta2 = latB * pi / 180;
% len(i) = R * acos(cos(pi/2-beta2)*cos(pi/2-beta1) + sin(pi/2-beta2)*sin(pi/2-beta1)*cos(alpha2-alpha1));
% end
% Satpos = find(len == min(len), 1);
% end


% function SeqOfTri = setBeamFoot(Ordpos, ifUpTri, NofRaw, rawNum, colNum)
% % NumOfBeam beam positionID/number
% if ifUpTri == false
% if Ordpos(2) + 1 <= colNum
% Ordpos(2) = Ordpos(2) + 1;
% else
% Ordpos(2) = Ordpos(2) - 1;
% end

% end
% SeqOfTri = [];
% for ii = 1 : NofRaw/2
% for jj = 1 : (NofRaw+1)+2*(ii-1)
% temp_i1 = Ordpos(1) - NofRaw/2 + ii;
% temp_j1 = Ordpos(2) - NofRaw/2 + 1 - ii + jj;
% temp_Seq1 = ij2Seq(temp_i1, temp_j1, rawNum, colNum);
% temp_i2 = Ordpos(1) + NofRaw/2 - ii + 1;
% temp_j2 = temp_j1;
% temp_Seq2 = ij2Seq(temp_i2, temp_j2, rawNum, colNum);
% if temp_Seq1 ~= 0 
% SeqOfTri = [SeqOfTri temp_Seq1];
% end
% if temp_Seq2 ~= 0
% SeqOfTri = [SeqOfTri temp_Seq2];
% end
% end
% end
% SeqOfTri = sort(SeqOfTri, 'ascend');
% end

% function Seq = ij2Seq(DiscrArea_i, DiscrArea_j, rawNum, colNum)
% if DiscrArea_i <= rawNum && DiscrArea_i > 0 && DiscrArea_j <= colNum && DiscrArea_j > 0
% Seq = (DiscrArea_j - 1) * rawNum + DiscrArea_i;
% else
% Seq = 0;
% end
% end