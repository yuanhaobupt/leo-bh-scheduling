function judgeEdgeUsr(self)
%JUDGESATOFEDGEUSR New edge user service competition
    % When sche==1
    % Find sub-satellite users for each satellite appearing in userLine
    % Traverse these users to find edge users
    % When sche~=1
    % Find newly added users compared to previous sche, perform service competition for them
    % Calculate user density for all edge users
    NumOfSche = self.interface.ScheInShot;
    OrderOfSat = self.interface.OrderOfServSatCur;
    NumOfSat = length(OrderOfSat);
    OrderOfSelectedUsrs = self.interface.OrderOfSelectedUsrs;
    egdeuser = [];
    for sche = 1 : NumOfSche
        UserLineCurrent = self.interface.usersInLine(sche,:);
        UserLineCurrent = UserLineCurrent(UserLineCurrent~=0);
%         UserLineIDXCurrent = zeros(1, length(UserLineCurrent));
%         for idx_ul = 1 : length(UserLineCurrent)
%             UserLineIDXCurrent(idx_ul) = find(OrderOfSelectedUsrs == UserLineCurrent(idx_ul));
%         end
%         NumOfUserCurrent = length(UserLineIDXCurrent);
        if sche == 1
            tmp_egdeuser = [];
            for idxOfSat = 1 : NumOfSat
                userSeqOfSat = self.interface.SatObj(idxOfSat).servUsr(sche, :);
                userSeqOfSat = userSeqOfSat(userSeqOfSat~=0);
                activateUsrs = intersect(userSeqOfSat, UserLineCurrent);
                activateUsrs_IDX = zeros(1, length(activateUsrs));
                for idx_a = 1 : length(activateUsrs)
                    activateUsrs_IDX(idx_a) = find(OrderOfSelectedUsrs == activateUsrs(idx_a));
                end
                egdeSigSeq = self.interface.SatObj(idxOfSat).egdeSigSeq;
                
                for idxOfUsr = 1 : length(activateUsrs_IDX)
                    if ~isempty(intersect(self.interface.UsrsObj(activateUsrs_IDX(idxOfUsr)).homeSig,egdeSigSeq))
                        tmp_egdeuser = [tmp_egdeuser activateUsrs_IDX(idxOfUsr)];
                    end
                end
            end
            egdeuser(sche, 1:length(tmp_egdeuser)) = tmp_egdeuser;
        else
            tmp_egdeuser = egdeuser(sche-1, egdeuser(sche-1,:)~=0);
            new_egdeuser = [];
            for idxOfSat = 1 : NumOfSat
                new_userSeqOfSat = self.interface.SatObj(idxOfSat).servUsr(sche, :);
                new_userSeqOfSat = new_userSeqOfSat(new_userSeqOfSat~=0);
                new_activateUsrs = setdiff(new_userSeqOfSat, userSeqOfSat);
                new_activateUsrs_IDX = zeros(1, length(new_activateUsrs));
                for idx_na = 1 : length(new_activateUsrs)
                    new_activateUsrs_IDX(idx_na) = find(OrderOfSelectedUsrs == new_activateUsrs(idx_na));
                end

%                 activateUsrs = intersect(userSeqOfSat, UserLineCurrent);
                egdeSigSeq = self.interface.SatObj(idxOfSat).egdeSigSeq;
                
                for idxOfUsr = 1 : length(new_activateUsrs_IDX)
                    if ~isempty(intersect(self.interface.UsrsObj(new_activateUsrs_IDX(idxOfUsr)).homeSig,egdeSigSeq))
                        tmp_egdeuser = [tmp_egdeuser new_activateUsrs_IDX(idxOfUsr)];
                        new_egdeuser = [new_egdeuser new_activateUsrs_IDX(idxOfUsr)];
                    end
                end
            end
                % Determine serving satellite for newly accessed users
            for idxOfnewUsr = 1 : length(new_egdeuser)
                homeSig = self.interface.UsrsObj(new_egdeuser(idxOfnewUsr)).homeSig;
                satLine = find(self.interface.SigBeamMapptoSat(homeSig, :)==1);
                DenseOfUsr = [];
                for idxOfsat_tmp = 1 : length(satLine)
                    SigOrderInSat = find(self.interface.SatObj(satLine(idxOfsat_tmp)).IdxOfsigbeam == homeSig);
                    if ~isempty(SigOrderInSat)
                        DenseOfUsr = [DenseOfUsr length(intersect(self.interface.SatObj(satLine(idxOfsat_tmp)).SignalBeamfoot(SigOrderInSat).usrs,UserLineCurrent))];
                    end
                end
                if ~isempty(DenseOfUsr)
                    selectedSatIdx = satLine(find(DenseOfUsr==min(DenseOfUsr),1));
                    servUsr = self.interface.SatObj(selectedSatIdx).servUsr(sche, :);
                    servUsr = servUsr(servUsr~=0);
                    servUsr_IDX = zeros(1, length(servUsr));
                    for idx_si = 1 : length(servUsr_IDX)
                        servUsr_IDX(idx_si) = find(OrderOfSelectedUsrs == servUsr(idx_si));
                    end
                    if isempty(find(servUsr_IDX == new_egdeuser(idxOfnewUsr), 1))
                        servUsr_IDX = [servUsr_IDX new_egdeuser(idxOfnewUsr)];
                        servUsr_IDX = sort(servUsr_IDX,'ascend');
                        self.interface.SatObj(selectedSatIdx).servUsr(sche, 1:length(servUsr_IDX)) = sort(OrderOfSelectedUsrs(servUsr_IDX),'ascend');
                        self.interface.SatObj(selectedSatIdx).numOfusrs(sche) = length(servUsr_IDX);
                        tmpSatIdx = find(self.interface.OrderOfServSatCur==self.interface.UsrsObj(new_egdeuser(idxOfnewUsr)).homeSat);
                        tmpServUsr = self.interface.SatObj(tmpSatIdx).servUsr(sche, :);
                        tmpServUsr = tmpServUsr(tmpServUsr~=0);
                        tmpServUsr_IDX = zeros(1, length(tmpServUsr));
                        for idx_tsi = 1 : length(tmpServUsr_IDX)
                            tmpServUsr_IDX(idx_tsi) = find(OrderOfSelectedUsrs == tmpServUsr(idx_tsi));
                        end
                        tmpServUsr_IDX(tmpServUsr_IDX==new_egdeuser(idxOfnewUsr)) = [];
                        self.interface.SatObj(tmpSatIdx).servUsr(sche, :) = 0;
                        self.interface.SatObj(tmpSatIdx).servUsr(sche, 1:length(tmpServUsr_IDX)) = sort(OrderOfSelectedUsrs(tmpServUsr_IDX),'ascend');
                        self.interface.SatObj(tmpSatIdx).numOfusrs(sche) = length(tmpServUsr_IDX);
                        self.interface.UsrsObj(new_egdeuser(idxOfnewUsr)).homeSat = self.interface.OrderOfServSatCur(selectedSatIdx);
                    end
                end
            end
            egdeuser(sche, 1:length(tmp_egdeuser)) = tmp_egdeuser;
        end
    end

    self.interface.edgeUserLine = egdeuser;

end


