function  BS = findClosestBS(self,usrspos)
            tempBSarray = self.BS_array;
            row = size(tempBSarray,1);
            col = size(tempBSarray,2);
            unitlat = abs(tempBSarray(1,1,2) - tempBSarray(row,1,2))/row;
            x1 = floor((tempBSarray(1,1,2) - usrspos(2))/unitlat); x1 = trans(x1);
            x2 = ceil((tempBSarray(1,1,2) - usrspos(2))/unitlat); x2 = trans(x2);
            unitlon = tempBSarray(x2,2,1) - tempBSarray(x2,1,1);
            y1 = floor((usrspos(1)-tempBSarray(x2,1,1))/unitlon); y1 = trans(y1);
            y2 = ceil((usrspos(1)-tempBSarray(x2,2,1))/unitlon); y2 = trans(y2);
           
            tempdist = zeros(1,4);
            tempdist(1) = tools.calcuDist(tempBSarray(x1,y1,1),usrspos(1),tempBSarray(x1,y1,2),usrspos(2));
            tempdist(2) = tools.calcuDist(tempBSarray(x2,y1,1),usrspos(1),tempBSarray(x2,y1,2),usrspos(2));
            tempdist(3) = tools.calcuDist(tempBSarray(x1,y2,1),usrspos(1),tempBSarray(x1,y2,2),usrspos(2));
            tempdist(4) = tools.calcuDist(tempBSarray(x2,y2,1),usrspos(1),tempBSarray(x2,y2,2),usrspos(2));

            tempID = find(tempdist == min(tempdist),1);
            switch tempID
                case 1
                    BS(1) = x1; BS(2) = y1;
                case 2
                    BS(1) = x2; BS(2) = y1;
                case 3
                    BS(1) = x1; BS(2) = y2;
                case 4
                    BS(1) = x2; BS(2) = y2;
            end




end

function a = trans(b)
       a = (b>0)*b + (b==0);
end
