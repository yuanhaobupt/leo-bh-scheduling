function SigSpan_Method(interface)
%SIGSPAN_METHOD Summary about this function

% Record satellites that have already generated tables
tabledSat = [];

    for idxOfSat = 1 : length(interface.OrderOfServSatCur)
        numOfsigbeamfoot = interface.SatObj(idxOfSat).numOfsigbeam; % Number of signaling beam positions under satellite
        numOfsigbeam = interface.numOfSigbeam; % Number of signaling beams
        SpanIDXOfsigbeam = interface.SatObj(idxOfSat).SpanIDXOfsigbeam; % Signaling beam position IDs used for satellite signaling scanning
%         ScheOfSig = ceil(interface.SatObj(idxOfSat).ScheOfSig/interface.timeInSlot);   % Signaling scanning period (slot)
%         LightTimeOfSig = ceil(interface.SatObj(idxOfSat).LightTimeOfSig/interface.timeInSlot);   % Signaling dwell time (slot)

        totalslot = interface.ScheInShot * interface.SlotInSche;
        signaltable = zeros(numOfsigbeam,totalslot);% Create signaling beam table, for the entire beam hopping period

        % Idea: Two beams, each beam is responsible for half of the beam positions

        midSerial = ceil(numOfsigbeamfoot/2);

        % First beam
        c = 1;% Counter
        cc = 1;% For pointing to beam position ID
        while(c <= totalslot)
            if mod(c - 1,midSerial) == 0 % If all have been traversed
                % Restart
                cc = 1;
            end
            signaltable(1,c) = SpanIDXOfsigbeam(cc);
            c = c + 1;
            cc = cc + 1;            
        end

        % Second beam
        c = 1;% Counter
        cc = midSerial + 1;% For pointing to beam position ID
        while(c <= totalslot)
            if mod(c - 1,numOfsigbeamfoot - midSerial) == 0 % If all have been traversed
                % Restart
                cc = midSerial + 1;
            end
            signaltable(2,c) = SpanIDXOfsigbeam(cc);
            c = c + 1;
            cc = cc + 1;            
        end

%         SeqInSpanOfsigbeam = zeros(numOfsigbeam, ceil(numOfsigbeamfoot/numOfsigbeam));
%         interval = ceil(numOfsigbeamfoot/numOfsigbeam);
%         for k = 1 : numOfsigbeam
%             if k*interval <= numOfsigbeamfoot
%                 SeqInSpanOfsigbeam(k, :) = SpanIDXOfsigbeam(1+(k-1)*interval : k*interval);
%             else
%                 SeqInSpanOfsigbeam(k, 1 : length(SpanIDXOfsigbeam(1+(k-1)*interval : end))) = SpanIDXOfsigbeam(1+(k-1)*interval : end);
%             end
%         end
%         interface.SatObj(idxOfSat).SeqInSpanOfsigbeam = SeqInSpanOfsigbeam;
%         TableOfSig = zeros(numOfsigbeam, interface.SlotInSche * interface.ScheInShot);
%         count = 1;
%         for j = 1 : LightTimeOfSig : interface.SlotInSche * interface.ScheInShot
%             if count ~= -1 
%                 for k = 1 : numOfsigbeam
%                     if j+LightTimeOfSig-1 <= interface.SlotInSche*interface.ScheInShot
%                         TableOfSig(k, j:j+LightTimeOfSig-1) = SeqInSpanOfsigbeam(k, count); 
%                     else
%                         TableOfSig(k, j:end) = SeqInSpanOfsigbeam(k, count);
%                     end
%                 end
%                 if count == ceil(numOfsigbeamfoot/numOfsigbeam)
%                     count = -1;
%                 else
%                     count = count + 1;
%                 end
%             end
%             if mod(j, ScheOfSig) < 3 && j > ScheOfSig
%                 count = 1;
%             end
%         end



        interface.SatObj(idxOfSat).TableOfSig = signaltable;
    end
    
    
end

% function SigSpan_Method(interface)
%     for idxOfSat = 1 : length(interface.OrderOfServSatCur)
%         numOfsigbeamfoot
%         numOfsigbeam
%         SpanIDXOfsigbeam
%         LightTimeOfSig
%         SeqInSpanOfsigbeam = zeros(numOfsigbeam, ceil(numOfsigbeamfoot/numOfsigbeam));
%         interval = ceil(numOfsigbeamfoot/numOfsigbeam);
%         for k = 1 : numOfsigbeam
%             if k*interval <= numOfsigbeamfoot
%                 SeqInSpanOfsigbeam(k, :) = SpanIDXOfsigbeam(1+(k-1)*interval : k*interval);
%             else
%                 SeqInSpanOfsigbeam(k, 1 : length(SpanIDXOfsigbeam(1+(k-1)*interval : end))) = SpanIDXOfsigbeam(1+(k-1)*interval : end);
%             end
%         end
%         interface.SatObj(idxOfSat).SeqInSpanOfsigbeam = SeqInSpanOfsigbeam;
%         TableOfSig = zeros(numOfsigbeam, interface.SlotInSche * interface.ScheInShot);
%         count = 1;
%         for j = 1 : LightTimeOfSig : interface.SlotInSche * interface.ScheInShot
%             if count ~= -1 
%                 for k = 1 : numOfsigbeam
%                     if j+LightTimeOfSig-1 <= interface.SlotInSche*interface.ScheInShot
%                         TableOfSig(k, j:j+LightTimeOfSig-1) = SeqInSpanOfsigbeam(k, count); 
%                     else
%                         TableOfSig(k, j:end) = SeqInSpanOfsigbeam(k, count);
%                     end
%                 end
%                 if count == ceil(numOfsigbeamfoot/numOfsigbeam)
%                     count = -1;
%                 else
%                     count = count + 1;
%                 end
%             end
%             if mod(j, ScheOfSig) < 3 && j > ScheOfSig
%                 count = 1;
%             end
%         end
%         interface.SatObj(idxOfSat).TableOfSig = TableOfSig;
%     end
% end


% function SigSpan_Method(interface)
%     for idxOfSat = 1 : length(interface.OrderOfServSatCur)
%         numOfsigbeamfoot
%         numOfsigbeam
%         SpanIDXOfsigbeam
%         ScheOfSig
%         LightTimeOfSig
%         SeqInSpanOfsigbeam = zeros(numOfsigbeam, ceil(numOfsigbeamfoot/numOfsigbeam));
%         interval = ceil(numOfsigbeamfoot/numOfsigbeam);
%         for k = 1 : numOfsigbeam
%             if k*interval <= numOfsigbeamfoot
%                 SeqInSpanOfsigbeam(k, :) = SpanIDXOfsigbeam(1+(k-1)*interval : k*interval);
%             else
%                 SeqInSpanOfsigbeam(k, 1 : length(SpanIDXOfsigbeam(1+(k-1)*interval : end))) = SpanIDXOfsigbeam(1+(k-1)*interval : end);
%             end
%         end
%         interface.SatObj(idxOfSat).SeqInSpanOfsigbeam = SeqInSpanOfsigbeam;
%         TableOfSig = zeros(numOfsigbeam, interface.SlotInSche * interface.ScheInShot);
%         count = 1;
%         for j = 1 : LightTimeOfSig : interface.SlotInSche * interface.ScheInShot
%             if count ~= -1 
%                 for k = 1 : numOfsigbeam
%                     if j+LightTimeOfSig-1 <= interface.SlotInSche*interface.ScheInShot
%                         TableOfSig(k, j:j+LightTimeOfSig-1) = SeqInSpanOfsigbeam(k, count); 
%                     else
%                         TableOfSig(k, j:end) = SeqInSpanOfsigbeam(k, count);
%                     end
%                 end
%                 if count == ceil(numOfsigbeamfoot/numOfsigbeam)
%                     count = -1;
%                 else
%                     count = count + 1;
%                 end
%             end
%             if mod(j, ScheOfSig) < 3 && j > ScheOfSig
%                 count = 1;
%             end
%         end
%         interface.SatObj(idxOfSat).TableOfSig = TableOfSig;
%     end
% end

