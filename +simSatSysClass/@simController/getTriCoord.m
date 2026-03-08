
%%
function getTriCoord(self)
    CoordiTri = zeros(length(self.SeqDiscrArea(:,1)),3,2);%����ά�������д������������꣬(:,:,1)�Ǿ��ȣ�(:,:,2)��γ��
%     N = self.Config.factorOfDiscr * abs(self.SimConfig.rangeOfinves(2,1)-self.SimConfig.rangeOfinves(2,2));
    N = length(self.DiscrArea(:,1,1));
    deltaLat = 1/self.Config.factorOfDiscr;
    triH = tools.LatLngCoordi2Length([0 0], [0 1], self.rOfearth)/self.Config.factorOfDiscr;%�����εĸ߶ȣ���λ��m
    triX = triH*2/sqrt(3);%�����εı߳�
    groundCoord2D=self.SeqDiscrArea;
    NumOfCoordiTri = length(CoordiTri(:,1));
    for i = 1 : NumOfCoordiTri
        if (mod(mod(i,N),2) == 1 && mod(ceil(i/N),2) == 1) ||(mod(mod(i,N),2) == 0 && mod(ceil(i/N),2) == 0) %����������е���������������ż���е�ż�������Ǿ��Ǽ������ 
            CoordiTri(i,1,1) = groundCoord2D(i,1);
            CoordiTri(i,1,2) = groundCoord2D(i,2)+deltaLat*2/3;
            CoordiTri(i,2,1) = d2Lon(groundCoord2D(i,2)-deltaLat/3,groundCoord2D(i,1),-triX/2);
            CoordiTri(i,2,2) = groundCoord2D(i,2)-deltaLat/3;
            CoordiTri(i,3,1) = d2Lon(groundCoord2D(i,2)-deltaLat/3,groundCoord2D(i,1),triX/2);
            CoordiTri(i,3,2) = groundCoord2D(i,2)-deltaLat/3;
    %         geoshow(CoordiTri(i,1,2),CoordiTri(i,1,1), 'Marker','*','MarkerEdgeColor','green');
    %         geoshow(CoordiTri(i,2,2),CoordiTri(i,2,1), 'Marker','*','MarkerEdgeColor','green');
    %         geoshow(CoordiTri(i,3,2),CoordiTri(i,3,1), 'Marker','*','MarkerEdgeColor','green');
        else%��Ȼ�Ļ�����������µ�
            CoordiTri(i,1,1) = groundCoord2D(i,1);
            CoordiTri(i,1,2) = groundCoord2D(i,2)-deltaLat*2/3;
            CoordiTri(i,2,1) = d2Lon(groundCoord2D(i,2)+deltaLat/3,groundCoord2D(i,1),-triX/2);
            CoordiTri(i,2,2) = groundCoord2D(i,2)+deltaLat/3;
            CoordiTri(i,3,1) = d2Lon(groundCoord2D(i,2)+deltaLat/3,groundCoord2D(i,1),triX/2);
            CoordiTri(i,3,2) = groundCoord2D(i,2)+deltaLat/3;
    %         geoshow(CoordiTri(i,1,2),CoordiTri(i,1,1), 'Marker','*','MarkerEdgeColor','blue');
    %         geoshow(CoordiTri(i,2,2),CoordiTri(i,2,1), 'Marker','*','MarkerEdgeColor','blue');
    %         geoshow(CoordiTri(i,3,2),CoordiTri(i,3,1), 'Marker','*','MarkerEdgeColor','blue');
        end
%         if self.ifDebug == 1
%             fprintf('���������ζ�������%f%%\n', i*100/NumOfCoordiTri); 
%         end
    end
    self.CoordiTri = CoordiTri;
end

function lon2 = d2Lon(lat,lon1,d)
    lat = lat*pi/180;
    lon1 = lon1*pi/180;
    R = 6371.393e3;
    a = sin(d/2/R).^2;
    b = cos(lat).^2;
    %lon2 = lon1 + acos(1-(2*(sin(d./2/R).^2)./(cos(lat).^2)));
    lon2 = lon1 + sign(d).*acos(1-2*a./b);
    lon2 = lon2*180/pi;
    if lon2 < -180
        lon2 = 180 - (-180 - lon2);
    end
    if lon2 > 180
        lon2 = -180 + (lon2 - 180);
    end
end