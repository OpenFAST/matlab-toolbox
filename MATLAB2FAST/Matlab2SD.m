% Matlab2SD
% Function for creating a new SD file given:
% 1) An input template file
% 2) A SD parameter structure
%
% In:   SDPar         -   A SD parameter list
%       TemplateFile    -   A .dat file to use as a template
%       OutputFilename  -   Desired filename of output .fst file
%
% Paul Fleming, JUNE 2011
% Using code copied from functions written by Knud Kragh
% Modified by Bonnie Jonkman, Feb 2013
% Modified by Greg Hayman, Oct 2013, for use with HydroDyn input files.
% Note: the template must not contain the string "OutList" anywhere
%  except for the actual "OutList" output parameter lists.

function Matlab2SD(SDPar,TemplateFile,OutputFilename,HdrLines)

if nargin < 4
    HdrLines = 0;
end

% we're going to get the appropriate newline character(s) from the template file

HaveNewLineChar = false;
% Set default values in case HdrLines=0
if ispc()
    newline = '\r\n'; %windows
else
    % newline = '\r'; %mac
    newline = '\n'; %linux
end
ContainsOutList = false;


%Declare file IDs from the template to the resulting file
fidIN = fopen(TemplateFile,'r');
if fidIN == -1
    error([' Template file, ' TemplateFile ', not found.'])
end
fidOUT = fopen(OutputFilename,'w');
if fidOUT == -1
    error(['Can''t create file ' OutputFilename])
end

for hi = 1:HdrLines
    line    = fgets(fidIN); 
    
        % get the line feed characters(s) here: CHAR(13)=CR(\r) CHAR(10)=LF(\n)
        % so our file has consistant line endings

    if ~HaveNewLineChar
        HaveNewLineChar = true;
        indx = min( strfind(line,char(13)), strfind(line,char(10)) );
        if ~isempty(indx)
            newline = line(indx:end);
        end
    end

        % print appropriate header lines:
    if isfield(SDPar, 'HdrLines') && hi ~= 1 %first line always comes from template file
        fprintf(fidOUT,'%s',SDPar.HdrLines{hi,1}); %does not contain the line ending
        fprintf(fidOUT,newline);                     %so print it here instead
    else
        fprintf(fidOUT,'%s',line);
    end
end

lastLabel = '';
lastValue = 0;
printTable = false; %assume we'll get the tables from the SDPar data structure;

%loop through the template up until OUTLIST or end of file
while true
    
    line = fgets(fidIN); %get the next line from the template
    
    if isnumeric(line) %we reached the end of the file
        break;
    end
    
        % get the line feed characters(s) here: CHAR(13)=CR(\r) CHAR(10)=LF(\n)
        % so our file has consistant line endings
    if ~HaveNewLineChar
        HaveNewLineChar = true;
        indx = min( strfind(line,char(13)), strfind(line,char(10)) );
        if ~isempty(indx)
            newline = line(indx:end);
        end
    end
    
    if ~isempty(strfind(upper(line),upper('OutList'))) 
        ContainsOutList = true;
        fprintf(fidOUT,'%s',line); %if we've found OutList, write the line and break 
        break;
    end  
    
    
    
    [value, label, isComment, ~, ~] = ParseFASTInputLine(line);
%     disp('>>>>>')
%     disp(line)
%     disp(isComment)
%     disp(label)
%     disp(value)
    if ~isComment && length(label) > 0        

        if strcmpi(label,'GuyanDampSize') 
            % First write this line
            line = ParseValue(SDPar.Val, SDPar.Label, value, label, line, TemplateFile);
            fprintf(fidOUT,'%s',line);
            % Then write the GuyanDampMat
            for i =1:value
                fprintf(fidOUT,'%f ',SDPar.GuyanDampMat(i,:));
                fprintf(fidOUT,newline);
            end
            continue
        
        elseif strcmpi(value,'"JointID"') %we've reached the member joints table (and we think it's a string value so it's in quotes)
            
            if ~isfield(SDPar,'Joints')
                disp( 'WARNING: the member joints table not found in the SD data structure.' );
                printTable = true;
            else

                if size(SDPar.Joints,2)==4
                    frmt = '%4i %20.5f %22.5f %22.5f';
                elseif size(SDPar.Joints,2)==9
                    frmt = '%4i %20.5f %22.5f %22.5f %4i %20.5f %20.5f %20.5f %20.5f';
                else
                    error('Unsupported size for joint table')
                end
                WriteFASTTable(line, fidIN, fidOUT, SDPar.Joints, SDPar.JointsHdr, newline, frmt);


                continue; %let's continue reading the template file            
            end

        elseif strcmpi(value,'"RJointID"') %we've reached the base reactions table (and we think it's a string value so it's in quotes)
            if ~isfield(SDPar,'ReactionJoints')
                disp( 'WARNING: the base reaction joints table not found in the SD data structure.' );
                printTable = true;
            else
                frmt = '%4i %11i %11i %11i %11i %11i %11i %s';
                WriteFASTTable(line, fidIN, fidOUT, SDPar.ReactionJoints, SDPar.ReactionJointsHdr, newline, frmt);
                continue; %let's continue reading the template file            
            end  

        elseif strcmpi(value,'"IJointID"') %we've reached the base reactions table (and we think it's a string value so it's in quotes)
            if ~isfield(SDPar,'InterfaceJoints')
                disp( 'WARNING: the interface joints table not found in the SD data structure.' );
                printTable = true;
            else
                frmt = '%4i %11i %11i %11i %11i %11i %11i';
                WriteFASTTable(line, fidIN, fidOUT, SDPar.InterfaceJoints, SDPar.InterfaceJointsHdr, newline, frmt);
                continue; %let's continue reading the template file            
            end  

        elseif strcmpi(value,'"MemberID"')

           if strcmpi(lastLabel, 'NMembers') %we've reached the member table
               if ~isfield(SDPar,'Members')
                   disp( 'WARNING: the members table not found in the SD data structure.' );
                   printTable = true;
               else
                   WriteMembersTable(line, fidIN, fidOUT, SDPar.Members, SDPar.MembersHdr, newline);
                   continue; %let's continue reading the template file            
               end
           elseif strcmpi(lastLabel, 'NMOutputs') %we've reached the member output list table
               if ~isfield(SDPar,'MemberOuts')
                   disp( 'WARNING: the members output list table not found in the SD data structure.' );
                   printTable = true;
               else
                   WriteMemberOutputTable(line, fidIN, fidOUT, SDPar.MemberOuts, SDPar.MemberOutsHdr, newline);
                   continue; %let's continue reading the template file            
               end
           end    
        elseif strcmpi(value,'"PropSetID"') %we've reached the member cross-section properties table (and we think it's a string value so it's in quotes)
            if strcmpi(lastLabel, 'NPropSets') %we've reached the first x-section property table
                if ~isfield(SDPar,'MemberSectionProp')
                    disp( 'WARNING: the first X-section properties table not found in the SD data structure.' );
                    printTable = true;
                else
                    frmt = '%4i %18.5e %15.5e %13.2f %16.6f %15.6f';
                    WriteFASTTable(line, fidIN, fidOUT, SDPar.MemberSectionProp, SDPar.MemberSectionPropHdr, newline, frmt);
                    continue; %let's continue reading the template file            
                end 
            elseif strcmpi(lastLabel, 'NXPropSets') %we've reached the first x-section property table
                if ~isfield(SDPar,'MemberSection2Prop')
                    disp( 'WARNING: the second X-section properties table not found in the SD data structure.' );
                    printTable = true;
                else
                    frmt = '%4i %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f';
                    WriteFASTTable(line, fidIN, fidOUT, SDPar.MemberSection2Prop, SDPar.MemberSection2PropHdr, newline, frmt);
                    continue; %let's continue reading the template file            
                end 
            elseif strcmpi(lastLabel, 'NCablePropSets') % Cable Prop table
                if ~isfield(SDPar,'CableProp')
                    disp( 'WARNING: the cable properties table not found in the SD data structure.' );
                    printTable=true;
                else
                    frmt = '%4i %14.5f %14.5f %14.5f';
                    WriteFASTTable(line, fidIN, fidOUT, SDPar.CableProp, SDPar.CablePropHdr, newline, frmt);
                    continue; %let's continue reading the template file            
                end

            elseif strcmpi(lastLabel, 'NRigidPropSets') % Rigid Prop table
                if ~isfield(SDPar,'RigidProp')
                    disp( 'WARNING: the cable properties table not found in the SD data structure.' );
                    printTable=true;
                else
                    frmt = '%4i %14.5f %14.5f %14.5f';
                    WriteFASTTable(line, fidIN, fidOUT, SDPar.RigidProp, SDPar.RigidPropHdr, newline, frmt);
                    continue; %let's continue reading the template file            
                end
            end
        elseif strcmpi(value,'"COSMID"') %we've reached the Member cosine matrices table (and we think it's a string value so it's in quotes)
            if ~isfield(SDPar,'CosMat')
                disp( 'WARNING: the Member cosine matrices table not found in the SD data structure.' );
                printTable = true;
            else
                frmt = '%4i %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f';
                WriteFASTTable(line, fidIN, fidOUT, SDPar.CosMat, SDPar.CosMatHdr, newline, frmt);
                continue; %let's continue reading the template file            
            end  
         elseif strcmpi(value,'"CMJointID"') %we've reached the joint additional concentrated masses  table (and we think it's a string value so it's in quotes)

            if ~isfield(SDPar,'JntConcMassProp')
                disp( 'WARNING: the joint additional concentrated masses table not found in the SD data structure.' );
                printTable = true;
            else
                if size(SDPar.JntConcMassProp, 2) ==5
                    frmt = '%4i %19.5e %14.5e %16.5e %16.5e';
                elseif size(SDPar.JntConcMassProp, 2)==11
                    frmt = '%4i %19.5e %14.5e %16.5e %16.5e %16.5e %16.5e %16.5e %16.5e %16.5e %16.5e';
                else
                    error('Wrong number of columns for Concentrated mass')
                end
                WriteFASTTable(line, fidIN, fidOUT, SDPar.JntConcMassProp, SDPar.JntConcMassPropHdr, newline, frmt);
                continue; %let's continue reading the template file            
            end  
        else
            line = ParseValue(SDPar.Val, SDPar.Label, value, label, line, TemplateFile);
        end
    else % isComment || length(label) == 0
        if isComment
           
            printTable = false;     % we aren't reading a table (if we were, we reached the end) 
           
        else
            if ~printTable
                continue;           % don't print this line without a label
            end
        end
    end       
    lastValue = value;
    lastLabel = label;
    %write this line into the output file
    fprintf(fidOUT,'%s',line);
end

if ContainsOutList
    if isfield(SDPar,'OutList')
        OutListChar = char(SDPar.OutList);  %this will line up the comments nicer
        spaces      = repmat(' ',1,max(1,26-size(OutListChar,2)));
        %Now add the Outlist
        for io = 1:length(SDPar.OutList)
            fprintf(fidOUT,'%s',[OutListChar(io,:) spaces SDPar.OutListComments{io}]);
            fprintf(fidOUT,newline);
        end
        fprintf(fidOUT,'END of output channels and end of file. (the word "END" must appear in the first 3 columns of this line)');
        fprintf(fidOUT,newline);
    
    else
        disp( 'WARNING: OutList was not found in the SD data structure. The OutList field will be empty.' );        
    end
end

fclose(fidIN);
fclose(fidOUT);
end %end function

function line = ParseValue(SDParVal, SDParLabel, value, label, line, TemplateFile)
        indx = strcmpi( SDParLabel, label );
            if any( indx )

                if sum(indx) > 1 % we found more than one....
                    disp( ['WARNING: multiple occurrences of ' label ' in the SD data structure.'] );
                end

                % The template label matches a label in SDPar
                %  so let's use the old value.
                indx2 = find(indx,1,'first');       
                val2Write = SDParVal{indx2}; 

                    % print the old value at the start of the line,
                    % using an appropriate format
                if isnumeric(val2Write)
                    if strcmpi(label,'WaveSeed(1)') || strcmpi(label,'WaveSeed(2)')
                        writeVal = sprintf('%14d',val2Write(1));
                    else
                        writeVal = sprintf('%14G',val2Write(1));
                    end
                    if ~isscalar(val2Write) %Check for the special case of an array
                        writeVal = [writeVal sprintf(',%14G',val2Write(2:end)) ' '];
                    end
                else
                    writeVal = [val2Write repmat(' ',1,max(1,14-length(val2Write)))];
                end


                idx = strfind( line, label ); %let's just take the line starting where the label is first listed            
                line = [writeVal '   ' line(idx(1):end)];            

            else
                disp( ['WARNING: ' label ' not found in the SD data structure. Default value listed below (from template file, ' TemplateFile ') will be used instead:'] )
                disp( value );
                disp( '' );            
            end
end




function WriteMembersTable( HdrLine, fidIN, fidOUT, Table, Headers, newline )

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    [shrtLine, remain]  = strtok(HdrLine,'!#[');  % treat everything after a '[' char as a comment
    TmpHdr = textscan(shrtLine,'%s');
    TemplateHeaders = TmpHdr{1};
    nc = length(TemplateHeaders);

    fprintf(fidOUT,'%s',HdrLine);           % print the new headers
    fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    ColIndx = ones(1,nc);
    

    for i=1:nc
        indx = strcmpi(TemplateHeaders{i}, Headers);
        if sum(indx) > 0
            ColIndx(i) = find(indx,1,'first');
            if sum(indx) ~= 1
                disp( ['WARNING: Multiple instances of ' TemplateHeaders{i} ' column found in SD table.'] );
            end
        else
           error( [ TemplateHeaders{i} ' column not found in SD table. Cannot write the table.'] );
        end                
    end
    
    
    % now we'll write the table:
    if size(Table,2)==5
        for i=1:size(Table,1) 
            fprintf(fidOUT, '%4i %11i %11i %12i %13i ', Table(i,1:5) );
            fprintf(fidOUT, newline);
        end
    elseif size(Table,2)==6 || size(Table,2)==7
        for i=1:size(Table,1) 
            fprintf(fidOUT, '%4i %11i %11i %12i %13i %13i', Table(i,1:6) );
            fprintf(fidOUT, newline);
        end
    else
        error('Number of columns for member table not supported')
    end
              
end

function WriteMemberOutputTable( HdrLine, fidIN, fidOUT, Table, Headers, newline )

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    [shrtLine, remain]  = strtok(HdrLine,'!#[');  % treat everything after a '[' char as a comment
    TmpHdr = textscan(shrtLine,'%s');
    TemplateHeaders = TmpHdr{1};
    nc = length(TemplateHeaders);

    fprintf(fidOUT,'%s',HdrLine);           % print the new headers
    fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    ColIndx = ones(1,nc);
    

    for i=1:nc
        indx = strcmpi(TemplateHeaders{i}, Headers);
        if sum(indx) > 0
            ColIndx(i) = find(indx,1,'first');
            if sum(indx) ~= 1
                disp( ['WARNING: Multiple instances of ' TemplateHeaders{i} ' column found in SD table.'] );
            end
        else
           error( [ TemplateHeaders{i} ' column not found in SD table. Cannot write the table.'] );
        end                
    end
    
    
    % now we'll write the table:
    for i=1:size(Table,1) 
        ColIndx = [1:Table(i).NOutLoc];
        fprintf(fidOUT, '%4i ', Table(i).ID );  
        fprintf(fidOUT, '%10i ', Table(i).NOutLoc );
        fprintf(fidOUT, '     ');
        fprintf(fidOUT, '%5i',Table(i).NodeLocs(ColIndx));           
        fprintf(fidOUT, newline);
    end
              
end

function WriteFASTTable( HdrLine, fidIN, fidOUT, Table, Headers, newline, frmt )
    % Default arguments
    if ~exist('frmt', 'var'); frmt = '%14.5E'; end

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    [shrtLine, remain]  = strtok(HdrLine,'!#[');  % treat everything after a '[' char as a comment
    TmpHdr = textscan(shrtLine,'%s');
    TemplateHeaders = TmpHdr{1};
    nc = length(TemplateHeaders);

    fprintf(fidOUT,'%s',HdrLine);           % print the new headers
    fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    ColIndx = ones(1,nc);
    

    for i=1:nc
        indx = strcmpi(TemplateHeaders{i}, Headers);
        if sum(indx) > 0
            ColIndx(i) = find(indx,1,'first');
            if sum(indx) ~= 1
                disp( ['WARNING: Multiple instances of ' TemplateHeaders{i} ' column found in SD table.'] );
            end
        else
           error( [ TemplateHeaders{i} ' column not found in SD table. Cannot write the table.'] );
        end                
    end
    
    % now we'll write the table:
    if iscell(Table)
        for i=1:size(Table,1) 
            fprintf(fidOUT, frmt, Table{i,ColIndx} );  %write all of the columns
            fprintf(fidOUT, newline);
        end
    else
        for i=1:size(Table,1) 
            fprintf(fidOUT, frmt, Table(i,ColIndx) );  %write all of the columns
            fprintf(fidOUT, newline);
        end
    end
              
end

