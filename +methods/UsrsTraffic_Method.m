function UsrsTraffic_Method(interface)
%USRSTRAFFIC_METHOD Generate user traffic
%     PossionTrafficLambda = 10e5; % Poisson traffic mean
    mu = 3e5;
    sigma = 5e4;
    %% Generate initial random traffic
    NumOfUsrs = interface.NumOfSelectedUsrs;
    ScheInShot = interface.ScheInShot;
%     interface.UsrsTraffic(:, 1) = poissrnd(PossionTrafficLambda, [NumOfUsrs, 1]);
%     interface.UsrsTraffic(:, 1) = [poissrnd(PossionTrafficLambda*0.5, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda*0.375, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda*0.25, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda*0.125, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda/0.125, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda/0.25, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda/0.375, [NumOfUsrs/10, 1]);...
%         poissrnd(PossionTrafficLambda/0.5, [NumOfUsrs/10, 1])];

    for idx_usr = 1 : NumOfUsrs
%         interface.UsrsTraffic(idx_usr, 1) = unifrnd(8e5,12e5);
        
        if normrnd(mu,sigma) > 0
            interface.UsrsTraffic(idx_usr, 1) = fix(normrnd(mu,sigma));
        else
            interface.UsrsTraffic(idx_usr, 1) = 0;
        end
    end
    %% Generate per-scheduling traffic
    for idx = 1 : ScheInShot
%         interface.UsrsTraffic(:, 1+idx) = poissrnd(PossionTrafficLambda, [NumOfUsrs, 1]);
        interface.UsrsTraffic(:, 1+idx) = 0;
    end
end


% function UsrsTraffic_Method(interface)
% %USRSTRAFFIC_METHOD Generateusertraffic
%     NumOfUsrs = interface.NumOfSelectedUsrs;
%     ScheInShot = interface.ScheInShot;
%     bhTime = interface.bhTime*1e3;
%     diffTrafficUserRatio = interface.diffTrafficUserRatio;
%     PacketOfUsr = trafficModels.packetOfUsr;
%     duration = bhTime*(ScheInShot + 1);
%     for idx_usr = 1 : NumOfUsrs
%         tmp = rand();
%         if tmp <= diffTrafficUserRatio(1)
%             tempclass = trafficModels.FTPModel;
%         elseif (tmp > diffTrafficUserRatio(1)) && (tmp <= (diffTrafficUserRatio(1)+diffTrafficUserRatio(2)))
%             tempclass = trafficModels.VideoStreamingModel;
%         elseif (tmp > (diffTrafficUserRatio(1)+diffTrafficUserRatio(2))) 
%             tempclass = trafficModels.VoIPModel;
%         end
%         temp = tempclass.generatePacket(duration);
%         temparray = cell2mat(struct2cell(temp));
%         [~,len] =size(temp) ;
%         PacketOfUsr(idx
%         PacketOfUsr(idx_usr).GenerateTime(1:len) = temparray(2,1,:);
%         PacketOfUsr(idx_usr).id = [1:len];
%     end
%     for n = 1 : NumOfUsrs
%         interface.UsrsTraffic(n,1) = sum(PacketOfUsr(n).packetsize(1:bhTime));
%     end
%     for n = 1 : NumOfUsrs
%         for idx = 1 : ScheInShot
%             interface.UsrsTraffic(n, 1+idx) = sum(PacketOfUsr(n).packetsize(1+idx*bhTime : (idx+1)*bhTime));
%         end
%     end
% end

) 
