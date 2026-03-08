% function generateBHST(self, IdxOfStep, NumOfShot)
% %GENERATEBHST BHSTGenerate
% for k = 1 : self.interface.numOfMethods_BeamGenerate
% for idxOfSat = 1 : length(self.interface.OrderOfServSatCur)
% eval(['self.interface.tmpSat(idxOfSat).NumOfBeamFoot = ', ...
% 'self.interface.tmpSat_',num2str(k-1),'(idxOfSat).NumOfBeamFoot;']); 
% eval(['self.interface.tmpSat(idxOfSat).beamfoot = ', ...
% 'self.interface.tmpSat_',num2str(k-1),'(idxOfSat).beamfoot;']); 
% end
% for p = 1 : self.interface.numOfMethods_BeamHopping
% eval(['methods.BHST_Method',num2str(p-1),'(self.interface)']);

% if self.interface.Config.ifAdjustBHST == 1
% self.adjustBHST();
% if self.interface.ifDebug == 1
% fprintf(
% end
% end

% for idxOfSat = 1 : length(self.interface.OrderOfServSatCur)
% eval(['self.interface.tmpSat_',num2str(k-1),'(idxOfSat).BHST_',num2str(p-1),' = ', ...
% 'self.interface.tmpSat(idxOfSat).BHST;']); 
% end
% self.interface.UsrsTransPort(p, :, :) = self.interface.tmp_UsrsTransPort;
% self.interface.tmp_UsrsTransPort = zeros(self.interface.NumOfSelectedUsrs, self.interface.ScheInShot);
% end
% end
% end

function generateBHST(self, IdxOfStep, NumOfShot)
%GENERATEBHST BHST generation
% Modified version: supports SA mechanism switch

% Configuration options (set in Config):
% - enable_SA: true/false (whether to enable SA mechanism, default true)
% - L_tabu_mode: 'adaptive'/'fixed' (tabu length mode, default 'adaptive')
% - fixed_L_tabu: integer (fixed tabu length, default 20)

 % GetSA
 enable_SA = true; % SA
 L_tabu_mode = 'adaptive'; % 
 fixed_L_tabu = 20; % length
 
 % fromConfiginRead
 if isfield(self.interface, 'Config')
 if isfield(self.interface.Config, 'enable_SA')
 enable_SA = self.interface.Config.enable_SA;
 end
 if isfield(self.interface.Config, 'L_tabu_mode')
 L_tabu_mode = self.interface.Config.L_tabu_mode;
 end
 if isfield(self.interface.Config, 'fixed_L_tabu')
 fixed_L_tabu = self.interface.Config.fixed_L_tabu;
 end
 end
 
 for k = 1 : self.interface.numOfMethods_BeamGenerate
 for idxOfSat = 1 : length(self.interface.OrderOfServSatCur)
 eval(['self.interface.tmpSat(idxOfSat).NumOfBeamFoot = ', ...
 'self.interface.tmpSat_',num2str(k-1),'(idxOfSat).NumOfBeamFoot;']); 
 eval(['self.interface.tmpSat(idxOfSat).beamfoot = ', ...
 'self.interface.tmpSat_',num2str(k-1),'(idxOfSat).beamfoot;']); 
 end
 p = 1;
 
 % based on
 if enable_SA
 % using
 methods.BHST_MY_SA(self.interface, enable_SA, L_tabu_mode, fixed_L_tabu);
 else
 % using
 methods.BHST_MY(self.interface);
 end
 
 % Alternative algorithms (commented out)
 % methods.BHST_greedy(self.interface); % Greedy
 % methods.BHST_greedyAndDist(self.interface); % Greedy + isolation

 for idxOfSat = 1 : length(self.interface.OrderOfServSatCur)
 eval(['self.interface.tmpSat_',num2str(k-1),'(idxOfSat).BHST_',num2str(p-1),' = ', ...
 'self.interface.tmpSat(idxOfSat).BHST;']); 
 end
 self.interface.UsrsTransPort(p, :, :) = self.interface.tmp_UsrsTransPort;
 self.interface.tmp_UsrsTransPort = zeros(self.interface.NumOfSelectedUsrs, self.interface.ScheInShot);
 end
end

) 
