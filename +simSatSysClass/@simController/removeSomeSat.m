function removeSomeSat(self, IdxOfStep, MC_idx)

 [row1,colu1,~] = tools.findPointXY(self,max(self.Config.rangeOfInves(2,:)),self.Config.rangeOfInves(1,1));%toareafirst 
 [~,colu2,~] = tools.findPointXY(self,max(self.Config.rangeOfInves(2,:)),self.Config.rangeOfInves(1,2));%toarea 
 [row2,~,~] = tools.findPointXY(self,min(self.Config.rangeOfInves(2,:)),self.Config.rangeOfInves(1,1));%toarea 


 ifDebug = self.ifDebug;

 OrderOfServSatCur = self.OrderOfServSatCur; % Whenstepwrapservice satelliteID/number
 NumOfOfServSatCur = length(OrderOfServSatCur); % Whenstepwrapservice satellitenumber

 orderOfActualSat_1_0 = zeros(1,NumOfOfServSatCur);% Storeareaservicesatellite，If，as/is1
 orderOfActualSat = zeros();%% Storeareaservicesatellite，ID/number 

 % GenerateVisibleSat
 tempVisibleSat_s = zeros(NumOfOfServSatCur,3); 
 tempVisibleSat_s(:,1:2) = self.VisibleSat(OrderOfServSatCur, IdxOfStep, :);
 tempVisibleSat_s(:,3) = OrderOfServSatCur;

 tempSeqDiscrArea = self.SeqDiscrArea;% centercoordinate
 
 [rawNum, colNum, ~] = size(self.DiscrArea);% 
 hOfDiscr = tools.LatLngCoordi2Length([0 0], [0 1], self.rOfearth)/self.Config.factorOfDiscr;%each altitude
 interval = ceil(tools.getEarthLength(self.Config.rangeOfBeam(2)*2, self.Config.height)/hOfDiscr/8);%interval

 for i = row1 : row2%Traverse
 last_q = 0;%Ifq == last_qDescriptionto？
 for j = colu1 : interval : colu2%intervalTraverse
 seq = simSatSysClass.tools.ij2Seq(i, j, rawNum, colNum);%CalculateWhenijinin ID/number
 q = findShortest(...
 tempSeqDiscrArea(seq, :),...
 tempVisibleSat_s(:, 1:2)...
 );%to satellite
 orderOfActualSat_1_0(q) = 1;
 if j ~= colu1%Calculate？
 if q ~= last_q
 for k = j-interval+1 : j
 seq = simSatSysClass.tools.ij2Seq(i, k, rawNum, colNum);
 q = findShortest(...
 tempSeqDiscrArea(seq, :),...
 tempVisibleSat_s(:, 1:2)...
 );%q ID/numberisinsatellitematrix ，thirdin1800 ID/number
 orderOfActualSat_1_0(q) = 1; 
 end
 last_q = q; 
 end 
 else 
 last_q = q;
 end
% if ifDebug == 1
% if self.Config.numOfMonteCarlo == 0
% fprintf(
% else
% fprintf(
% end
% end
 if colNum - j < interval
 for k = j+1 : colNum
 seq = simSatSysClass.tools.ij2Seq(i, k, rawNum, colNum);
 q = findShortest(...
 tempSeqDiscrArea(seq, :),...
 tempVisibleSat_s(:, 1:2)...
 ); 
 orderOfActualSat_1_0(q) = 1;
 
 end
% if ifDebug == 1
% if self.Config.numOfMonteCarlo == 0
% fprintf(
% else
% fprintf(
% end
% end
 end
 end 
 end

 for i = 1 : NumOfOfServSatCur
 if orderOfActualSat_1_0(i) ~= 0
 orderOfActualSat(i) = OrderOfServSatCur(i);
 end
 end
 

 % Deletesatellite
 if self.Config.WrapAroundLayer == 0
 
 tempDel = find(orderOfActualSat~=0);%areaservicesatellite
 orderOfActualSat(orderOfActualSat==0) = [];%isarea satelliteID/number
 
 count = 1;%
 for i = 1 : length(tempDel)
 self.SatObj(count) = self.SatObj(tempDel(count));
 count = count + 1;
 end
 for i = length(tempDel)+1 : NumOfOfServSatCur
 self.SatObj(length(tempDel)+1) = [];
 end
 
 self.OrderOfServSatCur = orderOfActualSat;
 % self.NumOfOfServSatCur = length(orderOfActualSat);

 tmpLenNeib = length(self.SatObj(1).Neighbor(:,1));
 for k = 1 : tmpLenNeib
 for i = 1 : length(orderOfActualSat)%Traverseall 
 temp= zeros(1,length(orderOfActualSat));
 count = 0;
 for j = 1 : length(self.SatObj(i).Neighbor(k,:))%Traverseall 
 if self.SatObj(i).Neighbor(k,j) ~= 0 && ismember(self.SatObj(i).Neighbor(k,j),orderOfActualSat)
 count = count + 1;
 temp(count) = self.SatObj(i).Neighbor(k,j); 
 end
 end
 temp2 = zeros(1, length(self.SatObj(i).Neighbor(k,:)));
 temp2(1:length(temp)) = temp;
 self.SatObj(i).Neighbor(k,:) = temp2;
% if ifDebug == 1
% if self.Config.numOfMonteCarlo == 0
% fprintf(
% else
% fprintf(
% end
% end 
 end
 end
 
 elseif self.Config.WrapAroundLayer == 1
 
 TempOrderOfActual = orderOfActualSat;
 TempOrderOfActual(TempOrderOfActual == 0) =[];

 for i = 1 : NumOfOfServSatCur
 if ismember(self.SatObj(i).order,TempOrderOfActual)
 temp = self.SatObj(i).Neighbor;% satellite
 for j = 1 : length(self.SatObj(i).Neighbor)
 if ~ismember(temp(j),orderOfActualSat)
 orderOfActualSat(find(OrderOfServSatCur==temp(j))) = temp(j);
 end
 end 
 end
 end
 
 tempDel = find(orderOfActualSat~=0);%areaservicesatellite
 orderOfActualSat(orderOfActualSat==0) = [];%isarea+ satelliteID/number
 
 count = 1;%
 for i = 1 : length(tempDel)
 self.SatObj(count) = self.SatObj(tempDel(count));
 count = count + 1;
 end
 for i = length(tempDel)+1 : NumOfOfServSatCur
 self.SatObj(length(tempDel)+1) = [];
 end
 
 self.OrderOfServSatCur = orderOfActualSat;
 % self.NumOfOfServSatCur = length(orderOfActualSat);

 tmpLenNeib = length(self.SatObj(1).Neighbor(:,1));
 for k = 1 : tmpLenNeib
 for i = 1 : length(orderOfActualSat)%Traverseall 
 temp= zeros(1,length(orderOfActualSat));
 count = 0;
 for j = 1 : length(self.SatObj(i).Neighbor(k,:))%Traverseall 
 if self.SatObj(i).Neighbor(k,j) ~= 0 && ismember(self.SatObj(i).Neighbor(k,j),orderOfActualSat)
 count = count + 1;
 temp(count) = self.SatObj(i).Neighbor(k,j); 
 end
 end
 temp2 = zeros(1, length(self.SatObj(i).Neighbor(k,:)));
 temp2(1:length(temp)) = temp;
 self.SatObj(i).Neighbor(k,:) = temp2;
% if ifDebug == 1
% if self.Config.numOfMonteCarlo == 0
% fprintf(
% else
% fprintf(
% end
% end 
 end
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