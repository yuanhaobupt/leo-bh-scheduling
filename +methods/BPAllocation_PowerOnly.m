function BPAllocation_PowerOnly(interface)
% This function allocates frequency band and power to users within beam positions, proposed algorithm

%% Get data
OrderOfServSatCur = interface.OrderOfServSatCur; % List of serving satellites
NumOfServSatCur = length(OrderOfServSatCur); % Number of serving satellites
NumOfSche = interface.ScheInShot; % Number of scheduling periods per snapshot
BW = interface.BandOfLink*1e6; % Bandwidth, unit is Hz
freqOfDownLink = interface.freqOfDownLink; % (Hz) Satellite downlink center frequency
startOfBand = freqOfDownLink - BW / 2;% (Hz) Satellite downlink start frequency
heightOfsat = interface.height;% Satellite orbit height
maxPower = 10^(interface.Pt_dBm_serv/10)/1000/interface.numOfServbeam;% Total power per beam, unit is w
K = 1.38e-23; % Boltzmann constant
Ta_usr = interface.Config.Usr_T_noise;
F_usr = interface.Config.Usr_F_noise;
% Do we need to consider that each beam's power is not average?
% If considered, it's also a convex optimization problem, can also use Lagrangian + water-filling, whether to consider can be two curve results
%% Traverse beam positions
for idxOfSat = 1 : NumOfServSatCur
 curSatPos = interface.SatObj(idxOfSat).position;
 satPosInDescartes = LngLat2Descartes(curSatPos, heightOfsat);
 curSatNextPos = interface.SatObj(idxOfSat).nextpos;
 for idxOfSche = 1 : NumOfSche
 for idxOfFoot = 1 : interface.tmpSat(idxOfSat).NumOfBeamFoot(idxOfSche)

 orderOfUsrs = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, idxOfFoot).usrs;
 numOfUserInFoot = length(orderOfUsrs);
 if numOfUserInFoot == 1
 % If only one user, no need to be complicated
 interface.UsrsObj(orderOfUsrs).Band = [startOfBand, startOfBand + BW];
 interface.UsrsObj(orderOfUsrs).BandWidth = BW;
 interface.UsrsObj(orderOfUsrs).PowerPercent = 1;
 else
 % Calculate pointing direction to this beam position
 BeamPoint = zeros(1,2);
 curBeamPos = interface.tmpSat(idxOfSat).beamfoot(idxOfSche, idxOfFoot).position;
 [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
 curSatPos, curSatNextPos, curBeamPos, heightOfsat);
 BeamPoint(1) = outputPhi;
 BeamPoint(2) = outputTheta;
 %% Allocate sub-bands: Hungarian algorithm
 n = numOfUserInFoot;% Matrix dimension
 Gtmp = zeros(n, n);
 d = zeros(1, n);
 avgPower = maxPower / n;
 subBandWidth = BW/numOfUserInFoot;% Width of each sub-band
 % Start generating n*n matrix below, the (i,j) element represents the cost of assigning the j-th sub-band to the i-th user
 HungMat = zeros(n, n);
 for i = 1 : n % User
 curUser = orderOfUsrs(i);
 curUserPos = interface.UsrsObj(curUser).position;
 usrPosInDescartes = LngLat2Descartes(curUserPos, 0);
 distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrPosInDescartes(3)).^2);
 d(i) = distance;
 for j = 1 : n % band
 % Calculate award
 tmpBand = [startOfBand + subBandWidth * (j - 1), startOfBand + subBandWidth * j];
 tmpFc = mean(tmpBand(1,:)); 
 
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(curSatPos, curSatNextPos, curUserPos, heightOfsat);% Calculate azimuth and elevation angles
 Gsat = antenna.getSatAntennaServG([UsrTheta, UsrPhi], [BeamPoint(2), BeamPoint(1)], tmpFc);
 Gusr = antenna.getUsrAntennaServG(0, tmpFc, false);
 % Also Gsat+Gusr??
 Gtmp(i,j) = Gsat * Gusr;

 N_noise_usr = subBandWidth*K*(Ta_usr+(F_usr-1)*300);
 
 award = (3e8/tmpFc / distance)^2 * Gsat * Gusr / N_noise_usr;% award = (lambda/d)^2*G/N0
 
 HungMat(i,j) = award;
 end
 end
 
 % Hungarian algorithm is for minimization problem, but I need maximization, so convert the problem
 [assignment,~] = munkres(HungMat);

 allocBand = zeros(n,2);
 for i = 1 : n
 res = assignment(i);
 allocBand(i, 1) = startOfBand + (res - 1) * subBandWidth;
 allocBand(i, 2) = startOfBand + res * subBandWidth; 
 end
 
 % Store results
 for i = 1 : n
 interface.UsrsObj(orderOfUsrs(i)).Band = [allocBand(i,1), allocBand(i,2)];
 interface.UsrsObj(orderOfUsrs(i)).BandWidth = allocBand(i,2) - allocBand(i,1);
 end


 %% Allocate power: Lagrangian + water-filling
 % Get result should be a ratio of each user's power to total power within beam position
 h = zeros(1, n);
 for i = 1 : n % User
 curUser = orderOfUsrs(i);
 curUserPos = interface.UsrsObj(curUser).position;
 curFc = mean(allocBand(i,:));

 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(curSatPos, curSatNextPos, curUserPos, heightOfsat);% Calculate azimuth and elevation angles
 Gsat = antenna.getSatAntennaServG([UsrTheta, UsrPhi], [BeamPoint(2), BeamPoint(1)], curFc);

 Gusr = antenna.getUsrAntennaServG(0, curFc, false);

 N_noise_usr = (allocBand(i, 2) - allocBand(i, 1)) * K * (Ta_usr+(F_usr-1)*300);
 
 curLambda = 3e8/curFc;

 h(i) = Gsat * Gusr * (curLambda/(4*pi*d(i)))^2 / N_noise_usr;% Gt*Gr*(lambda/(4*pi*d))^2/N
 end
 [~, allocPercentage] = water_filling2(1./h, maxPower);
 % Store results
 for i = 1 : n
 interface.UsrsObj(orderOfUsrs(i)).PowerPercent = allocPercentage(i);
 end
 end

 % When
 [assignment,~] = munkres(HungMat);

 allocBand = zeros(n,2);
 for i = 1 : n
 res = assignment(i);
 allocBand(i, 1) = startOfBand + (res - 1) * subBandWidth;
 allocBand(i, 2) = startOfBand + res * subBandWidth; 
 end

 for i = 1 : n
% res = assignment(i);
 interface.UsrsObj(orderOfUsrs(i)).Band = [allocBand(i,1), allocBand(i,2)];
 interface.UsrsObj(orderOfUsrs(i)).BandWidth = allocBand(i,2) - allocBand(i,1);
 end


 h = zeros(1, n);
 for i = 1 : n % user
 curUser = orderOfUsrs(i);
 curUserPos = interface.UsrsObj(curUser).position;
 curFc = mean(allocBand(i,:));

 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(curSatPos, curSatNextPos, curUserPos, heightOfsat);%Calculateand
 Gsat = antenna.getSatAntennaServG([UsrTheta, UsrPhi], [BeamPoint(2), BeamPoint(1)], curFc);

 Gusr = antenna.getUsrAntennaServG(0, curFc, false);

 N_noise_usr = (allocBand(i, 2) - allocBand(i, 1)) * K * (Ta_usr+(F_usr-1)*300);
 
 curLambda = 3e8/curFc;

 h(i) = Gsat * Gusr * (curLambda/(4*pi*d(i)))^2 / N_noise_usr;% Gt*Gr*(lambda/(4*pi*d))^2/N
 end
 [~, allocPercentage] = water_filling2(1./h, maxPower);

 for i = 1 : n
 interface.UsrsObj(orderOfUsrs(i)).PowerPercent = allocPercentage(i);
 end

 end
 
 end
 fprintf('Satellite %d scheduling period %d calculation completed\n',idxOfSat,idxOfSche);
 end
end
end

%% 
function [assignment,cost] = munkres(costMat)
% MUNKRES Munkres (Hungarian) Algorithm for Linear Assignment Problem. 

% [ASSIGN,COST] = munkres(COSTMAT) returns the optimal column indices,
% ASSIGN assigned to each row and the minimum COST based on the assignment
% problem represented by the COSTMAT, where the (i,j)th element represents the cost to assign the jth
% job to the ith worker.

% Partial assignment: This code can identify a partial assignment is a full
% assignment is not feasible. For a partial assignment, there are some
% zero elements in the returning assignment vector, which indicate
% un-assigned tasks. The cost returned only contains the cost of partially
% assigned tasks.

% This is vectorized implementation of the algorithm. It is the fastest
% among all Matlab implementations of the algorithm.

% Examples
% Example 1: a 5 x 5 example
%{
[assignment,cost] = munkres(magic(5));
disp(assignment); % 3 2 1 5 4
disp(cost); %15
%}
% Example 2: 400 x 400 random data
%{
n=400;
A=rand(n);
tic
[a,b]=munkres(A);
toc % about 2 seconds 
%}
% Example 3: rectangular assignment with inf costs
%{
A=rand(10,7);
A(A>0.7)=Inf;
[a,b]=munkres(A);
%}
% Example 4: an example of partial assignment
%{
A = [1 3 Inf; Inf Inf 5; Inf Inf 0.5]; 
[a,b]=munkres(A)
%}
% a = [1 0 3]
% b = 1.5
% Reference:
% "Munkres' Assignment Algorithm, Modified for Rectangular Matrices", 
% http://csclab.murraystate.edu/bob.pilgrim/445/munkres.html

% version 2.3 by Yi Cao at Cranfield University on 11th September 2011

assignment = zeros(1,size(costMat,1));
cost = 0;

validMat = costMat == costMat & costMat < Inf;
bigM = 10^(ceil(log10(sum(costMat(validMat))))+1);
costMat(~validMat) = bigM;

% costMat(costMat~=costMat)=Inf;
% validMat = costMat<Inf;
validCol = any(validMat,1);
validRow = any(validMat,2);

nRows = sum(validRow);
nCols = sum(validCol);
n = max(nRows,nCols);
if ~n
 return
end

maxv=10*max(costMat(validMat));

dMat = zeros(n) + maxv;
dMat(1:nRows,1:nCols) = costMat(validRow,validCol);

%*************************************************
% Munkres' Assignment Algorithm starts here
%*************************************************

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 1: Subtract the row minimum from each row.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
minR = min(dMat,[],2);
minC = min(bsxfun(@minus, dMat, minR));

%************************************************************************** 
% STEP 2: Find a zero of dMat. If there are no starred zeros in its
% column or row start the zero. Repeat for each zero
%**************************************************************************
zP = dMat == bsxfun(@plus, minC, minR);

starZ = zeros(n,1);
while any(zP(:))
 [r,c]=find(zP,1);
 starZ(r)=c;
 zP(r,:)=false;
 zP(:,c)=false;
end

while 1
%**************************************************************************
% STEP 3: Cover each column with a starred zero. If all the columns are
% covered then the matching is maximum
%**************************************************************************
 if all(starZ>0)
 break
 end
 coverColumn = false(1,n);
 coverColumn(starZ(starZ>0))=true;
 coverRow = false(n,1);
 primeZ = zeros(n,1);
 [rIdx, cIdx] = find(dMat(~coverRow,~coverColumn)==bsxfun(@plus,minR(~coverRow),minC(~coverColumn)));
 while 1
 %**************************************************************************
 % STEP 4: Find a noncovered zero and prime it. If there is no starred
 % zero in the row containing this primed zero, Go to Step 5. 
 % Otherwise, cover this row and uncover the column containing 
 % the starred zero. Continue in this manner until there are no 
 % uncovered zeros left. Save the smallest uncovered value and 
 % Go to Step 6.
 %**************************************************************************
 cR = find(~coverRow);
 cC = find(~coverColumn);
 rIdx = cR(rIdx);
 cIdx = cC(cIdx);
 Step = 6;
 while ~isempty(cIdx)
 uZr = rIdx(1);
 uZc = cIdx(1);
 primeZ(uZr) = uZc;
 stz = starZ(uZr);
 if ~stz
 Step = 5;
 break;
 end
 coverRow(uZr) = true;
 coverColumn(stz) = false;
 z = rIdx==uZr;
 rIdx(z) = [];
 cIdx(z) = [];
 cR = find(~coverRow);
 z = dMat(~coverRow,stz) == minR(~coverRow) + minC(stz);
 rIdx = [rIdx(:);cR(z)];
 cIdx = [cIdx(:);stz(ones(sum(z),1))];
 end
 if Step == 6
 % *************************************************************************
 % STEP 6: Add the minimum uncovered value to every element of each covered
 % row, and subtract it from every element of each uncovered column.
 % Return to Step 4 without altering any stars, primes, or covered lines.
 %**************************************************************************
 [minval,rIdx,cIdx]=outerplus(dMat(~coverRow,~coverColumn),minR(~coverRow),minC(~coverColumn)); 
 minC(~coverColumn) = minC(~coverColumn) + minval;
 minR(coverRow) = minR(coverRow) - minval;
 else
 break
 end
 end
 %**************************************************************************
 % STEP 5:
 % Construct a series of alternating primed and starred zeros as
 % follows:
 % Let Z0 represent the uncovered primed zero found in Step 4.
 % Let Z1 denote the starred zero in the column of Z0 (if any).
 % Let Z2 denote the primed zero in the row of Z1 (there will always
 % be one). Continue until the series terminates at a primed zero
 % that has no starred zero in its column. Unstar each starred
 % zero of the series, star each primed zero of the series, erase
 % all primes and uncover every line in the matrix. Return to Step 3.
 %**************************************************************************
 rowZ1 = find(starZ==uZc);
 starZ(uZr)=uZc;
 while rowZ1>0
 starZ(rowZ1)=0;
 uZc = primeZ(rowZ1);
 uZr = rowZ1;
 rowZ1 = find(starZ==uZc);
 starZ(uZr)=uZc;
 end
end

% Cost of assignment
rowIdx = find(validRow);
colIdx = find(validCol);
starZ = starZ(1:nRows);
vIdx = starZ <= nCols;
assignment(rowIdx(vIdx)) = colIdx(starZ(vIdx));
pass = assignment(assignment>0);
pass(~diag(validMat(assignment>0,pass))) = 0;
assignment(assignment>0) = pass;
cost = trace(costMat(assignment>0,assignment(assignment>0)));
end

function [minval,rIdx,cIdx]=outerplus(M,x,y)

ny=size(M,2);
minval=inf;
for c=1:ny
 M(:,c)=M(:,c)-(x+y(c));
 minval = min(minval,min(M(:,c)));
end
[rIdx,cIdx]=find(M==minval);
end

%% Water-filling
function [palloc_matrix, allocPercentage] = water_filling1(loss, P)
% loss, Kx1 vector, i.e., L
% P, Total power to allocate
% A, Diagonal matrix, i.e., weight alpha
% palloc_matrix, Diagonal matrix, power allocation result, trace equals P

	K = length(loss); % Number of users

 w = log(2) + zeros(1, K);
 
% 	w = diag(A); % width, step width
	h = loss./w; % height, step height
% h = loss;
	
 allo_set = 1:K; % Initialize index set of users to water-fill
 level = (P+sum(loss(allo_set>0)))/sum(w(allo_set>0)); % "Virtual" water level
 [h_hat, k_hat] = max(h(allo_set>0));
 
 while h_hat>=level
 
 allo_set(k_hat) = -1;
 level = (P+sum(loss(allo_set>0)))/sum(w(allo_set>0)); % "Virtual" water level
 [h_hat, k_hat] = max(h(allo_set>0));
 
 end
 
 palloc_matrix = zeros(K);
 for k = 1:K
 if allo_set(k)>0
 palloc_matrix(k, k) = (level - h(k))*w(k);
 end
 end

 % I want to get the ratio
 allocPercentage = zeros(1, K);
 for k = 1 : K
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end
 
end
function [palloc_matrix, allocPercentage] = water_filling2(loss, P)
% loss, Kx1 vector, i.e., L
% P, Total power to allocate
% A, Diagonal matrix, i.e., weight alpha
% palloc_matrix, Diagonal matrix, power allocation result, trace equals P
	K = length(loss);
 
	w = 1/log(2) + zeros(1, K); % Step width
	h = loss./w; % Step height
	
	[h_sorted, h_idx] = sort(h); % Sort in ascending order by step height
	w_sorted = w(h_idx);
 
 % Linear search, determine the last step that needs water-filling from back to front
 for i = K:-1:1
 
 w_tmp = sum(w_sorted(1:i-1)); % Sum of widths of all steps before the current step
 h_tmp = h_sorted(i); % Height of the current step
 
 % If there is still water remaining after filling steps before the current step to the same height
 if w_tmp*h_tmp-sum(h_sorted(1:i-1).*w_sorted(1:i-1))<P
 idx = i;
 break;
 end
 
 end
 
 w_filled = sum(w_sorted(1:idx)); % Total width of all steps that need water-filling
 h_filled = (P+sum(h_sorted(1:idx).*w_sorted(1:idx)))/w_filled; % Final water level
	
	p_allocate = zeros(1, K);
 p_allocate(1:idx) = w_sorted(1:idx).*(h_filled-h_sorted(1:idx));
	
 % Restore original order
 [~, back_idx] = sort(h_idx);
 p_allocate = p_allocate(back_idx);
 
 palloc_matrix = diag(p_allocate);

 % I want to get the ratio
 allocPercentage = zeros(1, K);
 for k = 1 : K
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end
 
end
function [palloc_matrix, allocPercentage] = water_filling3(loss, P)
 %% Initialization
 N= length(loss) ; % Number of channels
 [noise_sorted,index]=sort(loss); 
 for p=length(noise_sorted):-1:1 
 T_P=(P+sum(noise_sorted(1:p)))/p; 
 Input_Power=T_P-noise_sorted; 
 Pt=Input_Power(1:p); 
 if(Pt(:)>=0)
 break 
 end 
 end 
 power_alloc=zeros(1,N); 
 power_alloc(index(1:p))=Pt; % Allocated power
 
 palloc_matrix = diag(power_alloc);

 % I want to get the ratio
 allocPercentage = zeros(1, N);
 for k = 1 : N
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end

end
function PosInDescartes = LngLat2Descartes(CurPos, h)
 tmpPhi = CurPos(1) * pi / 180;
 if tmpPhi < 0
 tmpPhi = tmpPhi + 2*pi;
 end
 tmpTheta = (90 - CurPos(2)) * pi / 180;
 R = 6371.393e3; % Earth radius
 tmpX = (R+h) * sin(tmpTheta) * cos(tmpPhi);
 tmpY = (R+h) * sin(tmpTheta) * sin(tmpPhi);
 tmpZ = (R+h) * cos(tmpTheta); 
 PosInDescartes = [tmpX, tmpY, tmpZ]; 
end
 
 palloc_matrix = zeros(K);
 for k = 1:K
 if allo_set(k)>0
 palloc_matrix(k, k) = (level - h(k))*w(k);
 end
 end

 allocPercentage = zeros(1, K);
 for k = 1 : K
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end
 
end

function [palloc_matrix, allocPercentage] = water_filling2(loss, P)
% loss, Kx1vector
% P,
% A,
% palloc

	K = length(loss);
 
	w = 1/log(2) + zeros(1, K); % 
	h = loss./w; % altitude
	
	[h_sorted, h_idx] = sort(h); % based onaltitudeSort
	w_sorted = w(h_idx);

 for i = K:-1:1
 
 w_tmp = sum(w_sorted(1:i-1)); % Whenall and
 h_tmp = h_sorted(i); % When altitude

 if w_tmp*h_tmp-sum(h_sorted(1:i-1).*w_sorted(1:i-1))<P
 idx = i;
 break;
 end
 
 end
 
 w_filled = sum(w_sorted(1:idx)); % need all total
 h_filled = (P+sum(h_sorted(1:idx).*w_sorted(1:idx)))/w_filled; % 
	
	p_allocate = zeros(1, K);
 p_allocate(1:idx) = w_sorted(1:idx).*(h_filled-h_sorted(1:idx));

 [~, back_idx] = sort(h_idx);
 p_allocate = p_allocate(back_idx);
 
 palloc_matrix = diag(p_allocate);

 allocPercentage = zeros(1, K);
 for k = 1 : K
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end
 
end

function [palloc_matrix, allocPercentage] = water_filling3(loss, P)
 %% Initialize
 N= length(loss) ; %channel
 [noise_sorted,index]=sort(loss); 
 for p=length(noise_sorted):-1:1 
 T_P=(P+sum(noise_sorted(1:p)))/p; 
 Input_Power=T_P-noise_sorted; 
 Pt=Input_Power(1:p); 
 if(Pt(:)>=0)
 break 
 end 
 end 
 power_alloc=zeros(1,N); 
 power_alloc(index(1:p))=Pt; % power
 
 palloc_matrix = diag(power_alloc);

 allocPercentage = zeros(1, N);
 for k = 1 : N
 allocPercentage(k) = palloc_matrix(k, k) / P;
 end

end


function PosInDescartes = LngLat2Descartes(CurPos, h)
 tmpPhi = CurPos(1) * pi / 180;
 if tmpPhi < 0
 tmpPhi = tmpPhi + 2*pi;
 end
 tmpTheta = (90 - CurPos(2)) * pi / 180;
 R = 6371.393e3; % 
 tmpX = (R+h) * sin(tmpTheta) * cos(tmpPhi);
 tmpY = (R+h) * sin(tmpTheta) * sin(tmpPhi);
 tmpZ = (R+h) * cos(tmpTheta); 
 PosInDescartes = [tmpX, tmpY, tmpZ]; 
end


%% Calculate SINR and SNR values for a beam position
function [SINR, SNR] = CaculateR(SatIdx, ScheIdx, Gene, i, BeamPoint, interface)
 % Interference received by the i-th beam position on the gene
 Pt = (10.^((interface.SatObj(SatIdx).Pt_dBm_serv)./10))./1e3./interface.numOfServbeam; % W
 UsrIdx = interface.tmpSat(SatIdx).beamfoot(ScheIdx, i).usrs;
 T_noise = interface.UsrsObj(UsrIdx(1)).T_noise;
 F_noise_dB = interface.UsrsObj(UsrIdx(1)).F_noise;
 F_noise = 10.^(F_noise_dB./10);
 N0_noise = 1.380649e-23*(T_noise + (F_noise-1)*300);

% BW
% T
% k
% N0 = k*T*BW;%noise
 Bandwidth = interface.BandOfLink*1e6;
 ExpressedGene = find(Gene == 1);
 % Calculate pointing angle of current beam position center 
 usrCurPos = interface.tmpSat(SatIdx).beamfoot(ScheIdx, i).position; % Current user coordinates 
 satCurPos = interface.SatObj(SatIdx).position; % Current satellite sub-satellite point coordinates
 satCurnextPos = interface.SatObj(SatIdx).nextpos; % Next step coordinates of current satellite sub-satellite point
 [UsrTheta, UsrPhi] = tools.getPointAngleOfUsr(satCurPos, satCurnextPos, usrCurPos, interface.height);% Calculate azimuth and elevation angles
 % Calculate user receiving gain
 G_usrDown = antenna.getUsrAntennaServG(0, interface.freqOfDownLink, false);
 % Calculate distance from current satellite to current user
 usrPosInDescartes = LngLat2Descartes(usrCurPos, 0);
 satPosInDescartes = LngLat2Descartes(satCurPos, interface.height);
 distance = sqrt((satPosInDescartes(1)-usrPosInDescartes(1)).^2 + ...
 (satPosInDescartes(2)-usrPosInDescartes(2)).^2 + ...
 (satPosInDescartes(3)-usrPosInDescartes(3)).^2); 
 InterfInSatDown = 0;
 lambdaDown = 3e8/interface.freqOfDownLink;
 for bfIdx = 1 : length(ExpressedGene)
 if bfIdx ~= find(ExpressedGene == i)
 poiBeta = BeamPoint(bfIdx,1);
 poiAlpha = BeamPoint(bfIdx,2);
 AgleOfInv = [UsrTheta, UsrPhi];
 AgleOfPoi = [poiAlpha, poiBeta];
 G_sat_interfDown = antenna.getSatAntennaServG(AgleOfInv, AgleOfPoi, interface.freqOfDownLink);
 InterfInSatDown = InterfInSatDown + ...
 Pt * G_sat_interfDown * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 end
 end
 %%%%%%%%%%%%%%%%%%%%%
 bfIdx = find(ExpressedGene == i);
 poiBeta = BeamPoint(bfIdx,1);
 poiAlpha = BeamPoint(bfIdx,2);
 AgleOfInv = [UsrTheta, UsrPhi];
 AgleOfPoi = [poiAlpha, poiBeta];

 G_sat_down = antenna.getSatAntennaServG(AgleOfInv, AgleOfPoi, interface.freqOfDownLink);
 %%%%%%%%%%%%%%%%%%%%%
 Carrier_down = Pt * G_sat_down * G_usrDown * (lambdaDown.^2) / (((4*pi).^2)*(distance.^2));
 SINR = Carrier_down./(InterfInSatDown + Bandwidth*N0_noise);
 SNR = Carrier_down./(Bandwidth*N0_noise);
end