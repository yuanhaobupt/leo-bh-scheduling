function pos = ij2Pos(obj, tmpIJ, rawNum, colNum)
    pos = zeros(1,2);

    if tmpIJ(1) > 0 && tmpIJ(1) <= rawNum
        pos(2) = obj.DiscrArea(abs(tmpIJ(1)),1,2);
    elseif tmpIJ(1) <= 0
        pos(2) = obj.DiscrArea(1,1,2) + abs(obj.DiscrArea(1,1,2) - obj.DiscrArea(abs(tmpIJ(1)) + 1,1,2));
    elseif tmpIJ(1) > rawNum
        pos(2) = obj.DiscrArea(rawNum,1,2) - abs(obj.DiscrArea(abs(tmpIJ(1) - rawNum),1,2) - obj.DiscrArea(1,1,2));
    end

    if tmpIJ(2) > 0 && tmpIJ(2) <= colNum
        pos(1) = obj.DiscrArea(1,abs(tmpIJ(2)),1);
    elseif tmpIJ(2) <= 0
        pos(1) = obj.DiscrArea(1,1,1) - abs(obj.DiscrArea(1,1,1) - obj.DiscrArea(1,abs(tmpIJ(2)) + 1,1));
    elseif tmpIJ(2) > colNum
        pos(1) = obj.DiscrArea(1,colNum,1) + abs(obj.DiscrArea(1,abs(tmpIJ(2) - colNum),1) - obj.DiscrArea(1,1,1));
    end

end

