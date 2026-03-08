function DiscrInvesArea(self)

if self.Config.ifWrapAround == 1
 Range = self.wrapRange';
else
 Range = self.Config.rangeOfInves';
end

%e.g.RangeOfInvesArea =[110, 120;33, 48];һǾȣڶγ

R=self.rOfearth;

%֤Range(1,2)ǸǸγ
if abs(Range(1,2)) < abs(Range(2,2))
 t = Range(2,2);
 Range(2,2) = Range(1,2);
 Range(1,2) = t;
end

N=self.Config.factorOfDiscr * (Range(1,2)-Range(2,2));%ǰѾεл֣ÿСθ߶distColu/N

if Range(1,1) < Range(2,1)%ûп180
 midLon = (Range(1,1)+Range(2,1))/2;
else
 deltaLon = 360 - Range(1,1) + Range(2,1);%180
 if 180-Range(1,1) > Range(2,1)-(-180)
 midLon = Range(1,1) + deltaLon/2;
 else 
 midLon = Range(2,1) - deltaLon/2;
 end 
end

distRow = calcuDist(Range(1,1),Range(2,1),Range(1,2),Range(1,2));%ĺ᳤
deltaLat = (Range(1,2) - Range(2,2))/N;%ÿγ֮ľǲ
triH = calcuDist(midLon,midLon,Range(1,2),Range(2,2))/N;%εĸ߶ȣλm
triX = triH*2/sqrt(3);%εı߳

coluNum = floor(distRow/triX);%
groundCoord = zeros(2 * N,coluNum,2);%άĵľγȣһǾȣڶγȣÿһֵʾͼеڼеڼеľγֵ
newCoord = zeros(N, coluNum*2,2);
groundCoord2D = zeros(coluNum*N*2,2);%öάȥתgroundCoord

groundCoord(1,1,2) = Range(1,2) - deltaLat/3;%һεγ

%һǼϵ 
for i = 1 : N * 2 %groundCoord˵2*N
 if i == 1 %γȱ
 else
 if mod(i,2)==1
 groundCoord(i,1,2) = groundCoord(i-1,1,2) - 2 * deltaLat/3;%γȺһвdelta/sqrt(3)
 else 
 groundCoord(i,1,2) = groundCoord(i-1,1,2) - deltaLat/3;%żγȺһвsqrt(3)*delta/6
 end
 end
 %ÿеһεľ
 if mod(i,4)==2 || mod(i,4) == 3
 groundCoord(i,1,1) = d2Lon(groundCoord(i,1,2),midLon,-distRow/2 );
 else
 groundCoord(i,1,1) = d2Lon(groundCoord(i,1,2),midLon,-distRow/2 + triX/2);
 end
 if groundCoord(i,1,1)<-180
 groundCoord(i,1,1) = 360 + groundCoord(i,1,1);%Ϊ180
 end
 deltaLon = (acos(1-2*(sin(triX/2/R)^2)/(cos((groundCoord(i,1,2))*pi/180)^2)))*180/pi;
 for j = 1 : coluNum
 groundCoord(i,j,2) = groundCoord(i,1,2);%γȱÿһеγһ 
 tempLon = groundCoord(i,1,1) + (j - 1) * deltaLon;%ȱÿ֮deltaLon
 if tempLon >= 180
 groundCoord(i,j,1) = -180 + tempLon - 180;
 else
 groundCoord(i,j,1) = tempLon;
 end
 %geoshow(groundCoord(i,j,2),groundCoord(i,j,1), 'Marker','.','MarkerEdgeColor','red')%εĵ㶼
 newEqualArray = [2*j-1,2*j-1;2*j-1,2*j-1;2*j,2*j;2*j,2*j];
 newCoord(ceil(i/2),newEqualArray(mod(i,4)+1,mod(j,2)+1),1) = groundCoord(i,j,1);
 newCoord(ceil(i/2),newEqualArray(mod(i,4)+1,mod(j,2)+1),2) = groundCoord(i,j,2);
 %geoshow(newCoord(ceil(i/2),newEqualArray(mod(i,4)+1,mod(j,2)+1),2),newCoord(ceil(i/2),newEqualArray(mod(i,4)+1,mod(j,2)+1),1),'Marker','.','MarkerEdgeColor','red');
 equalArray = [i/2+N,(i-1)/2+1+N,i/2,(i+1)/2];
 groundCoord2D((j-1)*N*2+equalArray(mod(i,4)+1),1)= groundCoord(i,j,1);
 groundCoord2D((j-1)*N*2+equalArray(mod(i,4)+1),2)= groundCoord(i,j,2);
 %geoshow(groundCoord2D((j-1)*N*2+equalArray(mod(i,4)+1),2),groundCoord2D((j-1)*N*2+equalArray(mod(i,4)+1),1),'Marker','.','MarkerEdgeColor','red');
 end 
% if self.ifDebug == 1
% fprintf('ɢΪ%f%%\n', i*100/(N * 2)); 
% end
end

self.DiscrArea = newCoord;
self.SeqDiscrArea = groundCoord2D;

end
%% ľ
function dist = calcuDist(lon1,lon2,lat1,lat2)
%ľγȶǽǶ
R = 6371.393e3;%λm
lon1 = lon1*pi/180;
lon2 = lon2*pi/180;
lat1 = lat1*pi/180;
lat2 = lat2*pi/180;
dist = 2*R*asin(sqrt(2*(1-cos(lat2 - lat1) + cos(lat2)*cos(lat1)-cos(lat2)*cos(lat1)*cos(lon2-lon1)))/2);

end

%% ǰγlatʼľlon1dlon2
function lon2 = d2Lon(lat,lon1,d)
%γǡ㣬km
%γͬǰ
%ο:.ǵ[J].ձ,2008(03):7-12.DOI:10.19297/j.cnki.41-1228/tj.2008.03.002.

%dmΪλ
lat = lat*pi/180;
lon1 = lon1 *pi/180;
R = 6371.393e3;

a = sin(d/2/R).^2;
b = cos(lat).^2;
%lon2 = lon1 + acos(1-(2*(sin(d./2/R).^2)./(cos(lat).^2)));
lon2 = lon1 + sign(d).*acos(1-2*a./b);

lon2 = lon2 *180/pi;
%ĽlonСķУlon2-lon1>0С-180
if lon2 < -180
 lon2 = 180 - (-180 - lon2);
elseif lon2 > 180
 lon2 = -180 + (lon2 - 180);
end

end
