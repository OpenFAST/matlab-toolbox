% AeroDyn2Matlab
% Function for reading AD input files in to a MATLAB struct.
%
%
%This function returns a structure DataOut, which contains 2 cell arrays,
%.Val: An array of values
%.Label: An array of matching labels
%.FoilNm: A Cell array of foil names
%.BldNodes A matrix of blade nodes with columns RNodes, AeroTwst DRNodes
%Chord and Nfoil
%.PrnElm An array determining whether or not to print a given element
%These arrays are extracted from the FAST input file
%
% In:   AD_file    -   Name of AD input file
%       hdrLines    -   Number of lines to skip at the top (optional)
%
% Knud A. Kragh, May 2011, NREL, Boulder
%
% Modfied by Paul Fleming, JUNE 2011

function DataOut = AeroDyn2Matlab(AD_file,hdrLines)

if nargin < 2
    hdrLines = 0;
end

%----------------------Read FST main file----------------------------------
fid = fopen([AD_file],'r');
if fid == -1
    Flag = 0;
    error('AD file could not be found')
end

%skip hdr
for hi = 1:hdrLines
    fgets(fid);
end

%PF: Commenting this out, not sure it's necessary
%DataOut.Sections=0;

%Loop through the file line by line, looking for value-label pairs
%Stop once we've reached the FoilNm, meaning we've reached the list of foil
%names
count=1;


while true %loop until discovering FoilNm, than break
    
    
    % Get the Value, number or string
    testVal=fscanf(fid,'%f',1);  %First check if line begins with a number
    if isempty(testVal)
        testVal=fscanf(fid,'%s',1);  %If not look for a string instead
    end
    
    %assign value
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
    
    %check if the last label read is the NumFoil
    if strmatch(DataOut.Label{count},'NumFoil')
        break; %if it does end the loop
    end
    
    %if not NumFoil iterate
    count=count+1;
    
    
    % end %endif %PF no skipping in AD
end %end while


%% Read in FoilNm list
numFoil = GetFastPar(DataOut,'NumFoil');
for i = 1:numFoil
    DataOut.FoilNm{i} = fscanf(fid,'%s',1);
    fgets(fid); %Advance to the next line
end

%% Read in BldNodes and PrnElm

%Get the number of blade nodes
DataOut.Val{count+1}=fscanf(fid,'%f',1); %Get Blade Nodes
BldNodes = DataOut.Val{count+1};
DataOut.Label{count+1} = fscanf(fid,'%s',1);

%skip the header row
fgets(fid);

%Now loop through and get all the data
for i = 1:BldNodes
    fgets(fid); %Advance to the next line
    for col = 1:5
        DataOut.BldNodes(i,col) = fscanf(fid,'%f',1);
    end
    DataOut.PrnElm{i} = fscanf(fid,'%s',1);
end

fclose(fid); %close file

end %end function