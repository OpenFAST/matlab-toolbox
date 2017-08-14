function [Triplets, NTriplets] = findBladeTriplets(rotFrame,Desc )

%% Find the number of, and indices for, triplets in the rotating frame:
    chkStr = {'[Bb]lade \d', '[Bb]lade [Rr]oot \d', '[Bb]\d', '\d'};

    NTriplets = 0;              % first initialize to zero
    Triplets = [];
    for i = 1:size(rotFrame)    % loop through inputs/outputs
        if rotFrame(i)          % this is in the rotating frame
            Tmp = zeros(1,3);
            foundIt = false;
            for chk = 1:size(chkStr)
                BldNoCol = regexp(Desc{i},chkStr{chk},'match');
                if ~isempty(BldNoCol)
                    foundIt = true;

                    str = regexp(Desc{i},BldNoCol{1},'split'); %this should return the strings before and after the match
                    FirstStr = [str{1} BldNoCol{1}(1:end-1) '.' ];
                    checkThisStr = [FirstStr str{2}];
                    checkThisStr = strrep(strrep(strrep(checkThisStr,')','\)'), '(', '\('),'^','\^'); %we need to get rid of the special characters
                    k = str2double(BldNoCol{1}(end));
                    Tmp(k) = i;
                    break;
                end % check the next one;
            end

                % find the other match values
            if foundIt 
                for j = (i+1):size(rotFrame)	% loop through all remaining control inputs
                    if rotFrame(j)          % this is in the rotating frame
                        BldNoCol = regexp(Desc{j},checkThisStr,'match'); % match all but the blade number
                        if ~isempty(BldNoCol)                      
                            Num = regexp(Desc{j},FirstStr,'match'); % match all but the blade number
                            k = str2double(Num{1}(end));
                            Tmp(k) = j; % save the indices for the remaining blades                   
                            if ( all(Tmp ~=0) )                     % true if all the elements of Tmp are nonzero; thus, we found a triplet of rotating indices
                                NTriplets = NTriplets + 1;          % this  is  the number  of  control input triplets in the rotating frame
                                Triplets(NTriplets,:) = Tmp;        % these are the indices for control input triplets in the rotating frame
                                break;
                            end
                        end
                    end 
                end  % j - all remaining active control inputs            
            end

        end % in the rotating frame
    end  % for i 

    return;
end