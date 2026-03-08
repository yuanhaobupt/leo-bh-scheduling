% Control Class for simulation platform operation, This is a core Class
% All simulation modules run in Methods attached to this Class
%%
classdef simController < handle % Handle class
%% Whether to enable debug mode
    properties
        ifDebug      
    end
%% Constructor input parameters
    properties (Access = public) 
        Config  % Platform input configuration parameters     
    end
%% Constant configuration    
    properties (Access = public) 
    %-----------------------------------------------------------------------------------------------------
        numOfUsrs_inves             % Number of users in investigation area
    %-----------------------------------------------------------------------------------------------------
        numOfUsrs_all               % Total number of users when considering wrapAround
    %-----------------------------------------------------------------------------------------------------
        numOfUsrs_selected          % Number of users after removeSomeSat() when considering wrapAround
    %-----------------------------------------------------------------------------------------------------
        numOfMethods_BeamGenerate   % Number of imported beam footprint generation methods
    %-----------------------------------------------------------------------------------------------------
        numOfMethods_BeamHopping    % Number of imported beam hopping scheduling methods
    %-----------------------------------------------------------------------------------------------------
        vOfray          % (double) Speed of light (m/s)
    %-----------------------------------------------------------------------------------------------------    
        rOfearth        % (double) Earth radius (m)
    %-----------------------------------------------------------------------------------------------------        
        slotInSubF      % Number of time slots per subframe
    %-----------------------------------------------------------------------------------------------------            
        timeInSlot      % Duration of each time slot (s)
    %-----------------------------------------------------------------------------------------------------
        slotInShot      % Number of time slots per snapshot
    %-----------------------------------------------------------------------------------------------------
        subFInShot      % Number of subframes per snapshot
    %-----------------------------------------------------------------------------------------------------
        subFInSche      % Number of subframes per beam hopping schedule
    %-----------------------------------------------------------------------------------------------------
        scheInShot      % Number of beam hopping schedules per snapshot
    %-----------------------------------------------------------------------------------------------------
        aglOfServb      % Service beam 3dB opening angle (rad)
    %-----------------------------------------------------------------------------------------------------
        SatPosition     % Matrix, format "Number of satellites × Total simulation steps × 2"
                        % This is a satellite coordinate data matrix exported from STK and built into the platform,
                        % mapped according to rules determined by input configuration
                        % First dimension indicates satellite ID, second dimension indicates time sequence,
                        % third dimension indicates longitude and latitude coordinates
                        % SatPosition(k,s,1) indicates longitude coordinate of satellite k at simulation step s
                        % SatPosition(k,s,2) indicates latitude coordinate of satellite k at simulation step s
    %-----------------------------------------------------------------------------------------------------
        wrapRange       % From self.findWrap()
                        % Matrix, format "2×2"
                        % Stores the area after wrapAround expansion of investigation area
                        % [High latitude edge starting longitude, High latitude edge ending longitude
                        %  Starting latitude, Ending latitude]
    %-----------------------------------------------------------------------------------------------------
        DiscrArea       % From self.DiscrInvesArea(), stores coordinates of each discrete triangle center after area discretization
                        % Matrix, format "Total area rows × Total area columns × 2"
                        % First dimension indicates row number in area, second dimension indicates column number in area,
                        % third dimension indicates longitude and latitude coordinates
                        % DiscrArea(i,j,1) indicates longitude of triangle at row i, column j
                        % DiscrArea(i,j,2) indicates latitude of triangle at row i, column j
                        % The triangle at top-left corner of area is a upward-pointing triangle
    %-----------------------------------------------------------------------------------------------------
        SeqDiscrInNonWrap   % From self.getDiscrInNonWrap(), stores sequence numbers of discrete triangles in core investigation area under WarpAround
                            % Vector, length "Total number of triangles in investigation area"
                            % SeqDiscrInNonWrap(k) indicates the corresponding sequence number of triangle k in investigation area
                            % in the larger area including WrapAround
    %-----------------------------------------------------------------------------------------------------                         
        NofRawsInNonWrap    % From self.getDiscrInNonWrap()
                            % Indicates total number of rows in core investigation area
    %-----------------------------------------------------------------------------------------------------                         
        NofColsInNonWrap    % From self.getDiscrInNonWrap()
                            % Indicates total number of columns in core investigation area
    %-----------------------------------------------------------------------------------------------------                    
        SeqDiscrArea    % From self.DiscrInvesArea(), stores coordinates of each discrete triangle center after (wrapAround expanded) area discretization
                        % Matrix, format "Total number of triangles × 2"
                        % First dimension indicates triangle sequence number (by column), second dimension indicates longitude and latitude coordinates
                        % SeqDiscrArea(k,1) indicates center longitude coordinate of triangle k
                        % SeqDiscrArea(k,2) indicates center latitude coordinate of triangle k
    %-----------------------------------------------------------------------------------------------------
        CoordiTri       % From self.getTriCoord(), stores coordinates of each discrete triangle vertex after area discretization
                        % Matrix, format "Total number of triangles × Number of vertices per triangle 3 × Vertex coordinates 2"
                        % First dimension indicates triangle sequence number (by column), second dimension indicates vertex number,
                        % third dimension indicates longitude and latitude coordinates
                        % CoordiTri(k,n,1) indicates longitude coordinate of vertex n of triangle k
                        % CoordiTri(k,n,2) indicates latitude coordinate of vertex n of triangle k
                        %      Vertex 1           Vertex 2    Vertex 3
                        % Vertex 2    Vertex 3          Vertex 1
    %-----------------------------------------------------------------------------------------------------
        signalOfArea    % From self.getSignal(), stores signaling beam footprint center coordinates of current area
                        % Matrix, format "Number of signaling beam footprints × 4"
                        % signalOfArea(i,1) is longitude of signaling beam footprint center
                        % signalOfArea(i,2) is latitude of signaling beam footprint center
                        % signalOfArea(i,3) is sequence number of signaling beam footprint center triangle in Seq
                        % signalOfArea(i,4) is global original sequence number of signaling beam footprint
    %-----------------------------------------------------------------------------------------------------                    
        SignalOfDiscrArea    % From self.getSignal(), stores mapping from triangles to signaling beam footprints
                             % Matrix, format "Total area rows × Total area columns × 2"
                             % SignalOfDiscrArea(i, j, 1) indicates sequence number in signalOfArea of signaling beam footprint
                             %   to which triangle at row i, column j in DiscrArea belongs
                             % SignalOfDiscrArea(i, j, 2) indicates global original sequence number of signaling beam footprint
                             %   to which triangle at row i, column j in DiscrArea belongs
    %-----------------------------------------------------------------------------------------------------
        VisibleSat      % From self.calcuVisibleSat()
                        % NumOfSat × NumOfShot × 2 matrix, visible satellites
                        % VisibleSat(k, j, 1:2) indicates longitude and latitude coordinates of satellite k at step j,
                        % coordinates written as (500, 500) for invisible satellites
    %-----------------------------------------------------------------------------------------------------
        UsrsPosition    % From self.run() or self.getUsrsPositionInPossion()
                        % Matrix, format "Total number of users × 3"
                        % If wrapAround, first self.numOfUsrs_inves rows are users in investigation area, total self.numOfUsrs_all rows
                        % If not wrapAround, total self.numOfUsrs_inves rows
                        % UsrsPosition(k, 1) indicates longitude of user k
                        % UsrsPosition(k, 2) indicates latitude of user k
                        % UsrsPosition(k, 3) indicates sequence number of user k in SeqDiscrArea
    %-----------------------------------------------------------------------------------------------------
        InvesUsrsPosition   % From self.getUsrsPositionInPossion()
                            % Matrix, format "Number of users in investigation area × 3"
    %-----------------------------------------------------------------------------------------------------
        SelectedUsrsPosition    % From self.run()
                                % Matrix, format "Number of activated users after removeSomeSat × 3"
    %-----------------------------------------------------------------------------------------------------
        OrderOfSelectedUsrs     % Vector, length numOfUsrs_selected
                                % Stores user sequence after removeSat
    %-----------------------------------------------------------------------------------------------------
        Pt_dBm_BS;             % Base station transmit power, unit dBm

    end
%% Process variables 
    properties (Access = public) 
    %-----------------------------------------------------------------------------------------------------    
        UsrsObj   % User class instances, instance array, from self.run()
    %-----------------------------------------------------------------------------------------------------         
        ServSatOfDiscrAreaCur   % From self.calcuSatServArea()
                                % Current step serving satellite ID for each triangle in investigation area, i.e., satellite service coverage
                                % Matrix, format "DiscrArea rows × DiscrArea columns"
                                % ServSatOfDiscrAreaCur(i, j) indicates serving satellite ID for triangle at row i, column j
    %-----------------------------------------------------------------------------------------------------             
        OrderOfServSatCur     % Current step serving satellite IDs
    %-----------------------------------------------------------------------------------------------------
        SatObj   % Satellite class instances
    %-----------------------------------------------------------------------------------------------------    
        Usr2SatCur      % From self.calcuSatServArea()  
                        % Vector, length self.numOfUsrs_all
                        % Usr2SatCur(k) indicates serving satellite ID of user k
    %-----------------------------------------------------------------------------------------------------
        UsrsTraffic % Matrix, format "NumOfAllUsrs × (scheInShot+1)"
                    % UsrsTraffic(k, 1) is initial random traffic
                    % UsrsTraffic(k, 2)~UsrsTraffic(k,scheInShot+1) is newly generated traffic at beginning of each scheduling period
    %-----------------------------------------------------------------------------------------------------
        UsrsTransPort   % Matrix, format "NumOfAllUsrs × scheInShot"
                        % UsrsTransPort(idxOfMethod, k, p) is transported traffic of user k in scheduling period p
    %-----------------------------------------------------------------------------------------------------
        SigBeamMapptoSat    % Stores mapping between signalOfArea signaling beam footprint sequence numbers and SatObj satellite sequence numbers
                            % Format "NumOfSignalBeam × NumOfSat"
                            % SigBeamMapptoSat(i,j)=1 indicates signaling beam footprint i in signalOfArea belongs to satellite j in OrderOfServSatCur
    %-----------------------------------------------------------------------------------------------------
        UsrMapptoSig        % Stores mapping between numOfUsrs_selected user sequence numbers and signalOfArea signaling beam footprint sequence numbers
    %-----------------------------------------------------------------------------------------------------
        NeighborAdjaMatrix  % Adjacency matrix of serving satellites
    %-----------------------------------------------------------------------------------------------------    
        BS_invArea  % Base station coverage area longitude and latitude range coordinates storage
    %----------------------------------------------------------------------------------------------------
        BS_array  % Base station array stored by row and column
    end
%% Public methods    
    methods (Access = public)
        %% Construct function signature and constructor
        function self = simController( ...
                                Config, ...
                                numOfMethods_BeamGenerate, ...
                                numOfMethods_BeamHopping, ...
                                ifDebug ...
                            ) % Constructor
            if nargin == 0
            %% No input parameters
                error('Input must be in existence！')  % Throw error message
            elseif nargin > 0
            %% With input parameters
                %% Whether to enable debug
                self.ifDebug = ifDebug;
                %% Import input configuration parameters
                self.Config = Config;
                self.numOfMethods_BeamGenerate = numOfMethods_BeamGenerate;
                self.numOfMethods_BeamHopping = numOfMethods_BeamHopping;
                %% Determine constants
                self.vOfray = 3e8; % m/s
                self.rOfearth = 6371.393e3; % m
                path = pwd;
                % Use 5400 for satellite network
                name = '\5400.mat';
                % Use 1800 for thesis project
%                 name = '\1800.mat';
                load([path, name],'LLAresult');   % Data LLAresult format is "Total number of satellites × Total simulation steps × Longitude and latitude"
                TofCircle = round(2*pi*sqrt(((self.rOfearth+Config.height)^3)/(6.67259e-11*5.965e24)));
                if Config.time == 0   % If simulation total duration parameter is set to 0
                    self.SatPosition = LLAresult(:, 1:Config.step:TofCircle+Config.step+1, :);  % Satellite network 508km LEO orbital period is 5682.7s, period approximately 5683s  
                else
                    self.SatPosition = LLAresult(:, 1:Config.step:Config.time+1, :);    % Simulation time period is actually 0:step:TotalTime(s)
                end
                if self.ifDebug == true
                    fprintf('Built-in STK satellite data has been imported!\n');
                end
            end 
        end 
        %% Methods signature
        DataObj = run(self) % Run main simulation program
        findWrap(self); % WrapAround
        DiscrInvesArea(self) % Get discrete triangle center point coordinates  
        getTriCoord(self) % Get discrete triangle vertex coordinates
        getDiscrInNonWrap(self) % Get mapping between investigation area sequence numbers and larger area including WrapAround
        getSignal(self) % Get signaling beam footprints
        calcuVisibleSat(self) % Calculate all visible satellites in current area
        getUsrsPositionInPossion(self) % Calculate user positions when using Poisson point process sampling
        calcuSatServArea(self, OrderOfVisibleSat, IdxOfStep, MC_idx) % Calculate visible satellite service coverage in investigation area and determine user assignments
        getNeighborSat(self, IdxOfStep, MC_idx)
        getSignalOfSat(self, IdxOfStep, MC_idx)
        removeSomeSat(self, IdxOfStep, MC_idx)
        DataObj = calcuInterference(self, DataObj, IdxOfStep, MC_idx)
        getBeamPoint(self, slotIdx,MethodIdx)
        delSatObj(self)
        generateBS(self)  % Generate base station location array
        DataObj = calcuSatGroundInterference(self, DataObj, IdxOfStep, MC_idx) % Calculate satellite-ground co-frequency interference
        ID = findClosestBS(self,usrspos) % Find base station location index closest to selected user coordinates

        DataObj = calcuInterferenceForDiffBand(self, DataObj, IdxOfStep, MC_idx)% Interference calculation when each user occupies different frequency band
    end    
end
