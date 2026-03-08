% Calculate visible satellite service coverage in self.DiscrArea and determine user assignments
%%
function calcuSatServArea(self, OrderOfVisibleSat, IdxOfStep, MC_idx)
    ifDebug = self.ifDebug;

    numOfusrs = self.numOfUsrs_all;% Get all users in large area

    % Generate VisibleSat_s, first two columns are visible satellite coordinates, third column is its ID
    NumOfVisibleSat = length(OrderOfVisibleSat);
    tempVisibleSat_s = zeros(NumOfVisibleSat,3);    
    tempVisibleSat_s(:,1:2) = self.VisibleSat(OrderOfVisibleSat, IdxOfStep, :);
    tempVisibleSat_s(:,3) = OrderOfVisibleSat;

    % Generate SatServCur
    tempOfNum = zeros(NumOfVisibleSat, 1); % Count number of small triangles under each satellite
    tempSeqDiscrArea = self.SeqDiscrArea;% Center point coordinates of discrete small triangles
    tempSatServCur = zeros(length(self.SeqDiscrArea(:,1)), 3);% Store discrete small triangle assigned satellite
    tempSatServCur(:,1:2) = self.SeqDiscrArea;% First two columns are coordinates, third column is satellite ID
   
    [rawNum, colNum, ~] = size(self.DiscrArea);% Number of rows and columns of discrete triangles
    hOfDiscr = tools.LatLngCoordi2Length([0 0], [0 1], self.rOfearth)/self.Config.factorOfDiscr;% Height of each triangle
    interval = ceil(2*tools.getEarthLength(self.Config.rangeOfBeam(2)*2, self.Config.height)/hOfDiscr/8);% Investigation interval

    ServSatOfDiscrAreaCur = zeros(rawNum, colNum);% Assigned satellite for each small triangle

    for i = 1 : rawNum% Traverse rows
        last_q = 0;% If q == last_q means not found?
        for j = 1 : interval : colNum% Traverse columns at intervals
            seq = simSatSysClass.tools.ij2Seq(i, j, rawNum, colNum);% Calculate current ij sequence number in discrete triangles
            q = findShortest(...
                tempSeqDiscrArea(seq, :),...
                tempVisibleSat_s(:, 1:2)...
                );% Find nearest satellite
            if j ~= 1% Supplementary calculation?
                if q ~= last_q
                    for k = j-interval+1 : j
                        seq = simSatSysClass.tools.ij2Seq(i, k, rawNum, colNum);
                        q = findShortest(...
                            tempSeqDiscrArea(seq, :),...
                            tempVisibleSat_s(:, 1:2)...
                            );% This q index is in visible satellite matrix, so use third column to get its ID in 1800
                        tempSatServCur(seq, 3) = tempVisibleSat_s(q, 3);% Store satellite ID in third column
                        tempOfNum(q) = tempOfNum(q) + 1; 
                    end
                    last_q = q;
                else
                    for k = j-interval+1 : j
                        seq = simSatSysClass.tools.ij2Seq(i, k, rawNum, colNum);
                        tempSatServCur(seq, 3) = tempVisibleSat_s(q, 3);
                        tempOfNum(q) = tempOfNum(q) + 1; 
                    end                    
                end              
            else
                tempSatServCur(seq, 3) = tempVisibleSat_s(q, 3);
                tempOfNum(q) = tempOfNum(q) + 1;
                last_q = q;
            end
            if colNum - j < interval
                for k = j+1 : colNum
                    seq = simSatSysClass.tools.ij2Seq(i, k, rawNum, colNum);
                    q = findShortest(...
                        tempSeqDiscrArea(seq, :),...
                        tempVisibleSat_s(:, 1:2)...
                        );                
                    tempSatServCur(seq, 3) = tempVisibleSat_s(q, 3);
                    tempOfNum(q) = tempOfNum(q) + 1;
                end
            end
        end 
    end
    for j = 1:colNum
        for i = 1:rawNum
            ServSatOfDiscrAreaCur(i, j) = tempSatServCur((j-1)*rawNum+i, 3);
        end
    end
    self.ServSatOfDiscrAreaCur = ServSatOfDiscrAreaCur;    
    if ifDebug == 1
        if self.Config.numOfMonteCarlo == 0
            fprintf('Snapshot %d visible satellite service coverage determination completed\n', IdxOfStep);        
        else
            fprintf('Monte Carlo %d Snapshot %d visible satellite service coverage determination completed\n', MC_idx, IdxOfStep);     
        end
    end  
    % Create service satellite object array
    tempNumOfVisibleSat = NumOfVisibleSat;
    for p = 1 : NumOfVisibleSat
        if tempOfNum(p) == 0
            tempNumOfVisibleSat = tempNumOfVisibleSat - 1;
        end
    end 
    NumOfServSat = tempNumOfVisibleSat;
    OrderOfServSat = OrderOfVisibleSat(tempOfNum ~= 0);
    self.OrderOfServSatCur = OrderOfServSat;
    self.SatObj = simSatSysClass.simSatellite.empty(NumOfServSat, 0); 
    for i = 1 : NumOfServSat
        self.SatObj(i).position = self.VisibleSat(OrderOfServSat(i), IdxOfStep, :);       
        self.SatObj(i).nextpos = self.SatPosition(OrderOfServSat(i),IdxOfStep+1,:);
        self.SatObj(i).order = OrderOfServSat(i);   
        self.SatObj(i).Pt_dBm_serv = self.Config.Pt_dBm_serv;
        self.SatObj(i).Pt_dBm_signal = self.Config.Pt_dBm_signal;
        self.SatObj(i).T_noise = self.Config.SAT_T_noise;
        self.SatObj(i).F_noise = self.Config.SAT_F_noise;
%         self.SatObj(i).ScheOfSig = self.Config.ScheOfSig;
%         self.SatObj(i).LightTimeOfSig = self.Config.LightTimeOfSig;
%         self.SatObj(i).SatAntenna = self.Communication.SatAntenna;
%         self.SatObj(i).freqOfServ = self.Communication.freqOfServ;
%         self.SatObj(i) = self.SatObj(i).initialAntenna();
    end
    % Tell satellite its service coverage
    for k = 1 : NumOfServSat
        self.SatObj(k).servTri = find(tempSatServCur(:,3) == OrderOfServSat(k));  
    end
    if ifDebug == 1
        if self.Config.numOfMonteCarlo == 0
            fprintf('Snapshot %d satellite object creation completed\n', IdxOfStep); 
        else
            fprintf('Monte Carlo %d Snapshot %d satellite object creation completed\n', MC_idx, IdxOfStep);
        end
    end 
    % Determine user assigned satellite Usr2SatCur
    self.Usr2SatCur = zeros(numOfusrs, 1+self.numOfMethods_BeamGenerate,self.scheInShot);
    tempS2U = zeros(NumOfServSat, numOfusrs);
    for g = 1 : numOfusrs
        self.Usr2SatCur(g, 1, :) = tempSatServCur(self.UsrsPosition(g,3), 3);
%         self.Usr2SatCur(g) = tempSatServCur(self.UsrsObj(g).ordOfDiscr, 3); 
%         self.UsrsObj(g).homeSat = self.Usr2SatCur(g, 1);
        tempS2U(OrderOfServSat==self.Usr2SatCur(g,1,1), g) = 1;
    end
    % Tell satellite which users it serves
    for k = 1 : NumOfServSat
        temp = tempS2U(k, :);
        self.SatObj(k).servUsr = find(temp == 1);
        self.SatObj(k).numOfusrs = length(self.SatObj(k).servUsr);
    end
    if ifDebug == 1
        if self.Config.numOfMonteCarlo == 0
            fprintf('Snapshot %d user-satellite mapping completed\n', IdxOfStep); 
        else
            fprintf('Monte Carlo %d Snapshot %d user-satellite mapping completed\n', MC_idx, IdxOfStep); 
        end 
    end
end

%% Find nearest point
function Satpos = findShortest(pos, SatposSet)
% pos Investigation coordinates
% SatposSet Satellite coordinate set
    R = 6371.393e3; % Earth radius

    lngA = pos(1);
    alpha1 = lngA * pi / 180;
    latA = pos(2);
    beta1 = latA * pi / 180;

    num = length(SatposSet(:,1));
    len = zeros(num,1);% Number of visible satellites
    for i = 1 : num
        lngB = SatposSet(i, 1);
        alpha2 = lngB * pi / 180;
        latB = SatposSet(i, 2);
        beta2 = latB * pi / 180;
        len(i) = R * acos(cos(pi/2-beta2)*cos(pi/2-beta1) + sin(pi/2-beta2)*sin(pi/2-beta1)*cos(alpha2-alpha1));
    end
    Satpos = find(len == min(len), 1);
end
