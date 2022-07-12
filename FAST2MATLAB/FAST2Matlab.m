function DataOut = FAST2Matlab(FST_file,hdrLines,DataOut)
%% Fast2Matlab
% DataOut = Fast2Matlab(FST_file,hdrLines,DataOut)
% Function for reading FAST input files in to a MATLAB struct.
%
%
%This function returns a structure DataOut, which contains the following 
% cell arrays:
%.Val              An array of values
%.Label            An array of matching labels
%.HdrLines         An array of the header lines (size specified at input)
%
% The following cell arrays may or may not be part of the DataOut structure
% (depending on the type of file being read):
%.OutList          An array of variables to output
%.OutListComments  An array of descriptions of the .OutList values
%
%.TowProp          A data structure of tower properties 
%
%.BldProp          A data structure of blade properties with columns .BldPropHdr
%
%.DLLProp          A data structure of properties for the Bladed DLL Interface with columns .DLLPropHdr
%
%.FoilNm           A data structure of foil names
%
%.BldNodes         A data structure of blade nodes with columns RNodes, AeroTwst DRNodes Chord and Nfoil
%
%.Cases            A data structure of properties for individual cases in a driver file
%
%.AFCoeff          A data structure of airfoil coefficients
%
%.TMDspProp        A data structure of TMD spring forces
%
%.PointLoads      A data structure of point loads in the BeamDyn driver input file
%
%.PrnElm           An array determining whether or not to print a given element
%
%.kp               A data structure of key points defined in BeamDyn
%
%.profile          A data structure of profile values defined in TurbSim
%
%.LineTypes        A data structure of line types and its properties
%
%.ConProp          A data structure of connection properties
%
%.LineProp         A data structure of blade properties
%--------------------------------------------------------------------------

%These arrays are extracted from the FAST input file
%
% In:   FST_file    -   Name of FAST input file
%       hdrLines    -   Number of lines to skip at the top (optional)
%
% Knud A. Kragh, May 2011, NREL, Boulder
%
% Modified by Paul Fleming, JUNE 2011
% Modified by Bonnie Jonkman, February 2013 (to allow us to read the 
% platform file, too)
% Modified by Paul Schünemann, July 2020 (to allow us to read MoorDyn files, too)
%%
if nargin < 2
    hdrLines = 0;
end

%----------------------Read FST main file----------------------------------
fid = fopen(FST_file,'r');

if fid == -1
    error(['FST file, ' FST_file ', could not be opened for reading. Check if the file exists or is locked.'])
end

%skip hdr
for hi = 1:hdrLines
    if nargin == 3
        fgetl(fid);
    else
        DataOut.HdrLines{hi,1} = fgetl(fid); %bjj: added field for storing header lines
    end
end

%PF: Commenting this out, not sure it's necessary
%DataOut.Sections=0;

%Loop through the file line by line, looking for value-label pairs
%Stop once we've reached the OutList which this function is the last
%occuring thing before the EOF
if nargin == 3
    
    count = max(length(DataOut.Label),length(DataOut.Val))+1;
else
    count = 1;
end
NextIsMatrix = 0;
matrixVal = [];
iOutList = 1;

while true %loop until discovering Outlist or end of file, than break
    
    line = fgetl(fid);
    if isnumeric(line) % we reached the end of the file\
        break
    end
    
        % Check to see if the value is Outlist or OUTPUTS (for MoorDyn)

    %if ~isempty(strfind(upper(line),upper('OutList'))) 
    if ~isempty(strfind( upper(line), upper('OutList') )) || (containstring(upper(line),upper('OUTPUTS')) && isfield(DataOut,'ConProp')) % The second statement is to detect the outlist of MoorDyn input files (Field ConProp will only exist when processing MoorDyn input files.)
        % 6/23/2016: linearization inputs contain "OutList" in the
        % comments, so we need to make sure this is either the first (value) or
        % second (label) word of the line.
        [value2, ~, ~, nextindex] = sscanf(line,'%s', 1); 
        [value3] = sscanf(line(nextindex+1:end),'%s', 1); 
        if strcmpi(value2,'OutList') || strcmpi(value2,'OUTPUTS') || strcmpi(value2,'OutListAD') || strcmpi(value3,'OutList') || strcmpi(value3,'OUTPUTS') || strcmpi(value3,'OutListAD')
            [DataOut.OutList{iOutList} DataOut.OutListComments{iOutList}] = ParseFASTOutList(fid);
            iOutList = iOutList + 1;
        end            
    end      

        
    [value, label, isComment, descr, fieldType] = ParseFASTInputLine( line );    
    

    if ~isComment
        
        if strcmpi(value,'"HtFract"') %we've reached the distributed tower properties table (and we think it's a string value so it's in quotes)
            NTwInpSt = GetFASTPar(DataOut,'NTwInpSt');        
            [DataOut.TowProp] = ParseFASTNumTable(line, fid, NTwInpSt);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"TwrElev"') %we've reached the distributed tower properties table (and we think it's a string value so it's in quotes)
            NumTwrNds = GetFASTPar(DataOut,'NumTwrNds');        
            [DataOut.TowProp] = ParseFASTNumTable(line, fid, NumTwrNds);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"BlFract"') %we've reached the distributed blade properties table (and we think it's a string value so it's in quotes)
            NBlInpSt = GetFASTPar(DataOut,'NBlInpSt');        
            [DataOut.BldProp] = ParseFASTNumTable(line, fid, NBlInpSt);
            continue; %let's continue reading the file
        elseif strcmpi(label,'F_X') %we've reached the TMD spring forces table
            NKInpSt = GetFASTPar(DataOut,'NKInpSt');        
            [DataOut.TMDspProp] = ParseFASTNumTable(line, fid, NKInpSt);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"GenSpd_TLU"') %we've reached the DLL torque-speed lookup table (and we think it's a string value so it's in quotes)
            DLL_NumTrq = GetFASTPar(DataOut,'DLL_NumTrq');        
            [DataOut.DLLProp] = ParseFASTNumTable(line, fid, DLL_NumTrq);
            continue; %let's continue reading the file
        elseif strcmpi(label,'FoilNm') %note NO quotes because it's a label
            NumFoil = GetFASTPar(DataOut,'NumFoil');
            [DataOut.FoilNm] = ParseFASTFileList( line, fid, NumFoil );
            continue; %let's continue reading the file  
        elseif strcmpi(label,'AFNames') %note NO quotes because it's a label
            NumFoil = GetFASTPar(DataOut,'NumAFfiles');
            [DataOut.FoilNm] = ParseFASTFileList( line, fid, NumFoil );
            continue; %let's continue reading the file  
        elseif strcmpi(value,'"RNodes"')
            BldNodes = GetFASTPar(DataOut,'BldNodes');  
            [DataOut.BldNodes] = ParseFASTFmtTable( line, fid, BldNodes, false );
            continue;
        elseif strcmpi(value,'"BlSpn"')
            NumBlNds = GetFASTPar(DataOut,'NumBlNds');  
            [DataOut.BldNode] = ParseFASTNumTable( line, fid, NumBlNds );
            continue;            
        elseif strcmpi(value,'"WndSpeed"') %we've reached the AD cases table (and we think it's a string value so it's in quotes)
            NumCases = GetFASTPar(DataOut,'NumCases');        
            [DataOut.Cases] = ParseFASTFmtTable(line, fid, NumCases);
            continue; %let's continue reading the file
        elseif strcmpi(label,'NumPointLoads') 
            DataOut.Label{count,1} = label;
            DataOut.Val{count,1}   = value;
            count = count + 1;
            
            NumPointLoads = value;
            line = fgetl(fid);  % the next line is the header, and it may have comments
            [DataOut.PointLoads] = ParseFASTNumTable(line, fid, NumPointLoads);
            continue; %let's continue reading the file            
            
        elseif strcmpi(label,'NumAlf')
            DataOut.Label{count,1} = label;
            DataOut.Val{count,1}   = value;
            count = count + 1;
            
            NumAlf = value;
            line = fgetl(fid);  % the next line is the header, and it may have comments
            line = line(2:end);
            [DataOut.AFCoeff] = ParseFASTNumTable(line, fid, NumAlf);
            continue; %let's continue reading the file            
        elseif strcmpi(label,'kp_yr') %we've reached the BD key-points table
            kp_total = GetFASTPar(DataOut,'kp_total');        
            [DataOut.kp] = ParseFASTNumTable(line, fid, kp_total);
            continue; %let's continue reading the file
        elseif strcmpi(label,'StdScale3') %we've reached the TurbSim profiles table
            DataOut.Label{count,1} = label;
            DataOut.Val{count,1}   = value;
            count = count + 1;
            
            NumUSRz = GetFASTPar(DataOut,'NumUSRz');        
            line = fgetl(fid);  % the next line is the header, and it may have comments
            [DataOut.profile] = ParseFASTNumTable(line, fid, NumUSRz, 2 );
            continue; %let's continue reading the file
            
        elseif strcmpi(value,'"Name"') %we've reached the MoorDyn line types table (and we think it's a string value so it's in quotes)
            NTypes = GetFASTPar(DataOut,'NTypes');  %get number of LineTypes
            [DataOut.LineTypes] = ParseFASTFmtTable( line, fid, NTypes, true ); %parse the MoorDyn line types table
            continue;   
        elseif strcmpi(value,'"Node"') %we've reached the MoorDyn connection properties table (and we think it's a string value so it's in quotes)
            NConnects = GetFASTPar(DataOut,'NConnects'); %get number of connections (incl. anchors and fairleads)
            [DataOut.ConPro] = ParseFASTFmtTable( line, fid, NConnects, true ); %parse the MoorDyn connection properties table
            continue;   
        elseif strcmpi(value,'"Line"') %we've reached the MoorDyn line properties table (and we think it's a string value so it's in quotes)
            NLines = GetFASTPar(DataOut,'NLines'); %get number of line objects  
            [DataOut.LineProp] = ParseFASTFmtTable( line, fid, NLines, true ); %parse the MoorDyn line properties table
            continue;               
            
        else         
            
            if NextIsMatrix > 0
                matrixVal = vertcat( matrixVal, value );
                NextIsMatrix = NextIsMatrix - 1;
                label = nextLabel;
                value = matrixVal;
            end
            
            if NextIsMatrix == 0
                DataOut.Label{count,1} = label;
                DataOut.Val{count,1}   = value;
                count = count + 1;
                matrixVal = [];
            end
            
            if strcmpi(label,'GlbPos(3)') % the next one is a DCM from the BD driver file:
                NextIsMatrix = 3; % three rows of a matrix (DCM)
                nextLabel = 'DCM';
            elseif strcmpi(label,'kp_total') % the next one is a DCM from the BD driver file:
                NextIsMatrix = GetFASTPar(DataOut,'member_total');  
                nextLabel = 'MemberKeyPtTable';
            end            
        end
    end
    
end %end while

fclose(fid); %close file

return
end %end function
%%
function [OutList OutListComments] = ParseFASTOutList( fid )

    %Now loop and read in the OutList
    
    outCount = 0;
    while true
        line = fgetl(fid);
        if isempty(line) %Fortran allows blank lines in this list
            continue; 
        end
        [outVarC, position] = textscan(line,'%q',1); %we need to get the entire quoted line
        outVar  = outVarC{1}{1};    % this will not have quotes around it anymore...

        if isnumeric(line) %loop until we reach the word END or hit the end of the file
            break;
        else
            indx = strfind(upper(outVar),'END');
            if (~isempty(indx) && indx == 1) %we found "END" so that's the end of the file
                break;
            else
                outCount = outCount + 1;
                OutList{outCount,1} = ['"' outVar '"'];
                if position < length(line)
                  OutListComments{outCount,1} = line((position+1):end);
                else
                  OutListComments{outCount,1} = ' ';
                end
            end
        end
    end %end while   

    if outCount == 0
        disp( 'WARNING: no outputs found in OutList' );
        OutList = [];
        OutListComments = '';
    end
    
end %end function
%%
function [FullTable] = ParseFASTNumTable( line, fid, InpSt, NumUnitsLines )


    % read a numeric table from the FAST file
    
    if strncmp(line,'--------------------------------------------', 20)
        % this assumes we are using TurbSim profiles file
        Headers = fgetl(fid);
        nc = 5;
    else
    
        % we've read the line of the table that includes the header 
        % let's parse it now, getting the number of columns as well:
        if ~isempty(strfind(line,','))
            % these will be assumed to be comma delimited:
            TmpHdr  = textscan(line,'%s', 'Delimiter',',');
        else
            TmpHdr  = textscan(line,'%s');
        end

        Headers = TmpHdr{1};
        if strcmp( Headers{1}, '!' )
            Headers = Headers(2:end);
        end
        nc = length(Headers);
    end
    
    if nargin < 4 
        NumUnitsLines = 1;
    end
    
    for i=1:NumUnitsLines
        % read the units line:
        fgetl(fid);
    end
        
    % now initialize Table and read its values from the file:
    Table = zeros(InpSt, nc);   %this is the size table we'll read
    TableComments = cell(InpSt,1);
    i = 0;                      % this the line of the table we're reading           
    while i < InpSt
        
        line = fgetl(fid);
        if isnumeric(line)      % we reached the end prematurely
            break
        elseif i == 0            
            [~,cnt]=sscanf(line,'%50f',nc);
            if cnt==0
                break
                % stop reading and return because the line was not numeric
            elseif cnt<nc
                disp(['Warning: There are more headers in the table than columns. Ignoring the last ' num2str(nc-cnt) ' column(s). Problematic line:', line])
                Headers = Headers(1:cnt);
                Table = Table(:,1:cnt);
                nc = cnt;
            end
        end        

        i = i + 1;
        [Table(i,:),~,~,nextIndex] = sscanf(line,'%f',nc);

        if nextIndex < length(line)
            TableComments{i} = line(nextIndex:end);
        else
            TableComments{i} = '';
        end

    end
    
    if i < InpSt
        disp(['Warning: There are fewer rows in the table than expected. Ignoring the last ' num2str(InpSt-i) ' row(s).'])
        Table = Table(1:i,:);
    end
    
    FullTable.Table    = Table;
    FullTable.Headers  = Headers;
    FullTable.Comments = TableComments;
end %end function
%%
function [FullTable] = ParseFASTFmtTable( line, fid, InpSt, unitsLine )

    % we've read the line of the table that includes the header 
    % let's parse it now, getting the number of columns as well:
    TmpHdr  = textscan(line,'%s');
    Headers = TmpHdr{1};
    nc = length(Headers);

    if nargin < 4 || unitsLine
        % read the units line:
        fgetl(fid); 
    end
        
    % now initialize Table and read its values from the file:
    Table = cell(InpSt,nc);   % this is the size table we'll read
    TableComments = cell(InpSt,1); % these are comments that we add to the end of the line
    i = 0;                    % this the line of the table we're reading    
    while i < InpSt
        
        line = fgetl(fid);
        if isnumeric(line)      % we reached the end prematurely
            break
        end        

        i = i + 1;
        [TmpValue] = textscan(line,'%s',nc); 

        cnt1 = length(TmpValue{1}); %how many strings were actually read
            
        if i==1 && cnt1 ~= nc % note that cnt1 <= nc because we read at max nc values.
            disp(['Warning: There are more headers in the table than columns. Ignoring the last ' num2str(nc-cnt1) ' column(s).'])
            Headers = Headers(1:cnt1);
        end             
        
        for j=1:cnt1
            [testVal, cnt] = sscanf(TmpValue{1}{j},'%f',1);
            if cnt == 0
                Table{i,j}=TmpValue{1}{j}; % non-numeric value
            else
                Table{i,j}=testVal;        % numeric values
            end
        end
        %Table(i,:) = TmpValue{1};       

    end
    
    FullTable.Table    = Table;
    FullTable.Headers  = Headers;
    FullTable.Comments = TableComments; % note that we aren't reading comments here. FIX ME later.
    
end %end function

%%
function [fileList] = ParseFASTFileList( line, fid, nRows  )

    % we've read the line of the file that includes the first 
    % list of (airfoil) file names:
    fileList = cell(nRows,1);

    TmpValue  = textscan(line,'%s',1);
    fileList{1} = TmpValue{1}{1};

    for i=2:nRows
        line = fgetl(fid);
        if isnumeric(line)      % we reached the end prematurely
            break
        end
        
        TmpValue  = textscan(line,'%s',1);
        fileList{i} = TmpValue{1}{1};
    end
    
end %end function



function b=containstring(str, pattern)
    % function contains not available in Octave..
    if (exist ("OCTAVE_VERSION", "builtin") > 0)
        b=~isempty(strfind(str,pattern));
    else
        b=contains(str,pattern);
    end
end
