function DataOut = SD2Matlab(HD_file,hdrLines,DataOut)
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
% Modified by Greg Hayman, Oct 2013 for use with SubDyn v1 input files
%%
if nargin < 2
    hdrLines = 0;
end

%----------------------Read FST main file----------------------------------
fid = fopen(HD_file,'r');

if fid == -1
    error(['SD file, ' SD_file ', could not be opened for reading. Check if the file exists or is locked.'])
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
    
   
     
    
        % v2.00.03.  Check to see if the value is OUTPUT CHANNNELS
    if ~isempty(strfind(upper(line),upper('SSOutList'))) 
        [DataOut.OutList DataOut.OutListComments] = ParseFASTOutList(fid);
        continue; % break; %bjj: we could continue now if we wanted to assume OutList wasn't the end of the file...
    end   
    
  
       
    [value, label, isComment, descr, fieldType] = ParseFASTInputLine( line );    
    
    if isComment      
       
    elseif ~isComment
        
        
        if strcmpi(value,'"JointID"') %we've reached the member joints table (and we think it's a string value so it's in quotes)
            NJoints = GetFASTPar(DataOut,'NJoints');        
            [DataOut.Joints, DataOut.JointsHdr] = ParseFASTTable(line, fid, NJoints);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"RJointID"') %we've reached the base reaction joints table (and we think it's a string value so it's in quotes)
            NReact = GetFASTPar(DataOut,'NReact');        
            [DataOut.ReactionJoints, DataOut.ReactionJointsHdr] = ParseFASTTable(line, fid, NReact);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"IJointID"') %we've reached the interface joints table (and we think it's a string value so it's in quotes)
            NInterf = GetFASTPar(DataOut,'NInterf');        
            [DataOut.InterfaceJoints, DataOut.InterfaceJointsHdr] = ParseFASTTable(line, fid, NInterf);
            continue; %let's continue reading the file
        elseif strcmpi(value,'"MemberID"') 
            if strcmpi(DataOut.Label(end), 'NMembers') %we've reached the member table 
               NMembers = GetFASTPar(DataOut,'NMembers');        
               [DataOut.Members, DataOut.MembersHdr] = ParseFASTTable(line, fid, NMembers);
               continue; %let's continue reading the file
            elseif strcmpi(DataOut.Label(end), 'NMOutputs') %we've reached the member output list table 
               NMOutputs = GetFASTPar(DataOut,'NMOutputs');        
               [DataOut.MemberOuts, DataOut.MemberOutsHdr] = ParseMemberOutputs(line, fid, NMOutputs);
               continue; %let's continue reading the file
            end    
        elseif strcmpi(value,'"PropSetID"') %we've reached the member cross-section properties table (and we think it's a string value so it's in quotes)
            if strcmpi(DataOut.Label(end), 'NPropSets') %we've reached the member table 
               NPropSets = GetFASTPar(DataOut,'NPropSets');        
               [DataOut.MemberSectionProp, DataOut.MemberSectionPropHdr] = ParseFASTTable(line, fid, NPropSets);
               continue; %let's continue reading the file
            elseif strcmpi(DataOut.Label(end), 'NXPropSets') %we've reached the member table 
               NXPropSets = GetFASTPar(DataOut,'NXPropSets');        
               [DataOut.MemberSection2Prop, DataOut.MemberSection2PropHdr] = ParseFASTTable(line, fid, NXPropSets);
               continue; %let's continue reading the file          
            end
        elseif strcmpi(value,'"COSMID"') %we've reached the cosine matrices table (and we think it's a string value so it's in quotes)
            NCOSMs = GetFASTPar(DataOut,'NCOSMs');        
            [DataOut.CosMat, DataOut.CosMatHdr] = ParseFASTTable(line, fid, NCOSMs);
            continue; %let's continue reading the file  
        elseif strcmpi(value,'"CMJointID"') %we've reached the joint additional concentrated masses table (and we think it's a string value so it's in quotes)
            NCmass = GetFASTPar(DataOut,'NCmass');        
            [DataOut.JntConcMassProp, DataOut.JntConcMassPropHdr] = ParseFASTTable(line, fid, NCmass);
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
        [tmp, count] = sscanf(line,'%f',nc); 
        Table(i,1:count) = tmp; 
            

    end
    
end %end function


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




