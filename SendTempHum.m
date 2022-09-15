function [  ] = SendTempHum(s, Cont_temp,Cont_Hum)
%SENDTEMP Summary of this function goes here
%   Detailed explanation goes here
td=NumToChamberFormat(Cont_temp);                        % Number to XXX.X string format
hd=NumToChamberFormat(Cont_Hum);                         % Number to XXX.X string format

% message=[char(2),'1T',td,'F00R1100000000000000'];
message=[char(2),'1T',td,'F',hd,'R1100000000000000'];
CKS=CheckSum(message);                                   % Checksum of the message from start to Checksum

fwrite(s,[char(2),message,CKS,char(3)]);
X=fread(s,6);

end

