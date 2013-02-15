% Blade2Matlab
% Function for reading Blade input files in to a MATLAB struct.
%
%
%This function returns a structure DataOut, which contains cell arrays,
%.Val: An array of values
%.Label: An array of matching labels
%.BldProp A matrix of blade properties with columns BlFract	AeroCent
%                  StrcTwst	BMassDen	FlpStff	EdgStff	GJStff	EAStff	Alpha	FlpIner	EdgIner	PrecrvRef	PreswpRef	FlpcgOf	EdgcgOf	FlpEAOf	EdgEAOf

%
% In:   Blade_file    -   Name of Blade input file
%       hdrLines    -   Number of lines to skip at the top (optional)
%
% Knud A. Kragh, May 2011, NREL, Boulder
% Paul Fleming, July 2011

function DataOut = Blade2Matlab(Blade_file,hdrLines)

if nargin < 2
    hdrLines = 0;
end

%----------------------Read FST main file----------------------------------
fid = fopen([Blade_file],'r');
if fid == -1
    Flag = 0;
    error('Blade file could not be found')
end

%skip hdr
for hi = 1:hdrLines
    fgets(fid);
end


%Loop through the file line by line, looking for value-label pairs
%Stop once we've reached the FoilNm, meaning we've reached the list of foil
%names
count=1;


while true %loop until discovering BlFract, than break
        
    % Get the Value, number or string
    testVal=fscanf(fid,'%f',1);  %First check if line begins with a number
    if isempty(testVal)
        testVal=fscanf(fid,'%s',1);  %If not look for a string instead
        if testVal(1)=='-' %if this line is a comment
            fgets(fid); %Advanced to the next line
            continue %don't do any more with this line
        end
        if strcmpi(testVal,'BlFract') %we've reached the distributed blade propreties table
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


%% Read in BldPropm

%get the number of stations
numStations = GetFastPar(DataOut,'NBlInpSt');



%Now loop through and get all the data
for i = 1:numStations
    for col = 1:17
        DataOut.BldProp(i,col) = fscanf(fid,'%f',1);
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
    
    if strcmpi(DataOut.Label{count},'BldEdgSh(6)')
        break %this is the end of file
    end
        
    fgets(fid); %Advanced to the next line
    
    %iterate
    count=count+1;
    
end %end while

%% Close file

fclose(fid); %close file

end %end function