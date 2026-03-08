function getBeamPoint(self, slotIdx,MethodIdx)
    NumOfSat = length(self.OrderOfServSatCur);
%     NumOfSubFramePerShot = floor(self.Constellation.duration/self.Communication.subframe);  % ÿ֡
    SlotPerCycle = self.subFInSche * self.slotInSubF;
%     NofDispatch = floor(NumOfSubFramePerShot/SubframePerCycle); % ÿյĵȴ

    dpIdx = ceil(slotIdx/SlotPerCycle);

    for SatIdx =1 : NumOfSat
     %% MethodIdx
     % numOfMethods_BeamGenerate = N
     % numOfMethods_BeamHopping = M
     % N   1                   2         ...          N
     % M   1   2   ...     M   1   2    ...   M  ...  1         2       ...     M
     % Idx 1   2   3  ...  M   M+1 M+2   ...  2M ...  (N-1)M+1  (N-1)M+2   ...  NM        
     %%
        idxOfBG = ceil(MethodIdx/self.numOfMethods_BeamHopping);
        idxOfBH = mod(MethodIdx-1,self.numOfMethods_BeamHopping)+1;
        eval(['self.SatObj(SatIdx).BHST = self.SatObj(SatIdx).BHST_combi_',num2str((idxOfBG-1)+(idxOfBH-1)*5),';']);
        eval(['self.SatObj(SatIdx).numOfbeam = self.SatObj(SatIdx).numOfbeam_method',num2str(idxOfBG-1),';']);
        eval(['self.SatObj(SatIdx).beamfoot = self.SatObj(SatIdx).beamfoot_method',num2str(idxOfBG-1),';']);
        
        % 빦ʱ
        self.SatObj(SatIdx).PowerTable = self.SatObj(SatIdx).Pt_Antenna_combi_0;
       
%         if MethodIdx == 1
%             eval(['self.SatObj(SatIdx).BHST = self.SatObj(SatIdx).BHST_combi_0;']);
%         elseif MethodIdx == 2
%             eval(['self.SatObj(SatIdx).BHST = self.SatObj(SatIdx).BHST_combi_3;']);
%         elseif MethodIdx == 3
%             eval(['self.SatObj(SatIdx).BHST = self.SatObj(SatIdx).BHST_combi_6;']);
%         elseif MethodIdx == 4
%             eval(['self.SatObj(SatIdx).BHST = self.SatObj(SatIdx).BHST_combi_15;']);
%         elseif MethodIdx == 5
%             eval(['self.SatObj(SatIdx).BHST = self.SatObj(SatIdx).BHST_combi_20;']);
%         end
%         self.SatObj(SatIdx).beamfoot = self.SatObj(SatIdx).beamfoot_method0;
%         eval(['self.SatObj(SatIdx).BHST = self.SatObj(SatIdx).BHST_combi_',num2str(MethodIdx-1),';']);
%         eval(['self.SatObj(SatIdx).beamfoot = self.SatObj(SatIdx).beamfoot_method',num2str(MethodIdx-1),';']);
        tmpOrder = find(self.SatObj(SatIdx).BHST(:, slotIdx) ~= 0);%ҵǰ֡Ĳλ 
        if ~isempty(tmpOrder)%ǰ֡еҵλ

            if self.Config.numOfSigbeam > 0 
                curSig = self.SatObj(SatIdx).TableOfSig(:, slotIdx);%õǰ֡λ

%                 if length(find(curSig == 0))~=length(curSig) % еλ
                %λҵλ
                LightBeamfoot = self.SatObj(SatIdx).BHST(tmpOrder,slotIdx);  % Ĳλ
                NumOfLightBeamfoot = length(LightBeamfoot);

                temp = find(curSig ~= 0);
                LightSig = curSig(temp);%ǰλ
                NumOfLightSig = length(LightSig);%λ
                %òλ
                PosOfBeam = zeros(NumOfLightBeamfoot + NumOfLightSig, 2); % λ
                for bidx = 1 : NumOfLightBeamfoot
                    if ~isempty(self.SatObj(SatIdx).beamfoot)
                        PosOfBeam(bidx, :) = self.SatObj(SatIdx).beamfoot(dpIdx, LightBeamfoot(bidx)).position;
                    end
                end
                for bidx = 1 : NumOfLightSig
                    triNo = self.SatObj(SatIdx).SignalBeamfoot(LightSig(bidx)).centerTri;
                    PosOfBeam(NumOfLightBeamfoot + bidx, :) = self.SeqDiscrArea(triNo, :);
                end
                %ָ
                BeamPoint = zeros(NumOfLightBeamfoot + NumOfLightSig, 2); % varphi(ƫx),vartheta(ƫxOyƽ),zOyƽ(ϵ)
                for j = 1 : NumOfLightBeamfoot + NumOfLightSig
                    [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
                        self.SatObj(SatIdx).position, self.SatObj(SatIdx).nextpos, PosOfBeam(j, :), self.Config.height);
                    BeamPoint(j,1) = outputPhi;
                    BeamPoint(j,2) = outputTheta;
                end

                self.SatObj(SatIdx).BeamPoint = BeamPoint;
                self.SatObj(SatIdx).LightBeamfoot = LightBeamfoot;
                self.SatObj(SatIdx).LightSig = LightSig;
                % ʱ
                LightPower = self.SatObj(SatIdx).PowerTable(tmpOrder,slotIdx);
                self.SatObj(SatIdx).LightPower = LightPower;
%                 end

            else%ֻҵλûλ
                LightBeamfoot = self.SatObj(SatIdx).BHST(tmpOrder, slotIdx);  % Ĳλ
                NumOfLightBeamfoot = length(LightBeamfoot);
                PosOfBeam = zeros(NumOfLightBeamfoot, 2);    % λ            
                for bidx = 1 : NumOfLightBeamfoot
%                     if isempty(self.SatObj(SatIdx).beamfoot)
%                         1;
%                     end
                    if ~isempty(self.SatObj(SatIdx).beamfoot)
                        PosOfBeam(bidx, :) = self.SatObj(SatIdx).beamfoot(dpIdx, LightBeamfoot(bidx)).position; 
%                     PosOfBeam(bidx, :) = self.SeqDiscrArea(triNo, :);%òλĵľγ
                    end
                end
                %ָ
                BeamPoint = zeros(NumOfLightBeamfoot, 2); % varphi(ƫx),vartheta(ƫxOyƽ),zOyƽ(ϵ)
                for j = 1 : NumOfLightBeamfoot
                    [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
                        self.SatObj(SatIdx).position, self.SatObj(SatIdx).nextpos, PosOfBeam(j, :), self.Config.height);
                    BeamPoint(j,1) = outputPhi;
                    BeamPoint(j,2) = outputTheta;
                end
                self.SatObj(SatIdx).BeamPoint = BeamPoint;
                self.SatObj(SatIdx).LightBeamfoot = LightBeamfoot;
                self.SatObj(SatIdx).LightSig = [];
                LightPower = self.SatObj(SatIdx).PowerTable(tmpOrder,slotIdx);
                self.SatObj(SatIdx).LightPower = LightPower;
            end
            

        else%ûеҵλ
            %Ҫûλ
            if self.Config.numOfSigbeam > 0  % && length(find(curSig == 0))~=length(curSig) %λ,ҲǶͬʱڼڵʱ
                %ֻеλûҵλ
                curSig = self.SatObj(SatIdx).TableOfSig(:, slotIdx);%õǰ֡λ
                temp = find(curSig ~= 0);
                LightSig = curSig(temp);%ǰλ
                NumOfLightSig = length(LightSig);%λ
                PosOfBeam = zeros(NumOfLightSig, 2); % λ            
                for bidx = 1 : NumOfLightSig
                    triNo = self.SatObj(SatIdx).SignalBeamfoot(LightSig(bidx)).centerTri;
                    PosOfBeam(NumOfLightBeamfoot + bidx, :) = self.SeqDiscrArea(triNo, :);
                end
                %ָ
                BeamPoint = zeros(NumOfLightSig, 2); % varphi(ƫx),vartheta(ƫxOyƽ),zOyƽ(ϵ)
                for j = 1 : NumOfLightSig
                    [outputTheta, outputPhi] = tools.getPointAngleOfUsr(...
                        self.SatObj(SatIdx).position, self.SatObj(SatIdx).nextpos, PosOfBeam(j, :), self.Config.height);
                    BeamPoint(j,1) = outputPhi;
                    BeamPoint(j,2) = outputTheta;
                end
                self.SatObj(SatIdx).BeamPoint = BeamPoint;
                self.SatObj(SatIdx).LightBeamfoot = [];
                self.SatObj(SatIdx).LightSig = LightSig;
                self.SatObj(SatIdx).LightPower = [];
                
            else%ûҵҲûλ
                self.SatObj(SatIdx).BeamPoint = 0;            
                self.SatObj(SatIdx).LightBeamfoot = [];
                self.SatObj(SatIdx).LightSig = [];
                self.SatObj(SatIdx).LightPower = [];
            end
        end

    end
end