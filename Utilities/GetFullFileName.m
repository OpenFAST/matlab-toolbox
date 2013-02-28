function [fullFileName] = getFullFileName( inFile, relDir )
% inFile is the name of the file to check
% relDir is the path the file is relative to (if inFile isn't a absolute
%        path name)

fileName = sscanf(inFile,'%q',1); % remove quotes if necessary
if (nargin < 2)
    relDir = cd;
end
disp(fileName)
if isempty(fileName) || strcmpi(fileName,'unused')
%   fullFileName = '"unused"';
   fullFileName = '';
else   
      % is this a relative dir?
   if ( isempty(strfind( fileName, ':/'    )) && ...   % No drive is specified using ':/'
        isempty(strfind( fileName, ':\'    )) && ...   % No drive is specified using ':\'
        isempty(strfind( '/\', fileName(1) )) ) ...    % The file name doesn't start with '/' or '\'

        fullFileName = strcat('"', relDir, filesep, fileName, '"');
   else
        fullFileName = strcat('"', fileName, '"');
   end
    
end