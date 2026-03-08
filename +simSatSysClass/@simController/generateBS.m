function generateBS(self)
Range = self.Config.rangeOfInves;
%e.g.RangeOfInvesArea

%invAreaas
% LongSpan = Range(1,2) - Range(1,1);
% LatSpan = Range(2,2) - Range(2,1);
% invArea = zeros(2,2);
% invArea(1,1) = randi(LongSpan-4) + Range(1,1);
% invArea(1,2) = invArea(1,1) + 4;
% invArea(2,1) = randi(LatSpan-4) + Range(2,1);
% invArea(2,2) = invArea(2,1) + 4;
invArea = Range;
if abs(invArea(2,1)) < abs(invArea(2,2))
 t = invArea(2,2);
 invArea(2,2) = invArea(2,1);
 invArea(2,1) = t;
end
D = 0.8;%0.8km
h = D/2*sqrt(3);%
row = ceil(abs(invArea(2,1)-invArea(2,2))*110/h) ;%range， 
distRow = calcuDist(invArea(1,1),invArea(1,2),invArea(2,1),invArea(2,1));%area 
col = ceil(distRow/(D*1000));%
BS = zeros(row,col,2);%matrix ，firstis，secondis， valueindicatesisin value
for a = 1:row

 unitLat = h/110;
 BS(a,1,2) = invArea(2,1) - sign(invArea(2,1))*(a-1)*unitLat;
 unitLon = deltalong(D*1000,BS(a,1,2));
 if mod(a,2)==1
 BS(a,1,1) = invArea(1,1);
 else
 BS(a,1,1) = invArea(1,1) + 0.5*unitLon;
 end
 %as
 if BS(a,1,1) < -180
 BS(a,1,1) = BS(a,1,1) + 360;
 end
 
 for b = 2:col

 BS(a,b,2) = BS(a,1,2);
 tempLon = BS(a,1,1) + (b-1)*unitLon;
 %180 
 if tempLon>180
 BS(a,b,1) = -180 + tempLon - 180;
 else
 BS(a,b,1) = tempLon;
 end
 end
end
self.BS_array = BS;
self.BS_invArea = [BS(1,1,1),min(self.BS_array(:,col,1));
 BS(row,1,2),BS(1,1,2)];%first，second

end


function long = deltalong(d,lat)
lat = lat*pi/180;
R = 6371.393e3;
a = sin(d/2/R).^2;
b = cos(lat).^2;
long = sign(d).*acos(1-2*a./b);
long = long*180/pi;
end

%Calculate
function dist = calcuDist(lon1,lon2,lat1,lat2)
R = 6371.393e3;%ism
lon1 = lon1*pi/180;
lon2 = lon2*pi/180;
lat1 = lat1*pi/180;
lat2 = lat2*pi/180;
dist = 2*R*asin(sqrt(2*(1-cos(lat2 - lat1) + cos(lat2)*cos(lat1)-cos(lat2)*cos(lat1)*cos(lon2-lon1)))/2);
end

