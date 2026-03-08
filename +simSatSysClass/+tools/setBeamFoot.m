%% Given beam center triangle coordinates Ordpos in DiscrArea, find all triangles in the beam footprint
function SeqOfTri = setBeamFoot(Ordpos, ifUpTri, NofRaw, rawNum, colNum)
% NofRaw Number of triangle rows in beam footprint
% NumOfBeam Beam footprint ID
    if ifUpTri == false
        if Ordpos(2) + 1 <= colNum
            Ordpos(2) = Ordpos(2) + 1;
        else
            Ordpos(2) = Ordpos(2) - 1;
        end

    end
    SeqOfTri = [];
    for ii = 1 : NofRaw/2
        for jj = 1 : (NofRaw+1)+2*(ii-1)
            temp_i1 = Ordpos(1) - NofRaw/2 + ii;
            temp_j1 = Ordpos(2) - NofRaw/2 + 1 - ii + jj;
            temp_Seq1 = simSatSysClass.tools.ij2Seq(temp_i1, temp_j1, rawNum, colNum);
            temp_i2 = Ordpos(1) + NofRaw/2 - ii + 1;
            temp_j2 = temp_j1;
            temp_Seq2 = simSatSysClass.tools.ij2Seq(temp_i2, temp_j2, rawNum, colNum);
            if temp_Seq1 ~= 0 
                SeqOfTri = [SeqOfTri temp_Seq1];
            end
            if temp_Seq2 ~= 0
                SeqOfTri = [SeqOfTri temp_Seq2];
            end
        end
    end
    SeqOfTri = sort(SeqOfTri, 'ascend');
end