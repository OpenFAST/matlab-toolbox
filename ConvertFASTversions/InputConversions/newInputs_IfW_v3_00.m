function [IfWP, err1] = newInputs_IfW_v3_00(ADPar,EDPar)
% [IfWP] = newInputs_IfW_v3_00(ADPar,EDPar)
% ADPar is the data structure containing already-filled parameters for
% AeroDyn, which will be modified for InflowWind. EDPar is used to determine
% the value for RefLength that was used in previous versions of AeroDyn.
%


        WindType_steady=1; 
        WindType_uniform=2; 
        WindType_TSFF=3; 
        WindType_BlFF=4;
        WindType_HAWC=5;
        WindType_User=6;

    
    %----------------------------------------------------------------------
    % Create new fields for InflowWind v3.00.x:
    %----------------------------------------------------------------------      
    n = 0;    
        
    [WindFile, err1] = GetFASTPar(ADPar,'WindFile');
    [RefHt, err2] = GetFASTPar(ADPar,'HH');
    if (err2)
        [RefHt, err2] = GetFASTPar(ADPar,'RefHt');
    end    

        % if there *was* an error, WindFile does not existed, 
        % so we've likely already changed these inputs.    

    if err1   
        IfWP = '';
        return
    end
    
    n = n + 1;
    IfWP.Label{n} = 'Filename';
    IfWP.Val{n}   = WindFile;
            
    n = n + 1;
    IfWP.Label{n} = 'RefHt';
    IfWP.Val{n}   = RefHt;

    WindFileNoQuotes= strrep(WindFile,'"',''); % remove quotes to work with this file name
    [pathstr,name,ext] = fileparts(WindFileNoQuotes);
    if isempty(pathstr)
        FilenameRoot = ['"' name '"'];
    else
        FilenameRoot = ['"' pathstr '/' name '"'];
    end
        
    if isempty(ext) || strcmp(ext,'.')
        WindType = WindType_BlFF;           
    elseif strcmpi(ext,'.bts')
        WindType = WindType_TSFF;
    elseif strcmpi(ext,'.hh') 
        WindType = WindType_uniform;            
    elseif strcmpi(ext,'.wnd')
        WindType = WindType_BlFF; % or should it be WindType_uniform?
        disp('Warning: inconclusive wind type in InflowWind. Assuming Bladed format.')
    else
        WindType = WindType_uniform; 
        disp('Warning: inconclusive wind type in InflowWind. Assuming uniform (hub-height).')
    end
    
    
    n = n + 1;
    IfWP.Label{n} = 'WindType';
    IfWP.Val{n}   = WindType;
    
    n = n + 1;
    IfWP.Label{n} = 'FilenameRoot';
    IfWP.Val{n}   = FilenameRoot;
    
    
    n = n + 1;
    IfWP.Label{n} = 'WindVxiList';
    IfWP.Val{n}   = 0;
    
    n = n + 1;
    IfWP.Label{n} = 'WindVyiList';
    IfWP.Val{n}   = 0;

    n = n + 1;
    IfWP.Label{n} = 'WindVziList';
    IfWP.Val{n}   = RefHt;
    
    n = n + 1;
    IfWP.Label{n} = 'NWindVel';
    IfWP.Val{n}   = 1;
    
    n = n + 1;
    IfWP.Label{n} = 'PropogationDir';
    IfWP.Val{n}   = 0;    
    
    n = n + 1;
    IfWP.Label{n} = 'PropagationDir';
    IfWP.Val{n}   = 0;      

    n = n + 1;
    IfWP.Label{n} = 'VFlowAng';
    IfWP.Val{n}   = 0;      
    
    n = n + 1;
    IfWP.Label{n} = 'Echo';
    IfWP.Val{n}   = 'False';    
        
    n = n + 1;
    IfWP.Label{n} = 'HWindSpeed';
    IfWP.Val{n}   = 0;    
    
    n = n + 1;
    IfWP.Label{n} = 'PLExp';
    IfWP.Val{n}   = 0.2;    
    
    n = n + 1;
    IfWP.Label{n} = 'TowerFile';
    IfWP.Val{n}   = 'False';    
    
    n = n + 1;
    IfWP.Label{n} = 'SumPrint';
    IfWP.Val{n}   = 'False';    

    %%%%
    [TipRad,  err3] = GetFASTPar(EDPar,'TipRad');
    [PreCone, err4] = GetFASTPar(EDPar,'PreCone(1)');
    CosPreCone = cos(PreCone * pi/180); %convert input to radians and get cosine
    r = 2*TipRad*CosPreCone;

    n = n + 1;
    IfWP.Label{n} = 'RefLength';
    IfWP.Val{n}   = round(r*10^3)/10^3;    
    %%%

    IfWP.OutList = {'Wind1VelX','Wind1VelY','Wind1VelZ'};
    IfWP.OutListComments = {'X-direction wind velocity at point WindList(1)',...
        'Y-direction wind velocity at point WindList(1)',...
        'Z-direction wind velocity at point WindList(1)'};
                
end 