function [HAWCData, velocity] = readfile_HAWCwind(fileNames, nz, ny, nx)
% input:
%  fileNames - either (1) a cell array with the names of the U, V, and W wind files or 
%                     (2) a string containing the root name, which will
%                         have '.u-bin', '.v-bin', or '.w-bin' extensions added
%  nz - number of vertical points on the turbulence grid
%  ny - number of lateral points on the turbulence grid
%  nx - number of along-wind points (number of time steps) 
% output:
%   HAWCData - 4D array of velocities in order of [Z,Y,Component,time]
%   velocity - 4D array of velocities in order of [time,Component,Y,Z]
%   (Component is 1=U (along X), 2=V (along Y), 3=W (along Z, opposite gravity))

% fileNames = cell array of size 3, which contains the 3 wind file names

if nargin<1
    fileNames='C:\Users\bjonkman\Documents\Data\Software\Testing\BladedWindTimeHistories\IfW_Driver\tw06_80hh_s200.IfW.IfW-HAWC-';
    nx = 8192;
    ny = 26;
    nz = 32;
end

if ~iscell(fileNames)
    fileNames = strcat(fileNames, {'u.bin','v.bin','w.bin'});
%     fileNames = strcat(fileNames, {'.u-bin','.v-bin','.w-bin'});
end

%%
    HAWCData = zeros(nz,ny,length(fileNames),nx);
    
    for i = 1:length(fileNames)

        UnWind = fopen(fileNames{i});
        tmp = fread( UnWind, nz*ny*nx, 'float32' );
        tmp = reshape(tmp, nz,ny,nx); 
        
        HAWCData(:,:,i,:) = tmp(:, ny:-1:1, :);
%         for ix = 1:nx
%             for iy = ny:-1:1
%                HAWCData(:,iy,i,ix) = fread(UnWind, nz, 'float32');
%                indx = indx + nz;
%             end
%         end

        if nargout > 1
            for ix = 1:nx
                for iy = ny:-1:1
                   velocity(ix,i,iy,:) = HAWCData(:,iy,i,ix);
                end
            end        
        end
        
        fclose( UnWind );
    end
