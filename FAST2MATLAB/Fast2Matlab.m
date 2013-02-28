% Fast2Matlab
% Function for reading FAST input files in to a MATLAB struct.
%
%
%This function returns a structure DataOut, which contains 2 cell arrays,
%.Val: An array of values
%.Label: An array of matching labels
%.OutList: An array of variables to output
%.HdrLines: An array of the header lines (size specified at input)
%These arrays are extracted from the FAST input file
%
% In:   FST_file    -   Name of FAST input file
%       hdrLines    -   Number of lines to skip at the top (optional)
%
% Knud A. Kragh, May 2011, NREL, Boulder
%
% Modified by Paul Fleming, JUNE 2011
% Modified by Bonnie Jonkman, February 2013 (to allow us to read the 
% platform file, too)

function DataOut = Fast2Matlab(FST_file,hdrLines,DataOut)

if nargin < 2
    hdrLines = 0;
end

%----------------------Read FST main file----------------------------------
fid = fopen(FST_file,'r');

if fid == -1
    error(['FST file, ' FST_file ', could not be found'])
end

%skip hdr
for hi = 1:hdrLines
    if nargin == 3
        fgetl(fid);
    else
        DataOut.HdrLines{hi,1} = fgetl(fid); %bjj: added field for storing header lines
    end
end

%PF: Commenting this out, not sure it's necessary
%DataOut.Sections=0;

%Loop through the file line by line, looking for value-label pairs
%Stop once we've reached the OutList which this function is the last
%occuring thing before the EOF
if nargin == 3
    count = max(length(DataOut.Label),length(DataOut.Var))+1;
else
    count = 1;
end


while true %loop until discovering Outlist, than break
    skipLine = false; %reset skipline
    %Label=[]; %Re-initialize label  PF: Temp disabling this
    
    
    % Get the Value, number or string
    testVal=fscanf(fid,'%f',1);  %First check if line begins with a number
    if isempty(testVal)
        testVal=fscanf(fid,'%s',1);  %If not look for a string instead
%bjj: this won't work if we have "a space\in a file name"!!!

        %now check to see if the string in test val makes sense as a value
        if strcmpi(testVal,'false') || strcmpi(testVal,'true') || strcmp(testVal(1),'"')
%             disp(testVal) %this is a parameter
        else
%             disp([ num2str(count) ' ' testVal ] )
            skipLine = true;
            if ~strcmp(testVal(1),'-') %test if this non parameter not a comment
                DataOut.Label{count,1}=testVal;  %if not a comment, make the value the label
                DataOut.Val{count,1}=' ';
                count=count+1;
            end
            
        end
%     else
%         disp([count testVal])
    end    
    
    % Check to see if the value is Outlist
    if strcmpi(testVal,'OutList')
        fgets(fid); %Advance to the next line
        break; %testval is OutList, break the loop
    end

    if ~skipLine %if this is actually a parameter line add it
        DataOut.Val{count,1}=testVal; %assign Val
        
        
        % Now get the label, some looping is necessary because often
        % times, old values for FAST parameters and kept next to new
        % ones seperated by a space and need to be ignored
        test=0;
        while test==0
            testVal=fscanf(fid,'%f',1);
            if isempty(testVal) %if we've reached something besides a number
                testVal=fscanf(fid,'%s',1);
                if testVal(1)==',' %commas are an indication that this parameter is a list
                    %handle list case by appending list
                    DataOut.Val{count,1}=[DataOut.Val{count,1} str2num(testVal)];
                elseif ~strcmpi(testVal,'false') && ~strcmpi(testVal,'true')                        
                    test=1;
                end
            end
        end
        DataOut.Label{count,1}=testVal; %Now save label
        
        
%         if isempty(Label)==0

%         end
        count=count+1;
    end %endif
    
    fgets(fid); %Advance to the next line (read the remaining part of the line)
    
end %end while

%Now loop and read in the OutList
outCount = 0;
while true
    line = fgetl(fid);
    [outVarC, position] = textscan(line,'%q',1); %we need to get the entire quoted line
    outVar  = outVarC{1}{1};
%     [outVar, numRead] = fscanf(fid,'%q',1);
%     fgets(fid); %Advance to the next line

    if isnumeric(line) %loop until we reach the word END or hit the end of the file
        break;
    else
        indx = strfind(upper(outVar),'END');
        if (~isempty(indx) && indx == 1)
            break;
        else
            outCount = outCount + 1;
            DataOut.OutList{outCount,1} = ['"' outVar '"'];
            if position < length(line)
              DataOut.OutListComment{outCount,1} = line((position+1):end);
            else
              DataOut.OutListComment{outCount,1} = ' ';
            end
        end
    end
end %end while

fclose(fid); %close file

end %end function