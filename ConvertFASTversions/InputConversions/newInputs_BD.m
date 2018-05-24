function [BDP,BDdriverP] = newInputs_BD(BDPar, BDdriver)
%% [BDP,BDdriverP] = newInputs_BD(BDPar, BDdriver)
% BDP is the data structure containing already-filled parameters for
% BeamDyn. We're going to add existing fields and based on the old ones.
% BDdriver is the data structure containg already-filled parameters for 
% the BeamDyn driver. It is optional.

    
    %----------------------------------------------------------------------
    % How many fields currently exist in BeamDyn:
    %----------------------------------------------------------------------      
    BDP = BDPar;    % by default, we'll start with the old fields
    n   = length(BDP.Label);    

    %----------------------------------------------------------------------
    % How many fields currently exist in BeamDyn Driver:
    %----------------------------------------------------------------------      
    if nargin > 1
        BDdriverP = BDdriver;  % by default, we'll start with the old fields
        nd = length(BDdriver.Label);    
    elseif nargout < 1
        error('Incorrect number of arguments for BeamDyn driver parameters');
    else
        nd = -1;
    end
    
    %----------------------------------------------------------------------       
    % add QuasiStaticInit if it doesn't exist:
    %----------------------------------------------------------------------       
    [analysis_type, err1] = GetFASTPar(BDP,'analysis_type');
    if ~err1
    
        if analysis_type==3
            QuasiStaticInit  = 'True';
            DynamicSolve     = 'True';
        else
            QuasiStaticInit  = 'False';
            
            if analysis_type==1
                DynamicSolve = 'False';
            else
                DynamicSolve = 'True';
            end
                
        end

        n = n + 1;
        BDP.Label{n} = 'QuasiStaticInit';
        BDP.Val{n}   =  QuasiStaticInit;
        
        if nd > 0
            nd = nd + 1;
            BDdriverP.Label{nd} = 'DynamicSolve';
            BDdriverP.Val{nd}   =  DynamicSolve;
        end                   
    end

    %----------------------------------------------------------------------       
    % add PointLoads table to driver if it doesn't exist:
    %----------------------------------------------------------------------       
    if nd > 0
        [~, err1] = GetFASTPar(BDdriverP,'NumPointLoads');
        if err1 
            nd = nd + 1;
            BDdriverP.Label{nd} = 'NumPointLoads';
            BDdriverP.Val{nd}   =  0;
            
            BDdriverP.PointLoads = [];
            BDdriverP.PointLoadsHdr = [];            
        end
    end    
    
    %----------------------------------------------------------------------       
    % add RotStates if it doesn't exist:
    %----------------------------------------------------------------------       
    [~, err1] = GetFASTPar(BDP,'RotStates');
    if err1
        n = n + 1;
        BDP.Label{n} = 'RotStates';
        BDP.Val{n}   =  'True';        
    end
                    
    
end 