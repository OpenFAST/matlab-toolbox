function DataOut = HD2Matlab(HD_file,hdrLines,DataOut)
%% HD2Matlab
% Function for reading HydroDyn input files in to a MATLAB struct.
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
%.TowProp          A matrix of tower properties with columns .TowPropHdr 
%.TowPropHdr       A cell array of headers corresponding to the TowProp table
%.BldProp          A matrix of blade properties with columns .BldPropHdr
%.BldPropHdr       A cell array of headers corresponding to the BldProp table
%.DLLProp          A matrix of properties for the Bladed DLL Interface with columns .DLLPropHdr
%.DLLPropHdr       A cell array of headers corresponding to the DLLProp table
%
%These arrays are extracted from the HydroDyn input file
%
% In:   HD_file    -   Name of HydroDyn input file
%       hdrLines    -   Number of lines to skip at the top (optional)
%
% Knud A. Kragh, May 2011, NREL, Boulder
%
% Modified by Paul Fleming, JUNE 2011
% Modified by Bonnie Jonkman, February 2013 (to allow us to read the 
% platform file, too)
% Modified by Greg Hayman, Oct 2013 for use with HydroDyn v2 input files
%%
if nargin < 2
    hdrLines = 0;
end

%----------------------Read FST main file----------------------------------
fid = fopen(HD_file,'r');

if fid == -1
    error(['FST file, ' HD_file ', could not be opened for reading. Check if the file exists or is locked.'])
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


DataOut.Label{1} = '';
readJOut = false;

while true %loop until discovering Outlist or end of file, than break
    
    line = fgetl(fid);
    
    if isnumeric(line) % we reached the end of the file
        break
    end
    
        % Check to see if the value is PLATFORM OUTPUTS  deprecated at v2.00.03
    if ~isempty(strfind(upper(line),upper('PLATFORM OUTPUTS'))) 
        [DataOut.PtfmOutList DataOut.PtfmOutListComments] = ParseFASTOutList(fid);
        continue; % break; %bjj: we could continue now if we wanted to assume OutList wasn't the end of the file...
    end   
    
        % Check to see if the value is MESH-BASED OUTPUTS  deprecated at v2.00.03
    if ~isempty(strfind(upper(line),upper('MESH-BASED OUTPUTS'))) 
        [DataOut.MeshOutList DataOut.MeshOutListComments] = ParseFASTOutList(fid);
        continue; % break; %bjj: we could continue now if we wanted to assume OutList wasn't the end of the file...
    end     
    
        % v2.00.03.  Check to see if the value is OUTPUT CHANNNELS
    if ~isempty(strfind(upper(line),upper('OUTPUT CHANNELS'))) 
        [DataOut.OutList DataOut.OutListComments] = ParseFASTOutList(fid);
        continue; % break; %bjj: we could continue now if we wanted to assume OutList wasn't the end of the file...
    end   
    
    [value, label, isComment, descr, fieldType] = ParseFASTInputLine( line );    
    
    if isComment      
       if ~isempty(strfind(upper(line),upper('ADDITIONAL STIFFNESS')))
          [DataOut.AddF0, DataOut.AddCLin, DataOut.AddBLin, DataOut.AddBQuad] = ParseHDAddMatrices(fid);
          continue;
       end
    elseif ~isComment
        
        
        if  strcmpi(value,'"HvCoefID"') %we've reached the heave coefficients table (and we think it's a string value so it's in quotes)  deprecated at version v2.00.03
            NHvCoef = GetFastPar(DataOut,'NHvCoef');        
            [DataOut.HvCoefs, DataOut.HvCoefsHdr] = ParseFASTTable(line, fid, NHvCoef);
            continue; %let's continue reading the file
        elseif  strcmpi(value,'"AxCoefID"') %we've reached the axial coefficients table (and we think it's a string value so it's in quotes)  v2.00.03 of input specification
            NAxCoef = GetFastPar(DataOut,'NAxCoef');        
            [DataOut.AxCoefs, DataOut.AxCoefsHdr] = ParseFASTTable(line, fid, NAxCoef);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"JointID"') %we've reached the member joints table (and we think it's a string value so it's in quotes)
            NJoints = GetFastPar(DataOut,'NJoints');        
            [DataOut.Joints, DataOut.JointsHdr] = ParseFASTTable(line, fid, NJoints);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"PropSetID"') %we've reached the member cross-section properties table (and we think it's a string value so it's in quotes)
            NPropSets = GetFastPar(DataOut,'NPropSets');        
            [DataOut.MemberSectionProp, DataOut.MemberSectionPropHdr] = ParseFASTTable(line, fid, NPropSets);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"SimplCd"') %we've reached the simple hydrodynamic coefficients table (and we think it's a string value so it's in quotes)        
            [DataOut.SmplProp, DataOut.SmplPropHdr] = ParseFASTTable(line, fid, 1);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"Dpth"') %we've reached the member depth-based hydrodynamic coefficients table (and we think it's a string value so it's in quotes)
            NCoefDpth = GetFastPar(DataOut,'NCoefDpth');        
            [DataOut.DpthProp, DataOut.DpthPropHdr] = ParseFASTTable(line, fid, NCoefDpth);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"MemberID"') 
            if strcmpi(DataOut.Label(end), 'NCoefMembers') %we've reached the member-based hydrodynamic coefficients table 
               NCoefMembers = GetFastPar(DataOut,'NCoefMembers');        
               [DataOut.MemberProp, DataOut.MemberPropHdr] = ParseFASTTable(line, fid, NCoefMembers);
               continue; %let's continue reading the file
            elseif strcmpi(DataOut.Label(end), 'NMembers') %we've reached the member table 
               NMembers = GetFastPar(DataOut,'NMembers');        
               [DataOut.Members, DataOut.MembersHdr] = ParseMembersTable(line, fid, NMembers);
               continue; %let's continue reading the file
            elseif strcmpi(DataOut.Label(end), 'NMOutputs') %we've reached the member output list table 
               NMOutputs = GetFastPar(DataOut,'NMOutputs');        
               [DataOut.MemberOuts, DataOut.MemberOutsHdr] = ParseMemberOutputs(line, fid, NMOutputs);
               continue; %let's continue reading the file
            end
        elseif strcmpi(value,'"FillNumM"') %we've reached the filled members table (and we think it's a string value so it's in quotes)
            NFillGroups = GetFastPar(DataOut,'NFillGroups');        
            [DataOut.FillGroups, DataOut.FillGroupsHdr] = ParseFillGroups(line, fid, NFillGroups);
            continue; %let's continue reading the file
        elseif strcmpi(DataOut.Label(end), 'NJOutputs') && ~readJOut  %we've reached the joint outputs table (and we think it's a string value so it's in quotes)
            NJOutputs = GetFastPar(DataOut,'NJOutputs'); 
            if strcmpi(label,'HDSum')
               DataOut.Label{count,1} = label;
               DataOut.Val{count,1}   = value;
               count = count + 1;
               DataOut.JOutLst = 0;
            else
               DataOut.JOutLst = ParseJointOutputs(line,  NJOutputs);
            end
            readJOut = true;
            continue; %let's continue reading the file
        elseif strcmpi(value,'"MGDpth"') %we've reached the marine growth table (and we think it's a string value so it's in quotes)
            NMGDepths = GetFastPar(DataOut,'NMGDepths');        
            [DataOut.MGProp, DataOut.MGPropHdr] = ParseFASTTable(line, fid, NMGDepths);
            continue; %let's continue reading the file
        else                
            DataOut.Label{count,1} = label;
            DataOut.Val{count,1}   = value;
            count = count + 1;
                %NWaveElev
%             if strcmpi(label,'NWaveElev') %we've reached the heave coefficients table (and we think it's a string value so it's in quotes)
%                line = fgetl(fid);
%                DataOut.WaveElevxi = zeros(1,value);
%                DataOut.WaveElevyi = zeros(1,value);
%                DataOut.WaveElevxi(:) =sscanf(line,'%f',value);
%                line = fgetl(fid);
%                DataOut.WaveElevyi(:) =sscanf(line,'%f',value);
%             end
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

function [AddF0, AddCLin, AddBLin, AddBQuad] = ParseHDAddMatrices(fid)

   AddF0    = zeros(1,6);
   AddCLin  = zeros(6,6);
   AddBLin  = zeros(6,6);
   AddBQuad = zeros(6,6);
   
      % read the AddF0:
    line = fgetl(fid); 
    AddF0(1,:) = sscanf(line,'%f',6); 
      % read the AddCLin:
    for i=1:6
      line = fgetl(fid); 
      AddCLin(i,:) = sscanf(line,'%f',6); 
    end
    for i=1:6
      line = fgetl(fid); 
      AddBLin(i,:) = sscanf(line,'%f',6); 
    end
    for i=1:6
      line = fgetl(fid); 
      AddBQuad(i,:) = sscanf(line,'%f',6); 
    end
end


function [Table, Headers] = ParseFASTTable( line, fid, InpSt  )

    % we've read the line of the table that includes the header 
    % let's parse it now, getting the number of columns as well:
    line  = strtok(line,'[');  % treat everything after a '[' char as a comment
    TmpHdr  = textscan(line,'%s');
    Headers = TmpHdr{1};
    nc = length(Headers);

    % read the units line:
    fgetl(fid); 
        
    % now initialize Table and read its values from the file:
    Table = zeros(InpSt, nc);   %this is the size table we'll read
    i = 0;                      % this the line of the table we're reading    
    while i < InpSt
        
        line = fgetl(fid);
        if isnumeric(line)      % we reached the end prematurely
            break
        end        

        i = i + 1;
        Table(i,:) = sscanf(line,'%f',nc);       

    end
    
end %end function

function [Table, Headers] = ParseFillGroups( line, fid, InpSt )

      % we've read the line of the table that includes the header 
      % let's parse it now, getting the number of columns as well:
    line  = strtok(line,'[');  % treat everything after a '[' char as a comment
    TmpHdr  = textscan(line,'%s');
    Headers = TmpHdr{1};
    nc = length(Headers);

      % read the units line:
    fgetl(fid); 
    
      % now initialize Table and read its values from the file:
    Table = repmat( struct( 'NumM','', 'MList','', 'FSLoc','','Dens','' ), double( InpSt ), 1 );
    i = 0;                      % this the line of the table we're reading    
    while i < InpSt
        
        line = fgetl(fid);
        if isnumeric(line)      % we reached the end prematurely
            break
        end        

        i = i + 1;      
        nc     = sscanf(line,'%f',1);
        group  = zeros(1,nc+3);
        group(:)  = sscanf(line,'%f',nc+3); 
        Table(i).NumM  = group(1);
        Table(i).MList = group(2:nc+1); 
        Table(i).FSLoc = group(nc+2);
        Table(i).Dens  = group(nc+3);
    end
    
end



function [Table] = ParseJointOutputs( line, InpSt )

    
      % now initialize Table and read its values from the file:
    Table = zeros( 1, InpSt );     
    
    Table(:)  = sscanf(line,'%i',InpSt); 
   
   
    
end

function [Table, Headers] = ParseMemberOutputs( line, fid, InpSt )

      % we've read the line of the table that includes the header 
      % let's parse it now, getting the number of columns as well:
    line  = strtok(line,'[');  % treat everything after a '[' char as a comment
    TmpHdr  = textscan(line,'%s');
    Headers = TmpHdr{1};
    nc = length(Headers);

      % read the units line:
    fgetl(fid); 
    
      % now initialize Table and read its values from the file:
    Table = repmat( struct( 'ID','', 'NOutLoc','', 'NodeLocs','' ), double( InpSt ), 1 );
    i = 0;                      % this the line of the table we're reading    
    while i < InpSt
        
        line = fgetl(fid);
        if isnumeric(line)      % we reached the end prematurely
            break
        end        

        i = i + 1;      
        nc     = sscanf(line,'%f',2);
        outputs = zeros(nc(2)+2,1);
        outputs(:)  = sscanf(line,'%f',nc(2)+2); 
        Table(i).ID  = outputs(1);
        Table(i).NOutLoc = outputs(2); 
        Table(i).NodeLocs = outputs(3:nc(2)+2);
    
    end
    
end

function [Table, Headers] = ParseMembersTable( line, fid, InpSt  )

    % we've read the line of the table that includes the header 
    % let's parse it now, getting the number of columns as well:
    line  = strtok(line,'[');  % treat everything after a '[' char as a comment
    TmpHdr  = textscan(line,'%s');
    Headers = TmpHdr{1};
    nc = length(Headers);

    % read the units line:
    fgetl(fid); 
        
    % now initialize Table and read its values from the file:
    Table = zeros(InpSt, nc);   %this is the size table we'll read
    i = 0;                      % this the line of the table we're reading    
    while i < InpSt
        
      line = fgetl(fid);
      if isnumeric(line)      % we reached the end prematurely
            break
      end        

      i = i + 1;
       Table(i,1:nc-1)  = sscanf(line,'%f',nc-1); 
       [junk, count] = textscan(line,'%f',nc-1);
      logical = sscanf(line(count+1:end),'%s',1);
      
      switch lower( logical )
      case 'true'
         Table(i,nc) = true;
      case 'false'
         Table(i,nc) = false;
      otherwise
         beep
         error( sprintf( '  The logical variable must be "true" or "false".  Instead, it was "%s".', logical ) );
      end
    end
    
end %end function


