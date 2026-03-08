% Get
%%
% self.SignalOfDiscrArea
% matrix
% self.SignalOfDiscrArea(i,j,1)indicates
% self.SignalOfDiscrArea(i,j,2)indicates
%%
function getSignal(self)
% ifDebug = self.ifDebug;
path = pwd;
name = '\SignalCoord.mat';
load([path, name],'signaling');

if self.Config.ifWrapAround == 1 %Ifwraparound
 lat1 = min(self.wrapRange(2,:));% 
 lat2 = max(self.wrapRange(2,:));
else
 lat1 = min(self.Config.rangeOfInves(2,:));% 
 lat2 = max(self.Config.rangeOfInves(2,:));
end
if self.Config.rangeOfInves(1,1) < self.Config.rangeOfInves(1,2)
%Ifis
 if self.Config.ifWrapAround == 1 %Ifwraparound
 lon1 = min(min(self.wrapRange(1,:)),self.DiscrArea(end,1,1));% 
 lon2 = max(max(self.wrapRange(1,:)),self.DiscrArea(end,end,1));
 else
 lon1 = min(min(self.Config.rangeOfInves(1,:)),self.DiscrArea(end,1,1));% 
 lon2 = max(max(self.Config.rangeOfInves(1,:)),self.DiscrArea(end,end,1)); 
 end

 t = intersect(find(signaling(:,1) >= lon1 & signaling(:,1) <= lon2), find(signaling(:,2) >= lat1 & signaling(:,2) <= lat2));
 temp = signaling(t,1:2);
 signalOfArea = zeros();%Storeto beam position
 count = 1;%
 rawNum = length(self.DiscrArea(:,1,1));%total
 for i = 1 : length(temp)
 [ii,jj,~] = tools.findPointXY(self,temp(i,2),temp(i,1));
 if ii > 0 && ii <= rawNum && jj > 0 && jj <= length(self.DiscrArea(1,:,1))
 signalOfArea(count,1:2) = [temp(i,1),temp(i,2)]; % coordinate
 signalOfArea(count,3) = (jj - 1) * rawNum + ii; % ID/number
% signalOfArea(count,1:2)
 tmpK = find(signaling == temp(i,:));
 signalOfArea(count,4) = tmpK(1); % beam position ID/number
 count = count + 1;
 end
% if ifDebug == 1
% fprintf(
% end
 end
else
%Ifis
 if self.Config.ifWrapAround == 1 %Ifwraparound
 lon1 = min(min(self.wrapRange(1,:)),self.DiscrArea(end,end,1));% 
 lon2 = max(max(self.wrapRange(1,:)),self.DiscrArea(end,1,1)); 
 else
 lon1 = min(min(self.Config.rangeOfInves(1,:)),self.DiscrArea(end,end,1));% 
 lon2 = max(max(self.Config.rangeOfInves(1,:)),self.DiscrArea(end,1,1)); 
 end

 t = intersect(find(signaling(:,1) <= lon1 | signaling(:,1) >= lon2), find(signaling(:,2) >= lat1 & signaling(:,2) <= lat2));
 temp = signaling(t,1:2);
 signalOfArea = zeros();%Storeto beam position
 count = 1;%
 rawNum = length(self.DiscrArea(:,1,1));%total
 for i = 1 : length(temp)
 [ii,jj,~] = tools.findPointXY(self,temp(i,2),temp(i,1));
 if ii > 0 && ii <= rawNum && jj > 0 && jj <= length(self.DiscrArea(1,:,1))
 signalOfArea(count,1:2) = [temp(i,1),temp(i,2)];% coordinate
 signalOfArea(count,3) = (jj - 1) * rawNum + ii; % ID/number
% signalOfArea(count,1:2)
 tmpK = find(signaling == temp(i,:));
 signalOfArea(count,4) = tmpK(1); % beam position ID/number
 count = count + 1;
 end
% if ifDebug == 1
% fprintf(
% end
 end
end
self.signalOfArea = signalOfArea;%Whenarea beam positioncoordinate，step，andarea

 NumOfSigB = length(signalOfArea(:,1));
 tempSeqDiscrArea = self.SeqDiscrArea;% centercoordinate
 tempsignal = zeros(NumOfSigB,3); 
 tempsignal(:,1:2) = signalOfArea(:, 1:2); % beam position coordinate
 tempsignal(:,3) = signalOfArea(:, 4); % beam position ID/number

 tempOfNum = zeros(NumOfSigB, 1); % statisticsbeam positionnumber
 tempSignalServCur = zeros(length(self.SeqDiscrArea(:,1)), 4); % Storebeam position
 tempSignalServCur(:,1:2) = self.SeqDiscrArea; %is，thirdisbeam positioninself.signalOfArea ID/number，isID/number

 rawNum = length(self.DiscrArea(:,1,1));%total
 colNum = length(self.DiscrArea(1,:,1));%total
 interval = floor(colNum/100);
 for i = 1 : rawNum%Traverse
 last_q = 0;%Ifq == last_qDescriptionto
 for j = 1 : interval : colNum%intervalTraverse
 seq = simSatSysClass.tools.ij2Seq(i, j, rawNum, colNum);%CalculateWhenijinin ID/number
 q = findShortest(...
 tempSeqDiscrArea(seq, :),...
 tempsignal(:, 1:2)...
 );%to beam position
 if j ~= 1%Calculate
 if q ~= last_q
 for k = j-interval+1 : j
 seq = simSatSysClass.tools.ij2Seq(i, k, rawNum, colNum);
 q = findShortest(...
 tempSeqDiscrArea(seq, :),...
 tempsignal(:, 1:2)...
 );
 tempSignalServCur(seq, 3) = q;
 tempSignalServCur(seq, 4) = tempsignal(q, 3);%inthirdsatelliteID/number
 tempOfNum(q) = tempOfNum(q) + 1; 
 end
 last_q = q;
 else
 for k = j-interval+1 : j
 seq = simSatSysClass.tools.ij2Seq(i, k, rawNum, colNum);
 tempSignalServCur(seq, 3) = q;
 tempSignalServCur(seq, 4) = tempsignal(q, 3);
 tempOfNum(q) = tempOfNum(q) + 1; 
 end 
 end 
 else
 tempSignalServCur(seq, 3) = q;
 tempSignalServCur(seq, 4) = tempsignal(q, 3);
 tempOfNum(q) = tempOfNum(q) + 1;
 last_q = q;
 end
% if ifDebug == 1
% fprintf(
% end
 if colNum - j < interval
 for k = j+1 : colNum
 seq = simSatSysClass.tools.ij2Seq(i, k, rawNum, colNum);
 q = findShortest(...
 tempSeqDiscrArea(seq, :),...
 tempsignal(:, 1:2)...
 );
 tempSignalServCur(seq, 3) = q;
 tempSignalServCur(seq, 4) = tempsignal(q, 3);
 tempOfNum(q) = tempOfNum(q) + 1;
 end
% if ifDebug == 1
% fprintf(
% end
 end
 end 
 end

 self.SignalOfDiscrArea = zeros(rawNum, colNum, 2); % each beam position，1isinsimulationarea ID/number，2isID/number
 for j = 1:colNum
 for i = 1:rawNum
 self.SignalOfDiscrArea(i, j, 1) = tempSignalServCur((j-1)*rawNum+i, 3);
 self.SignalOfDiscrArea(i, j, 2) = tempSignalServCur((j-1)*rawNum+i, 4);
 end
 end


end

function Satpos = findShortest(pos, SatposSet)
 % pos
 % SatposSet satellitecoordinate
 R = 6371.393e3; % 
 lngA = pos(1);
 alpha1 = lngA * pi / 180;
 latA = pos(2);
 beta1 = latA * pi / 180;
 num = length(SatposSet(:,1));
 len = zeros(num,1);%satellite
 for i = 1 : num
 lngB = SatposSet(i, 1);
 alpha2 = lngB * pi / 180;
 latB = SatposSet(i, 2);
 beta2 = latB * pi / 180;
 len(i) = R * acos(cos(pi/2-beta2)*cos(pi/2-beta1) + sin(pi/2-beta2)*sin(pi/2-beta1)*cos(alpha2-alpha1));
 end
 Satpos = find(len == min(len), 1);
end
) 
) 
) 
) 
