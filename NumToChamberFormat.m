function [td] = NumToChamberFormat( Cont_temp )
%INTTOCHAMBERFORMAT Summary of this function goes here
%   Detailed explanation goes here

x=sprintf('%03d',fix(Cont_temp));
y=sprintf('%.1f',Cont_temp);
td=[x '.' y(end)];

if(Cont_temp<0 && Cont_temp>-1)
    td=['-' td(2:end)];
end

end

