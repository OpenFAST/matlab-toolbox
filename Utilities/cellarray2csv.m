function cellarray2csv(csvName, M, replaceFunction)
% Write a cell array to a csv file.
% This is used to replace the xlswrite call that is not availbale with Octave.
% INPUTS:
%    csvName        : filename to write
%    M              : cell array as returned for instance by (campbell_diagram_data()).ModesTable
%    replaceFunction: (optional) function to perform substitutions in mode description

% --- Optional arguments
if ~exist('replaceFunction', 'var'); replaceFunction=@(x)x; end;

fid = fopen(csvName, 'w');
for i = 1:size(M,1)
    for j = 1:size(M,2)
        if isnumeric(M{i,j})
            fprintf(fid,'%f',M{i,j})
        elseif ischar(M{i,j})
            s=M{i,j};
            s=replaceFunction(s);
            s=strrep(s,',',' '); % no matter what, we don't want commas in a csv file
            fprintf(fid,'%s',s)
        elseif islogical(M{i,j})
            fprintf(fid,'%d',M{i,j})
        else
            keyboard
            error('TODO, find out this datatype and adapt this function')
        end
        if j<size(M,2)
            fprintf(fid,',')
        end
    end
    fprintf(fid,'\n');
end
fclose(fid);
