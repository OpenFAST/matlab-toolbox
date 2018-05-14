function [Triplets, NTriplets] = findBladeTriplets_EDstate(rotFrame,Desc )

% descriptions of ED states contain the blade number twice. This is the old
% method of comparing strings.

    %   frame: 
    NTriplets = 0;                  % first initialize to zero 
    for i = 1:length(rotFrame)  % loop through all active (enabled) DOFs 
        if rotFrame(i)  % this is a state in the rotating frame 

            col = strfind(Desc{i},'blade');              % find the starting index of the string 'blade' 
            if ~isempty(col)                             % true if the Desc{i} contains the string 'blade' 
                k = str2double(Desc{i}(col+6));          % save the blade number for the initial blade 
                Tmp = zeros(1,3);                        % first initialize to zero 
                Tmp(k) = i;                              % save the index for the initial blade 
                

                % find the other match values

                for j = (i+1):length(rotFrame)           % loop through all remaining active (enabled) DOFs 
                    if strncmp(Desc{j},Desc{i},col)      % true if we have the same state from a different blade 
                        k = str2double(Desc{j}(col+6));  % save the blade numbers for the remaining blades 

                        Tmp(k) = j;                      % save the indices for the remaining blades
                        if ( all(Tmp) )                  % true if all the elements of Tmp are nonzero; thus, we found a triplet of rotating indices 
                            NTriplets = NTriplets + 1;   % this  is  the number  of  state triplets in the rotating frame 
                            Triplets(NTriplets,:) = Tmp; % these are the indices for state triplets in the rotating frame
                            break; 
                        end 
                    end 
                end  % j 
                
            end 

        end 
    end % i - all active (enabled) DOFs
    
    return;
end
