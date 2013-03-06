function [value, label, isComment] = ParseFASTInputLine( line )

    trueFalseValues = {'true','false','t','f'};

    % determine if this is a comment line:
    firstChar = sscanf(strtrim(line),'%c',1); %read the first non-whitespace character
    
    if ~isempty( strfind( '#!-=', firstChar ) ) %comments start with any of these characters: # ! - =
        isComment = true;
        value = strtrim(line);
        label = '';
    else
        isComment = false;

        % Get the Value, number or string
        [value, cnt, ~, nextindex] = sscanf(line,'%f',1);  %First check if line begins with a number

        if cnt == 0
            [testVal, position] = textscan(line,'%q',1);  %If not look for a string instead
            if any( strcmpi(testVal,trueFalseValues) )
                value = testVal;                %this is a logical input
            else
                value = ['"' testVal{1}{1} '"']; %add quotes back around the string
            end
            nextindex = position + 1;
        end

        % Now get the label     

            % Some looping is necessary because often times,
            % old values for FAST parameters and kept next to new
            % ones seperated by a space and need to be ignored


        IsLabel = false;
        label   = '';  %initialize in case the line doesn't have a label

        while ~IsLabel && length(line) >= nextindex
            line = line(nextindex:end);

            [~, cnt, ~, nextindex] =sscanf(line,'%f',1);
            if cnt == 0 %if we've reached something besides a number

                [testVal, cnt, ~, nextindex] = sscanf(line,'%s',1);
                if any( strcmpi(testVal,trueFalseValues) )
                    %this is a logical input
                else
                    IsLabel = true;
                    label = testVal;
                end
            end

        end %while 
            
    end %not a comment

return