% Class for storing simulation data
%%
classdef (HandleCompatible = false) dataObj
    properties (Access = public)  
        %% Simulation Results Statistics
        %---------------------------------------------------------------------- 
        % Format: Total number of scheduling methods × Slots per snapshot × NumOfInvesUsrs × 2
        InterfFromAll_Down  % Downlink interference C/I and C/(I+N), considering all satellites and beams in the investigation area
        InterfFromAll_Up    % Uplink interference C/I and C/(I+N), considering all satellites and beams in the investigation area
        % Format: Total number of scheduling methods × Slots per snapshot × NumOfInvesUsrs × 2
        InterfFromSingleSat_Down    % Downlink interference C/I and C/(I+N), considering only beams from serving satellite
        InterfFromSingleSat_Up      % Uplink interference C/I and C/(I+N), considering only beams from serving satellite
        % Format: Total number of scheduling methods × Slots per snapshot × NumOfInvesUsrs × 3
        Interf1 % Base station interference to satellite UE reception C/(I+N), I and C/I
        Interf4 % Ground UE interference to satellite UE reception C/(I+N), I and C/I
        Interf6 % Base station + ground UE interference to satellite UE reception C/(I+N), I and C/I
        % Format: Total number of scheduling methods × Slots per snapshot × Number of serving satellites × Number of active beams × 3
        Interf2 % Ground UE interference to satellite reception C/(I+N), I and C/I
        Interf3 % Base station interference to satellite reception C/(I+N), I and C/I
        Interf5 % Base station + ground UE interference to satellite reception C/(I+N), I and C/I
        
        %---------------------------------------------------------------------- 
        UsrsTraffic % Matrix, format "NumOfSelectedUsrs × (scheInShot+1)"
                    % UsrsTraffic(k, 1) is initial random traffic
                    % UsrsTraffic(k, 2)~UsrsTraffic(k,scheInShot+1) is newly generated traffic at the beginning of each scheduling period
        %----------------------------------------------------------------------            
        UsrsTransPort   % Matrix, format "NumOfSelectedUsrs × scheInShot"
                        % UsrsTransPort(idxOfMethod, k, p) is transported traffic of user k in scheduling period p
        %----------------------------------------------------------------------
        InterSat_UsrsTransPort  % Matrix, format "NumOfSelectedUsrs × scheInShot"
                                % InterSat_UsrsTransPort(idxOfMethod, k, p) is transported traffic of user k in scheduling period p
        %----------------------------------------------------------------------
        NumOfInvesUsrs  % Number of users in investigation area
        %----------------------------------------------------------------------
        OrderOfSelectedUsrs % Vector, length NumOfSelectedUsrs, stores user sequence after removeSat, first NumOfInvesUsrs are investigation area users
        %----------------------------------------------------------------------
        UsrsObj   % User class instances, instance array, from self.run(), length NumOfSelectedUsrs, first NumOfInvesUsrs are investigation area users
        %----------------------------------------------------------------------
        ServSatOfDiscrAreaCur   % From self.calcuSatServArea()
                                % Current step serving satellite ID for each triangle in investigation area, i.e., satellite service coverage
                                % Matrix, format "DiscrArea rows × DiscrArea columns"
                                % ServSatOfDiscrAreaCur(i, j) indicates the serving satellite ID for triangle at row i, column j                   
        %----------------------------------------------------------------------                        
        OrderOfServSatCur     % Current step serving satellite IDs
        %----------------------------------------------------------------------
        SatObj   % Satellite class instances
        %----------------------------------------------------------------------
        Usr2SatCur      % From self.calcuSatServArea()    
                        % Usr2SatCur(OrderOfSelectedUsrs(k),) indicates the serving satellite ID for user k in UsrsObj
        %-----------------------------
        TerrestrialDuplexing
        %% For plotting
        forPlot 
%                 CoordiTri
%                 factorOfDiscr
%                 rangeOfInves
%                 ifWrapAround
%                 wrapRange
%                 numOfMethods_BeamGenerate
%                 numOfMethods_BeamHopping
%                 NumOfSchePerShot
%                 stepOfSimuMove
         forWeb    
         % heightOfSat
         % intervalOfStep
         % totalSeconds
         % SatPosition
         % halfCone
         % userPostion Number of users * 2

    end
    
    methods (Access = public)  
        % Constructor
        function self = dataObj()

        end
        % Method signature

    end
end


