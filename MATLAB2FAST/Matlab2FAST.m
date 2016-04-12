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
    if isfield(FastPar, 'HdrLines') && hi ~= 1 && hi <= length(FastPar.HdrLines) %first line always comes from template file
        fprintf(fidOUT,'%s',FastPar.HdrLines{hi,1}); %does not contain the line ending
        fprintf(fidOUT,newline);                     %so print it here instead
    else
        fprintf(fidOUT,'%s',line);
    end
end

printTable = false; %assume we'll get the tables from the FastPar data structure;

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
            
    if ~printTable && ~isComment && ~isempty(label)        
        
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
            if ~isfield(FastPar,'AFCoeff')
                disp( 'WARNING: AeroDyn airfoil coefficients not found in the FAST data structure.' );
                printTable = true;
            else
                line = GetLineToWrite( line, FastPar, label, TemplateFile, value );
                fprintf(fidOUT,'%s',line);
                line = fgets(fidIN); %get the next line from the template
                WriteFASTTable(line, fidIN, fidOUT, FastPar.AFCoeff, FastPar.AFCoeffHdr, newline, true);
                continue; %let's continue reading the template file            
            end            
            
        elseif strcmpi(value,'"RNodes"') %we've reached the AeroDyn Blade properies table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'BldNodes')
                disp( 'WARNING: AeroDyn blade properties table not found in the FAST data structure.' );
                printTable = true;
            else
                IntegerCols = {'NFoil'};
                WriteFASTTable(line, fidIN, fidOUT, FastPar.BldNodes, FastPar.BldNodesHdr, newline, false, IntegerCols);
                continue; %let's continue reading the template file            
            end   
            
        elseif strcmpi(value,'"BlSpn"') %we've reached the AeroDyn15 Blade properies table (and we think it's a string value so it's in quotes)
            if ~isfield(FastPar,'BldNodes')
                disp( 'WARNING: AeroDyn blade properties table not found in the FAST data structure.' );
                printTable = true;
            else
                IntegerCols = {'BlAFID'};
                WriteFASTTable(line, fidIN, fidOUT, FastPar.BldNodes, FastPar.BldNodesHdr, newline, true, IntegerCols);
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
        else

            line = GetLineToWrite( line, FastPar, label, TemplateFile, value );
            
        end
    else % isComment || length(label) == 0 || printTable (i.e. tables must end with comments
        if isComment
            printTable = false;     % we aren't reading a table (if we were, we reached the end) 
        else
            if ~printTable
                continue;           % don't print this line without a label
            end
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

function WriteFASTTable( HdrLine, fidIN, fidOUT, Table, Headers, newline, printUnits, IntegerCols )

    % we've read the line of the template table that includes the header 
    % let's parse it now:
    TmpHdr = textscan(HdrLine,'%s');
    TemplateHeaders = TmpHdr{1};
    if (strcmp(TemplateHeaders{1},'!'))
        TemplateHeaders = TemplateHeaders(2:end);
    end
    nc = length(TemplateHeaders);

    fprintf(fidOUT,'%s',HdrLine);           % print the new headers
    if nargin < 7 || printUnits
        fprintf(fidOUT,'%s',fgets(fidIN));      % print the new units (we're assuming they are the same)
    end
    
    colFmtR='%11.7E  ';
    colFmtI='%9i      ';
    if nargin < 8
        IntegerCols={};
    end
    
    % let's figure out which columns in the old Table match the headers
    % in the new table:
    ColIndx = ones(1,nc);
    colIsInteger = false(1,nc);

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
                display( [ TemplateHeaders{i} ' column not found in FAST table. Last column will be missing.'] );                
                nc = nc-1;
            else
                error( [ TemplateHeaders{i} ' column not found in FAST table. Cannot write the table.'] );
            end
        end                
    end
    
    
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
                    fmt = '%s ';
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