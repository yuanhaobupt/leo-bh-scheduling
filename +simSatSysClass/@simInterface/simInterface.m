%%
classdef simInterface < handle % Handle class
 %SIMINTERFACE Interface class for beam hopping resource allocation algorithm design
 % This class provides all properties required by the interface
%% Interface properties
 properties (Access = public)
 Config % Configuration parameters

 UsrsObj % User class instance array
 NumOfAllUsrs % Number of users in full area
 NumOfSelectedUsrs % Number of users in wrap area + core area (same as NumOfInvesUsrs when not wrap)
 OrderOfSelectedUsrs % Stores user sequence after removeSat
 NumOfInvesUsrs % Number of users in core investigation area

 % New additions
 usersInLine % Format: Total scheduling periods * Maximum number of users
 % Each row is the users to be served in current scheduling period
 edgeUserLine % Format: Total scheduling periods * Maximum number of edge users
 SigBeamMapptoSat 
 UsrMapptoSig
 NeighborAdjaMatrix

 
 SatObj % Satellite class instance array
 OrderOfServSatCur % Current step serving satellite IDs

 SeqDiscrArea % Coordinates of each discrete triangle center after area discretization
 CoordiTri

 ScheInShot % Number of scheduling periods in one snapshot
 SlotInSche % Number of slots in one scheduling period
 timeInSlot % Duration of one slot (s)

 height % Satellite height (m)
 BandOfLink % Link bandwidth (MHz)
 freqOfDownLink % (Hz) Satellite downlink center frequency
 freqOfUpLink % (Hz) Satellite uplink center frequency
 SCS % (kHz) Subcarrier spacing

 numOfServbeam % Number of service beams
 numOfSigbeam % Number of signaling beams

 IsoAgl_Serv % Service beam isolation angle
 IsoAgl_Sig % Signaling beam isolation angle
 IsoAgl_ServAndSig % Service beam and signaling beam isolation angle

 numOfMethods_BeamGenerate % Number of imported beam footprint generation methods
 numOfMethods_BeamHopping % Number of imported beam hopping scheduling methods

 AngleOf3dB % Beam half-power beamwidth angle

 % New additions
 factorOfDiscr
 rowNum
 colNum
 ifWrapAround
 wrapRange
 rangeOfInves
 rowLon1

 bhTime % Duration of one scheduling period (s)
 diffTrafficUserRatio

 Pt_dBm_serv % Service beam total power

 ifDebug


 
 end
%% Process variables
 properties (Access = public)
 tmpSat % Structure array, length NumOfSat
 % Properties
 % NumOfBeamFoot, vector, length NumOfSche, stores number of beam footprints formed in each scheduling
 % beamfoot, structure matrix, format "NumOfSche × MAXNumOfBeamFoot"
 % Property position, matrix, stores current scheduling beam footprint center coordinates
 % Property usrs, vector, stores current scheduling beam footprint serving user indices
 % BHST, matrix, format "NumOfServBeam × SlotInShot"
 % Pt_Antenna, matrix, format "NumOfServBeam × SlotInShot", stores service beam power for each beam footprint in each time slot

 end
%% Output results 
 properties (Access = public)
 UsrsTraffic % Matrix, format "NumOfAllUsrs × (scheInShot+1)"
 % UsrsTraffic(k, 1) is initial random traffic
 % UsrsTraffic(k, 2)~UsrsTraffic(k,scheInShot+1) is newly generated traffic at beginning of each scheduling period

 UsrsTransPort % Matrix, format "NumOfMethod × NumOfAllUsrs × scheInShot"
 % UsrsTransPort(idxOfMethod, k, p) is transported traffic of user k in scheduling period p 
 tmp_UsrsTransPort % Matrix, format "NumOfAllUsrs × scheInShot"
 % UsrsTransPort(k, p) is transported traffic of user k in scheduling period p 

 tmpSat_0 % Stores "Imported beam footprint generation method 1"
 % Structure array, length NumOfSat
 % Properties are
 % NumOfBeamFoot, vector, length NumOfSche, stores number of beam footprints formed in each scheduling
 % beamfoot, structure matrix, format "NumOfSche × MAXNumOfBeamFoot"
 % Property position, matrix, stores current scheduling beam footprint center coordinates
 % Property usrs, vector, stores current scheduling beam footprint serving user indices
 % BHST_0, matrix, format "NumOfServBeam × SlotInShot", stores "Imported beam scheduling method 1"
 % BHST_1, stores "Imported beam scheduling method 2"
 % BHST_2, stores "Imported beam scheduling method 3"
 % BHST_3, stores "Imported beam scheduling method 4"
 % BHST_4, stores "Imported beam scheduling method 5"
 % Pt_Antenna_0, matrix, format "NumOfServBeam × SlotInShot", stores "Imported beam scheduling method 1"
 % Pt_Antenna_1, stores "Imported beam scheduling method 2"
 % Pt_Antenna_2, stores "Imported beam scheduling method 3"
 % Pt_Antenna_3, stores "Imported beam scheduling method 4"
 % Pt_Antenna_4, stores "Imported beam scheduling method 5"
 tmpSat_1 % Stores "Imported beam footprint generation method 2"
 tmpSat_2 % Stores "Imported beam footprint generation method 3" 
 tmpSat_3 % Stores "Imported beam footprint generation method 4"
 tmpSat_4 % Stores "Imported beam footprint generation method 5"
 end
 properties (Access = public)
 UsrsTraffic % matrix，formatas/is“NumOfAllUsrs × (scheInShot+1)”
 % UsrsTraffic(k, 1)as
 % UsrsTraffic(k, 2)

 UsrsTransPort % matrix，formatas/is“NumOfMethod × NumOfAllUsrs × scheInShot”
 % UsrsTransPort(idxOfMethod, k, p)as
 tmp_UsrsTransPort % matrix，formatas/is“NumOfAllUsrs × scheInShot”
 % UsrsTransPort(k, p)as

 tmpSat_0 % “beam positionGenerate1”


 % NumOfBeamFoot
 % beamfoot


 % BHST
 % BHST
 % BHST
 % BHST
 % BHST
 % Pt
 % Pt
 % Pt
 % Pt
 % Pt
 tmpSat_1 % “beam positionGenerate2”
 tmpSat_2 % “beam positionGenerate3” 
 tmpSat_3 % “beam positionGenerate4”
 tmpSat_4 % “beam positionGenerate5”
 end
%% 
 methods
 function obj = simInterface(controller)
 %SIMINTERFACE Construct instance of this class
 % Detailed description here
 obj.ifDebug = controller.ifDebug;
 obj.Config = controller.Config;
 obj.SigBeamMapptoSat = controller.SigBeamMapptoSat; 
 obj.UsrMapptoSig = controller.UsrMapptoSig;
 obj.UsrsObj = controller.UsrsObj;
 obj.NumOfAllUsrs = controller.numOfUsrs_all;
 obj.NumOfSelectedUsrs = length(controller.SelectedUsrsPosition(:,3));
 obj.OrderOfSelectedUsrs = controller.OrderOfSelectedUsrs;
 obj.NumOfInvesUsrs = controller.numOfUsrs_inves;
 obj.SatObj = controller.SatObj;
 obj.OrderOfServSatCur = controller.OrderOfServSatCur;
 obj.SeqDiscrArea = controller.SeqDiscrArea;
 obj.CoordiTri = controller.CoordiTri;
 obj.ScheInShot = controller.scheInShot;
 obj.SlotInSche = controller.subFInSche * controller.slotInSubF;
 obj.timeInSlot = controller.timeInSlot;
 obj.bhTime = controller.Config.bhTime;
 obj.height = controller.Config.height;
 obj.BandOfLink = controller.Config.BandOfLink/1e6;
 obj.freqOfDownLink = controller.Config.freqOfDownLink;
 obj.freqOfUpLink = controller.Config.freqOfUpLink;
 obj.SCS = controller.Config.SCS/1e3;
 obj.numOfServbeam = controller.Config.numOfServbeam;
 obj.numOfSigbeam = controller.Config.numOfSigbeam;
% obj.IsoAgl_Serv = controller.Config.IsoAgl_Serv;
% obj.IsoAgl_Sig = controller.Config.IsoAgl_Sig;
% obj.IsoAgl_ServAndSig = controller.Config.IsoAgl_ServAndSig;
 obj.numOfMethods_BeamGenerate = controller.numOfMethods_BeamGenerate;
 obj.numOfMethods_BeamHopping = controller.numOfMethods_BeamHopping;
 obj.UsrsTraffic = zeros(obj.NumOfSelectedUsrs, obj.ScheInShot+1);
 obj.UsrsTransPort = zeros(obj.numOfMethods_BeamGenerate * obj.numOfMethods_BeamHopping, obj.NumOfSelectedUsrs, obj.ScheInShot);
 obj.tmp_UsrsTransPort = zeros(obj.NumOfSelectedUsrs, obj.ScheInShot);
 obj.NeighborAdjaMatrix = controller.NeighborAdjaMatrix;
 obj.diffTrafficUserRatio = controller.Config.diffTrafficUserRatio;
 obj.Pt_dBm_serv = controller.Config.Pt_dBm_serv;

 obj.tmpSat = struct( ...
 'NumOfBeamFoot', 0, ...
 'beamfoot', struct( ...
 'position', 0, ...
 'usrs', 0 ...
 ), ...
 'BHST', [], ...
 'Pt_Antenna', [] ...
 );
 obj.tmpSat_0 = struct( ...
 'NumOfBeamFoot', 0, ...
 'beamfoot', struct( ...
 'position', 0, ...
 'usrs', 0 ...
 ), ...
 'BHST_0', [], ...
 'BHST_1', [], ...
 'BHST_2', [], ...
 'BHST_3', [], ...
 'BHST_4', [], ...
 'Pt_Antenna_0', [], ...
 'Pt_Antenna_1', [], ...
 'Pt_Antenna_2', [], ...
 'Pt_Antenna_3', [], ...
 'Pt_Antenna_4', [] ...
 );
 obj.tmpSat_1 = struct( ...
 'NumOfBeamFoot', 0, ...
 'beamfoot', struct( ...
 'position', 0, ...
 'usrs', 0 ...
 ), ...
 'BHST_0', [], ...
 'BHST_1', [], ...
 'BHST_2', [], ...
 'BHST_3', [], ...
 'BHST_4', [], ...
 'Pt_Antenna_0', [], ...
 'Pt_Antenna_1', [], ...
 'Pt_Antenna_2', [], ...
 'Pt_Antenna_3', [], ...
 'Pt_Antenna_4', [] ...
 );
 obj.tmpSat_2 = struct( ...
 'NumOfBeamFoot', 0, ...
 'beamfoot', struct( ...
 'position', 0, ...
 'usrs', 0 ...
 ), ...
 'BHST_0', [], ...
 'BHST_1', [], ...
 'BHST_2', [], ...
 'BHST_3', [], ...
 'BHST_4', [], ...
 'Pt_Antenna_0', [], ...
 'Pt_Antenna_1', [], ...
 'Pt_Antenna_2', [], ...
 'Pt_Antenna_3', [], ...
 'Pt_Antenna_4', [] ...
 );
 obj.tmpSat_3 = struct( ...
 'NumOfBeamFoot', 0, ...
 'beamfoot', struct( ...
 'position', 0, ...
 'usrs', 0 ...
 ), ...
 'BHST_0', [], ...
 'BHST_1', [], ...
 'BHST_2', [], ...
 'BHST_3', [], ...
 'BHST_4', [], ...
 'Pt_Antenna_0', [], ...
 'Pt_Antenna_1', [], ...
 'Pt_Antenna_2', [], ...
 'Pt_Antenna_3', [], ...
 'Pt_Antenna_4', [] ...
 );
 obj.tmpSat_4 = struct( ...
 'NumOfBeamFoot', 0, ...
 'beamfoot', struct( ...
 'position', 0, ...
 'usrs', 0 ...
 ), ...
 'BHST_0', [], ...
 'BHST_1', [], ...
 'BHST_2', [], ...
 'BHST_3', [], ...
 'BHST_4', [], ...
 'Pt_Antenna_0', [], ...
 'Pt_Antenna_1', [], ...
 'Pt_Antenna_2', [], ...
 'Pt_Antenna_3', [], ...
 'Pt_Antenna_4', [] ...
 );
 %% Calculate satellite antenna 3dB opening angle
 obj.AngleOf3dB = tools.find3dBAgle(obj.freqOfDownLink);

 %% New additions
 obj.factorOfDiscr = controller.Config.factorOfDiscr;
 obj.rowNum = length(controller.DiscrArea(:,1,1));
 obj.colNum = length(controller.DiscrArea(1,:,1));
 obj.ifWrapAround = controller.Config.ifWrapAround;
 obj.wrapRange = controller.wrapRange;
 obj.rangeOfInves = controller.Config.rangeOfInves;
 obj.rowLon1 = controller.CoordiTri(obj.rowNum,:,1);

 end
 refreshValue(obj, controller)
 
 end
end

