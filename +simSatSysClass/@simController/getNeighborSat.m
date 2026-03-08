
%%
function getNeighborSat(self, IdxOfStep, MC_idx)
ifDebug = self.ifDebug;
%ʹõ
%self.ServSatOfDiscrAreaCur (i,j,1)ǵiеjڵǱ
%self.DiscrArea Сε꣬άʾǸ
%self.NumOfAdjaLayer 

%OrderOfServSat пɼǵı
%NumOfServSat пɼǵ
%ɵ
%self.SatObj(find(OrderOfServSat == Ǳ)).Neighbor
%self.NumOfAdjaLayer NumOfServSat
%Neighbor(k,:)ʾǰǵĵkھǵıż
OrderOfServSat = self.OrderOfServSatCur;
NumOfServSat = length(OrderOfServSat);

adjaMatrix = zeros(NumOfServSat,NumOfServSat);
%ڽӾ󣬳ͿNumOfServSatǱ˵һʵʴOrderOfServSat1Ǳ

% %һмߵľ
% lat1 = self.RangeOfInvesArea(2,1);lat2 = self.RangeOfInvesArea(2,2);
% lon1 = self.RangeOfInvesArea(1,1);lon2 = self.RangeOfInvesArea(1,2); 
% if lon1 < lon2 %ûп180
% midLon = (lon1+lon2)/2;
% else
% deltaLon = 360 - lon1 + lon2; %180
% if 180-lon1 > lon2-(-180)
% midLon = lon1 + deltaLon/2;
% else 
% midLon = lon2- deltaLon/2;
% end
% end
% %εĸ
% R=self.RadiusOfEarth; %뾶
% N=self.FactorOfDiscr; %
% triH = tools.LatLngCoordi2Length([midLon,lat1],[midLon,lat2],R)/N;%εĸ߶ȣλm
hOfDiscr = tools.LatLngCoordi2Length([0 0], [0 1], self.rOfearth)/self.Config.factorOfDiscr;
interval = ceil(1e5/hOfDiscr); %㷽1e5/θ߶(β̫֪զˣ1e5ӽ1㣩ȥθ߶Ȼһֵ

rowNum = length(self.DiscrArea(:,1,1)); %
coluNum = length(self.DiscrArea(1,:,1)); %

triDot = zeros(ceil((rowNum-1)/interval)+1,ceil((coluNum-1)/interval)+1);%ÿǣѼĵ㣩ǵһ/УceilǸά

%㣺кжǸinterval
for i = 1 : interval : coluNum %еĵ㣬
 for j = 1 : interval: rowNum %ǰе
 if j == rowNum
 break;
 end
 triDot(((j-1)/interval)+1,((i-1)/interval)+1) = self.ServSatOfDiscrAreaCur(j,i);%triDotĳĳдǺ
 
 jDown = j + interval;
 if j + interval > rowNum
 jDown = rowNum;
 triDot(ceil((rowNum-1)/interval)+1,((i-1)/interval)+1)= self.ServSatOfDiscrAreaCur(jDown,i);
 end
 iRight = i + interval;
 if (i + interval - 1)* rowNum > rowNum * (coluNum - 1) 
 iRight = coluNum;
 triDot(((j-1)/interval)+1,ceil((coluNum-1)/interval)+1)= self.ServSatOfDiscrAreaCur(j,iRight);
 end
 
 %¿ʼжϣڵıͶӦڽӾֵ
 if self.ServSatOfDiscrAreaCur(j,i)~= self.ServSatOfDiscrAreaCur(jDown,i)%֮ж 
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j,i)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(jDown,i)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(jDown,i)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j,i)))=1;
 end 
 if self.ServSatOfDiscrAreaCur(j,i) ~= self.ServSatOfDiscrAreaCur(j,iRight)%ӵڶеĵ㿪ʼж֮ûб
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j,i)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j,iRight)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j,iRight)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j,i)))=1;
 end
% if ifDebug == 1
% fprintf('%dڽӾɸ%f%%\n',IdxOfStep,((i-1)*rowNum+j)*100/(coluNum*rowNum));
% else
% % tmpStr = num2str(((i-1)*rowNum+j)*100/(coluNum*rowNum));
% % tmpstr_s = 'ڽӾɸ';
% % tmpStr = strcat(tmpStr, '%');
% % tmpStr = strcat(tmpstr_s, tmpStr);
% % app.MonitorPrint(2, tmpStr);
% end 
 end
end

for i = 1 : length(triDot(1,:)) - 1 %
 for j = 1 : length(triDot(:,1)) - 1 %
 %currentDot = (j-1)*interval + rowNum * (i-1)*interval + 1;
 if triDot(j,i) ~= triDot(j+1,i) || triDot(j,i) ~= triDot(j,i+1)%˱Ҫû© 
 %жСΣ
 if j ~= length(triDot(:,1)) - 1 && i ~= length(triDot(1,:)) - 1
 %֮ǰڹϵ¼
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j*interval,(i-1)*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j*interval,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,i*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,i*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)))=0;
 for m = (j-1)*interval+1 : j*interval%Сε
 for k = (i-1)*interval + 1 : i*interval %СÿеԪ
 if self.ServSatOfDiscrAreaCur(m,k) ~= self.ServSatOfDiscrAreaCur(m+1,k) %֮жϣֹ±߽
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m+1,k)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m+1,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)))=1;
 end
 if self.ServSatOfDiscrAreaCur(m,k) ~= self.ServSatOfDiscrAreaCur(m,k+1) %֮жϣֹ±߽
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k+1)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k+1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)))=1;
 end
 end
 end
 else
 %һ
 if j == length(triDot(:,1)) - 1 && i ~= length(triDot(1,:)) - 1 %ʱСαɲһ
 %֮ǰڹϵ¼
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(rowNum,(i-1)*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(rowNum,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,i*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,i*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)))=0;
 for m = (j-1)*interval+1 : rowNum - 1 %Сε
 for k = (i-1)*interval + 1 : i*interval%СÿеԪ
 if self.ServSatOfDiscrAreaCur(m,k) ~= self.ServSatOfDiscrAreaCur(m+1,k) %֮жϣֹ±߽
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m+1,k)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m+1,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)))=1;
 end
 if self.ServSatOfDiscrAreaCur(m,k) ~= self.ServSatOfDiscrAreaCur(m,k+1) %֮жϣֹ±߽
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k+1)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k+1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)))=1;
 end
 end
 end
 else
 %ұһ
 if j ~= length(triDot(:,1)) - 1 && i == length(triDot(1,:)) - 1
 %֮ǰڹϵ¼
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j*interval,(i-1)*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(j*interval,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,coluNum)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,coluNum)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)))=0;
 for m = (j-1)*interval+1 : j*interval%Сε
 for k = (i-1)*interval + 1 : coluNum-1 %СÿеԪ
 if self.ServSatOfDiscrAreaCur(m,k) ~= self.ServSatOfDiscrAreaCur(m+1,k) %֮жϣֹ±߽
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m+1,k)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m+1,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)))=1;
 end
 if self.ServSatOfDiscrAreaCur(m,k) ~= self.ServSatOfDiscrAreaCur(m,k+1) %֮жϣֹ±߽
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k+1)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k+1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)))=1;
 end
 end
 end
 else
 %һҲһ 
 %֮ǰڹϵ¼
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(rowNum,(i-1)*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(rowNum,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,coluNum)))=0;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,coluNum)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur((j-1)*interval+1,(i-1)*interval + 1)))=0; 
 for m = (j-1)*interval+1 : rowNum - 1%Сε
 for k = (i-1)*interval + 1 : coluNum - 1 %СÿеԪ
 if self.ServSatOfDiscrAreaCur(m,k,1) ~= self.ServSatOfDiscrAreaCur(m+1,k) %֮жϣֹ±߽
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m+1,k)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m+1,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)))=1;
 end
 if self.ServSatOfDiscrAreaCur(m,k,1) ~= self.ServSatOfDiscrAreaCur(m,k+1) %֮жϣֹ±߽
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k+1)))=1;
 adjaMatrix(find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k+1)),find(OrderOfServSat==self.ServSatOfDiscrAreaCur(m,k)))=1;
 end
 end
 end
 end
 end
 end
 end
% if ifDebug == 1
% fprintf('%dڽӾϸɸ%f%%\n',IdxOfStep,((i-1)*(length(triDot(:,1))-1)+j)*100/(length(triDot(1,:))-1)/(length(triDot(:,1))-1));
% else
% % tmpStr = num2str(((i-1)*(length(triDot(:,1))-1)+j)*100/(length(triDot(1,:))-1)/(length(triDot(:,1))-1));
% % tmpstr_s = 'ڽӾϸɸ';
% % tmpStr = strcat(tmpStr, '%');
% % tmpStr = strcat(tmpstr_s, tmpStr);
% % app.MonitorPrint(2, tmpStr);
% end 
 end
end

%пɼǣÿǵھ
for i = 1 : NumOfServSat 
 self.SatObj(i).Neighbor = zeros(self.Config.layerOfinterf,NumOfServSat);%SatObjıʾOrderOfServSat 
 self.SatObj(i).Neighbor(1,1:length(find(adjaMatrix(i,:)==1))) = OrderOfServSat(find(adjaMatrix(i,:)==1));%һھ 
 for j = 2 : self.Config.layerOfinterf%ӵڶ㿪ʼÿһ㣬ʼ
 negbr=[];%ۼнֹ֮ǰеĳظ
 lastLayer = self.SatObj(i).Neighbor(j-1,:);
 lastLayer(lastLayer==0) = []; 
 for k = 1 : length(lastLayer)%һھӣʼҵڶ
 % temp=[]; 
 temp = find(adjaMatrix(find(OrderOfServSat == lastLayer(k)),:)==1);%ҵһǵ
 temp = OrderOfServSat(temp);
 temp = temp(~ismember(temp,self.SatObj(i).Neighbor));%ȥһǣʣµľһ 
 temp = temp(~ismember(temp,OrderOfServSat(i)));%ҪȥмǸ 
 temp = temp(~ismember(temp,negbr));
 negbr = [negbr;temp];%ۻһ½ 
 end
 self.SatObj(i).Neighbor(j,1:length(negbr)) = negbr;%Ҫ¼1800ľ 
% if ifDebug == 1
% fprintf('%dղھ%f%%\n',IdxOfStep,((i-1)*(self.Config.layerOfinterf-1)+j-1)*100/(self.Config.layerOfinterf-1)/NumOfServSat);
% end 
 end
end

self.NeighborAdjaMatrix = adjaMatrix;
end


) 
