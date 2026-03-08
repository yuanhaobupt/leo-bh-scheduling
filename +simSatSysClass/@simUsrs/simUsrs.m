%%
classdef ( ...
 Abstract = false,... % is
 ConstructOnLoad = true,... % 
 HandleCompatible = false,... % value 
 Sealed = false... % 
 ) simUsrs
%% 
 properties
 position % position
 ordOfDiscr % inSeqDiscrArea ID/number
 homeSat % satellite
 homeSig % beam positioninsignalOfArea ID/number
 
% measureSINR
 SCS % subcarrierinterval（kHz）

 BandWidth % to bandwidth（MHz）
 Band %to ，1*2array（MHz）
% Power
 PowerPercent % power 

 SlotInSche % scheduling time slot
 timeInSlot % time slot duration（s）

 CurLinkRate % When（bps）
 CurLinkNRB % Whenslot（beam）transmissionNRB

 Buffer % totaltraffic（bit）,vector，lengthas/is schedulingnumber
 GenerTraffic % WhenGeneratetraffic（bit）,vector，lengthas/is schedulingnumber
 TransTraffic % Whenschedulingtransmissiontraffic（bit）,vector，lengthas/is schedulingnumber

 Pt_dBm % dBm
 T_noise % K
 F_noise % dB
 end
%% 
 methods
 function self = simUsrs()
 %SIMUSRS

% self.BandWidth = BandWidth;
% self.SCS = SCS;
 end
 getCurLinkRate(self, measureSINR) % When（Calculate）
 self = getCurLinkNRB(self) % WhentransmissionNRB（ total,slot）
% getCurTransRB(self)
 
 end
end

