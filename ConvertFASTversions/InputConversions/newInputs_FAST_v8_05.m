function [FASTP] = newInputs_FAST_v8_05(FASTPar)
% [FASTPar] = newInputs_FAST_v8_05(FASTPar)
% FASTPar is the data structure containing already-filled parameters for
% FAST. 

    FASTP = FASTPar;
    
    %----------------------------------------------------------------------
    % Modify fields for FAST v8.05.x:
    %----------------------------------------------------------------------      
    n = length(FASTP.Label);    
    
    
    %----------------------------------------------------------------------       
    % The following file names have now changed:
    %..............................
    % ADFile is now AeroFile
    % SrvDFile is now ServoFile
    % HDFile is now HydroFile
    % SDFile is now SubFile
    % MAPFile is now MooringFile
    %..............................
    % this switch was renamed:
    %..............................    
    % CompMAP is nowCompMooring
    %----------------------------------------------------------------------
    oldNames = {'ADFile',  'SrvDFile', 'HDFile',   'SDFile', 'MAPFile',    'CompMAP'};
    newNames = {'AeroFile','ServoFile','HydroFile','SubFile','MooringFile','CompMooring'};
    
    for i=1:length(oldNames)
        [parValue, err, n] = GetFastPar(FASTP,oldNames{i});
        if ~err 
            FASTP.Label{n} = newNames{i};
            FASTP.Val{n}   = parValue;
        end             
    end
    
    %----------------------------------------------------------------------       
    % The following T/F flags have been changed to {0/1} switches:
    %..............................
    % CompAero
    % CompServo
    % CompHydro
    % CompSub
    % CompMooring (was called CompMAP)
    %----------------------------------------------------------------------  
    
    oldFlag = {'CompAero','CompServo','CompHydro','CompSub','CompMooring'};
    for i=1:length(oldFlag)
        [parValue, err] = GetFastPar(FASTP,oldFlag{i});
        
        if ~err 
                        
                % convert to a logical value:
            if strcmpi(parValue,'t') || strcmpi(parValue,'true')
                parValue = true;
                isALogical = true;
            elseif strcmpi(parValue,'f') || strcmpi(parValue,'false')
                parValue = false;
                isALogical = true;
            else 
                isALogical = false;
            end        
        
            if isALogical
                if parValue 
                    FASTP = SetFastPar(FASTP,oldFlag{i},1); % set it = 1 if it was true before
                else
                    FASTP = SetFastPar(FASTP,oldFlag{i},0); % set it = 0 if it was false before
                end
            end % isALogical
        end        
    end    

    %----------------------------------------------------------------------       
    % InterpOrder no longer allowed to be 0:
    %..............................
    % if InterpOrder == 0, InterpOrder = 2 
    %----------------------------------------------------------------------  
    [InterpOrder, err] = GetFastPar(FASTP,'InterpOrder');
    if ~err && InterpOrder == 0
        FASTP = SetFastPar(FASTP,'InterpOrder',2); % set InterpOrder = 2 if it was 0 before
    end
    
return    
end 