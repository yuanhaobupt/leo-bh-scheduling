function getCurLinkRate(self, measureSINR)
    % Shannon formula
    self.CurLinkRate = ...
        self.BandWidth*1e6*log10(1+10.^(measureSINR/10));
end

