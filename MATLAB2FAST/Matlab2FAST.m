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


function Matlab2FAST(FastPar,TemplateFile,OutputFilename)


%Declare file IDs from the template to the resulting file
fidIN = fopen(TemplateFile,'r');
if fidIN == -1
    error([TemplateFile ' not found'])
end
fidOUT = fopen(OutputFilename,'w');
if fidOUT == -1
    error(['Can''t create ' OutputFilename])
end


%loop through the template up until OUTLIST
while true
    line = fgets(fidIN); %get the next line from the template
    
    if ~isempty(strfind(line,'OutList'))
        fprintf(fidOUT,'%s',line); %if we've found OutList, write the line and break
        break;
    end
    
    %now see if there is a match to a known parameter
    idx = 9999; %9999 code is no match
    label2Write = []; %keep track of the label to make sure we find the longest matching label
    for i = 1:length(FastPar.Label)
        idxTemp = strfind(line,FastPar.Label{i});
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
    if (idx ~= 9999)
        if(line(1)~='-') %not a comment
            
            %build a string version of the value
            writeVal = num2str(val2Write);
            
            
            %Check for the special case of an array
            if isnumeric(val2Write)
                if ~isscalar(val2Write)
                    writeVal = [];
                    for ii = 1:length(val2Write)
                        writeVal = [writeVal ',' num2str(val2Write(ii))];
                    end
                    writeVal(1) = []; %get rid of leading comma
                end
            end
            
            %add space padding to make it look nice
            if length(writeVal) < 11
                for i = 1:12 - length(writeVal)
                    writeVal = [writeVal ' '];
                end
            else
                writeVal = [writeVal '     '];
            end
            
            line = [writeVal line(idx(1):end)];
        end %endif
    end %endif
    
    
    %write this line into the output file
    fprintf(fidOUT,'%s',line);
end

%Now add the Outlist
for io = 1:length(FastPar.OutList)
    fprintf(fidOUT,[FastPar.OutList{io} '\n']);
end

%Now add the close of file
fprintf(fidOUT,'\n');
fprintf(fidOUT,'END of FAST input file (the word "END" must appear in the first 3 columns of this last line).\n');
fprintf(fidOUT,'--------------------------------------------------------------------------------\n');
fclose(fidIN);
fclose(fidOUT);
end %end function
