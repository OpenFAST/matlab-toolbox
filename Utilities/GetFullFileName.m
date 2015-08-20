function [fullFileName, wasRelative] = GetFullFileName( inFile, relDir )
% inFile is the name of the file to check, removing any quotes around the 
% file name.
% relDir is the path the file is relative to (if inFile isn't a absolute
%        path name)

fileName = textscan(inFile,'%q',1); % remove quotes if necessary
fileName = fileName{1}{1};

if (nargin < 2)
    relDir = cd;
end

if isempty(fileName) || strcmpi(fileName,'unused')
%   fullFileName = '"unused"';
   fullFileName = '';
   wasRelative = false;
else   
      % is this a relative dir?
   if ( isempty(strfind( fileName, ':/'    )) && ...   % No drive is specified using ':/'
        isempty(strfind( fileName, ':\'    )) && ...   % No drive is specified using ':\'
        isempty(strfind( '/\', fileName(1) )) ) ...    % The file name doesn't start with '/' or '\'

    
        if isempty( relDir )
            relDir = '.';
        end
        fullFileName = strcat(relDir, filesep, fileName );
        wasRelative = true;
   else
        fullFileName = fileName;
        wasRelative = false;        
   end
    
end