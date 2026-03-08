function getCurUsers(self, sche)
% Get users in sche scheduling period, generate sequence usersInLine of users to be served

if sche == 1
    % In the first scheduling period, randomly select users based on activation ratio
    self.interface.usersInLine = zeros(self.interface.ScheInShot, self.interface.NumOfSelectedUsrs);
    userNum = floor(self.interface.Config.activePercent * self.interface.NumOfSelectedUsrs);    
    userInLineIndex = randperm(self.interface.NumOfSelectedUsrs, userNum);% This index corresponds to userObj index!!!
    userInLine = self.interface.OrderOfSelectedUsrs(userInLineIndex);% Finally used the index in OrderOfSelectedUsrs
    self.interface.usersInLine(sche, 1:length(userInLine)) = userInLine;    

    % Re-obtain users for satobj
    user2sat = zeros(userNum,2);
    for i = 1 : userNum
        userId = userInLine(i);
        user2sat(i, 1) = userId;
        user2sat(i, 2) = self.interface.UsrsObj(find(self.interface.OrderOfSelectedUsrs == userId)).homeSat;
    end
    OrderOfServSatCur = self.interface.OrderOfServSatCur;
    for satId = 1 : length(OrderOfServSatCur)
        self.interface.SatObj(satId).servUsr = [];
        self.interface.SatObj(satId).numOfusrs = [];

        curSatId = OrderOfServSatCur(satId);
        temp = find(user2sat(:,2) == curSatId);
        self.interface.SatObj(satId).servUsr(sche,1:length(temp)) = sort(userInLine(temp));
        self.interface.SatObj(satId).numOfusrs(sche) = length(temp);
    end
    OrderOfServSatCur = self.interface.OrderOfServSatCur;
    for satId = 1 : length(OrderOfServSatCur)
        self.interface.SatObj(satId).servUsr = [];
        self.interface.SatObj(satId).numOfusrs = [];

        curSatId = OrderOfServSatCur(satId);
        temp = find(user2sat(:,2) == curSatId);
        self.interface.SatObj(satId).servUsr(sche,1:length(temp)) = sort(userInLine(temp));
        self.interface.SatObj(satId).numOfusrs(sche) = length(temp);
    end

else
    if self.interface.Config.numOfSigbeam == 2
        userInLine = self.interface.usersInLine(sche - 1, self.interface.usersInLine(sche - 1, : )~=0);
    
        % Non-first scheduling period: newly accessed users + users with completed transmission
        OrderOfServSatCur = self.interface.OrderOfServSatCur;
        for satId = 1 : length(OrderOfServSatCur)
            SignalBeamfoot = self.interface.SatObj(satId).SignalBeamfoot;
    
            % Current timeline
            curTime = self.interface.SlotInSche * (sche - 1);
        
            % Count if there are signaling beam footprints that have appeared three times at current timeline
            tb1 = tabulate(self.interface.SatObj(satId).TableOfSig(1,1:curTime));
            tb2 = tabulate(self.interface.SatObj(satId).TableOfSig(2,1:curTime));
            already3 = find(tb1(:,2) >= 3);
            temp = find(tb2(:,2) >= 3);
            already3 = [already3;temp];
        
            % Access new users from unselected users in these beam footprints
            newUsers = [];
            if ~isempty(already3)
                for i = 1 : length(already3)
                    curSig = already3(i,1);
                    userInThisSig = SignalBeamfoot(curSig).usrs;% This is the index in OrderOfSelectedUsrs
                    diff = setdiff(userInThisSig ,userInLine);% Set difference of matrix A minus matrix B
                    diff = intersect(diff, self.interface.OrderOfSelectedUsrs);
                    if ~isempty(diff)
                        randChoose = randperm(length(diff),1);
                        newUsers = [newUsers diff(randChoose)];
                    end
                end
            end
            userInLine = [userInLine newUsers];
        end
     
        self.interface.usersInLine(sche, 1 : length(userInLine)) = userInLine;
     
        % Re-obtain users for satobj
        userNum = length(userInLine);
        user2sat = zeros(userNum,2);
        for i = 1 : userNum
            userId = userInLine(i);
            user2sat(i, 1) = userId;
    %         if isempty(find(self.interface.OrderOfSelectedUsrs == userId))
    %             fprintf('aaa');
    %         end
            user2sat(i, 2) = self.interface.UsrsObj(find(self.interface.OrderOfSelectedUsrs == userId)).homeSat;
        end
        OrderOfServSatCur = self.interface.OrderOfServSatCur;
        for satId = 1 : length(OrderOfServSatCur)
            curSatId = OrderOfServSatCur(satId);
            temp = find(user2sat(:,2) == curSatId);
            self.interface.SatObj(satId).servUsr(sche,1:length(temp)) = sort(userInLine(temp)); % servUsr stores OrderOfSelectedUsrs index
            self.interface.SatObj(satId).numOfusrs(sche) = length(temp);
        end
    elseif self.interface.Config.numOfSigbeam == 0
        % No new users, keep the same
        userInLine = self.interface.usersInLine(sche - 1, :);
        self.interface.usersInLine(sche, 1 : length(userInLine)) = userInLine;
    
        % Re-obtain users for satobj
        OrderOfServSatCur = self.interface.OrderOfServSatCur;
        for satId = 1 : length(OrderOfServSatCur)
            lastServ = self.interface.SatObj(satId).servUsr(sche - 1,:);
            self.interface.SatObj(satId).servUsr(sche,1:length(lastServ)) = lastServ;
            self.interface.SatObj(satId).numOfusrs(sche) = self.interface.SatObj(satId).numOfusrs(sche - 1);
        end

    end
        OrderOfServSatCur = self.interface.OrderOfServSatCur;
        for satId = 1 : length(OrderOfServSatCur)
            curSatId = OrderOfServSatCur(satId);
            temp = find(user2sat(:,2) == curSatId);
            self.interface.SatObj(satId).servUsr(sche,1:length(temp)) = sort(userInLine(temp)); % servUsr stores OrderOfSelectedUsrs index
            self.interface.SatObj(satId).numOfusrs(sche) = length(temp);
        end
    elseif self.interface.Config.numOfSigbeam == 0
        % No new users, keep the same
        userInLine = self.interface.usersInLine(sche - 1, :);
        self.interface.usersInLine(sche, 1 : length(userInLine)) = userInLine;
    
        OrderOfServSatCur = self.interface.OrderOfServSatCur;
        for satId = 1 : length(OrderOfServSatCur)
            lastServ = self.interface.SatObj(satId).servUsr(sche - 1,:);
            self.interface.SatObj(satId).servUsr(sche,1:length(lastServ)) = lastServ;
            self.interface.SatObj(satId).numOfusrs(sche) = self.interface.SatObj(satId).numOfusrs(sche - 1);
        end

    end

end

end