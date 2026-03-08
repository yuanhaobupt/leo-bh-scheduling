function [DiscrArea_i,DiscrArea_j] = Seq2ij(P, rawNum)
    if mod(P, rawNum) == 0
        DiscrArea_i = rawNum;
    else
        DiscrArea_i = mod(P, rawNum);
    end
    DiscrArea_j = ceil(P / rawNum);
end

