% Matlab2Blade
% Function for creating a new Blade file given:
% 1) A Blade parameter structure
% 2) An input template file
% 3) An output filename
%
% In:   BDPar         -   An AD parameter list
%       TemplateFile    -   A .ipt file to use as a template
%       OutputFilename  -   Desired filename of output .ipt file
%
% Paul Fleming, JULY 2011
% Using code copied from functions written by Knud Kragh, 2011


function Matlab2Blade(BDPar,TemplateFile,OutputFilename)


%Declare file IDs from the template to the resulting file
fidIN = fopen(TemplateFile,'r');
if fidIN == -1
    error([TemplateFile ' not found'])
end
fidOUT = fopen(OutputFilename,'w');
if fidOUT == -1
    error(['Cant create ' OutputFilename])
end


%% loop through the template up until the value is BlFract
while true
    line = fgets(fidIN); %get the next line from the template
    
    if ~isempty(strfind(line,'BlFract'))
        %write the HDR lines to file
        fprintf(fidOUT,'%s',line); %write the current line to file
        line = fgets(fidIN); %get the next line from the template
        fprintf(fidOUT,'%s',line); %write the current line to file
        break
    end
    
    
    
    %see if there is a match to a known parameter
    idx = 9999; %9999 code is no match
    label2Write = []; %keep track of the label to make sure we find the longest matching label
    for i = 1:length(BDPar.Label)
        idxTemp = strfind(line,BDPar.Label{i});
        if ~isempty(idxTemp) %if there is a match,
            if idxTemp(1) < idx %if this match occurs before other matches use it
                
                label2Write = BDPar.Label{i}; %store this label
                idx =idxTemp(1);
                val2Write = BDPar.Val{i};
                
            elseif idxTemp(1) == idx %if this match equals other matches check if it is the longer match
                if (length(BDPar.Label{i}) > length(label2Write)) %and this label is longer than others (avoid coincident substring matches)
                    label2Write = BDPar.Label{i}; %store this label
                    idx =idxTemp(1);
                    val2Write = BDPar.Val{i};
                end
            end
        end
    end
    

    
    %if we found a match
    if (idx ~= 9999)
        if(line(1)~='-') %not a comment
            
            %build a string version of the value
            writeVal = num2str(val2Write);
            
            
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

%% now loop through and print out blade props matrix
for i = 1:GetFastPar(BDPar,'NBlInpSt')
    for j = 1:size(BDPar.BldProp,2)
        fprintf(fidOUT,[num2str(BDPar.BldProp(i,j)) '\t']);
    end
    fprintf(fidOUT,'\n');
    fgets(fidIN);
    %fprintf(fidOUT,[num2str(BDPar.BldNodes(i,1)),'\t',num2str(BDPar.BldNodes(i,2)),'\t',num2str(BDPar.BldNodes(i,3)),'\t',num2str(BDPar.BldNodes(i,4)),'\t',num2str(BDPar.BldNodes(i,5)),'\t',BDPar.PrnElm{i},'\n']);
end


%% Now go back to normal parameter writing (Blade Mode Shapes)
while true
    line = fgets(fidIN); %get the next line from the template
    
    
    %see if there is a match to a known parameter
    idx = 9999; %9999 code is no match
    label2Write = []; %keep track of the label to make sure we find the longest matching label
    for i = 1:length(BDPar.Label)
        idxTemp = strfind(line,BDPar.Label{i});
        if ~isempty(idxTemp) %if there is a match,
            if idxTemp(1) < idx %if this match occurs before other matches use it
                
                label2Write = BDPar.Label{i}; %store this label
                idx =idxTemp(1);
                val2Write = BDPar.Val{i};
                
            elseif idxTemp(1) == idx %if this match equals other matches check if it is the longer match
                if (length(BDPar.Label{i}) > length(label2Write)) %and this label is longer than others (avoid coincident substring matches)
                    label2Write = BDPar.Label{i}; %store this label
                    idx =idxTemp(1);
                    val2Write = BDPar.Val{i};
                end
            end
        end
    end
    
    
    %if we found a match
    if (idx ~= 9999)
        if(line(1)~='-') %not a comment
            
            %build a string version of the value
            writeVal = num2str(val2Write);
            
            
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
    
    if strcmpi(label2Write,'BldEdgSh(6)') %we've reached the EOF
        break
    end
end



%% Close files
fclose(fidIN);
fclose(fidOUT);
end %end function
