function self = getCurLinkNRB(self)
 %-----------------------------------
 % NRB
 % SCS(kHz) BandWidth(MHz) 5 10 15 20 25 30 40 50 60 70 80 90 100 
 % 15 NRB 25 52 79 106 133 160 216 270 - - - - - 
 % 30 NRB 11 24 38 51 65 78 106 133 162 189 217 245 273
 % 60 NRB - 11 18 24 31 38 51 65 79 93 107 121 135
 % NRB
 % SCS(kHz) BandWidth(MHz) 50 100 200 400
 % 120 NRB 66 132 264 -
 % 240 NRB 32 66 132 264
 %-----------------------------------
 TABLE1 = [25, 52, 79, 106, 133, 160, 216, 270, 0, 0, 0, 0, 0; 
 11, 24, 38, 51, 65, 78, 106, 133, 162, 189, 217, 245, 273;
 0, 11, 18, 24, 31, 38, 51, 65, 79, 93, 107, 121, 135];
 TABLE2 = [66, 132, 264, 0;
 32, 66, 132, 264];

 switch self.SCS
 case 15
 conf1 = 1;
 switch self.BandWidth
 case 5
 conf2 = 1;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 10
 conf2 = 2;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 15
 conf2 = 3;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 20
 conf2 = 4;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 25
 conf2 = 5;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 30
 conf2 = 6;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 40
 conf2 = 7;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 50
 conf2 = 8;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 60
 conf2 = 9;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 70
 conf2 = 10;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 80
 conf2 = 11;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 90
 conf2 = 12;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 100
 conf2 = 13;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 otherwise
 error('3GPP bandwidth！')
 end
 case 30
 conf1 = 2;
 switch self.BandWidth
 case 5
 conf2 = 1;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 10
 conf2 = 2;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 15
 conf2 = 3;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 20
 conf2 = 4;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 25
 conf2 = 5;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 30
 conf2 = 6;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 40
 conf2 = 7;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 50
 conf2 = 8;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 60
 conf2 = 9;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 70
 conf2 = 10;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 80
 conf2 = 11;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 90
 conf2 = 12;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 100
 conf2 = 13;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 otherwise
 error('3GPP bandwidth！')
 end 
 case 60
 conf1 = 3;
 switch self.BandWidth
 case 5
 conf2 = 1;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 10
 conf2 = 2;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 15
 conf2 = 3;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 20
 conf2 = 4;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 25
 conf2 = 5;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 30
 conf2 = 6;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 40
 conf2 = 7;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 50
 conf2 = 8;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 60
 conf2 = 9;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 70
 conf2 = 10;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 80
 conf2 = 11;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 90
 conf2 = 12;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 case 100
 conf2 = 13;
 self.CurLinkNRB = TABLE1(conf1, conf2);
 otherwise
 error('3GPP bandwidth！')
 end 
 case 120
 conf1 = 1;
 switch self.BandWidth
 case 50
 conf2 = 1;
 self.CurLinkNRB = TABLE2(conf1, conf2);
 case 100
 conf2 = 2;
 self.CurLinkNRB = TABLE2(conf1, conf2);
 case 200
 conf2 = 3;
 self.CurLinkNRB = TABLE2(conf1, conf2);
 case 400
 conf2 = 4;
 self.CurLinkNRB = TABLE2(conf1, conf2);
 otherwise
 error('3GPP bandwidth！')
 end
 case 240
 conf1 = 2;
 switch self.BandWidth
 case 50
 conf2 = 1;
 self.CurLinkNRB = TABLE2(conf1, conf2);
 case 100
 conf2 = 2;
 self.CurLinkNRB = TABLE2(conf1, conf2);
 case 200
 conf2 = 3;
 self.CurLinkNRB = TABLE2(conf1, conf2);
 case 400
 conf2 = 4;
 self.CurLinkNRB = TABLE2(conf1, conf2);
 otherwise
 error('3GPP bandwidth！')
 end 
 otherwise
 error('Please enter subcarrier spacing compliant with 3GPP protocol!')
 end
end

