function [ Hum ] = ReadHum(s)
%READTEMP Summary of this function goes here
%   Detailed explanation goes here

fwrite(s,[char(2),char('1?8E'),char(3)]);
A = fread(s,57);
B = char(A)';
Hum=str2num(B(10:14));

end