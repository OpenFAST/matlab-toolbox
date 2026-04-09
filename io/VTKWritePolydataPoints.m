function VTKWritePolydataPoints(filename, header, Points, varargin )
    % Write points data to VTK file
    % 
    % INPUTS:
    %  - P: Points, preferably (3 x n), otherwise (n x 3) will be transposed
    %  - varargin: 
    %      - lists of pair arguments  'varname',var  where vart is scalar (1xn) or vector (3xn)
    %
    % --------------------------------------------------------------------------------
    % --- Default arguments 
    % --------------------------------------------------------------------------------
    if ~exist('filename','var'); filename = 'test_poly.vtk'; end
    if ~exist('header', 'var');  header = 'PolyData written by Matlab Toolbox'; end
    if ~exist('Points' ,'var');  Points   = eye(3,3); end
    bBinary  = false; % TODO

    % --------------------------------------------------------------------------------
    % --- Safety checks on inputs 
    % --------------------------------------------------------------------------------
    if size(Points,1)~=3 ; Points=Points'; end % transposing input if required
    np=size(Points,2);


    % --------------------------------------------------------------------------------
    % --- Header coordinates 
    % --------------------------------------------------------------------------------
    fid = fopen(filename, 'w'); 
    fprintf(fid, '# vtk DataFile Version 2.0\n');
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
    end
    %dlmwrite(filename, Points,'delimiter',' ','-append');

    % --------------------------------------------------------------------------------
    % ---  Point data
    % --------------------------------------------------------------------------------
    if ~isempty(varargin)

        fprintf(fid, '\nPOINT_DATA %d\n',np);

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
%                 dlmwrite(filename, [ upper(mesh.attributes(j).attribute) ' ' mesh.attributes(j).name ' ' mesh.attributes(j).type ],'delimiter','','-append');
%                 dlmwrite(filename, [ 'LOOKUP_TABLE ' mesh.attributes(j).lookup_table ],'delimiter','','-append');
%                 dlmwrite(filename, mesh.attributes(j).attribute_array ,'delimiter','','-append');
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
%                  dlmwrite(filename, [ upper(mesh.attributes(j).attribute) ' FieldData ' num2str(nfielddatas) ],'delimiter','','-append');
%                  dlmwrite(filename, [ upper(mesh.attributes(j).attribute) '  ' mesh.attributes(j).name   ' ' mesh.attributes(j).type ],'delimiter','','-append');
%                  dlmwrite(filename, mesh.attributes(j).attribute_array ,'delimiter',' ','-append');



            end
        end
    end
    fclose(fid);
