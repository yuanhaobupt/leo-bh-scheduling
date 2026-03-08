classdef ( ...
        Abstract = false,...            % Not an abstract class
        ConstructOnLoad = true,...      % Must have a constructor
        HandleCompatible = false,...    % Value-type class
        Sealed = false...               % Can be inherited by subclasses
          ) simSatellite
%% Public properties
    properties (Access = public)  
        order % ID/number
        position % Longitude and latitude coordinates
        nextpos % Next step coordinates
        servTri % Service triangle ID/number, size is total number of triangles under satellite

        servUsr % User ID/number under satellite
        numOfusrs % Number of users under satellite
        Neighbor % Adjacent satellite ID/number, Neighbor(k,:) indicates the k-th layer neighbor satellite ID/number set of current satellite

        numOfsigbeam % Number of signaling beam positions under satellite
        IdxOfsigbeam % Index of signaling beam positions in signalOfArea directory
        SeqOfsigbeam % Original ID/number of signaling beam positions in global area
        SpanIDXOfsigbeam % Signaling beam position ID/number for signaling scanning
        SeqInSpanOfsigbeam  % Scanning sequence of signaling beam positions, matrix, format is "numOfsigbeam × ceil(length(SpanIDXOfsigbeam)/numOfsigbeam)"
        ScheOfSig   % Signaling scanning period
        LightTimeOfSig   % Signaling dwell duration
        SignalBeamfoot % Signaling beam position
            % SignalBeamfoot(k).servTri Triangle ID/number under beam position k, size is total number of beam position triangles
            % SignalBeamfoot(k).centerTri Center triangle ID/number of beam position k
            % Signaleamfoot(k).usrs User ID/number of beam position k  
        TableOfSig  % Matrix, format is "signaling beam number × slots per snapshot"

        egdeSig  % Edge signaling beam position sequence at current step, format is "numOfSat × numOfSigInSat"
                 % egdeSig(k,j)=1 indicates current satellite's j-th signaling beam position intersects with SatObj(k) satellite
        egdeSigSeq  % Store signalOfArea ID/number of edge signaling beam positions
            
        numOfbeam  % Number of beam positions under satellite, vector, length is NumOfSche, numOfbeam(p) indicates beam position number at p-th scheduling
        beamfoot   % Structure matrix, format is "NumOfSche × MAXNumOfBeamFoot" 

        BHST % Matrix, format is "NumOfServBeam × SlotInShot"
    
        numOfbeam_method0   % Number of beam positions under satellite, vector, length is NumOfSche, numOfbeam(p) indicates beam position number at p-th scheduling
        beamfoot_method0    % Structure matrix, format is "NumOfSche × MAXNumOfBeamFoot"
                            % beamfoot(p, k).position Center coordinates of beam position k at p-th scheduling
                            % beamfoot(p, k).usrs User ID/number of beam position k at p-th scheduling
                            % beamfoot(p, k).servTri Triangles of beam position k at p-th scheduling
        
        numOfbeam_method1   % Loadable beam position formation algorithm 1
        beamfoot_method1    % Loadable beam position formation algorithm 1

        numOfbeam_method2   % Loadable beam position formation algorithm 2
        beamfoot_method2    % Loadable beam position formation algorithm 2

        numOfbeam_method3   % Loadable beam position formation algorithm 3
        beamfoot_method3    % Loadable beam position formation algorithm 3

        numOfbeam_method4   % Loadable beam position formation algorithm 4
        beamfoot_method4    % Loadable beam position formation algorithm 4 

        BHST_combi_0    % Beam hopping schedule table, matrix "NumOfServBeam × SlotInShot"
        BHST_combi1_0
        
        BHST_combi_5    % Combination of loadable BHST formation algorithm 1 and beam position formation algorithm 0
        BHST_combi_10   % Combination of loadable BHST formation algorithm 2 and beam position formation algorithm 0
        BHST_combi_15   % Combination of loadable BHST formation algorithm 3 and beam position formation algorithm 0
        BHST_combi_20   % Combination of loadable BHST formation algorithm 4 and beam position formation algorithm 0
        Pt_Antenna_combi_0    % Power allocation schedule table, matrix "NumOfServBeam × SlotInShot"
        Pt_Antenna_combi_5   
        Pt_Antenna_combi_10   
        Pt_Antenna_combi_15    
        Pt_Antenna_combi_20         

        BHST_combi_1     % Combination of loadable BHST formation algorithm 0 and beam position formation algorithm 1
        BHST_combi_6     % Combination of loadable BHST formation algorithm 1 and beam position formation algorithm 1
        BHST_combi_11    % Combination of loadable BHST formation algorithm 2 and beam position formation algorithm 1
        BHST_combi_16    % Combination of loadable BHST formation algorithm 3 and beam position formation algorithm 1
        BHST_combi_21    % Combination of loadable BHST formation algorithm 4 and beam position formation algorithm 1
        Pt_Antenna_combi_1    
        Pt_Antenna_combi_6   
        Pt_Antenna_combi_11   
        Pt_Antenna_combi_16    
        Pt_Antenna_combi_21 

        BHST_combi_2     % Combination of loadable BHST formation algorithm 0 and beam position formation algorithm 2
        BHST_combi_7     % Combination of loadable BHST formation algorithm 1 and beam position formation algorithm 2
        BHST_combi_12    % Combination of loadable BHST formation algorithm 2 and beam position formation algorithm 2
        BHST_combi_17    % Combination of loadable BHST formation algorithm 3 and beam position formation algorithm 2
        BHST_combi_22    % Combination of loadable BHST formation algorithm 4 and beam position formation algorithm 2
        Pt_Antenna_combi_2    
        Pt_Antenna_combi_7   
        Pt_Antenna_combi_12  
        Pt_Antenna_combi_17    
        Pt_Antenna_combi_22 

        BHST_combi_3     % Combination of loadable BHST formation algorithm 0 and beam position formation algorithm 3
        BHST_combi_8     % Combination of loadable BHST formation algorithm 1 and beam position formation algorithm 3
        BHST_combi_13    % Combination of loadable BHST formation algorithm 2 and beam position formation algorithm 3
        BHST_combi_18    % Combination of loadable BHST formation algorithm 3 and beam position formation algorithm 3
        BHST_combi_23    % Combination of loadable BHST formation algorithm 4 and beam position formation algorithm 3
        Pt_Antenna_combi_3   
        Pt_Antenna_combi_8  
        Pt_Antenna_combi_13  
        Pt_Antenna_combi_18    
        Pt_Antenna_combi_23

        BHST_combi_4     % Combination of loadable BHST formation algorithm 0 and beam position formation algorithm 4
        BHST_combi_9     % Combination of loadable BHST formation algorithm 1 and beam position formation algorithm 4
        BHST_combi_14    % Combination of loadable BHST formation algorithm 2 and beam position formation algorithm 4
        BHST_combi_19    % Combination of loadable BHST formation algorithm 3 and beam position formation algorithm 4
        BHST_combi_24    % Combination of loadable BHST formation algorithm 4 and beam position formation algorithm 4
        Pt_Antenna_combi_4   
        Pt_Antenna_combi_9  
        Pt_Antenna_combi_14  
        Pt_Antenna_combi_19   
        Pt_Antenna_combi_24

        Pt_dBm_serv     % dBm 
        Pt_dBm_signal   % dBm 
        T_noise         % K
        F_noise         % dB

        BeamPoint % Beam pointing angle
        LightBeamfoot % Illuminated beam position ID/number
        LightSig % Illuminated signaling beam position ID/number

        % Newly added
        PowerTable % Power allocation table
        LightPower % Current time slot power allocation

    end
%% Public methods
    methods (Access = public)
        % Constructor
        function self = simSatellite()
            
        end
        % Method signature       
        
        G = getSatAntennaServG(self, varTheta, varPhi, BfIdx, freq) % Antenna gain
        G = getSatSigServG(self, varTheta, varPhi, BfIdx, freq) % Antenna gain
    end


end