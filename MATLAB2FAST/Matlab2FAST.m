% Matlab2FAST
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


function Matlab2FAST(FastPar,TemplateFile,OutputFilename,hdrLines)

newline = '\r\n';

if nargin < 4
    hdrLines = 0;
end

%Declare file IDs from the template to the resulting file
fidIN = fopen(TemplateFile,'r');
if fidIN == -1
    error([TemplateFile ' not found'])
end
fidOUT = fopen(OutputFilename,'w');
if fidOUT == -1
    error(['Can''t create ' OutputFilename])
end

for hi = 1:hdrLines
    line    = fgets(fidIN);        
%     newline = '\r' %mac
%     newline = '\n' %linux
%     newline = '\r\n' %windows;
    
%     fprintf(fidOUT,'%s',line);
    fprintf(fidOUT,'%s',FastPar.HdrLines{hi,1});
    fprintf(fidOUT,newline);
end


%loop through the template up until OUTLIST
while true
    line = fgets(fidIN); %get the next line from the template
    %bjj: we could get the line feed character(s) here CHAR(13)=CR(\r) CHAR(10)=LF(\n):
    
    if ~isempty(strfind(line,'OutList')) 
        fprintf(fidOUT,'%s',line); %if we've found OutList, write the line and break        
        break;
    elseif isnumeric(line) %we reached the end of the file
        break;
    end
    
    %now see if there is a match to a known parameter
    idx = inf;  %inf means there is no match (this is an upper limit on number of lines in the file)
    label2Write = []; %keep track of the label to make sure we find the longest matching label
    for i = 1:length(FastPar.Label)
        idxTemp = strfind(upper(line),upper(FastPar.Label{i})); %allow for differences in case
        if ~isempty(idxTemp) %if there is a match,
            if idxTemp(1) < idx %if this match occurs before other matches use it                
                label2Write = FastPar.Label{i}; %store this label
                idx =idxTemp(1);
                val2Write = FastPar.Val{i};               
            elseif idxTemp(1) == idx %if this match equals other matches check if it is the longer match
                if (length(FastPar.Label{i}) > length(label2Write)) %and this label is longer than others (avoid coincident substring matches)
                    label2Write = FastPar.Label{i}; %store this label
                    idx =idxTemp(1);
                    val2Write = FastPar.Val{i};
                end
            end
        end
    end
    %if we found a match
    if ( isfinite(idx) )
        if(line(1)~='-') %not a comment
            
            if isnumeric(val2Write)
                writeVal = sprintf('%11G',val2Write(1));
                if ~isscalar(val2Write) %Check for the special case of an array
                    writeVal = [writeVal sprintf(',%11G',val2Write(2:end)) ' '];
                end
            else
                writeVal = [val2Write repmat(' ',1,max(1,11-length(val2Write)))];
            end
            
            line = [writeVal '   ' line(idx(1):end)];
        end %endif %not a comment
    end %endif %found a match
    
    
    %write this line into the output file
    fprintf(fidOUT,'%s',line);
end

if isfield(FastPar,'OutList')
    OutListChar = char(FastPar.OutList);  %this will line up the comments nicer
    spaces      = repmat(' ',1,max(1,30-size(OutListChar,2)));
    %Now add the Outlist
    for io = 1:length(FastPar.OutList)
        fprintf(fidOUT,[OutListChar(io,:) spaces FastPar.OutListComment{io} newline]);
    end
end

%Now add the close of file
fprintf(fidOUT,newline);
if (~isnumeric(line))
fprintf(fidOUT,'END of FAST input file (the word "END" must appear in the first 3 columns of this last line).');
fprintf(fidOUT,newline);
end
fprintf(fidOUT,'--------------------------------------------------------------------------------');
fprintf(fidOUT,newline);
fclose(fidIN);
fclose(fidOUT);
end %end function
