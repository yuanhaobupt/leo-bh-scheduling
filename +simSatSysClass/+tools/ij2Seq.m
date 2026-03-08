function Seq = ij2Seq(DiscrArea_i, DiscrArea_j, rawNum, colNum)
    if DiscrArea_i <= rawNum && DiscrArea_i > 0 && DiscrArea_j <= colNum && DiscrArea_j > 0
        Seq = (DiscrArea_j - 1) * rawNum + DiscrArea_i;
    else
        Seq = 0;
    end
end

