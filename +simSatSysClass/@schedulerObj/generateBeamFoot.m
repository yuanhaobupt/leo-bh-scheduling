function generateBeamFoot(self)
%GENERATEBEAMFOOT Beam footprint formation
    for k = 1 : self.interface.numOfMethods_BeamGenerate
        eval(['methods.BeamFoot_Method',num2str(k-1),'(self.interface)']);
        for idx = 1 : length(self.interface.OrderOfServSatCur)
            eval(['self.interface.tmpSat_',num2str(k-1),'(idx).NumOfBeamFoot = ', ...
                'self.interface.tmpSat(idx).NumOfBeamFoot;']);
            eval(['self.interface.tmpSat_',num2str(k-1),'(idx).beamfoot = ', ...
                'self.interface.tmpSat(idx).beamfoot;']);       
        end
    end

%     k = 3;
%     eval(['methods.BeamFoot_Method',num2str(k-1),'(self.interface)']);
%         for idx = 1 : length(self.interface.OrderOfServSatCur)
%             eval(['self.interface.tmpSat_',num2str(k-1),'(idx).NumOfBeamFoot = ', ...
%                 'self.interface.tmpSat(idx).NumOfBeamFoot;']);
%             eval(['self.interface.tmpSat_',num2str(k-1),'(idx).beamfoot = ', ...
%                 'self.interface.tmpSat(idx).beamfoot;']);       
%         end

end

