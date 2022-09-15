function [ CheckSum_res ] = CheckSum(message)
%CHECKSUM Summary of this function goes here
%   Detailed explanation goes here
sum=256;

for i=1:1:length(message)
    sum=sum-message(i);
   if(sum<0)
       sum=sum+256;
   end
end

a1=bitand(sum,hex2dec('F0'));
a1=bitsra(a1,4);
a2=bitand(sum,hex2dec('0F'));
a1=dec2hex(a1);
a2=dec2hex(a2);

CheckSum_res=[a1 a2];

end

