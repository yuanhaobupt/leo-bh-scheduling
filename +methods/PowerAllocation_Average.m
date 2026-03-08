function PowerAllocation_Average(interface)
% This function allocates power equally among beam users based on BHST

for satIdx = 1 : length(interface.OrderOfServSatCur)
    % Calculate satellite total power
    Pt_sat = interface.SatObj(satIdx).Pt_dBm_serv; % Total transmit power of satellite antenna
    Pt_sat = (10.^(Pt_sat/10))/1e3; % Unit is W

    BHST = interface.tmpSat(satIdx).BHST;
    totalSlots = interface.SlotInSche; % Length of one beam-hopping scheduling period
    maxBeam = length(BHST(:,1));

    PtTable = zeros(maxBeam, totalSlots);

    for slotIdx = 1 : totalSlots
        curIllu = find(BHST(:,slotIdx) ~= 0);
        curBeamNum = length(curIllu);
        curAvgPower = Pt_sat / curBeamNum;
        for beamIdx = 1 : curBeamNum
            PtTable(curIllu(beamIdx), slotIdx) = curAvgPower;
        end
    end

    interface.tmpSat(satIdx).Pt_Antenna = PtTable;

end

end

