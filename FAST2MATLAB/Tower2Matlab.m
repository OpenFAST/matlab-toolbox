% Tower2Matlab
% Function for reading Tower input files in to a MATLAB struct.
%
%
%This function returns a structure DataOut, which contains cell arrays,
%.Val: An array of values
%.Label: An array of matching labels
%.TowProp A matrix of tower properties with columns HtFract	TMassDen
%TwFAStif	TwSSStif	TwGJStif	TwEAStif	TwFAIner	TwSSIner	TwFAcgOf	TwSScgOf

%
% In:   Tower_file    -   Name of Tower input file
%       hdrLines    -   Number of lines to skip at the top (optional)
%
% Knud A. Kragh, May 2011, NREL, Boulder
% Paul Fleming, July 2011

function DataOut = Tower2Matlab(Tower_file,hdrLines)

if nargin < 2
    hdrLines = 0;
end

fid = fopen(Tower_file,'r');
if fid == -1
    Flag = 0;
    error('Tower file could not be found')
end

%skip hdr
for hi = 1:hdrLines
    fgets(fid);
end



count=1;


while true %loop until discovering HtFract, than break
        
    % Get the Value, number or string
    testVal=fscanf(fid,'%f',1);  %First check if line begins with a number
    if isempty(testVal)
        testVal=fscanf(fid,'%s',1);  %If not look for a string instead
        if testVal(1)=='-' %if this line is a comment
            fgets(fid); %Advanced to the next line
            continue %don't do any more with this line
        end
        if strcmpi(testVal,'HtFract') %we've reached the distributed blade propreties table
            fgets(fid); %Advanced to the next line
            fgets(fid); %Advanced to the next line
            break
        end
    end

    DataOut.Val{count}=testVal; %assign Val
    
    %Now get the label
    % Now get the label, some looping is necessary because often
    % times, old values for FAST parameters and kept next to new
    % ones seperated by a space and need to be ignored
    test=0;
    while test==0
        testVal=fscanf(fid,'%f',1);
        if isempty(testVal) %if we've reached something besides a number
            testVal=fscanf(fid,'%s',1);
            test=1;
        end
    end
    DataOut.Label{count}=testVal; %Now save label

    
    fgets(fid); %Advanced to the next line
    
    %iterate
    count=count+1;
    
end %end while


%% Read in TowProp

%get the number of stations
numStations = GetFastPar(DataOut,'NTwInpSt');



%Now loop through and get all the data
for i = 1:numStations
    for col = 1:10 %10 columns currently, this could be more flexible...
        DataOut.TowProp(i,col) = fscanf(fid,'%f',1);
    end
    fgets(fid); %Advance to the next line
end
fgets(fid); %Advance to the next line

%% Read in remaining parameters (mode shapes)

while true %loop until discovering BlFract, than break
        
    % Get the Value, number or string
    testVal=fscanf(fid,'%f',1);  %First check if line begins with a number
    if isempty(testVal)
        testVal=fscanf(fid,'%s',1);  %If not look for a string instead
        if testVal(1)=='-' %if this line is a comment
            fgets(fid); %Advanced to the next line
            continue %don't do any more with this line
        end
    end
    
    DataOut.Val{count}=testVal; %assign Val
    
    %Now get the label
    % Now get the label, some looping is necessary because often
    % times, old values for FAST parameters and kept next to new
    % ones seperated by a space and need to be ignored
    test=0;
    while test==0
        testVal=fscanf(fid,'%f',1);
        if isempty(testVal) %if we've reached something besides a number
            testVal=fscanf(fid,'%s',1);
            test=1;
        end
    end
    DataOut.Label{count}=testVal; %Now save label
    
    if strcmpi(DataOut.Label{count},'TwSSM2Sh(6)')
        break %this is the end of file
    end
        
    fgets(fid); %Advanced to the next line
    
    %iterate
    count=count+1;
    
end %end while

%% Close file

fclose(fid); %close file

end %end function