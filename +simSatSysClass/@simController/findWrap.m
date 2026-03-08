% based onParameterWrapExtendValueandWrapAroundLayer
%%
function findWrap(self)
% based on
% isbased on

%% 
index = self.Config.WrapAroundLayer + 1;

h = self.Config.height; %orbitaltitude,ism
beamForward = self.Config.rangeOfBeam(1); % 
halfForward = h * tan(beamForward); %satellite 
deltaLat = acos(1-2*(sin(halfForward/2/6371.393e3))^2)*180/pi;

lat1 = min(self.Config.rangeOfInves(2,:)) - index*self.Config.WrapExtendValue;%firstis 
lat2 = max(self.Config.rangeOfInves(2,:)) + index*self.Config.WrapExtendValue;%secondis 
if lat2 > min(max(max(self.SatPosition(:,:,2)))+deltaLat,90)%range？
 lat2 = min(max(max(self.SatPosition(:,:,2)))+deltaLat,90);
end
if lat1 < (-1) * min(max(max(self.SatPosition(:,:,2)))+10,90)
 lat1 = (-1) * min(max(max(self.SatPosition(:,:,2)))+10,90);
end

%% 

lon1 = self.Config.rangeOfInves(1,1) - index*self.Config.WrapExtendValue;
lon2 = self.Config.rangeOfInves(1,2) + index*self.Config.WrapExtendValue;

if lon1 < -180 && lon2 > 180
 lon1 = -180;
 lon2 = 180;
elseif lon1 < -180
 lon1 = 180 - (-180 - lon1);
elseif lon2 > 180
 lon2 = -180 + (lon2 - 180);%needlon1andlon2
end

Range = self.Config.rangeOfInves';
if Range(1,1) < Range(2,1) % ，180
 midLon = (Range(1,1)+Range(2,1))/2;
else
 deltaLon = 360 - Range(1,1) + Range(2,1);%180
 if 180-Range(1,1) > Range(2,1)-(-180)
 midLon = Range(1,1) + deltaLon/2;
 else 
 midLon = Range(2,1) - deltaLon/2;
 end 
end

midLat = (Range(1,2) + Range(2,2))/2;

% based on
dist = tools.LatLngCoordi2Length([midLon midLat], [lon1 midLat], self.rOfearth);% 

lon11 = tools.d2Lon(lat2,midLon,-dist);
lon22 = tools.d2Lon(lat2,midLon,dist);

self.wrapRange = [lon11,lon22;lat1,lat2];

end

