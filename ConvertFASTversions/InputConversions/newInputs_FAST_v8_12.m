function [FP,InflowFile,AeroFile] = newInputs_FAST_v8_12(FASTPar, newDir)
% [FASTPar] = newInputs_FAST_v8_12(FASTPar)
% FASTPar is the data structure containing already-filled parameters for
% FAST. 

    FP = FASTPar;
    
    %----------------------------------------------------------------------
    % Modify fields for FAST v8.12.x:
    %----------------------------------------------------------------------      
   
    
    %----------------------------------------------------------------------       
    % CompInflow and InflowFile are new inputs:
    %----------------------------------------------------------------------       
    [InflowFile, err1] = GetFASTPar(FP,'InflowFile');  
    AeroFile = GetFASTPar(FP,'AeroFile');  
    if (err1)
        CompInflow = GetFASTPar(FP,'CompAero');  
        
        if CompInflow
                                        
            AeroFile = strrep(AeroFile,'"',''); %let's remove the quotes so we can actually use this file name
            [~, FileWasRelative] = GetFullFileName( AeroFile, newDir );            
            
            if ~FileWasRelative
%                 disp( ['WARNING: AeroDyn file (' AeroFile ') is not a relative name. New InflowWind file will be located here: '] )
                [~, AeroRoot, ext] = fileparts( AeroFile );
                AeroFile = [AeroRoot ext];
                disp( [newDir filesep AeroFile] )
            end                       
            AeroFile = [ '"' AeroFile '"' ]; % add the quotes back
            
            % get name of new file:
            InflowFile = strrep(AeroFile,'AeroDyn','InflowWind');
            if strcmp( AeroFile, InflowFile )
                InflowFile = strrep(AeroFile,'.','_InflowWind.');
                if strcmp( AeroFile, InflowFile )
                    InflowFile = [ AeroFile '_InflowWind' ];
                end
            end
            
            if ~FileWasRelative
                disp(InflowFile)
            end
            
        else
            InflowFile = '"unused"';            
        end
        
        % add some new fields to the primary FAST data type
        n=length(FP.Label);
        
        n = n + 1;
        FP.Label{n} = 'CompInflow';
        FP.Val{n}   = CompInflow;

        n = n + 1;
        FP.Label{n} = 'InflowFile';
        FP.Val{n}   = InflowFile;        
        
    end    
    
    %----------------------------------------------------------------------       
    
return    
end 