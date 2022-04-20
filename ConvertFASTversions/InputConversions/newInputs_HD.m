function [HDP, SSP] = newInputs_HD(HDPar, SEAPar)
% [HDP] = newInputs_HD_v2_02_00(HDPar)
% HDP is the data structure containing already-filled parameters for
% HydroDyn. We're going to add existing fields and based on the old ones.


    HDP = HDPar;  
%     n = length(HDP.Label);

    % sea state parameters:
    if isempty(SEAPar)
        SSP = HDP;
        SSP.OutList = {};
        SSP.OutListComments = {};
    else
        SSP = SEAPar;
    end 
    
 % v3 Specification
    

    %----------------------------------------------------------------------
    % Sort output channels:
    %----------------------------------------------------------------------
    if isfield(HDP,'OutList')
   
        [OutList, OutListComments] = GetOutListVars(HDP.OutList, HDP.OutListComments);
        numOuts = length(OutList);    
    
        if numOuts > 0
            
            % we'll see which of the modules these match
            IsSeaChannel = startsWith(lower(OutList),'wave');

            HDP.OutList         = OutList(~IsSeaChannel);
            HDP.OutListComments = OutListComments(~IsSeaChannel);

            SSP.OutList         = [SSP.OutList;         OutList(IsSeaChannel)];
            SSP.OutListComments = [SSP.OutListComments; OutListComments(IsSeaChannel)];
                                    
        else
            disp('WARNING: there are no outputs to be generated.')
        end
    end

    
end 
