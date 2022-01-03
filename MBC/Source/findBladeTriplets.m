function [Triplets, NTriplets] = findBladeTriplets(rotFrame,Desc )

%% Find the number of, and indices for, triplets in the rotating frame:
    chkStr = {'[Bb]lade \d', '[Bb]lade [Rr]oot \d', 'BD_\d', '[Bb]\d', '[Bb]lade\d', 'PitchBearing\d', '\d'};

    NTriplets = 0;              % first initialize to zero
    Triplets = [];
    origDesc = Desc;
    
    % hack for ElastoDyn state names (remove unnecessary text in parenthesis)
    for i=1:length(rotFrame)
        ix = strfind(Desc{i},'(internal DOF index = ');
        if ~isempty(ix)
            ix2 = strfind(Desc{i},'))');
            Desc{i} = [Desc{i}(1:ix-1) Desc{i}(ix2+2:end)];
        end 
    end
    
    for i = 1:length(rotFrame)  % loop through inputs/outputs/states
        if rotFrame(i)          % this is in the rotating frame
            Tmp = zeros(1,3);
            foundTriplet = false;
            foundBladeNumber = false;
            for chk = 1:length(chkStr)
                BldNoCol = regexp(Desc{i},chkStr{chk},'match');
                if ~isempty(BldNoCol)
                    foundBladeNumber = true;

                        % create another regular expression to find the
                        % exact match on a different blade:
                    str = regexp(Desc{i},BldNoCol{1},'split'); %this should return the strings before and after the match
                    FirstStr = [str{1} BldNoCol{1}(1:end-1) '.' ];
                    checkThisStr = [FirstStr str{2}];
                    
                        %we need to get rid of the special characters that
                        %may exist in Desc{}:
                    checkThisStr = strrep(strrep(strrep(checkThisStr,')','\)'), '(', '\('),'^','\^'); 
                    FirstStr     = strrep(strrep(strrep(FirstStr,    ')','\)'), '(', '\('),'^','\^'); 
                    
                    k = str2double(BldNoCol{1}(end));
                    Tmp(k) = i;
                    break;
                end % check the next regular expression if necessary;
            end

                % find the other match values
            if foundBladeNumber 
                for j = (i+1):length(rotFrame)           % loop through all remaining control inputs
                    if rotFrame(j)                       % this is in the rotating frame
                        BldNoCol = regexp(Desc{j},checkThisStr,'match'); % match all but the blade number
                        if ~isempty(BldNoCol)
                            Num = regexp(Desc{j},FirstStr,'match'); % match all but the blade number
                            k = str2double(Num{1}(end));
                            Tmp(k) = j;                             % save the indices for the remaining blades
                            if ( all(Tmp) )                         % true if all the elements of Tmp are nonzero; thus, we found a triplet of rotating indices
                                foundTriplet = true;                
                                
                                NTriplets = NTriplets + 1;          % this  is  the number  of  control input triplets in the rotating frame
                                Triplets(NTriplets,:) = Tmp;        % these are the indices for control input triplets in the rotating frame
                                
                                % we'll set rotFrame to false so that we don't have to check the found channels again; also allows us to throw error if we have a rotating channel that doesn't have a unique match
                                rotFrame(Tmp) = false;                                                                    
                                
                                break;
                            end
                        end
                    end 
                end  % j - all remaining active control inputs
                
                if (~foundTriplet)
                     disp( ['Rotating channel "' Desc{i} '" does not form a unique blade triplet. Blade(s) not found: ' num2str(find(Tmp==0)) ] )
                end
                
            else
                error( ['Could not find blade number in rotating channel "' Desc{i} '".'] )                
            end

        end % in the rotating frame
    end  % for i 

    return;
end
