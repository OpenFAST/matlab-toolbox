function [p] = ReadIfWpoints(fileName)

data = dlmread(fileName,'',5,0);

t0 = data(1,1); %first time in the file
np = sum( data(:,1)==t0 ); % number of points in the file

nt = size(data,1) / np; % number of times in the file

p.t=data(1:np:end,1);
p.U = zeros(nt,np);
p.V = p.U;
p.W = p.U;
for i=1:np
    p.XYZ{i}=data(i,2:4);
    p.U(:,i)=data(i:np:end,5);
    p.V(:,i)=data(i:np:end,6);
    p.W(:,i)=data(i:np:end,7);
end



