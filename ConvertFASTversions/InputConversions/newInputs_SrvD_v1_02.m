function [SrvDP] = newInputs_SrvD_v1_02(SrvDPar)
% [SrvDP] = newInputs_SrvD_v1_02(SrvDPar)
% SrvDP is the data structure containing already-filled parameters for
% ServoDyn.  
%

    SrvDP = SrvDPar;
    
    %----------------------------------------------------------------------
    % Modify fields for ServoDyn v1.02.x:
    %----------------------------------------------------------------------      
    n = length(SrvDP.Label);    
    
%     ControlMode_DLL    = 5;      
    ControlMode_EXTERN = 4;
    ControlMode_USER   = 3;
    
    %----------------------------------------------------------------------       
    % 1) These switches must change:
    %    PCMode    { 1 => 3 
    %                2 => 4 }
    %    VSContrl  { 2 => 3
    %                3 => 4 }
    %    HSSBrMode { 2 => 3 
    %                3 => 4 }
    %    YCMode    { 2 => 3   
    %                3 => 4 }
    %----------------------------------------------------------------------  
    [~, err1] = GetFastPar(SrvDP,'CompNTMD');

        % if there *wasn't* an error, CompNTMD already existed, 
        % and we don't want to change these values again.    

    if err1  
        n = n + 1;
        SrvDP.Label{n} = 'CompNTMD';
        SrvDP.Val{n}   = 'False';

        n = n + 1;
        SrvDP.Label{n} = 'NTMDfile';
        SrvDP.Val{n}   = '"unused"';

        % find all the user-defined from subroutine switches and make them ControlMode_USER
        % find all the user-defined from Simulink/LabVIEW switches and make them ControlMode_EXTERN

        %..............................................................
        %    PCMode    { 1 => 3 
        %                2 => 4 }
        %..............................................................
        [PCMode, err] = GetFastPar(SrvDP,'PCMode');
        if ~err 
            if PCMode == 1
                SrvDP = SetFastPar(SrvDP,'PCMode',ControlMode_USER);
            elseif PCMode == 2
                SrvDP = SetFastPar(SrvDP,'PCMode',ControlMode_EXTERN);
            end
        end

        %..............................................................
        %    VSContrl  { 2 => 3
        %                3 => 4 }
        %..............................................................
        [VSContrl, err] = GetFastPar(SrvDP,'VSContrl');         
        if ~err 
            if VSContrl == 2
                SrvDP = SetFastPar(SrvDP,'VSContrl',ControlMode_USER);
            elseif VSContrl == 3
                SrvDP = SetFastPar(SrvDP,'VSContrl',ControlMode_EXTERN);
            end
        end
        %..............................................................
        %    HSSBrMode { 2 => 3 
        %                3 => 4 }
        %..............................................................
        [HSSBrMode, err] = GetFastPar(SrvDP,'HSSBrMode');
        if ~err 
            if HSSBrMode == 2
                SrvDP = SetFastPar(SrvDP,'HSSBrMode',ControlMode_USER);
            elseif HSSBrMode == 3
                SrvDP = SetFastPar(SrvDP,'HSSBrMode',ControlMode_EXTERN);
            end
        end
        
        %..............................................................
        %    YCMode    { 2 => 3   
        %                3 => 4 }
        %..............................................................
        [YCMode, err] = GetFastPar(SrvDP,'YCMode');
        if ~err 
            if YCMode == 2
                SrvDP = SetFastPar(SrvDP,'YCMode',ControlMode_USER);
            elseif YCMode == 3
                SrvDP = SetFastPar(SrvDP,'YCMode',ControlMode_EXTERN);
            end
        end
        

    end % err1  
           
end 