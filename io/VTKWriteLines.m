function [ filename ] = VTKWriteLines(filename, header, Points, Lines, varargin)
    % --------------------------------------------------------------------------------
    % --- Default arguments 
    % --------------------------------------------------------------------------------
    if ~exist('filename','var'); filename = 'test_lines.vtk'; end
    if ~exist('header', 'var');  header = 'Lines data written by Matlab Toolbox'; end
    if ~exist('Points' ,'var');  Points   = eye(3,3); end
    if ~exist('Lines' ,'var');  Lines  = [[1 2];[2 3]]; end
    bBinary  = false; % TODO
    

    % --------------------------------------------------------------------------------
    % --- Safety checks on inputs 
    % --------------------------------------------------------------------------------
    if size(Points,1)~=3 ; Points=Points'; end % transposing input if required
    np = size(Points,2);
    nl = size(Lines,1);

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

    L = zeros(nl,size(Lines,2)+1);
    L(:,1)     = 2    ; % TODO just for segments here
    L(:,2:end) = Lines;

    fprintf(fid,'LINES %d %d\n',nl, size(L,1) * size(L,2));
    fprintf(fid,'%d\t%d\t%d\n',L'); % TODO just for segments here..
    fprintf(fid,'\n');
    %dlmwrite(filename, L ,'delimiter',' ','-append');


% 
%     fprintf(fid,'CELL_DATA %d\n',nl);
%     fprintf(fid,'SCALARS SegIntensity float\n');
%     fprintf(fid,'LOOKUP_TABLE default\n');
%     fprintf(fid,'%f\n',Values);
%     fprintf(fid,'\n');

    % --------------------------------------------------------------------------------
    % ---  Point data
    % --------------------------------------------------------------------------------
%     if ~isempty(varargin)
% 
%         fprintf(fid, '\nPOINT_DATA %d\n',np);
% 
%         bLookupWritten=false;
%         %  looping on pair of values 'varname',var
%         for iv=1:floor(length(varargin)/2)
%             varname = varargin{2*iv-1};
%             M       = varargin{2*iv}  ;
% 
%             % --- Detecting scalar/vector and transposing if necessary
%             if length(size(M))==1
%                 bScalar=true;
%             elseif length(size(M))>2
%                 error('Can''t export variables of dimensions above 3')
%             elseif size(M,1)==1 || size(M,2)==1
%                 bScalar=true;
%             else
%                 bScalar=false;
%                 if size(M,1)~=3
%                     M=M'; % transposition required
%                 end
%             end
%             if bScalar
%                 fprintf(fid,'\nSCALARS %s float\n',varname);
%                 if ~bLookupWritten
%                     fprintf(fid,'LOOKUP_TABLE default\n');
%                 end
%                 bLookupWritten=true;
%                 if bBinary
%                     fwrite(fid, M,'float','b');
%                 else
%                     fprintf(fid, '%.15e\n', M);
%                 end
%             else
%                 fprintf(fid,'\nVECTORS %s float\n',varname);
%                 if ~bLookupWritten
% %                     fprintf(fid,'LOOKUP_TABLE default\n');
%                 end
%                 bLookupWritten=true;
%                 if bBinary
%                     fwrite(fid, M,'float','b');
%                 else
%                     fprintf(fid, '%.15e %.15e %.15e\n', M);
%                 end
%             end
%         end
%     end
% 
% 
% 
%     fclose(fid);
end

