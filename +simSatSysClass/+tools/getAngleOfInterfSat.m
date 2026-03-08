
function [varThetaUsr, r2, r1] = getAngleOfInterfSat(UsrPosition, CurSatPosition, SatPosition, height)

% Calculate off-axis angle of interfering satellite relative to main satellite boresight
R = 6371.393e3; % 

% a1 = LatLngCoordi2Alpha(UsrPosition, SatPosition);
% m1 = height + R - R*cos(a1);
% r1 = sqrt(m1.^2+(R*sin(a1)).^2);

% a2 = LatLngCoordi2Alpha(UsrPosition, CurSatPosition);
% m2 = height + R - R*cos(a2);
% r2 = sqrt(m2.^2+(R*sin(a2)).^2);

% beta = LatLngCoordi2Alpha(SatPosition, CurSatPosition);
% s = 2*(R+height)*sin(beta/2);

% varThetaUsr = acos((r1.^2+r2.^2-s.^2)/(2*r1*r2));
AxisX_Alpha = 0;
AxisY_Beta = 0;
AxisZ_Gama = 0;

rho = R;
theta = 90 - UsrPosition(2);
phi = UsrPosition(1);
if phi < 0
 phi = phi + 360;
end
NewOrigin_in_Spherical = [rho, theta, phi];

Coordinate_in_LngLat_1 = [CurSatPosition(1), CurSatPosition(2), R+height];
NewSatCur = LngLat2Descartes(...
 NewOrigin_in_Spherical,...
 AxisX_Alpha,...
 AxisY_Beta,...
 AxisZ_Gama,...
 Coordinate_in_LngLat_1);

Coordinate_in_LngLat_2 = [SatPosition(1), SatPosition(2), R+height];
NewSatInterf = LngLat2Descartes(...
 NewOrigin_in_Spherical,...
 AxisX_Alpha,...
 AxisY_Beta,...
 AxisZ_Gama,...
 Coordinate_in_LngLat_2);

r2 = sqrt(NewSatCur(1)^2 + NewSatCur(2)^2 + NewSatCur(3)^2);
r1 = sqrt(NewSatInterf(1)^2 + NewSatInterf(2)^2 + NewSatInterf(3)^2);
varThetaUsr = acos(abs(dot(NewSatCur, NewSatInterf))/...
 (r1 * r2));
end



% function Alpha = LatLngCoordi2Alpha(CoordiA, CoordiB)


% lngA = CoordiA(1);
% alpha1 = lngA * pi / 180;
% latA = CoordiA(2);
% beta1 = latA * pi / 180;

% lngB = CoordiB(1);
% alpha2 = lngB * pi / 180;
% latB = CoordiB(2);
% beta2 = latB * pi / 180;

% Alpha = acos(cos(pi/2-beta2)*cos(pi/2-beta1) + sin(pi/2-beta2)*sin(pi/2-beta1)*cos(alpha2-alpha1));

% end

function Coordinate_in_Descartes = LngLat2Descartes(...
 NewOrigin_in_Spherical,...
 AxisX_Alpha,...
 AxisY_Beta,...
 AxisZ_Gama,...
 Coordinate_in_LngLat)
 % Step1
 Phi = Coordinate_in_LngLat(1) * pi / 180;
 if Phi < 0
 Phi = Phi + 2*pi;
 end
 Theta = (90 - Coordinate_in_LngLat(2)) * pi / 180;
 % Step2
 R = Coordinate_in_LngLat(3);
 X = R * sin(Theta) * cos(Phi);
 Y = R * sin(Theta) * sin(Phi);
 Z = R * cos(Theta);
 % Step3
 alpha = AxisX_Alpha * pi / 180;
 T1 = [1, 0, 0;...
 0, cos(alpha), sin(alpha);...
 0, -sin(alpha), cos(alpha)];
 beta = AxisY_Beta * pi / 180;
 T2 = [cos(beta), 0, -sin(beta);...
 0, 1, 0;...
 sin(beta), 0, cos(beta)];
 gama = AxisZ_Gama * pi / 180;
 T3 = [cos(gama), sin(gama), 0;...
 -sin(gama), cos(gama), 0;...
 0, 0, 1];
 % From geocentric to satellite system: first rotate z-axis to align x-axis with longitude; then rotate y-axis to align x-axis with Earth center; then rotate x-axis to align y-axis with travel direction
 Coord = [X; Y; Z];
 NewCoord = T1*(T2*(T3*Coord));
% T = T1*T2*T3;
 r = NewOrigin_in_Spherical(1);
 theta = NewOrigin_in_Spherical(2) * pi / 180;
 phi = NewOrigin_in_Spherical(3) * pi / 180;
 X_0 = r * sin(theta) * cos(phi);
 Y_0 = r * sin(theta) * sin(phi);
 Z_0 = r * cos(theta);
% T_0 = [T(1,1), T(1,2), T(1,3), X_0;...
% T(2,1), T(2,2), T(2,3), Y_0;...
% T(3,1), T(3,2), T(3,3), Z_0;...
% 0, 0, 0, 1];
% temp_b = [X; Y; Z; 1];
% NewDescartes = inv(T_0) \ temp_b;
 NewDescartes = NewCoord - [X_0; Y_0; Z_0];
 Coordinate_in_Descartes = [NewDescartes(1), NewDescartes(2), NewDescartes(3)];
end
