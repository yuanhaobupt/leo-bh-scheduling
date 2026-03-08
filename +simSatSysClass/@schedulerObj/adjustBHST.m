function adjustBHST(self)
%ADJUSTBHST Summary of this function
%   Detailed description here
    % Traverse scheduling periods
        % Traverse satellites
            % Traverse neighbor satellites
                % Find edge users with neighbor satellites
                % Determine service beam footprint of edge users
                    % Compare coverage overlap of edge users between two satellites, the one with lower user density makes compromise
                    % Traverse time slots, check if edge users are simultaneously lit
                        % If yes, satellite with lower density adjusts BHST, in current scheduling period, find 1st time slot without edge users scheduled for swap
                            % If no time slot without edge users exists, find time slot with fewest scheduled edge users for swap
    method_type = 1; %                        
    for scheIdx = 1 : self.interface.ScheInShot
        adjaMatrix = self.interface.NeighborAdjaMatrix;
        for satIdx  = 1 : length(self.interface.OrderOfServSatCur)
            NeighborSat = self.interface.SatObj(satIdx).Neighbor(1,:);
            NeighborSat = NeighborSat(NeighborSat~=0);
            BHST = self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+1):(scheIdx*self.interface.SlotInSche));
            for neighbor = 1 : length(NeighborSat)
                neighbor_satIdx = find(self.interface.OrderOfServSatCur==NeighborSat(neighbor));
                if adjaMatrix(satIdx, neighbor_satIdx) == 0
                    break
                end
                adjaMatrix(satIdx, neighbor_satIdx) = 0;
                adjaMatrix(neighbor_satIdx, satIdx) = 0;
                egdeSigSeq = intersect(self.interface.SatObj(satIdx).egdeSigSeq,self.interface.SatObj(neighbor_satIdx).egdeSigSeq);
                BHST_neighbor = self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+1):(scheIdx*self.interface.SlotInSche));
                for sigIdx = 1 : length(egdeSigSeq)
                    edgeUsr_sat = [];
                    edgeUsr_sat_servBeamf = [];
                    edgeUsr_neighbor = [];
                    edgeUsr_neighbor_servBeamf = [];
                    sigBidx = find(self.interface.SatObj(satIdx).IdxOfsigbeam==egdeSigSeq(sigIdx));
                    tmpUsrs_1 = self.interface.SatObj(satIdx).SignalBeamfoot(sigBidx).usrs;
                    tmpUsrs_2 = self.interface.SatObj(satIdx).servUsr(scheIdx,:);
                    tmpUsrs_2 = tmpUsrs_2(tmpUsrs_2~=0);
                    selectedUsr = intersect(tmpUsrs_1, tmpUsrs_2);
                    edgeUsr_sat = [edgeUsr_sat selectedUsr];
                    % Judge
                    if isempty(edgeUsr_sat)
                        continue
                    end

                    for servBIdx = 1 : self.interface.tmpSat(satIdx).NumOfBeamFoot(scheIdx)
                        flag = 0;
                        for idx_selectedUsr = 1 : length(selectedUsr)
                            if find(self.interface.tmpSat(satIdx).beamfoot(scheIdx,servBIdx).usrs==selectedUsr(idx_selectedUsr))
                                flag = 1;
                            end
                        end
                        if flag == 1
                            edgeUsr_sat_servBeamf = [edgeUsr_sat_servBeamf servBIdx];
                        end
                    end

                    sigBidx_tmp = find(self.interface.SatObj(neighbor_satIdx).IdxOfsigbeam==egdeSigSeq(sigIdx));
                    tmpUsrs_3 = self.interface.SatObj(neighbor_satIdx).SignalBeamfoot(sigBidx_tmp).usrs;
                    tmpUsrs_4 = self.interface.SatObj(neighbor_satIdx).servUsr(scheIdx,:);
                    tmpUsrs_4 = tmpUsrs_4(tmpUsrs_4~=0);
                    selectedUsr_neighbor = intersect(tmpUsrs_3, tmpUsrs_4);
                    edgeUsr_neighbor = [edgeUsr_neighbor intersect(tmpUsrs_3, tmpUsrs_4)];
                    % Judge
                    if isempty(edgeUsr_neighbor)
                        continue
                    end

                    for servBIdx = 1 : self.interface.tmpSat(neighbor_satIdx).NumOfBeamFoot(scheIdx)
                        flag = 0;
                        for idx_selectedUsr_neighbor = 1 : length(selectedUsr_neighbor)
                            if find(self.interface.tmpSat(neighbor_satIdx).beamfoot(scheIdx,servBIdx).usrs==selectedUsr_neighbor(idx_selectedUsr_neighbor))
                                flag = 1;
                            end
                        end
                        if flag == 1
                            edgeUsr_neighbor_servBeamf = [edgeUsr_neighbor_servBeamf servBIdx];
                        end
                    end
                    if (length(edgeUsr_sat)~=length(edgeUsr_sat_servBeamf)) || (length(edgeUsr_neighbor)~=length(edgeUsr_neighbor_servBeamf)) 
                        error('Error finding service beam footprint for edge users!')
                    end
                    

                    if method_type == 1    % Edge beam footprint user density
                        if length(edgeUsr_sat) > length(edgeUsr_neighbor)
                            axis = zeros(self.interface.SlotInSche,2);
                            for slotIdx = 1 : self.interface.SlotInSche
                                tmp1 = intersect(BHST(:, slotIdx), edgeUsr_sat_servBeamf);
                                if ~isempty(tmp1)
                                    axis(slotIdx,1) = 1;
                                end
                                tmp2 = intersect(BHST_neighbor(:, slotIdx), edgeUsr_neighbor_servBeamf);
                                if ~isempty(tmp2)
                                    axis(slotIdx,2) = 1;
                                end
                            end
                            for slotIdx = 1 : self.interface.SlotInSche
                                if (axis(slotIdx,1)==1) && (axis(slotIdx,2)==1)
                                    tmpOrder = find(axis(:,1)==0);
                                    tmpOrder_2 = find(axis(tmpOrder,2)==0);
                                    if isempty(tmpOrder_2)
                                        continue
                                    end
                                    selectslot = tmpOrder(tmpOrder_2(1));                                    
                                    if ~isempty(selectslot)
                                        tmp = self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+slotIdx));
                                        self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+slotIdx)) = ...
                                            self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+selectslot));
                                        self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+selectslot))= ...
                                            tmp;
                                        tmp = axis(slotIdx,2);
                                        axis(slotIdx,2) = axis(selectslot,2);
                                        axis(selectslot,2) = tmp;
                                    end
                                end
                            end
                        else
                            axis = zeros(self.interface.SlotInSche,2);
                            for slotIdx = 1 : self.interface.SlotInSche
                                tmp1 = intersect(BHST(:, slotIdx), edgeUsr_sat_servBeamf);
                                if ~isempty(tmp1)
                                    axis(slotIdx,1) = 1;
                                end
                                tmp2 = intersect(BHST_neighbor(:, slotIdx), edgeUsr_neighbor_servBeamf);
                                if ~isempty(tmp2)
                                    axis(slotIdx,2) = 1;
                                end
                            end
                            for slotIdx = 1 : self.interface.SlotInSche
                                if (axis(slotIdx,1)==1) && (axis(slotIdx,2)==1)
                                    tmpOrder = find(axis(:,1)==0);
                                    tmpOrder_2 = find(axis(tmpOrder,2)==0);
                                    if isempty(tmpOrder_2)
                                        continue
                                    end
                                    selectslot = tmpOrder(tmpOrder_2(1));                                    
                                    if ~isempty(selectslot)
                                        tmp = self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+slotIdx));
                                        self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+slotIdx)) = ...
                                            self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+selectslot));
                                        self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+selectslot))= ...
                                            tmp;
                                        tmp = axis(slotIdx,1);
                                        axis(slotIdx,1) = axis(selectslot,1);
                                        axis(selectslot,1) = tmp;
                                    end
                                end
                            end    
                        end
                    else    % Satellite load
                        if length(self.interface.SatObj(satIdx).servUsr) > length(self.interface.SatObj(neighbor_satIdx).servUsr)
                            axis = zeros(self.interface.SlotInSche,2);
                            for slotIdx = 1 : self.interface.SlotInSche
                                tmp1 = intersect(BHST(:, slotIdx), edgeUsr_sat_servBeamf);
                                if ~isempty(tmp1)
                                    axis(slotIdx,1) = 1;
                                end
                                tmp2 = intersect(BHST_neighbor(:, slotIdx), edgeUsr_neighbor_servBeamf);
                                if ~isempty(tmp2)
                                    axis(slotIdx,2) = 1;
                                end
                            end
                            for slotIdx = 1 : self.interface.SlotInSche
                                if (axis(slotIdx,1)==1) && (axis(slotIdx,2)==1)
                                    tmpOrder = find(axis(:,1)==0);
                                    tmpOrder_2 = find(axis(tmpOrder,2)==0);
                                    if isempty(tmpOrder_2)
                                        continue
                                    end
                                    selectslot = tmpOrder(tmpOrder_2(1));                                    
                                    if ~isempty(selectslot)
                                        tmp = self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+slotIdx));
                                        self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+slotIdx)) = ...
                                            self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+selectslot));
                                        self.interface.tmpSat(neighbor_satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+selectslot))= ...
                                            tmp;
                                        tmp = axis(slotIdx,2);
                                        axis(slotIdx,2) = axis(selectslot,2);
                                        axis(selectslot,2) = tmp;
                                    end
                                end
                            end
                        else
                            axis = zeros(self.interface.SlotInSche,2);
                            for slotIdx = 1 : self.interface.SlotInSche
                                tmp1 = intersect(BHST(:, slotIdx), edgeUsr_sat_servBeamf);
                                if ~isempty(tmp1)
                                    axis(slotIdx,1) = 1;
                                end
                                tmp2 = intersect(BHST_neighbor(:, slotIdx), edgeUsr_neighbor_servBeamf);
                                if ~isempty(tmp2)
                                    axis(slotIdx,2) = 1;
                                end
                            end
                            for slotIdx = 1 : self.interface.SlotInSche
                                if (axis(slotIdx,1)==1) && (axis(slotIdx,2)==1)
                                    tmpOrder = find(axis(:,1)==0);
                                    tmpOrder_2 = find(axis(tmpOrder,2)==0);
                                    if isempty(tmpOrder_2)
                                        continue
                                    end
                                    selectslot = tmpOrder(tmpOrder_2(1));                                    
                                    if ~isempty(selectslot)
                                        tmp = self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+slotIdx));
                                        self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+slotIdx)) = ...
                                            self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+selectslot));
                                        self.interface.tmpSat(satIdx).BHST(:,((scheIdx-1)*self.interface.SlotInSche+selectslot))= ...
                                            tmp;
                                        tmp = axis(slotIdx,1);
                                        axis(slotIdx,1) = axis(selectslot,1);
                                        axis(selectslot,1) = tmp;
                                    end
                                end
                            end 
                        end
                    end
                end

            end
            
        end

    end


end

