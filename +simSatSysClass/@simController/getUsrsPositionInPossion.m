% 2023/03/16
% Generate
%%
% self.UsrsPosition
% matrix
% IfiswrapAround
% If
% UsrsPosition(k, 1)indicatesk
% UsrsPosition(k, 2)indicatesk
% UsrsPosition(k, 3)indicatesk
%%
function getUsrsPositionInPossion(self)
r = self.rOfearth; %，ism

HeightOfArea = tools.LatLngCoordi2Length( ...
 [0, self.Config.rangeOfInves(2,1)], ...
 [0, self.Config.rangeOfInves(2,2)], ...
 self.rOfearth);
LengthOfArea = self.rOfearth * ...
 cos(self.Config.rangeOfInves(2,2)*pi/180) * ...
 abs(self.Config.rangeOfInves(1,1)-self.Config.rangeOfInves(1,2))*pi/180;
AreaOfInves = HeightOfArea * LengthOfArea;
DensOfUsrs = self.Config.Uniform_NumOfUsrs/AreaOfInves; % user lambda

possionCofig = 4*pi*self.rOfearth*self.rOfearth*DensOfUsrs; % Parameteras/islambda*Area

numbPoints=poissrnd(possionCofig);%total， usernumber

xxRand=normrnd(0,1,numbPoints,3);
normRand=vecnorm(xxRand,2,2); %Euclidean norms (across each row)
xxRandBall=xxRand./normRand; %rescale by Euclidean norms
xxRandBall=r*xxRandBall; %rescale for non-unit sphere

xx=xxRandBall(:,1);
yy=xxRandBall(:,2);
zz=xxRandBall(:,3);
% markerSize=200;
% scatter3(xx,yy,zz,markerSize,'b.');
% axis square;
% hold on;


longitude = atan2(yy,xx)*180/pi;
latitude = atan2(zz,sqrt(xx .^ 2 + yy .^ 2))*180/pi;

% worldmap('World');
% plotm(latitude,longitude,'.','Color',[0 0 1]);

%e.g.RangeOfInvesArea
if self.Config.ifWrapAround == 1 % IfwrapAround
 minLat = min(self.wrapRange(2,:));
 maxLat = max(self.wrapRange(2,:));
% minLon = min(min(self.wrapRange(1,:)),self.DiscrArea(end,1,1));
% maxLon = max(max(self.wrapRange(1,:)),self.DiscrArea(end,end,1));
 rawNum = length(self.DiscrArea(:,1,1));
else
 minLat = min(self.Config.rangeOfInves(2,:));
 maxLat = max(self.Config.rangeOfInves(2,:));
% minLon = min(min(self.SimConfig.rangeOfinves(1,:)),self.DiscrArea(end,1,1));
% maxLon = max(max(self.SimConfig.rangeOfinves(1,:)),self.DiscrArea(end,end,1));
 rawNum = length(self.DiscrArea(:,1,1));
end

count = 1;%area user
user = zeros();

for i = 1 : numbPoints
% if latitude(i) >= minLat && latitude(i) <= maxLat && longitude(i) >= minLon && longitude(i) <= maxLon
 if latitude(i) >= minLat && latitude(i) <= maxLat 
 [ii,jj,~] = tools.findPointXY(self,latitude(i),longitude(i));
 if ii >0 && jj > 0 && jj <= length(self.DiscrArea(1,:,1))
% user(count,1:2) = [longitude(i),latitude(i)];
 user(count) = (jj - 1) * rawNum + ii;
 count = count + 1;
 end
 end
end
self.numOfUsrs_all = length(user);
user = user(randperm(self.numOfUsrs_all));
% for ui = 1 : length(user(:,1))
% self.Usrs(ui).position
% self.Usrs(ui).OrdOfDiscr = user(ui,3);
% end
self.UsrsPosition = zeros(self.numOfUsrs_all, 3);
if self.Config.ifWrapAround == 1 % IfwrapAround
 [~, tmpS1, tmpS2] = intersect(user,self.SeqDiscrInNonWrap); % toarea user
 tmpUsrsTriOrder = self.SeqDiscrInNonWrap(sort(tmpS2));
 self.numOfUsrs_inves = length(tmpUsrsTriOrder);
 self.InvesUsrsPosition = zeros(self.numOfUsrs_inves, 3);
 user(tmpS1) = []; % inuserDeleteareauser
 for k = 1 : self.numOfUsrs_all
 if k <= self.numOfUsrs_inves
 self.UsrsPosition(k, 3) = tmpUsrsTriOrder(k); % user inwraparea ID/number
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 self.InvesUsrsPosition(k, 3) = tmpUsrsTriOrder(k);
 self.InvesUsrsPosition(k, 1:2) = self.SeqDiscrArea(self.InvesUsrsPosition(k, 3), :);
 else
 self.UsrsPosition(k, 3) = user(k-self.numOfUsrs_inves);
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 end
 end
else
 self.numOfUsrs_inves = self.numOfUsrs_all;
 self.InvesUsrsPosition = zeros(self.numOfUsrs_inves, 3);
 for k = 1 : self.numOfUsrs_all
 self.UsrsPosition(k, 3) = user(k);
 self.UsrsPosition(k, 1:2) = self.SeqDiscrArea(self.UsrsPosition(k, 3), :);
 self.InvesUsrsPosition(k, 3) = user(k);
 self.InvesUsrsPosition(k, 1:2) = self.SeqDiscrArea(self.InvesUsrsPosition(k, 3), :);
 end
end

end

