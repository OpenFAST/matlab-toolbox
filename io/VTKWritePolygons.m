function [ filename ] = VTKWritePolygons(filename, header, Points, Polys, varargin)
    % --------------------------------------------------------------------------------
    % --- Default arguments 
    % --------------------------------------------------------------------------------
    if ~exist('filename','var'); filename = 'test_polys.vtk'; end
    if ~exist('header', 'var');  header = 'Polys data written by Matlab Toolbox'; end
    if ~exist('Points' ,'var');  Points   = eye(3,3); end
    if ~exist('Polys' ,'var');  Polys  = [[1 2 3 3];[2 3 1 1]]; end
    bBinary  = false; % TODO
    

    % --------------------------------------------------------------------------------
    % --- Safety checks on inputs 
    % --------------------------------------------------------------------------------
    if size(Points,1)~=3 ; Points=Points'; end % transposing input if required
    np = size(Points,2);
    nl = size(Polys,1);

    % --------------------------------------------------------------------------------
    % --- Header coordinates 
    % --------------------------------------------------------------------------------
    fid=fopen(filename,'w');
    fprintf(fid,'# vtk DataFile Version 2.0\n');
    fprintf(fid, '%s\n', header); % header
    if bBinary
        fprintf(fid, 'BINARY\n');
    else
        fprintf(fid, 'ASCII\n');
    end
    fprintf(fid, 'DATASET POLYDATA\n');
    % --------------------------------------------------------------------------------
    % --- Point coordinates 
    % --------------------------------------------------------------------------------
    fprintf(fid, 'POINTS %d float\n',np);
    if bBinary
        fwrite(fid, Points,'float','b');
    else
        fprintf(fid, '%.15e %.15e %.15e\n', Points);
        %fprintf(fid,'%f\t%f\t%f\n',Points(:,1:3)');
        fprintf(fid,'\n');
    end

    L = zeros(nl,size(Polys,2)+1);
    L(:,1)     = 4    ; % TODO just for segments here
    L(:,2:end) = Polys;

    fprintf(fid,'POLYGONS %d %d\n',nl, size(L,1) * size(L,2));
    fclose(fid);
    dlmwrite(filename, L ,'delimiter',' ','-append');


    % See VTKWritePolydataPoints for CELL_DATA and POINT_DATA dlmwrite might be eaiser to use.
end


