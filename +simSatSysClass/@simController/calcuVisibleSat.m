% Calculate visible satellites based on beam scanning range self.Config.rangeOfBeam and simulation area self.DiscrArea
% Output self.VisibleSat
%%
function calcuVisibleSat(self)
%using 
%self.SatPosition stores satellite latitude/longitude information at each time step, first is longitude, second is latitude
%self.Config.rangeOfBeam beam scanning range, first is forward/backward, second is left/right
%self.SeqDiscrArea stores triangle center coordinates, (k,1) is longitude, (k,2) is latitude
%Generate 
%self.VisibleSat visible satellite position matrix, VisibleSat(k, j, 1:2) indicates longitude/latitude coordinates of satellite ID k at time step j, invisible satellite coordinates set to (500, 500) 

if self.Config.ifWrapAround == 1
    lat1 = self.wrapRange(2,1);lat2 = self.wrapRange(2,2);
    lon1 = self.wrapRange(1,1);lon2 = self.wrapRange(1,2);
else
    %test location range
    lat1 = self.Config.rangeOfInves(2,1);lat2 = self.Config.rangeOfInves(2,2);
    lon1 = self.Config.rangeOfInves(1,1);lon2 = self.Config.rangeOfInves(1,2); 
    %Ensure lat2 stores the higher latitude, where higher means larger numerical value, used to define the large area
    if lat2 < lat1
        t = lat2;
        lat2 = lat1;
        lat1 = t;
    end
end

h = self.Config.height;                   %orbital altitude, unit is m
beamForward = self.Config.rangeOfBeam(1);                 %larger angle 
beamLeft = self.Config.rangeOfBeam(2);                    %smaller angle
halfForward = h * tan(beamForward);                 %half of satellite illumination rectangle length
halfLeft = h * tan(beamLeft);                       %half of satellite illumination rectangle width

[satNum,timeNum,~] = size(self.SatPosition);        %Get total time steps and total satellites
tempVisibleSat = zeros(satNum,timeNum - 1,2);       %Assign values to satellite coordinates
[triNum,~] = size(self.SeqDiscrArea);               %Get total number of triangles

%Use flag to distinguish cases, total 2 situations: 1 for normal calculation; 0 for symmetry method
if lon2 < lon1                                      %If area crosses 180 degrees, need symmetry
    flag = 0;                                       %flag is 0 indicates using symmetry method
else
    flag = 1;                                       %If flag is 1, use normal calculation
end

tempCrust = sqrt(halfForward^2+halfLeft^2)*0.00001;
if lon1 - tempCrust <-180 || lon2 +tempCrust>180
    if lon1 - tempCrust <-180 && lon2 +tempCrust>180    %Exclude the case where investigation area is very long
    else
        flag =0;                                        %Large area crosses 180 degree line, also use symmetry method
    end
end

% %Calculate the longitude of the middle line
% if lon1 < lon2                             %Did not cross 180
%     midLon = (lon1+lon2)/2;
% else
%     deltaLon = 360 - lon1 + lon2;          %Crossed 180
%     if 180-lon1 > lon2-(-180)
%         midLon = lon1 + deltaLon/2;
%     else 
%         midLon = lon2- deltaLon/2;
%     end
% end

% R=self.rOfearth;                         %Earth radius
% N=self.FactorOfDiscr;                         %Total area rows
% triH = tools.LatLngCoordi2Length([midLon,lat1],[midLon,lat2],R)/N;%Triangle altitude, unit is m
% interval = ceil( 2 * halfLeft/triH);          %interval, Calculation method: satellite illumination rectangle width / triangle altitude
hOfDiscr = tools.LatLngCoordi2Length([0 0], [0 1], self.rOfearth)/self.Config.factorOfDiscr;
interval = ceil(2*tools.getEarthLength(self.Config.rangeOfBeam(2)*2, h)/hOfDiscr);

tempSatNum = zeros(satNum,1);                   %Temporarily store satellite ID, if already found visible, skip in supplementary calculation

%% flag = 1 Normal calculation case for visible satellites
if flag == 1
    bjLarge = [lon1 - tempCrust,lon2 + tempCrust;
    lat1 - tempCrust/1.1,lat2 + tempCrust/1.1];     %Large area that might be visible
    for i = 1 : timeNum - 1                         %Traverse all time steps, need next time step to judge satellite movement direction, so timeNum-1 
        triDot = zeros(ceil(triNum/interval),1);    %Store visible satellites for current time step triangles
        for j = 1 : satNum                          %Traverse satellites
            if self.SatPosition(j,i,1) ~= 500
                if self.SatPosition(j,i,1) >= bjLarge(1,1) && self.SatPosition(j,i,1) <= bjLarge(1,2) && self.SatPosition(j,i,2) >= bjLarge(2,1) && self.SatPosition(j,i,2) <= bjLarge(2,2)
                    satRec = findSatRec(beamForward, beamLeft, self.SatPosition(j,i,2), self.SatPosition(j,i+1,2), self.SatPosition(j,i,1),self.SatPosition(j,i+1,1));%Get satellite coverage rectangle
                       for m = 1 : interval : triNum
                        dotCoord = self.SeqDiscrArea(m,:);
                        in= calcuIN(satRec,dotCoord);
                            if in ==1
                                triDot(1 + (m-1)/interval,1) = j;
                                tempSatNum(j,1) = 1;
                                tempVisibleSat(j,i,1) = self.SatPosition(j,i,1);
                                tempVisibleSat(j,i,2) = self.SatPosition(j,i,2);
                                %fprintf('%d\n',j);
                                %If inside, store coordinates
                                break;
                            else
                                tempVisibleSat(j,i,1) = 500;
                                tempVisibleSat(j,i,2) = 500;
                            end                        
                       end
                else
                    tempVisibleSat(j,i,1) = 500;
                    tempVisibleSat(j,i,2) = 500;
                end
            else
                    tempVisibleSat(j,i,1) = 500;
                    tempVisibleSat(j,i,2) = 500;                
            end
        end
        %Supplementary calculation
        for k = 2 : ceil(triNum/interval)
            if(triDot(k-1,1)==0 && triDot(k,1)>0) || (triDot(k-1,1)>0 && triDot(k,1) > 0 && triDot(k-1,1) ~= triDot(k,1))%Satisfied supplementary judgment condition
                for j = 1 : satNum
                    if self.SatPosition(j,i,1) ~= 500
                        if tempSatNum(j,1) == 0 %Already found visible, no need to judge again
                            if self.SatPosition(j,i,1) >= bjLarge(1,1) && self.SatPosition(j,i,1) <= bjLarge(1,2) && self.SatPosition(j,i,2) >= bjLarge(2,1) && self.SatPosition(j,i,2) <= bjLarge(2,2)
                            satRec = findSatRec(beamForward, beamLeft, self.SatPosition(j,i,2), self.SatPosition(j,i+1,2), self.SatPosition(j,i,1),self.SatPosition(j,i+1,1));%Get satellite coverage rectangle
                                for m = (k-2)*interval +2  : (k-1)*interval
                                    dotCoord = self.SeqDiscrArea(m,:);
                                    in= calcuIN(satRec,dotCoord);
                                    if in ==1
                                        %fprintf('other:%d\n',j);
                                        tempVisibleSat(j,i,1) = self.SatPosition(j,i,1);
                                        tempVisibleSat(j,i,2) = self.SatPosition(j,i,2);
                                        break;
                                    end                        
                                end
                            end
                        end
                    else
                        tempVisibleSat(j,i,1) = 500;
                        tempVisibleSat(j,i,2) = 500;
                    end
                end
            end
        end
%         if ifDebug == 1
%             fprintf('Calculate visible satellites for each snapshot %f%%\n',i*100/(timeNum - 1));            
%         end
        %fprintf('Calculate visible satellites for each snapshot %f%%\n',((i-1)*satNum+j)*100/(satNum*(timeNum - 1)));
    end
end

%% flag = 0 Use symmetry method to calculate visible satellites
if flag == 0
    lon1 = sign(lon1)*180 - lon1;lon2 = sign(lon2)*180 - lon2;%Symmetrize test area, symmetry rule: latitude unchanged, longitude symmetric to 0 degree line, direct normal symmetry, no crossover
    bjLarge = [lon1 + tempCrust,lon2 - tempCrust;
    lat1 - tempCrust/1.1,lat2 + tempCrust/1.1];               %Large area that might be visible
    SatPosition(:,:,1) = sign(self.SatPosition(:,:,1))*180 - self.SatPosition(:,:,1);%Symmetrize satellite sub-satellite point
    SatPosition(:,:,2) = self.SatPosition(:,:,2);
    for i = 1 : timeNum - 1                                   %Need next time step to judge satellite movement direction, so timeNum-1
        SeqDiscrArea(:,1) = sign(self.SeqDiscrArea(:,1))*180 - self.SeqDiscrArea(:,1);%Symmetrize all discrete triangle center points
        SeqDiscrArea(:,2) = self.SeqDiscrArea(:,2);
        triDot = zeros(ceil(triNum/interval),1);              %Store visible satellites for each triangle at current time step
        for j = 1 : satNum                                    %Traverse satellites
            if self.SatPosition(j,i,1) ~= 500            
                if SatPosition(j,i,1) <= bjLarge(1,1) && SatPosition(j,i,1) >= bjLarge(1,2) && SatPosition(j,i,2) >= bjLarge(2,1) && SatPosition(j,i,2) <= bjLarge(2,2)
                    satRec = findSatRec(beamForward, beamLeft, SatPosition(j,i,2), SatPosition(j,i+1,2), SatPosition(j,i,1),SatPosition(j,i+1,1));%Get satellite coverage rectangle                   
                        for m = 1 : interval : triNum                       
                        dotCoord = SeqDiscrArea(m,:);
                        in= calcuIN(satRec,dotCoord);
                            if in ==1
                                triDot(1 + (m-1)/interval,1) = j;
                                tempSatNum(j,1) = 1;
                                tempVisibleSat(j,i,1) = self.SatPosition(j,i,1);
                                tempVisibleSat(j,i,2) = self.SatPosition(j,i,2);
                                %If inside, store coordinates
                                break;
                            else
                                tempVisibleSat(j,i,1) = 500;
                                tempVisibleSat(j,i,2) = 500;
                            end                        
                        end
                else
                    tempVisibleSat(j,i,1) = 500;
                    tempVisibleSat(j,i,2) = 500;
                end
            else
                    tempVisibleSat(j,i,1) = 500;
                    tempVisibleSat(j,i,2) = 500;
            end
        end 
        %Supplementary calculation
        for k = 2 : ceil(triNum/interval)
            if(triDot(k-1,1)==0 && triDot(k,1)>0) || (triDot(k-1,1)>0 && triDot(k,1) > 0 && triDot(k-1,1) ~= triDot(k,1))%Satisfied supplementary judgment condition
                for j = 1 : satNum
                    if self.SatPosition(j,i,1) ~= 500
                        if tempSatNum(j,1) ~= 0 %Already found visible, no need to judge, key is to supplement
                        else
                            if SatPosition(j,i,1) <= bjLarge(1,1) && SatPosition(j,i,1) >= bjLarge(1,2) && SatPosition(j,i,2) >= bjLarge(2,1) && SatPosition(j,i,2) <= bjLarge(2,2)
                            satRec = findSatRec(beamForward, beamLeft, SatPosition(j,i,2), SatPosition(j,i+1,2), SatPosition(j,i,1),SatPosition(j,i+1,1));%Get satellite coverage rectangle
                                for m = (k-2)*interval +2  : (k-1)*interval
                                    dotCoord = SeqDiscrArea(m,:);
                                    in= calcuIN(satRec,dotCoord);
                                    if in ==1
                                        tempVisibleSat(j,i,1) = self.SatPosition(j,i,1);
                                        tempVisibleSat(j,i,2) = self.SatPosition(j,i,2);
                                        %fprintf('%d\n',j);
                                        %If inside, store coordinates
                                        break;
                                    end                        
                                end
                            end
                        end
                    else
                        tempVisibleSat(j,i,1) = 500;
                        tempVisibleSat(j,i,2) = 500;
                    end
                end
            end
        end
%         if ifDebug == 1
%            fprintf('Calculate visible satellites for each snapshot %f%%\n',i*100/(timeNum - 1));
%         end
        %fprintf('Calculate visible satellites for each snapshot %f%%\n',((i-1)*satNum+j)*100/(satNum*(timeNum - 1)));
    end

end
                        end
                else
                    tempVisibleSat(j,i,1) = 500;
                    tempVisibleSat(j,i,2) = 500;
                end
            else
                    tempVisibleSat(j,i,1) = 500;
                    tempVisibleSat(j,i,2) = 500;
            end
        end 
        % Supplementary calculation
        for k = 2 : ceil(triNum/interval)
            if(triDot(k-1,1)==0 && triDot(k,1)>0) || (triDot(k-1,1)>0 && triDot(k,1) > 0 && triDot(k-1,1) ~= triDot(k,1))% Supplementary judgment condition met
                for j = 1 : satNum
                    if self.SatPosition(j,i,1) ~= 500
                        if tempSatNum(j,1) ~= 0 % Already found visible, no need to judge again
                        else
                            if SatPosition(j,i,1) <= bjLarge(1,1) && SatPosition(j,i,1) >= bjLarge(1,2) && SatPosition(j,i,2) >= bjLarge(2,1) && SatPosition(j,i,2) <= bjLarge(2,2)
                            satRec = findSatRec(beamForward, beamLeft, SatPosition(j,i,2), SatPosition(j,i+1,2), SatPosition(j,i,1),SatPosition(j,i+1,1));% Get satellite coverage rectangle
                                for m = (k-2)*interval +2  : (k-1)*interval
                                    dotCoord = SeqDiscrArea(m,:);
                                    in= calcuIN(satRec,dotCoord);
                                    if in ==1
                                        tempVisibleSat(j,i,1) = self.SatPosition(j,i,1);
                                        tempVisibleSat(j,i,2) = self.SatPosition(j,i,2);
                                        % If inside, store coordinates
                                        break;
                                    end                        
                                end
                            end
                        end
                    else
                        tempVisibleSat(j,i,1) = 500;
                        tempVisibleSat(j,i,2) = 500;
                    end
                end
            end
        end
%         if ifDebug == 1
%            fprintf('Calculate visible satellites for snapshot %f%%\n',i*100/(timeNum - 1));
%         else
% %             tmpStr = num2str(i*100/(timeNum - 1));
% %             tmpstr_s = 'Calculate visible satellites for snapshot';
% %             tmpStr = strcat(tmpStr, '%');
% %             tmpStr = strcat(tmpstr_s, tmpStr);
% %             app.MonitorPrint(2, tmpStr); 
%         end
        %fprintf('Calculate visible satellites for snapshot %f%%\n',((i-1)*satNum+j)*100/(satNum*(timeNum - 1)));
    end

end

self.VisibleSat = tempVisibleSat;

end

%% This function finds the four vertex coordinates of the satellite illumination rectangle
function satRec = findSatRec(Forward, Left, satLat1, satLat2, satLon1, satLon2)

beamForward = Forward + 10*pi/180; 
beamLeft = Left + 10*pi/180;%beam scanning angle
h = 508*1000;%orbital altitude

halfForward = h * tan(beamForward);
halfLeft = h * tan(beamLeft);

satMove = [satLat2 - satLat1, satLon2 - satLon1];%satellite movement direction vector
latVecRight = [1,0];%latitude line direction vector, pointing right 
latVecLeft = [-1,0];%latitude line direction vector, pointing left 

alpha = min(acos(dot(satMove,latVecRight)/norm( satMove)/norm(latVecRight)),acos(dot(satMove,latVecLeft)/norm( satMove)/norm(latVecLeft)));%Angle between latitude line and satellite movement direction
beta = pi/2-alpha;

satDiamd = zeros(4,2);%Store inscribed diamond vertex coordinates of satellite, 1 is latitude, reversed
satDiamd(1,:) = [satLat1 + sign(satMove(1))*halfForward*sin(alpha)/1.1*0.00001, satLon1 + sign(satMove(2))*halfForward*cos(alpha)*0.00001];%Forward coordinate
satDiamd(3,:) = [2*satLat1 - satDiamd(1,1), 2*satLon1 - satDiamd(1,2)];%Rows 1,3 are forward/backward coordinates
satDiamd(2,:) = [satLat1 + (-1)*sign(satMove(1))*halfLeft*sin(beta)/1.1*0.00001,satLon2 + sign(satMove(2))*halfLeft*cos(beta)*0.00001];
satDiamd(4,:) = [2*satLat1 - satDiamd(2,1), 2*satLon1 - satDiamd(2,2)];%Rows 2,4 are left/right coordinates

satRec = zeros(4,2);%Store satellite beam rectangle range vertex coordinates
for i = 1 : 4
    if  i == 4
        satRec(i,2) = satDiamd(i,1) + satDiamd(1,1) - satLat1;%At this time, use 1 to store longitude
        satRec(i,1) = satDiamd(i,2) + satDiamd(1,2) - satLon1;
    else
        satRec(i,2) = satDiamd(i,1) + satDiamd(i+1,1) - satLat1;
        satRec(i,1) = satDiamd(i,2) + satDiamd(i+1,2) - satLon1;
    end
end

end

%% Judge if a point is inside a certain rectangle
function in= calcuIN(satRec,dotCoord)

if getCross(satRec(1,:),satRec(2,:),dotCoord) * getCross(satRec(3,:),satRec(4,:),dotCoord) >= 0 && getCross(satRec(2,:),satRec(3,:),dotCoord) * getCross(satRec(4,:),satRec(1,:),dotCoord) >= 0
    in = 1;
else
    in = 0;
end

%in = inpolygon(dotLat,dotLon,[satRec(1,1),satRec(2,1),satRec(3,1),satRec(4,1)],[satRec(1,1),satRec(2,2),satRec(3,2),satRec(4,2)]);

end

%% Cross product
function result = getCross(p1,p2,p)
%Use the directionality of cross product to judge if the angle exceeds 180 degrees to determine if inside rectangle
result = (p2(1,1) - p1(1,1)) * (p(1,2) - p1(1,2)) -(p(1,1) - p1(1,1)) * (p2(1,2) - p1(1,2));
end