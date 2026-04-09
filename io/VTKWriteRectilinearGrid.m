function [ filename ] = VTKWriteRectilinearGrid(filename, header, vx, vy, vz, varargin)
    % --------------------------------------------------------------------------------
    % --- Default arguments 
    % --------------------------------------------------------------------------------
    if ~exist('filename','var'); filename = 'test_recti.vtk'; end
    if ~exist('header', 'var');  header = 'Rectilinear data written by Matlab Toolbox'; end
    if ~exist('vx' ,'var');  vx  = [0,1]; end
    if ~exist('vy' ,'var');  vy  = [0,2]; end
    if ~exist('vz' ,'var');  vz  = [0,3]; end


    % --------------------------------------------------------------------------------
    % --- Header coordinates 
    % --------------------------------------------------------------------------------
    fid = fopen(filename, 'w'); 
    fprintf(fid, '# vtk DataFile Version 2.0\n');
    fprintf(fid, '%s\n', header); % header
    fprintf(fid , 'ASCII\n'                      ) ; 
    fprintf(fid , '\n') ; 
    nx = length(vx);
    ny = length(vy);
    nz = length(vz);
    nP = nx *ny *nz;
    fprintf(fid,'DATASET RECTILINEAR_GRID\n') ;
    % --------------------------------------------------------------------------------
    % --- Point coordinates 
    % --------------------------------------------------------------------------------
    fprintf(fid,'DIMENSIONS %d %d %d\n', nx, ny, nz);
    fprintf(fid,'X_COORDINATES %d float\n',nx);
    fprintf(fid,'%f ', vx);
    fprintf(fid,'\n');
    fprintf(fid,'Y_COORDINATES %d float\n',ny);
    fprintf(fid,'%f ', vy);
    fprintf(fid,'\n');
    fprintf(fid,'Z_COORDINATES %d float\n',nz);
    fprintf(fid,'%f ', vz);
    fprintf(fid,'\n');

    % --------------------------------------------------------------------------------
    % ---  Point data
    % --------------------------------------------------------------------------------
    if ~isempty(varargin)

        fprintf(fid, '\nPOINT_DATA %d\n',nP);

        bLookupWritten=false;
        %  looping on pair of values 'varname',var
        for iv=1:floor(length(varargin)/2)
            varname = varargin{2*iv-1};
            M       = varargin{2*iv}  ;

            % --- Detecting scalar/vector and transposing if necessary
            if length(size(M))==1
                bScalar=true;
            elseif length(size(M))>2
                error('Can''t export variables of dimensions above 3')
            elseif size(M,1)==1 || size(M,2)==1
                bScalar=true;
            else
                bScalar=false;
                if size(M,1)~=3
                    M=M'; % transposition required
                end
            end
            if bScalar
                fprintf(fid,'\nSCALARS %s float\n',varname);
                if ~bLookupWritten
                    fprintf(fid,'LOOKUP_TABLE default\n');
                end
                bLookupWritten=true;
                if bBinary
                    fwrite(fid, M,'float','b');
                else
                    fprintf(fid, '%.15e\n', M);
                end
            else
                fprintf(fid,'\nVECTORS %s float\n',varname);
                if ~bLookupWritten
%                     fprintf(fid,'LOOKUP_TABLE default\n');
                end
                bLookupWritten=true;
                if bBinary
                    fwrite(fid, M,'float','b');
                else
                    fprintf(fid, '%.15e %.15e %.15e\n', M);
                end
            end
        end
    end
    fclose(fid);
end

