function [names, CampbellData]= modeNames(CampbellData)
Descriptions.searchStr = cell(8,1);

TowerFA = 1;
Descriptions.name{TowerFA}            = 'Tower fore-aft';
Descriptions.searchStr{TowerFA}       = {'MBD TowerElem[0-9]*_Mode[0-9]*(C|N)_Uy, -'  
                                         'ED (1st|2nd) tower fore-aft bending mode DOF, m'};

TowerSS = 2;
Descriptions.name{TowerSS}            = 'Tower side-to-side';
Descriptions.searchStr{TowerSS}       = {'MBD TowerElem[0-9]*_Mode[0-9]*(C|N)_Uz, -' 
                                         'ED (1st|2nd) tower side-to-side bending mode DOF, m'};
                         
BladeFlap = 3;
Descriptions.name{BladeFlap}          = 'Blade flap'; % regressive, progressive
Descriptions.searchStr{BladeFlap}     = {'MBD Blade (sine|cosine) Elem[0-9]*_Mode[0-9]*(C|N)_Uy, -'
                                         'Blade (sine|cosine) finite element node [0-9]* rotational displacement in Y, rad' 
                                         'Blade (sine|cosine) finite element node [0-9]* translational displacement in X, rad' 
                                         'ED (1st|2nd) flapwise bending-mode DOF of blade (sine|cosine), m' };

BladeFlapColl = 4;
Descriptions.name{BladeFlapColl}      = 'Blade flap, collective'; % collective
Descriptions.searchStr{BladeFlapColl} = {'MBD Blade collective Elem[0-9]*_Mode[0-9]*(C|N)_Uy, -'
                                         'Blade collective finite element node [0-9]* rotational displacement in Y, rad' 
                                         'Blade collective finite element node [0-9]* translational displacement in X, rad' 
                                         'ED (1st|2nd) flapwise bending-mode DOF of blade collective, m' };

BladeEdge = 5;
Descriptions.name{BladeEdge}          = 'Blade edge'; % regressive, progressive
Descriptions.searchStr{BladeEdge}     = {'MBD Blade (sine|cosine) Elem[0-9]*_Mode[0-9]*(C|N)_Uz, -'
                                         'Blade (sine|cosine) finite element node [0-9]* rotational displacement in X, rad' 
                                         'Blade (sine|cosine) finite element node [0-9]* translational displacement in Y, rad' 
                                         'ED (1st|2nd) edgewise bending-mode DOF of blade (sine|cosine), m' };
                         
BladeEdgeColl = 6;
Descriptions.name{BladeEdgeColl}      = 'Blade edge, collective'; % collective=drivetrain torsion
Descriptions.searchStr{BladeEdgeColl} = {'MBD Blade collective Elem[0-9]*_Mode[0-9]*(C|N)_Uz, -'
                                         'Blade collective finite element node [0-9]* rotational displacement in X, rad' 
                                         'Blade collective finite element node [0-9]* translational displacement in Y, rad' 
                                         'ED (1st|2nd) edgewise bending-mode DOF of blade collective, m' 
                                         'MBD ShaftTors_Rot, -' 
                                         'ED Drivetrain rotational-flexibility DOF, rad'};

% Descriptions.name(7)      = 'Drivetrain torsion'; %this is the same as 1st Blade Edge, collective
% Descriptions.searchStr(7) = {'MBD ShaftTors_Rot, -' 
%                              'ED Drivetrain rotational-flexibility DOF, rad' };
                         
GenDOF = 7;
Descriptions.name{GenDOF}      = 'Generator';
Descriptions.searchStr{GenDOF} = {'MBD Gearbox_Rot, -'
                                  'ED Variable speed generator DOF, rad'};

NacelleYaw = 8;
Descriptions.name{NacelleYaw}      = 'Nacelle yaw';
Descriptions.searchStr{NacelleYaw} = {'ED Nacelle yaw DOF, rad'};

%%
nRuns = length(CampbellData);

nModes = 1000; % some arbitrary large number (max number of modes to check) 
for i=1:nRuns
    nModes = min(nModes,length(CampbellData{i}.Modes));
end

% modeID_table = zeros(nModes,nRuns);

names = cell(nRuns,1);
for i=1:nRuns % go through each case (wind speed or rotor speed)
    names{i} = cell(nModes,1);
    
    for m=1:size( CampbellData{i}.Modes ) % go through each identified frequency
        
        maxDesc = CampbellData{i}.Modes{m}.DescStates ( CampbellData{i}.Modes{m}.StateHasMaxAtThisMode );        
        found = false;
        for tryNumber = 1:2
            if ~isempty(maxDesc)
% fprintf('%f %f: %s\n', i,m, maxDesc{1} );
           
                StrNum = 1;
                while StrNum <= length( Descriptions.searchStr ) && ~found
                    for iExp = 1:length( Descriptions.searchStr{StrNum} )
                        if ~isempty( regexp(maxDesc{1},Descriptions.searchStr{StrNum}{iExp},'match') )
                            names{i,m} = Descriptions.name{StrNum};
                            CampbellData{i}.Modes{m}.name = Descriptions.name{StrNum};
                            CampbellData{i}.ModesTable(1,m*CampbellData{i}.nColsPerMode - 2) = Descriptions.name(StrNum);
                            found = true;
                            break;
                        end                   
                    end
                    StrNum = StrNum+1;
                end %while
            end %~empty
            
            if found
                break
            else
                maxDesc = CampbellData{i}.Modes{m}.DescStates ( ~CampbellData{i}.Modes{m}.StateHasMaxAtThisMode );                
            end
        end %tryNumber
                            
    end %m
end %i
   
