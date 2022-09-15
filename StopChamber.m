function [ output_args ] = StopChamber(s)
%STOPCHAMBER Summary of this function goes here
%   Detailed explanation goes here
% td=NumToChamberFormat(Cont_temp);                        % Number to XXX.X string format

message=[char(2),'1T','025.0','F00R0000000000000000'];
CKS=CheckSum(message);                                   % Checksum of the message from start to Checksum

fwrite(s,[char(2),message,CKS,char(3)]);
X=fread(s,6);


end

