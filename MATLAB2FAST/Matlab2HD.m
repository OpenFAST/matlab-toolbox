% Matlab2HD
% Function for creating a new HD file given:
% 1) An input template file
% 2) A HD parameter structure
%
% In:   HDPar         -   A HD parameter list
%       TemplateFile    -   A .dat file to use as a template
%       OutputFilename  -   Desired filename of output .fst file
%
% Paul Fleming, JUNE 2011
% Using code copied from functions written by Knud Kragh
% Modified by Bonnie Jonkman, Feb 2013
% Modified by Greg Hayman, Oct 2013, for use with HydroDyn input files.
% Note: the template must not contain the string "OutList" anywhere
%  except for the actual "OutList" output parameter lists.

function Matlab2HD(HDPar,TemplateFile,OutputFilename,hdrLines)

if nargin < 4
    hdrLines = 0;
end

% we're going to get the appropriate newline character(s) from the template file

HaveNewLineChar = false;
% newline = '\r'; %mac
% newline = '\n'; %linux
% newline = '\r\n'; %windows
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

for hi = 1:hdrLines
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
    if isfield(HDPar, 'HdrLines') && hi ~= 1 %first line always comes from template file
        fprintf(fidOUT,'%s',HDPar.HdrLines{hi,1}); %does not contain the line ending
        fprintf(fidOUT,newline);                     %so print it here instead
    else
        fprintf(fidOUT,'%s',line);
    end
end

lastLabel = '';
lastValue = 0;
printTable = false; %assume we'll get the tables from the HDPar data structure;

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
    
    if contains(upper(line),upper('OUTPUT CHANNELS')) 
        ContainsOutList = true;
        fprintf(fidOUT,'%s',line); %if we've found OutList, write the line and break 
        break;
    end  
    
    
    
    [value, label, isComment, ~, ~] = ParseFASTInputLine(line);
    if ~isComment && length(label) > 0        
%         if strcmpi(label,'"NWaveElev"') %we've reached wave elevations table (and we think it's a string value so it's in quotes)            
%             if ~isfield(HDPar,'WaveElevxi')
%                 disp(  ['WARNING: wave elevations not found in the HD data structure.'] );
%                 printTable = true;
%             else
%                 lastValue = value;
%                 lastLabel = label;
%                 %write this line into the output file
%                 fprintf(fidOUT,'%s',line); 
%                 line = fgets(fidIN); %get the next line from the template
%                 line = fgets(fidIN); %get the next line from the template
%     
%                 continue; %let's continue reading the template file            
%             end
        
        
        if strcmpi(value,'"AxCoefID"') %we've reached the heave coefficients table (and we think it's a string value so it's in quotes)            
            if ~isfield(HDPar,'AxCoefs')
                disp(  ['WARNING: heave coefficients table not found in the HD data structure.'] );
                printTable = true;
            else
                frmt = ' %4i %8.2f %8.2f %8.2f %6i    %8.2f   %8.2f';
                WriteFASTTable(line, fidIN, fidOUT, HDPar.AxCoefs, newline, frmt);
                continue; %let's continue reading the template file            
            end
        elseif  strcmpi(lastLabel,'NJOutputs')  %we've reached the Joint Output list
            if length(HDPar.JOutLst) > 0
              [shrtLine, remain]  = strtok(line,'J');
              fprintf(fidOUT, '%4i', HDPar.JOutLst ); 
              filler = repmat(' ',1,max(1,17-(4*length(HDPar.JOutLst))));
              fprintf(fidOUT,'%s%s',filler,remain);
              lastValue = value;
              lastLabel = label;
              continue;
            end

        elseif strcmpi(value,'"JointID"') %we've reached the member joints table (and we think it's a string value so it's in quotes)
            if ~isfield(HDPar,'Joints')
                disp( 'WARNING: the member joints table not found in the HD data structure.' );
                printTable = true;
            else
                frmt = ' %4i %11.5f %11.5f %11.5f %6i %12i';
                WriteFASTTable(line, fidIN, fidOUT, HDPar.Joints, newline, frmt);
                continue; %let's continue reading the template file            
            end
            
        elseif strcmpi(value,'"PropSetID"') %we've reached the member cross-section properties table (and we think it's a string value so it's in quotes)
            if ~isfield(HDPar,'MemberSectionProp')
                disp( 'WARNING: the member cross-section properties table not found in the HD data structure.' );
                printTable = true;
            else
                frmt = ' %4i %14.5f %14.5f';
                WriteFASTTable(line, fidIN, fidOUT, HDPar.MemberSectionProp, newline, frmt);
                for k = 1:lastValue % NPropSets
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end                 
                continue; %let's continue reading the template file            
            end 
            
        elseif strcmpi(value,'"SimplCd"') %we've reached the simple hydrodynamic coefficients table (and we think it's a string value so it's in quotes)        
            if ~isfield(HDPar,'SmplProp')
                disp( 'WARNING: the simple hydrodynamic coefficients table not found in the HD data structure.' );
                printTable = true;
            else
                frmt = repmat( '%11.2f ', 1, 10 );
                WriteFASTTable(line, fidIN, fidOUT, HDPar.SmplProp, newline, frmt);
                for k = 1:1 %only 1 line here
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end  
                continue; %let's continue reading the template file            
            end
        
        elseif strcmpi(value,'"Dpth"') %we've reached the member depth-based hydrodynamic coefficients table (and we think it's a string value so it's in quotes)
            if ~isfield(HDPar,'DpthProp')
               
                disp( 'WARNING: the member depth-based hydrodynamic coefficients table not found in the HD data structure.' );
                printTable = true;
            else
                frmt = '%8.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f';
                WriteFASTTable(line, fidIN, fidOUT, HDPar.DpthProp, newline, frmt);
                for k = 1:lastValue
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end
                continue; %let's continue reading the template file            
            end
            
        elseif strcmpi(value,'"MGDpth"') %we've reached the marine growth table (and we think it's a string value so it's in quotes)
            if ~isfield(HDPar,'MGProp')
                disp( 'WARNING: the marine growth table not found in the HD data structure.' );
                printTable = true;
            else
                frmt = ' %6.2f %9.3f %7.0f';
                WriteFASTTable(line, fidIN, fidOUT, HDPar.MGProp, newline, frmt);
                for k = 1:lastValue
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end
                continue; %let's continue reading the template file            
            end
        elseif strcmpi(value,'"FillNumM"') %we've reached the fill group table (and we think it's a string value so it's in quotes)
             if ~isfield(HDPar,'FillGroups')
                disp( 'WARNING: the fill group table not found in the HD data structure.' );
                printTable = true;
              else
                WriteFillGroupTable(line, fidIN, fidOUT, HDPar.FillGroups, newline);
                continue; %let's continue reading the template file            
              end     
        elseif strcmpi(value,'"MemberID"')
           if strcmpi(lastLabel,'NCoefMembers')  %we've reached the member-based hydrodynamic coefficients table 
              if ~isfield(HDPar,'MemberProp')
                disp( 'WARNING: the member-based hydrodynamic coefficients table not found in the HD data structure.' );
                printTable = true;
              else
                 frmt = [' %4i' repmat(' %13.2f', 1, 24) ];
                WriteFASTTable(line, fidIN, fidOUT, HDPar.MemberProp, newline, frmt);
                for k = 1:lastValue
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end
                continue; %let's continue reading the template file            
              end
           elseif strcmpi(lastLabel, 'NMembers') %we've reached the member table
              if ~isfield(HDPar,'Members')
                disp( 'WARNING: the members table not found in the HD data structure.' );
                printTable = true;
              else
                WriteMembersTable(line, fidIN, fidOUT, HDPar.Members, newline);
                for k = 1:lastValue
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end
                continue; %let's continue reading the template file            
              end
           elseif strcmpi(lastLabel, 'NMOutputs') %we've reached the member output list table
              if ~isfield(HDPar,'MemberOuts')
                disp( 'WARNING: the members output list table not found in the HD data structure.' );
                printTable = true;
              else
                WriteMemberOutputTable(line, fidIN, fidOUT, HDPar.MemberOuts, newline);
                for k = 1:lastValue
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end
                continue; %let's continue reading the template file            
              end
           end
        else
            
            line = ParseValue(HDPar.Val, HDPar.Label, value, label, line, TemplateFile);
            
        end
    else % isComment || length(label) == 0
        if isComment
            if (contains(upper(line),upper('ADDITIONAL STIFFNESS')))
                fprintf(fidOUT,'%s',line);                  
                NBodyMod=GetFASTPar(HDPar,'NBodyMod');
                NBody=GetFASTPar(HDPar,'NBody');
                WriteHDAddMatrices( fidIN, fidOUT, HDPar.AddF0, HDPar.AddCLin, HDPar.AddBLin, HDPar.AddBQuad, newline,NBodyMod,NBody);

                if NBodyMod_template > 1
                    nr_in = 6;
                else
                    nr_in = 6*NBody_template;
                end

                for i = 1:(4*nr_in) % hopefully this works for both older and newer version of HD (if NBody > 1, this might be an issue)
                   line    = fgets(fidIN);
                end
                continue;
            end           
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

    if (strcmpi(lastLabel, 'NBodyMod'))
        NBodyMod_template = lastValue;
    elseif (strcmpi(lastLabel, 'NBody'))
        NBody_template = lastValue;
    end
        
end

if ContainsOutList
    if isfield(HDPar,'OutList')
        OutListChar = char(HDPar.OutList);  %this will line up the comments nicer
        spaces      = repmat(' ',1,max(1,26-size(OutListChar,2)));
        %Now add the Outlist
        for io = 1:length(HDPar.OutList)
            fprintf(fidOUT,'%s',[OutListChar(io,:) spaces HDPar.OutListComments{io} newline]);
        end
    else
        disp( 'WARNING: OutList was not found in the HD data structure. The OutList field will be empty.' );        
    end
    fprintf(fidOUT,'END of output channels and end of file. (the word "END" must appear in the first 3 columns of this line)');
    fprintf(fidOUT,newline);
    
    
    %fprintf(fidOUT,newline);
    %fprintf(fidOUT,'---------------------------------------------------------------------------------------');
    %fprintf(fidOUT,newline);
end

fclose(fidIN);
fclose(fidOUT);
end %end function

function line = ParseValue(HDParVal, HDParLabel, value, label, line, TemplateFile)
        indx = strcmpi( HDParLabel, label );
            if any( indx )

                if sum(indx) > 1 % we found more than one....
                    disp( ['WARNING: multiple occurrences of ' label ' in the HD data structure.'] );
                end

                % The template label matches a label in HDPar
                %  so let's use the old value.
                indx2 = find(indx,1,'first');       
                val2Write = HDParVal{indx2}; 

                    % print the old value at the start of the line,
                    % using an appropriate format
                if isnumeric(val2Write)
                    if strcmpi(label,'WaveSeed(1)') || strcmpi(label,'WaveSeed(2)')
                        writeVal = sprintf('%14d',val2Write(1));
                    else
                        writeVal = sprintf('%14.10G',val2Write(1));
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
                disp( ['WARNING: ' label ' not found in the HD data structure. Default value listed below (from template file, ' TemplateFile ') will be used instead:'] )
                disp( value );
                disp( '' );            
            end
end

function WriteHDAddMatrices( fidIN, fidOUT, AddF0, AddCLin, AddBLin, AddBQuad, newline, NBodyMod, NBody)

    
      % now we'll write the AddF0:
   % If NBodyMod = 1 then vecMultiplier = NBody and nWAMITObj = 1
   % Else                 vecMultiplier = 1     and nWAMITObj = NBody

    if NBodyMod > 1
        nr_in = 6;
%         nc_in = NBody;
    else
        nr_in = 6*NBody;
%         nc_in = 1;
    end
       
   fprintf(fidOUT, '%14.0f', AddF0(1,:) );  %write all of the columns
   fprintf(fidOUT, '   AddF0    - Additional preload (N, N-m)  [If NBodyMod=1, one size 6*NBody x 1 vector; if NBodyMod>1, NBody size 6 x 1 vectors]');
   fprintf(fidOUT, newline);
   for i=2:nr_in    
      fprintf(fidOUT, '%14.0f', AddF0(i,:) );
      fprintf(fidOUT, newline);
   end
   
   fprintf(fidOUT, '%14.0f', AddCLin(1,:) );  %write all of the columns
   fprintf(fidOUT, '   AddCLin  - Additional linear stiffness (N/m, N/rad, N-m/m, N-m/rad)  [If NBodyMod=1, one size 6*NBody x 6*NBody matrix; if NBodyMod>1, NBody size 6 x 6 matrices]');  
   fprintf(fidOUT, newline);
   for i=2:nr_in    
      fprintf(fidOUT, '%14.0f', AddCLin(i,:) );
      fprintf(fidOUT, newline);
   end
   
   fprintf(fidOUT, '%14.0f', AddBLin(1,:) );  %write all of the columns
   fprintf(fidOUT, '   AddBLin  - Additional linear damping(N/(m/s), N/(rad/s), N-m/(m/s), N-m/(rad/s))  [If NBodyMod=1, one size 6*NBody x 6*NBody matrix; if NBodyMod>1, NBody size 6 x 6 matrices]');    
   fprintf(fidOUT, newline);
   for i=2:nr_in    
      fprintf(fidOUT, '%14.0f', AddBLin(i,:) );
      fprintf(fidOUT, newline);
   end
   
   fprintf(fidOUT, '%14.0f', AddBQuad(1,:) );  %write all of the columns
   fprintf(fidOUT, '   AddBQuad - Additional quadratic drag(N/(m/s)^2, N/(rad/s)^2, N-m(m/s)^2, N-m/(rad/s)^2)  [If NBodyMod=1, one size 6*NBody x 6*NBody matrix; if NBodyMod>1, NBody size 6 x 6 matrices]');    
   fprintf(fidOUT, newline);
   for i=2:nr_in    
      fprintf(fidOUT, '%14.0f', AddBQuad(i,:) );
      fprintf(fidOUT, newline);
   end

end


function WriteMembersTable( HdrLine, fidIN, fidOUT, FullTable, newline )

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    [shrtLine, ~]  = strtok(HdrLine,'[');  % treat everything after a '[' char as a comment
    TmpHdr = textscan(shrtLine,'%s');
    TemplateHeaders = TmpHdr{1};
    nc = length(TemplateHeaders);

    fprintf(fidOUT,'%s',HdrLine);           % print the new headers
    fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    ColIndx = ones(1,nc);
    

    for i=1:nc
        indx = strcmpi(TemplateHeaders{i}, FullTable.Headers);
        if sum(indx) > 0
            ColIndx(i) = find(indx,1,'first');
            if sum(indx) ~= 1
                disp( ['WARNING: Multiple instances of ' TemplateHeaders{i} ' column found in HD table.'] );
            end
        else
           error( [ TemplateHeaders{i} ' column not found in HD table. Cannot write the table.'] );
        end                
    end
    
    
    % now we'll write the table:
%     ColIndx = [1:nc-1];
    for i=1:size(FullTable.Table,1) 
        if (FullTable.Table(i,8))
           logic = 'TRUE';
        else
           logic = 'FALSE';
        end
        fprintf(fidOUT, ' %4i %9i %10i %11i %12i ', FullTable.Table(i,1:5) );
       
        fprintf(fidOUT, '%14.4f', FullTable.Table(i,6) );  %write all of the columns
        fprintf(fidOUT, '%7i ', FullTable.Table(i,7) );
        fprintf(fidOUT, '       %s',logic);
        fprintf(fidOUT, FullTable.Comments{i});
        fprintf(fidOUT, newline);
    end
              
end
function WriteFillGroupTable( HdrLine, fidIN, fidOUT, FullTable, newline )

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    [shrtLine, ~]  = strtok(HdrLine,'[');  % treat everything after a '[' char as a comment
    TmpHdr = textscan(shrtLine,'%s');
    TemplateHeaders = TmpHdr{1};
    nc = length(TemplateHeaders);

    fprintf(fidOUT,'%s',HdrLine);           % print the new headers
    fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    ColIndx = ones(1,nc);
    

    for i=1:nc
        indx = strcmpi(TemplateHeaders{i}, FullTable.Headers);
        if sum(indx) > 0
            ColIndx(i) = find(indx,1,'first');
            if sum(indx) ~= 1
                disp( ['WARNING: Multiple instances of ' TemplateHeaders{i} ' column found in HD table.'] );
            end
        else
           error( [ TemplateHeaders{i} ' column not found in HD table. Cannot write the table.'] );
        end                
    end
    
    
    % now we'll write the table:
    for i=1:size(FullTable.Table,1) 
        ColIndx = 1:FullTable.Table(i).NumM;
        fprintf(fidOUT, '%5i ', FullTable.Table(i).NumM );  
        fprintf(fidOUT, '%3i ', FullTable.Table(i).MList(ColIndx) );
        fprintf(fidOUT, '%8.2f',FullTable.Table(i).FSLoc);  
        fprintf(fidOUT, '%15.0f',FullTable.Table(i).Dens);  
        fprintf(fidOUT, FullTable.Comments{i});
        fprintf(fidOUT, newline);
    end
              
end

function WriteMemberOutputTable( HdrLine, fidIN, fidOUT, FullTable, newline )

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    [shrtLine, ~]  = strtok(HdrLine,'[');  % treat everything after a '[' char as a comment
    TmpHdr = textscan(shrtLine,'%s');
    TemplateHeaders = TmpHdr{1};
    nc = length(TemplateHeaders);

    fprintf(fidOUT,'%s',HdrLine);           % print the new headers
    fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    ColIndx = ones(1,nc);
    

    for i=1:nc
        indx = strcmpi(TemplateHeaders{i}, FullTable.Headers);
        if sum(indx) > 0
            ColIndx(i) = find(indx,1,'first');
            if sum(indx) ~= 1
                disp( ['WARNING: Multiple instances of ' TemplateHeaders{i} ' column found in HD table.'] );
            end
        else
           error( [ TemplateHeaders{i} ' column not found in HD table. Cannot write the table.'] );
        end                
    end
    
    
    % now we'll write the table:
    for i=1:size(FullTable.Table,1) 
        ColIndx = 1:FullTable.Table(i).NOutLoc;
        fprintf(fidOUT, '%5i ', FullTable.Table(i).ID );  
        fprintf(fidOUT, '%10i ', FullTable.Table(i).NOutLoc );
        fprintf(fidOUT, '     ');
        fprintf(fidOUT, '%7.3f',FullTable.Table(i).NodeLocs(ColIndx));           
        fprintf(fidOUT, FullTable.Comments{i});
        fprintf(fidOUT, newline);
    end
              
end

function WriteFASTTable( HdrLine, fidIN, fidOUT, FullTable, newline, frmt )

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    [shrtLine, ~]  = strtok(HdrLine,'[');  % treat everything after a '[' char as a comment
    TmpHdr = textscan(shrtLine,'%s');
    TemplateHeaders = TmpHdr{1};
    nc = length(TemplateHeaders);

    fprintf(fidOUT,'%s',HdrLine);           % print the new headers
    fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    ColIndx = ones(1,nc);
    

    for i=1:nc
        indx = strcmpi(TemplateHeaders{i}, FullTable.Headers);
        if sum(indx) > 0
            ColIndx(i) = find(indx,1,'first');
            if sum(indx) ~= 1
                disp( ['WARNING: Multiple instances of ' TemplateHeaders{i} ' column found in HD table.'] );
            end
        else
           error( [ TemplateHeaders{i} ' column not found in HD table. Cannot write the table.'] );
        end                
    end
    
    if nargin < 6 
       frmt = '%14.5E';
    end
    
    % now we'll write the table:
    for i=1:size(FullTable.Table,1) 
        
        fprintf(fidOUT, frmt, FullTable.Table(i,ColIndx) );  %write all of the columns
        fprintf(fidOUT, FullTable.Comments{i});
        fprintf(fidOUT, newline);
    end
              
end

