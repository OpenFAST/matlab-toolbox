% Matlab2FAST(FastPar,TemplateFile,OutputFilename,hdrLines)
% Function for creating a new FAST file given:
% 1) An input template file
% 2) A FAST parameter structure
%
% In:   FastPar         -   A FAST parameter list
%       TemplateFile    -   A .fst file to use as a template
%       OutputFilename  -   Desired filename of output .fst file
%
% Paul Fleming, JUNE 2011
% Using code copied from functions written by Knud Kragh
% Modified by Bonnie Jonkman, Feb 2013
% Note: the template must not contain the string "OutList" anywhere
%  except for the actual "OutList" output parameter lists.

function Matlab2FAST(FastPar,TemplateFile,OutputFilename,hdrLines)

if nargin < 4
    hdrLines = 0;
end

% we're going to get the appropriate newline character(s) from the template file

HaveNewLineChar = false;
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
    
        % get the line feed characters(s) here: char(13)=CR(\r) char(10)=LF(\n)
        % so our file has consistant line endings
    if ~HaveNewLineChar
        newline = getNewlineChar(line);
        HaveNewLineChar = true;
    end

        % print appropriate header lines:
    if isfield(FastPar, 'HdrLines') && hi ~= 1 && hi <= length(FastPar.HdrLines) %first line always comes from template file
        fprintf(fidOUT,'%s',FastPar.HdrLines{hi,1}); %does not contain the line ending
        fprintf(fidOUT,newline);                     %so print it here instead
    else
        fprintf(fidOUT,'%s',line);
    end
end

printTable = false; %assume we'll get the tables from the FastPar data structure;
printTableComments = 0;
NextMatrix = '';
isInteger = false;

%loop through the template up until OUTLIST, OUTPUTS (for MoorDyn files) or end of file
while true
    
    line = fgets(fidIN); %get the next line from the template
    
    if isnumeric(line) %we reached the end of the file
        break;
    end
    
        % get the line feed characters(s) here: CHAR(13)=CR(\r) CHAR(10)=LF(\n)
        % so our file has consistant line endings
    if ~HaveNewLineChar
        newline = getNewlineChar(line);
        HaveNewLineChar = true;
    end
    
    if contains(upper(line),upper('OutList')) || (contains(upper(line),upper('OUTPUTS')) && isfield(FastPar,'ConProp')) % The second statement is to detect the outlist of MoorDyn input files (Field ConProp will only exist when processing MoorDyn input files.)
        % 6/23/2016: linearization inputs contain "OutList" in the
        % comments, so we need to make sure this is either the first (value) or
        % second (label) word of the line.
        [value2, ~, ~, nextindex] = sscanf(line,'%s', 1); 
        if strcmpi(value2,'OutList') || strcmpi(value2,'OUTPUTS')
            ContainsOutList = true;
            fprintf(fidOUT,'%s',line); %if we've found OutList, write the line and break 
            break; %bjj: we could continue now if we wanted to assume OutList wasn't the end of the file...
        else
            % try the second
            [value2] = sscanf(line(nextindex+1:end),'%s', 1); 
            if strcmpi(value2,'OutList') || strcmpi(value2,'OUTPUTS')
                ContainsOutList = true;
                fprintf(fidOUT,'%s',line); %if we've found OutList, write the line and break 
                break; %bjj: we could continue now if we wanted to assume OutList wasn't the end of the file...
            end
        end            
    end      
    
    
    
    [value, label, isComment, ~, ~] = ParseFASTInputLine(line);
            
    if ~printTable && ~isComment && ~isempty(label)        
        
        if ~isempty(NextMatrix)                
            WriteFASTMatrix( FastPar, fidOUT, NextMatrix, newline, isInteger )
            NextMatrix = '';
        end
        
        if strcmpi(value,'"HtFract"') || strcmpi(value,'"TwrElev"') %we've reached the distributed tower properties table (and we think it's a string value so it's in quotes)            
            if ~isfield(FastPar,'TowProp')
                disp(  'WARNING: tower properties table not found in the FAST data structure.' );
                printTable = true;
            else
                WriteFASTTable(line, fidIN, fidOUT, FastPar.TowProp, FastPar.TowPropHdr, newline);
                continue; %let's continue reading the template file            
            end

        elseif strcmpi(value,'"BlFract"') %we've reached the distributed blade properties table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'BldProp')
                disp( 'WARNING: blade properties table not found in the FAST data structure.' );
                printTable = true;
            else
                WriteFASTTable(line, fidIN, fidOUT, FastPar.BldProp, FastPar.BldPropHdr, newline);
                continue; %let's continue reading the template file            
            end
            
        elseif strcmpi(label,'F_X') %we've reached the TMD spring forces table
            if ~isfield(FastPar,'TMDspProp')
                disp( 'WARNING: TMD spring forces table not found in the FAST data structure.' );
                printTable = true;
            else
                WriteFASTTable(line, fidIN, fidOUT, FastPar.TMDspProp, FastPar.TMDspPropHdr, newline);
                continue; %let's continue reading the template file            
            end
            
        elseif strcmpi(value,'"GenSpd_TLU"') %we've reached the DLL torque-speed lookup table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'DLLProp')
                disp( 'WARNING: Bladed Interface torque-speed look-up table not found in the FAST data structure.' );
                printTable = true;
            else
                WriteFASTTable(line, fidIN, fidOUT, FastPar.DLLProp, FastPar.DLLPropHdr, newline);
                continue; %let's continue reading the template file            
            end            
            
        elseif strcmpi(label,'FoilNm') || strcmpi(label,'AFNames') %we've reached the airfoil names
            if ~isfield(FastPar,'FoilNm')
                disp( 'WARNING: AeroDyn airfoil list not found in the FAST data structure.' );
                printTable = true;
            else
                WriteFASTFileList(line, fidIN, fidOUT, FastPar.FoilNm, label, newline);
                continue; %let's continue reading the template file            
            end                                     
            
        elseif strcmpi(label,'NumAlf')  %we've reached the airfoil coefficients
            line = GetLineToWrite( line, FastPar, label, TemplateFile, value );
            fprintf(fidOUT,'%s',line);
            
            line = fgets(fidIN); %get the next line from the template
            if ~isfield(FastPar,'AFCoeff')
                disp( 'WARNING: AeroDyn airfoil coefficients not found in the FAST data structure.' );
                printTable = true;
            else                
                WriteFASTTable(line, fidIN, fidOUT, FastPar.AFCoeff, FastPar.AFCoeffHdr, newline, 1);
            end            
            continue; %let's continue reading the template file            
            
        elseif strcmpi(label,'NumPointLoads')  % BeamDyn driver point-load table
            line = GetLineToWrite( line, FastPar, label, TemplateFile, value );                
            fprintf(fidOUT,'%s',line);
            
            if ~isfield(FastPar,'PointLoads')
                disp( 'WARNING: BeamDyn driver point loads not found in the FAST data structure.' );
                printTable = true;
                printTableComments = 2;
            else                
                line = fgets(fidIN); %get the next (header) line from the template
                WriteFASTTable(line, fidIN, fidOUT, FastPar.PointLoads, FastPar.PointLoadsHdr, newline, 1);
            end            
            continue; %let's continue reading the template file            
            
        elseif strcmpi(value,'"RNodes"') %we've reached the AeroDyn Blade properies table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'BldNodes')
                disp( 'WARNING: AeroDyn blade properties table not found in the FAST data structure.' );
                printTable = true;
            else
                IntegerCols = {'NFoil'};
                WriteFASTTable(line, fidIN, fidOUT, FastPar.BldNodes, FastPar.BldNodesHdr, newline, 0, IntegerCols);
                continue; %let's continue reading the template file            
            end   
            
        elseif strcmpi(value,'"BlSpn"') %we've reached the AeroDyn15 Blade properies table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'BldNodes')
                disp( 'WARNING: AeroDyn blade properties table not found in the FAST data structure.' );
                printTable = true;
            else
                IntegerCols = {'BlAFID'};
                WriteFASTTable(line, fidIN, fidOUT, FastPar.BldNodes, FastPar.BldNodesHdr, newline, 1, IntegerCols);
                continue; %let's continue reading the template file            
            end   
            
        elseif strcmpi(label,'kp_yr') %we've reached the BD key-points table
            if ~isfield(FastPar,'kp')
                disp( 'WARNING: BeamDyn key-point table not found in the FAST data structure.' );
                printTable = true;
            else
                WriteFASTTable(line, fidIN, fidOUT, FastPar.kp, FastPar.kpHdr, newline, 1);
                continue; %let's continue reading the template file            
            end   
            
        elseif strcmpi(label,'StdScale3') %we've reached the TurbSim profile table
            line = GetLineToWrite( line, FastPar, label, TemplateFile, value );
            fprintf(fidOUT,'%s',line);

            for i=1:3
                line = fgets(fidIN); %get the next line from the template
                fprintf(fidOUT,'%s',line);           % print the comment line
            end
            line = fgets(fidIN); %get the next line from the template

            if ~isfield(FastPar,'profile')
                disp( 'WARNING: TurbSim profile table not found in the FAST data structure.' );
                printTable = true;
                printTableComments = 2;
            else
                WriteFASTTable(line, fidIN, fidOUT, FastPar.profile, [], newline, 0);
                continue; %let's continue reading the template file            
            end
        elseif strcmpi(value,'"WndSpeed"') %we've reached the cases table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'Cases')
                disp( 'WARNING: AeroDyn driver cases properties table not found in the FAST data structure.' );
                printTable = true;
            else
                WriteFASTTable(line, fidIN, fidOUT, FastPar.Cases, FastPar.CasesHdr, newline);
                continue; %let's continue reading the template file            
            end   
            
        elseif strcmpi(label,'NOPRINT') || strcmpi(label,'PRINT')
            continue;  % this comes from AeroDyn BldNodes table                                    

        elseif strcmpi(value,'"Name"') %we've reached the MoorDyn line types table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'LineTypes')
                disp( 'WARNING: MoorDyn line types table not found in the FAST data structure.' );
                printTable = true;
            else
                WriteFASTTable(line, fidIN, fidOUT, FastPar.LineTypes, FastPar.LineTypesHdr, newline, 1); %write the MoorDyn line types table 
                for k = 1:NTypes_old
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end                
                continue; %let's continue reading the template file            
            end   
        elseif strcmpi(value,'"Node"') %we've reached the MoorDyn connection properties table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'ConProp')
                disp( 'WARNING: MoorDyn connection properties table not found in the FAST data structure.' );
                printTable = true;
            else
                IntegerCols = {'Node'};
                WriteFASTTable(line, fidIN, fidOUT, FastPar.ConProp, FastPar.ConPropHdr, newline, 1, IntegerCols); %write the MoorDyn connection properties table
                for k = 1:NConnects_old
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end
                continue; %let's continue reading the template file            
            end
        elseif strcmpi(value,'"Line"') %we've reached the MoorDyn line properties table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'LineProp')
                disp( 'WARNING: MoorDyn line properties table not found in the FAST data structure.' );
                printTable = true;
            else
                IntegerCols = {'Line','NumSegs','NodeAnch','NodeFair'};
                WriteFASTTable(line, fidIN, fidOUT, FastPar.LineProp, FastPar.LinePropHdr, newline, 1, IntegerCols); %write the MoorDyn line properties table
                for k = 1:NLines_old
                    fgets(fidIN); %skip the table content from the template file, i.e. prevent it from being written in the new file
                end                
                continue; %let's continue reading the template file            
            end
            
        else

            line = GetLineToWrite( line, FastPar, label, TemplateFile, value );

            if strcmpi(label,'GlbPos(3)')
                NextMatrix = 'DCM';
                isInteger  = false;
            elseif strcmpi(label,'kp_total')
                NextMatrix = 'MemberKeyPtTable';
                isInteger  = true;
            elseif strcmpi(label,'NTypes') %we've reached MoorDyn parameter NTypes, so we save its value from the template file to be able to skip the table content from the template file when writing the new file
                NTypes_old = value;
            elseif strcmpi(label,'NConnects') %we've reached MoorDyn parameter NConnects, so we save its value from the template file to be able to skip the table content from the template file when writing the new file
                NConnects_old = value;
            elseif strcmpi(label,'NLines') %we've reached MoorDyn parameter NLines, so we save its value from the template file to be able to skip the table content from the template file when writing the new file
                NLines_old = value;
            end            
                
        end
        
    else % isComment || length(label) == 0 || printTable (i.e. tables must end with comments)
        if isComment
            if printTableComments == 0
                printTable = false;     % we aren't reading a table (if we were, we reached the end)
            else
                printTableComments = printTableComments - 1;
            end
        else
            if ~isempty(NextMatrix)                
                WriteFASTMatrix( FastPar, fidOUT, NextMatrix, newline, isInteger )
                NextMatrix = '';
            end
            continue;           % don't print this line without a label (or inside a table)
        end
    end       
    
    %write this line into the output file
    fprintf(fidOUT,'%s',line);
end

if ContainsOutList
    if isfield(FastPar,'OutList')
        OutListChar = char(FastPar.OutList);  %this will line up the comments nicer
        spaces      = repmat(' ',1,max(1,26-size(OutListChar,2)));
        %Now add the Outlist
        for io = 1:length(FastPar.OutList)
            fprintf(fidOUT,'%s',[OutListChar(io,:) spaces FastPar.OutListComments{io} newline]);
        end
    else
        disp( 'WARNING: OutList was not found in the FAST data structure. The OutList field will be empty.' );        
    end

        %Now add the close of file
    fprintf(fidOUT,'END of input file (the word "END" must appear in the first 3 columns of this last OutList line)');
    fprintf(fidOUT,newline);
    fprintf(fidOUT,'---------------------------------------------------------------------------------------');
    fprintf(fidOUT,newline);
end

fclose(fidIN);
fclose(fidOUT);
return;
end %end function

function [line] = GetLineToWrite( line, FastPar, label, TemplateFile, value )

    indx = strcmpi( FastPar.Label, label );
    if any( indx )

        if sum(indx) > 1 % we found more than one....
            vals2Write = FastPar.Val{indx};
            disp( ['WARNING: multiple occurrences of ' label ' in the FAST data structure.'] );
        end

        % The template label matches a label in FastPar
        %  so let's use the old value.
        indx2 = find(indx,1,'first');       
        val2Write = FastPar.Val{indx2}; 

            % print the old value at the start of the line,
            % using an appropriate format
        if isnumeric(val2Write)
            writeVal= getNumericVal2Write( val2Write, '%11G' );
            if isscalar(writeVal) && any( str2num(writeVal) ~= val2Write ) %we're losing precision here!!!
                writeVal=getNumericVal2Write( val2Write, '%15G' );
            end
        else
            writeVal = [val2Write repmat(' ',1,max(1,11-length(val2Write)))];
        end


        idx = strfind( line, label ); %let's just take the line starting where the label is first listed            
        line = [writeVal '   ' line(idx(1):end)];            

    else
        disp( ['WARNING: ' label ' not found in the FAST data structure. Default value listed below (from template file, ' TemplateFile ') will be used instead:'] )
        disp( value );
        disp( '' );            
    end


return;
end

function [writeVal] = getNumericVal2Write( val2Write, fmt )
    writeVal = sprintf(fmt,val2Write(1));
    if ~isscalar(val2Write) %Check for the special case of an array
        writeVal = [writeVal sprintf([',' fmt],val2Write(2:end)) ' '];
    end
    return;
end

function WriteFASTTable( HdrLine, fidIN, fidOUT, Table, Headers, newline, NumUnitLines, IntegerCols )

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    if strncmp(HdrLine,'--------------------------------------------', 20)
        % this assumes we are using TurbSim profiles file
        nc = size(Table,2); 
    else
        
        
        
        if contains(HdrLine,',')
            TmpHdr = textscan(HdrLine,'%s','Delimiter',','); %comma-delimited headers
        else
            TmpHdr = textscan(HdrLine,'%s');
        end
        TemplateHeaders = TmpHdr{1};
        if (strcmp(TemplateHeaders{1},'!'))
            TemplateHeaders = TemplateHeaders(2:end);
        end
        nc = length(TemplateHeaders);
    end
    
    fprintf(fidOUT,'%s',HdrLine);           % print the new headers

    if nargin < 7 
        NumUnitLines = 1;
    end
    
    for i=1:NumUnitLines
        fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    end
        
    if ~iscell(Table) && size(Table,1) < 1
        return
    end
    
    if strcmpi(TemplateHeaders{1}, 'Name') || strcmpi(TemplateHeaders{1}, 'Node') || strcmpi(TemplateHeaders{1}, 'Line')
        % We are dealing with a MoorDyn input file, so let's adjust the
        % format specifier to get a nice readable table.
        colFmtR='%-8G ';
        colFmtI='  %-5i ';
        colFmtS='%-9s ';
    else
        colFmtR='%11.7E  ';
        colFmtI='%9i      ';
        colFmtS='%s ';
    end
    
    if nargin < 8
        IntegerCols={};
    end
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    colIsInteger = false(1,nc);        
    if isempty(Headers)
        ColIndx = 1:nc;
    else
        ColIndx = ones(1,nc);
        
        for i=1:nc
            indx = strcmpi(TemplateHeaders{i}, Headers);
            if sum(indx) > 0
                ColIndx(i) = find(indx,1,'first');
                if sum(indx) ~= 1
                    disp( ['WARNING: Multiple instances of ' TemplateHeaders{i} ' column found in FAST table.'] );
                end

                indx2 = strcmpi(TemplateHeaders{i},IntegerCols);
                colIsInteger(i) = sum(indx2)>0;

            else
                if i==nc
                    disp( [ TemplateHeaders{i} ' column not found in FAST table. Last column will be missing.'] );                
                    nc = nc-1;
                else
                    error( [ TemplateHeaders{i} ' column not found in FAST table. Cannot write the table.'] );
                end
            end                
        end
    end
    
    ColIndx=ColIndx(1:nc);
    
    % now we'll write the table:    
    if iscell(Table)
        for i=1:size(Table,1)
            for j=ColIndx
                if isnumeric(Table{i,j})
                    if colIsInteger(j)
                        fmt = colFmtI;
                    else
                        fmt = colFmtR;
                    end
                else                    
                    fmt = colFmtS;
                end
                fprintf(fidOUT, fmt, Table{i,j} );
            end
            fprintf(fidOUT, newline);
        end        
    else        
        for i=1:size(Table,1) 
            fprintf(fidOUT, '%11.7E  ', Table(i,ColIndx) );  %write all of the columns
            fprintf(fidOUT, newline);
        end
    end    
end


function WriteFASTFileList( line, fidIN, fidOUT, List, label, newline )

    val2Write = List{1};
        % print the old value at the start of the line,
        % using an appropriate format
    if isnumeric(val2Write)
        writeVal = getNumericVal2Write( val2Write, '%11G' );
        if any( str2num(writeVal) ~= val2Write ) %we're losing precision here!!!
            writeVal=getNumericVal2Write( val2Write, '%15G' );
        end

    else
        writeVal = [val2Write repmat(' ',1,max(1,11-length(val2Write)))];
    end

    idx = strfind( line, label ); %let's just take the line starting where the label is first listed            
    line = [writeVal '   ' line(idx(1):end)];    

    fprintf(fidOUT,'%s',line);              % print the first value in the list, including the label
    for i=2:length(List)
        if isnumeric(List{i})
            fprintf(fidOUT,'%11G',List{i});
        else
            fprintf(fidOUT,'%s',List{i});         
        end
        fprintf(fidOUT,newline);
    end
end

function WriteFASTMatrix( FastPar, fidOUT, matrixName, newline, UseIntFormat )

    indx = strcmpi( FastPar.Label, matrixName );
    indx2 = find(indx,1,'first');
    matrix = FastPar.Val{indx2};               
                
    if UseIntFormat
        fmt = '%6i ';
    else
        fmt = '%11.7E  ';
    end
    % now we'll write the table:    
    for i=1:size(matrix,1) 
        fprintf(fidOUT, fmt, matrix(i,:) );  %write all of the columns
        fprintf(fidOUT, newline);
    end
    return;
end


function [newline] = getNewlineChar(line)

    indx = strfind(line,char(10));
    cr_indx = strfind(line,char(13));
    if isempty( indx ) 
        indx = cr_indx;
    else
        if ~isempty(cr_indx)
            indx = min( indx, cr_indx );
        end
    end
    
    if isempty( indx )
        if ismac
            newline = char(13); % '\r'; %mac
        elseif isunix
            newline = char(10); % '\n'; %linux
        else % ispc
            newline = [char(13) char(10)]; % '\r\n'; %windows
        end
    else
        newline = line(indx:end);
    end
    
    return;
end