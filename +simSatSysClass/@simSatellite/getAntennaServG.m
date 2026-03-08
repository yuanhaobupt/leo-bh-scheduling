function G = getAntennaServG(self, varTheta, varPhi, BfIdx, freq)

    [tmpRaw, ~] = size(self.BeamPoint);
    if tmpRaw == 1
        poiBeta = self.BeamPoint(1);
        poiAlpha = self.BeamPoint(2);
    else
        poiBeta = self.BeamPoint(BfIdx,1);
        poiAlpha = self.BeamPoint(BfIdx,2);
    end

    AgleOfInv = [varTheta, varPhi];
    AgleOfPoi = [poiAlpha, poiBeta];

    G = antenna.getSatAntennaServG(AgleOfInv, AgleOfPoi, freq);

end

