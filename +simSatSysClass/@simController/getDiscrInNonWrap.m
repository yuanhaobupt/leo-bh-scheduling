% inwrapAround
%%
function getDiscrInNonWrap(self)
 left_up_Tri = [self.Config.rangeOfInves(1,1), self.Config.rangeOfInves(2,2)];
 left_down_Tri = [self.Config.rangeOfInves(1,1), self.Config.rangeOfInves(2,1)];
 right_up_Tri = [self.Config.rangeOfInves(1,2), self.Config.rangeOfInves(2,2)];
% right_down_Tri = [self.Config.rangeOfInves(1,2), self.Config.rangeOfInves(2,1)];
 [raw_up,colu_left_up,dire_left_up] = tools.findPointXY(self,left_up_Tri(2),left_up_Tri(1));
 [raw_down,~,~] = tools.findPointXY(self,left_down_Tri(2),left_down_Tri(1));
 [~,colu_right_up,~] = tools.findPointXY(self,right_up_Tri(2),right_up_Tri(1));
% [row_right_down,colu_right_down,dire_right_down] = tool.findPointXY(self,right_down_Tri(2),right_down_Tri(1));
 
 if dire_left_up == 0 
 colu_left_up = colu_left_up + 1; % first
 end

 FirstXY = [raw_up, colu_left_up];
% LastXYInFirstColu = [raw_down, colu_left_up];

 NofRaws = length(self.DiscrArea(:,1,1));
% NofColus = length(self.DiscrArea(1,:,1));
 self.NofRawsInNonWrap = raw_down-raw_up+1;
 self.NofColsInNonWrap = colu_right_up-colu_left_up+1;
 NumOfTri = self.NofRawsInNonWrap*self.NofColsInNonWrap;
 SeqDiscrInNonWrap = zeros(1, NumOfTri);
 for k = 1 : NumOfTri
 SeqDiscrInNonWrap(k) = ...
 (FirstXY(2)-1+floor(k/self.NofRawsInNonWrap))*NofRaws + ...
 FirstXY(1)-1+mod(k,self.NofRawsInNonWrap);
 end
 self.SeqDiscrInNonWrap = SeqDiscrInNonWrap;



end

