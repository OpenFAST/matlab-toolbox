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
    elseif nargout < 2
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
    % add RotStates if it doesn't exist:
    %----------------------------------------------------------------------       
    [~, err1] = GetFASTPar(BDP,'RotStates');
    if ~err1
        n = n + 1;
        BDP.Label{n} = 'RotStates';
        BDP.Val{n}   =  'True';        
    end
    
%     %----------------------------------------------------------------------   
%     % 2) if we had a platform file, read it and add its inputs to the ED
%     %    file; if we didn't, initialize those values.
%     %----------------------------------------------------------------------           
%     [PtfmModel, err1] = GetFASTPar(BDP,'PtfmModel');
%     if ~err1
%         setPtfmVals = true;
%         if ( PtfmModel ~= 0 ) 
%             [PlatformFile] = GetFASTPar(BDP,'PtfmFile');
%             inputfile = GetFullFileName(PlatformFile,oldDir);
% 
%             if ( ~isempty(inputfile) )                        
%                 BDP = FAST2Matlab(inputfile,3, BDP); %add Platform Parameters to EDP, specify 3 lines of header
%                 setPtfmVals = false;
%             end                   
%         end
%     
%         if setPtfmVals %these were the defaults when the platform file was not used
% 
%             NewFieldVals ={'PtfmSgDOF',       'False';    
%                            'PtfmSwDOF',       'False'; 
%                            'PtfmHvDOF',       'False'; 
%                            'PtfmRDOF',        'False'; 
%                            'PtfmPDOF',        'False'; 
%                            'PtfmYDOF',        'False';  
%                            'PtfmCM',           0;                        
%                            'PtfmSurge',        0;                        
%                            'PtfmSway',         0;                        
%                            'PtfmHeave',        0;                                               
%                            'PtfmRoll',         0;                                               
%                            'PtfmPitch',        0;                                               
%                            'PtfmYaw',          0;                         
%                            'TwrDraft',         0;                           
%                            'PtfmRef',          0;                        
%                            'PtfmMass',         0;                        
%                            'PtfmRIner',        0;                        
%                            'PtfmPIner',        0;                        
%                            'PtfmYIner',        0;  };     
% 
%             for k = 1:size(NewFieldVals,1)
%                 n = n + 1;
%                 BDP.Label{n} = NewFieldVals{k,1};
%                 BDP.Val{n}   = NewFieldVals{k,2};
%             end                   
%         end  % setPtfmVals
%     end
                
    
end 