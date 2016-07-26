function [EDP] = newInputs_ED_v1_00(EDPar, oldDir)
% [EDP] = newInputs_ED_v1_00(EDPar, oldDir)
% EDP is the data structure containing already-filled parameters for
% ElastoDyn. We're going to add existing fields and based on the old ones.
% oldDir is needed so that we can read the correct platform file, if it
% existed.

    EDP = EDPar;
    
    %----------------------------------------------------------------------
    % Add fields for ElastoDyn v1.00.x:
    %----------------------------------------------------------------------      
    n = length(EDP.Label);    
    
    %----------------------------------------------------------------------       
    % 1) modify GBRatio based on the removed GBRevers variable
    %----------------------------------------------------------------------       
    [GBRevers, err1] = GetFASTPar(EDP,'GBRevers');
    if ~err1
    
        if strcmpi(GBRevers,'t')
            GBRevers = true;
        elseif strcmpi(GBRevers,'f')
            GBRevers = false;
        else
            GBRevers = eval(lower(GBRevers)); % convert "true"/"false" text to a logical value
        end

        if GBRevers 
            [GBRatio, err2] = GetFASTPar(EDP,'GBRatio');
            if ~err2
                GBRatio = -1*GBRatio;
                disp('GBRatio sign being reversed.')
                SetFASTPar(EDP,'GBRatio', GBRatio);
            else
                disp('GBRatio was not found; it should be set negative.')
            end            
        end
    end
    
    %----------------------------------------------------------------------   
    % 2) if we had a platform file, read it and add its inputs to the ED
    %    file; if we didn't, initialize those values.
    %----------------------------------------------------------------------           
    [PtfmModel, err1] = GetFASTPar(EDP,'PtfmModel');
    if ~err1
        setPtfmVals = true;
        if ( PtfmModel ~= 0 ) 
            [PlatformFile] = GetFASTPar(EDP,'PtfmFile');
            inputfile = GetFullFileName(PlatformFile,oldDir);

            if ( ~isempty(inputfile) )                        
                EDP = Fast2Matlab(inputfile,3, EDP); %add Platform Parameters to EDP, specify 3 lines of header
                setPtfmVals = false;
            end                   
        end
    
        if setPtfmVals %these were the defaults when the platform file was not used

            NewFieldVals ={'PtfmSgDOF',       'False';    
                           'PtfmSwDOF',       'False'; 
                           'PtfmHvDOF',       'False'; 
                           'PtfmRDOF',        'False'; 
                           'PtfmPDOF',        'False'; 
                           'PtfmYDOF',        'False';  
                           'PtfmCM',           0;                        
                           'PtfmSurge',        0;                        
                           'PtfmSway',         0;                        
                           'PtfmHeave',        0;                                               
                           'PtfmRoll',         0;                                               
                           'PtfmPitch',        0;                                               
                           'PtfmYaw',          0;                         
                           'TwrDraft',         0;                           
                           'PtfmRef',          0;                        
                           'PtfmMass',         0;                        
                           'PtfmRIner',        0;                        
                           'PtfmPIner',        0;                        
                           'PtfmYIner',        0;  };     

            for k = 1:size(NewFieldVals,1)
                n = n + 1;
                EDP.Label{n} = NewFieldVals{k,1};
                EDP.Val{n}   = NewFieldVals{k,2};
            end                   
        end  % setPtfmVals
    end
        
    %----------------------------------------------------------------------  
    % 3) We don't allow furling in this version.
    %----------------------------------------------------------------------       
    EDP = SetFASTPar(EDP,'Furling','False');      % Furling isn't available in this version 
    
    %----------------------------------------------------------------------  
    % 4) Add new inputs:
    %    PtfmCMzt = -PtfmCM 
    %    PtfmCMxt = 0
    %    PtfmCMyt = 0
    %----------------------------------------------------------------------       
    % note that this must be done after adding PtfmCM (step 2).
    PtfmCM = GetFASTPar(EDP,'PtfmCM');
    
    n = n + 1;
    EDP.Label{n} = 'PtfmCMzt';
    EDP.Val{n}   = -PtfmCM;
    
    n = n + 1;
    EDP.Label{n} = 'PtfmCMxt';
    EDP.Val{n}   = 0;
    
    n = n + 1;
    EDP.Label{n} = 'PtfmCMyt';
    EDP.Val{n}   = 0;
    
    
end 