function generateBeamPower(self, IdxOfStep, NumOfShot)
    % Average allocation
    k = 1;
    q = 1;
    methods.PowerAllocation_Average(self.interface);
    for idxOfSat = 1 : length(self.interface.OrderOfServSatCur)
        eval(['self.interface.tmpSat_',num2str(k-1),'(idxOfSat).Pt_Antenna_',num2str(q-1),' = ', ...
                'self.interface.tmpSat(idxOfSat).Pt_Antenna;']);  
    end

%     % Water-filling
%     k = 1;
%     q = 1;
%     methods.PowerAllocation_Method(self.interface);
%     for idxOfSat = 1 : length(self.interface.OrderOfServSatCur)
%         eval(['self.interface.tmpSat_',num2str(k-1),'(idxOfSat).Pt_Antenna_',num2str(q-1),' = ', ...
%                 'self.interface.tmpSat(idxOfSat).Pt_Antenna;']);  
%     end
end