function [Channels, ChanName, ChanUnit,DescStr] = ReadFASTtext(FileName, delim, HeaderRows, NameLine, UnitsLine )
%[Channels, ChanName, ChanUnit] = ReadFASTtext(FileName)
% Author: Bonnie Jonkman, National Renewable Energy Laboratory
% (c) 2012, National Renewable Energy Laboratory
%
%  Edited for FAST v7.02.00b-bjj  22-Oct-2012
%
% Input:
%  FileName      - string: contains file name to open
% Optional Input:
%    delim      - the column delimiter, default is all whitespace
%    HeaderRows - the number of header rows in the file; default is 8
%    NameLine   - the line number containing the column names; default is
%                 max( HeaderRows - 1, 0);
%    UnitsLine  - the line number containing the column units; default is
%                 min( NameLine + 1, HeaderRows );
%
% Output:
%  Channels      - 2-D array: dimension 1 is time, dimension 2 is channel 
%  ChanName      - cell array containing names of output channels
%  ChanUnit      - cell array containing unit names of output channels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
LenName = 10;  % number of characters per channel name
LenUnit = 10;  % number of characters per unit name
DescStr = '';

switch nargin;
    case 1
        delim = '';
        HeaderRows = 8;
        NameLine   = 7;
        UnitsLine  = 8;
    case 2
        HeaderRows = 8;
        NameLine   = 7;
        UnitsLine  = 8;
    case 3
        NameLine   = max(HeaderRows - 1, 0);
        UnitsLine  = NameLine + 1;
    case 4
        UnitsLine  = NameLine + 1;
    case 5
    otherwise
        error('ReadFASTtext::Invalid number of inputs.')
end
              
if nargout < 3
    UnitsLine = 0;
    if nargout < 2
        NameLine = 0;
    end
end
    
if UnitsLine > HeaderRows
    UnitsLine = 0;
end

if NameLine > HeaderRows
    NameLine = 0;
end
    
     
fid = fopen(FileName);
if fid <= 0
    disp(['ReadFASTtext::Error ' int2str(fid) ' reading from file, "' FileName '"'] )
    Channels = [];
    ChanName = {};
    ChanUnit = {};
else    
    nCols1 = 0;
    nCols2 = 0;
    
    if UnitsLine == 0 && NameLine == 0
        fclose(fid);
        Channels = dlmread(FileName,delim,HeaderRows,0);
        nCols = size(Channels, 2);
    else
        for i = 1:HeaderRows
            line = fgetl(fid);

            if i == NameLine
                if isempty( delim )
                    ChanName = textscan( line, '%s' );  %all whitespace; consecutive whitespace is okay
                else
                    ChanName = textscan( line, '%s', 'delimiter', delim ); %consecutive delimiters are separate columns
                end
                ChanName = ChanName{1};                    
                nCols1 = length(ChanName);

            elseif i == UnitsLine
                if isempty( delim )
                    ChanUnit = textscan( line, '%s' );
                else
                    ChanUnit = textscan( line, '%s', 'delimiter', delim );
                end
                ChanUnit = ChanUnit{1};
                nCols2 = length(ChanUnit);
            elseif i == NameLine-2
                DescStr=line;
            end %if i

        end %for i
            
        if nCols1 ~= nCols2 && nCols1*nCols2 > 0
             disp( ['ReadFASTtext::Column names and units are different sizes in file, "' FileName '."']  );
        end 
        nCols = max( nCols1, nCols2 );
        
        if ~exist('ChanUnit','var')
            ChanUnit = cell(1,nCols);
        end

        fmtStr = repmat('%f',1,nCols);
        if isempty( delim )
           Channels = cell2mat( textscan( fid, fmtStr ) );
        else
           Channels = cell2mat( textscan( line, fmtStr, 'delimiter', delim ) );
        end

        fclose(fid);

    end %UnitsLine == 0 && NameLine == 0

    if nargout > 1
      if nCols < nCols1
         ChanName(nCols+1:end) = cell(nCols1-nCols,1);
      end

      if nargout > 2
         if nCols < nCols2
            ChanUnit(nCOls+1:end) = cell(nCols2-nCols,1);
         end
      end
    end

end


return;

