% Scheduling related Class
% Used to indirectly mount modules including traffic generation, beam footprint formation, beam scheduling, signaling polling that dynamically change under certain simulation spatial states
% The above data is transferred to the core class @simController through this class
%%
classdef schedulerObj < handle

    properties (Access = public)  
        interface
    end
    
    methods (...
            Access = public,...         % Public methods
            Static = false...           % Non-static methods
            )% Constructor
        function self = schedulerObj()
            
        end
        getinterface(self, interface)
        generateUsrsTraffic(self)
        generateBeamFoot(self)
        generateBHST(self, IdxOfStep, NumOfShot)
        generateSigSpan(self)

        % Get users accessed in current scheduling period
        getCurUsers(self, sche)

        judgeEdgeUsr(self)

        adjustBHST(self)

        % Inter-beam power allocation
        generateBeamPower(self, IdxOfStep, NumOfShot)

        % Band and power allocation
        generateBPAllocation(self, IdxOfStep, NumOfShot)
    end
end

