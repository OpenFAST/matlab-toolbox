function [] = writeUniformHAWCwind(timeseries,RootName)
%% writeUniformHAWCwind(timeseries,RootName)
% 11-Apr-2018   B. Jonkman, Envision Energy 
%
% Inputs:
%   timeseries: either a single time series or a matrix containing up to 3
%               time series (in u-v-w order). 
%   RootName:   root name of the hawc-format wind files to be
%               generated. Generated files will be called
%               {RootName}-[u|v|w].bin
% Outputs:
%   No outputs will be returned from this function, but three files will be
%   generated with two points in the y and z directions and the number of 
%   values contained in the input time series for the x direction.
%
%  The u component will have the value of the first wind speed
%  removed, and this value should be added back in the htc file
% -------------------------------------------------------------------------


% create dimensions for the wind box:
nx = length(timeseries);
ny = 2;
nz = 2;

if nx ~= size(timeseries,2)
    timeseries = timeseries';
end
nc = size(timeseries,1);

fileNames = strcat(RootName, {'-u.bin','-v.bin','-w.bin'});
velocity_shift = [timeseries(1,1) 0 0];

%%
for i = 1:length(fileNames)

    UnWind = fopen(fileNames{i},'w');

    if i<=nc
        tmp = repmat( reshape(timeseries(i,:)-velocity_shift(i),1,1,nx), nz, ny, 1); 
    else
        tmp = zeros(nz,ny,nx);
    end
    fwrite( UnWind, tmp, 'float32' );

    fclose( UnWind );
end