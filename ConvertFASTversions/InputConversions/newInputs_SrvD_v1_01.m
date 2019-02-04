function [SrvDP] = newInputs_SrvD_v1_01(SrvDPar,usedBladed)
% [SrvDP] = newInputs_SrvD_v1_01(SrvDPar, usedBladed)
% SrvDP is the data structure containing already-filled parameters for
% ServoDyn. If the previous code used Bladed, we're going to modify the 
% input switches. 
%
% Inputs:
%  usedBladed - a logical determining if this input file was for FAST 
%               compiled with the BladedDLLInterface.f90 source file

    SrvDP = SrvDPar;
    
    %----------------------------------------------------------------------
    % Modify fields for ServoDyn v1.01.x:
    %----------------------------------------------------------------------      
    n = length(SrvDP.Label);    
    
    ControlMode_DLL    = 5;      
    
    %----------------------------------------------------------------------       
    % 1) If this was compiled with BladedDLLInterface.f90, these switches
    %    must change:
    %    PCMode { if 1 => 5 }
    %    VSContrl { if 2 => 5 }
    %    HSSBrMode { if 2 => 5 }
    %    YCMode { if 2 => 5 }  
    %----------------------------------------------------------------------  
    if usedBladed
        [~, err1] = GetFASTPar(SrvDP,'DLL_FileName');
        
            % if there *wasn't* an error, DLL_FileName already existed, 
            % and we don't want to change these values again.    
            
        if err1  
            n = n + 1;
            SrvDP.Label{n} = 'DLL_FileName';
            SrvDP.Val{n}   = 'DISCON.dll';

            NewLabels={'Ptch_SetPnt';
                       'Ptch_Min';
                       'Ptch_Max';
                       'PtchRate_Min';
                       'PtchRate_Max';
                       'NacYaw_North';
                       'Ptch_Cntrl';                       
                       'Gain_OM';
                       'GenSpd_MinOM';
                       'GenSpd_MaxOM';
                       'GenSpd_Dem';
                       'GenTrq_Dem';
                       'GenPwr_Dem';
                       'DLL_NumTrq' };

            for i_label = 1:length(NewLabels)
                n = n + 1;
                SrvDP.Label{n} = NewLabels{i_label};
                SrvDP.Val{n}   = 0;
            end
                     
            SrvDP.DLLProp    = zeros(0, 2);
            SrvDP.DLLPropHdr = {'GenSpd_TLU','GenTrq_TLU'};
                        
            % find all the user-defined from Bladed DLL switches and make
            % them ControlMode_DLL (i.e., 5)
            
            %..............................................................
            % PCMode { if 1 => 5 }
            %..............................................................
            [PCMode, err] = GetFASTPar(SrvDP,'PCMode');
            if ~err && PCMode == 1
                SrvDP = SetFASTPar(SrvDP,'PCMode',ControlMode_DLL);
            end
            
            %..............................................................
            % VSContrl { if 2 => 5 }
            %..............................................................
            [VSContrl, err] = GetFASTPar(SrvDP,'VSContrl');
            if ~err && VSContrl == 2
                SrvDP = SetFASTPar(SrvDP,'VSContrl',ControlMode_DLL);
            end            
            
            %..............................................................
            % HSSBrMode { if 2 => 5 }
            %..............................................................
            [HSSBrMode, err] = GetFASTPar(SrvDP,'HSSBrMode');
            if ~err && HSSBrMode == 2
                SrvDP = SetFASTPar(SrvDP,'HSSBrMode',ControlMode_DLL);
            end             
            
            %..............................................................
            % YCMode { if 2 => 5 }
            %..............................................................
            [YCMode, err] = GetFASTPar(SrvDP,'YCMode');
            if ~err && YCMode == 2
                SrvDP = SetFASTPar(SrvDP,'YCMode',ControlMode_DLL);
            end             
            
            
        end % err1  
    end % usedBladed
         
    
end 