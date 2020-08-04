function [ModesData] = identifyModes(CampbellData)
% Identify modes from CampbellData and creates a ModesData structure with fields:
%  - modeID_table
%  - modeID_name
%  - opTable
%  - ModesTable (one per OP)
%  - ModesTable_names (one per OP)
%
% INPUTS:
%   - CampbellData: cell-array of CampbellData (one per operating point), as returned for instance by getCampbellData
%
% OUPUTS:
%  - ModesData: structure
%
% Inspired by script from Bonnie Jonkman
% (c) 2016 National Renewable Energy Laboratory
% (c) 2018 Envision Energy, USA


modesDesc = { 
{'Generator DOF (not shown)'     , 'ED Variable speed generator DOF, rad'}
{'1st Tower FA'                  , 'ED 1st tower fore-aft bending mode DOF, m'}
{'1st Tower SS'                  , 'ED 1st tower side-to-side bending mode DOF, m'}
{'1st Blade Flap (Regressive)'   , 'ED 1st flapwise bending-mode DOF of blade (sine|cosine), m', ...
                                   'Blade (sine|cosine) finite element node \d rotational displacement in Y, rad'}
{'1st Blade Flap (Collective)'   , 'ED 1st flapwise bending-mode DOF of blade collective, m', ...
                                   'Blade collective finite element node \d rotational displacement in Y, rad'}
{'1st Blade Flap (Progressive)'  , 'ED 1st flapwise bending-mode DOF of blade (sine|cosine), m'} % , ...% 'Blade (sine|cosine) finite element node \d rotational displacement in Y, rad'}
{'1st Blade Edge (Regressive)'   , 'ED 1st edgewise bending-mode DOF of blade (sine|cosine), m', ...
                                   'Blade (sine|cosine) finite element node \d rotational displacement in X, rad'}
{'1st Blade Edge (Progressive)'  , 'ED 1st edgewise bending-mode DOF of blade (sine|cosine), m'}
{'1st Drivetrain Torsion'        , 'ED Drivetrain rotational-flexibility DOF, rad'}
{'2nd Tower FA'                  , 'ED 2nd tower fore-aft bending mode DOF, m'}
{'2nd Tower SS'                  , 'ED 2nd tower side-to-side bending mode DOF, m'}
{'2nd Blade Flap (Regressive)'   , 'ED 2nd flapwise bending-mode DOF of blade (sine|cosine), m'}
{'2nd Blade Flap (Collective)'   , 'ED 2nd flapwise bending-mode DOF of blade collective, m', ...
                                   'Blade collective finite element node \d rotational displacement in Y, rad'}
{'2nd Blade Flap (Progressive)'  , 'ED 2nd flapwise bending-mode DOF of blade (sine|cosine), m'} 
{'Nacelle Yaw (not shown)'  , 'ED Nacelle yaw DOF, rad'} ...
...
};

%%
nModes = length(modesDesc);
nRuns = length(CampbellData);
modeID_table = zeros(nModes,nRuns);

modesIdentified = cell(nRuns,1);


for i=1:nRuns
    modesIdentified{i} = false( size(CampbellData{i}.Modes) );
    
    for modeID = 2:length(modesDesc) % list of modes we want to identify
        found = false;
        
        if isempty( strtrim( modesDesc{modeID}{2} ) ) 
            continue;
        end 
        
        tryNumber = 0;
        
        while ~found && tryNumber <= 2
            m = 0;
            while ~found && m < length(modesIdentified{i})
                m = m + 1;
                if modesIdentified{i}(m) || CampbellData{i}.Modes{m}.NaturalFreq_Hz < 0.1 % already identified this mode
                    continue;
                end

                if tryNumber == 0
                    maxDesc = CampbellData{i}.Modes{m}.DescStates ( CampbellData{i}.Modes{m}.StateHasMaxAtThisMode );
                
                    if isempty(maxDesc)
                        tryNumber = tryNumber + 1;
                    end
                end
                if tryNumber > 0 
                    if tryNumber < length(CampbellData{i}.Modes{m}.DescStates)
                        maxDesc = CampbellData{i}.Modes{m}.DescStates ( ~CampbellData{i}.Modes{m}.StateHasMaxAtThisMode );
%                         maxDesc = CampbellData{i}.Modes{m}.DescStates ( tryNumber );
                    else
                        maxDesc = [];
                    end
                end
                    
                j = 0;
                while ~found && j < length(maxDesc)
                    j = j + 1;
                    for iExp = 2:length( modesDesc{modeID} )
                        if ~isempty( regexp(maxDesc{j},modesDesc{modeID}{iExp},'match') )
                            modesIdentified{i}(m) = true;
                            modeID_table(modeID,i) = m;
                            found = true;
                            break;
                        end
                    end                    
                end % while                

            end
            tryNumber = tryNumber + 1;
        end        
        
    end
end


% --- Creating tables to be written to file
[idTable, modeID_name, ModesTable_names] = createIDTable(CampbellData, modeID_table, modesDesc);
[opTable]                                = createOPTable(CampbellData);

% --- Creating an output structure to store all tables (and potentially more in the future..)
ModesData=struct();
nOP = length(CampbellData);
for iOP = 1:nOP
    ModesData.ModesTable{iOP} = CampbellData{iOP}.ModesTable;
end
ModesData.ModesTable_names    = ModesTable_names;
ModesData.modeID_table    = idTable;
ModesData.modeID_name     = modeID_name;
ModesData.opTable         = opTable;


return

end


function [ModesTable, idSheetName, ModesTable_names] = createIDTable(CampbellData, modeID_table, modesDesc)
    % Create a table (cell array of string) that contains the mode identification: Mode Names and IDs for each OP
    % 
    % Inspired by script from Bonnie Jonkman
    % (c) 2016 National Renewable Energy Laboratory
    % (c) 2018 Envision Energy, USA
    nPoints = length(CampbellData);
    ModesTable_names = cell(nPoints,1);
    ModesTable = cell(length(modesDesc)+2,nPoints+1);
    ModesTable{1,1} = 'Mode Number Table';

    iRef = round(length(CampbellData)/2); % We'll use that file as a reference

    if CampbellData{iRef}.CompAero > 0 % NOTE: using ref file to look at CompAero
        ModesTable{2,1} = 'Wind Speed (mps)';
        for i=1:nPoints
            ModesTable(2,i+1) = num2cell( CampbellData{i}.WindSpeed );
            ModesTable_names{i} = [ num2str( CampbellData{i}.WindSpeed ), ' mps' ];
        end
        idSheetName = 'WS_ModesID';
    else
        ModesTable{2,1} = 'Rotor Speed (rpm)';
        for i=1:nPoints
            ModesTable(2,i+1) = num2cell( CampbellData{i}.RotSpeed_rpm );
            ModesTable_names{i} = [ num2str( CampbellData{i}.RotSpeed_rpm ), ' RPM' ];
        end
        idSheetName = 'ModesID';
    end    

    for i = 1:length(modesDesc)
        MD = modesDesc(i);
        ModesTable{i+2,1} = MD{1}{1}; % TODO this might need special treatment Matlab/Octave 
    end

    ModesTable(3:end,2:end) = num2cell(modeID_table);
end


function [opTable] = createOPTable(CampbellData)
    % Create a table (cell array of string) that contains the operating point
    %
    % Inspired by script from Bonnie Jonkman
    % (c) 2016 National Renewable Energy Laboratory
    % (c) 2018 Envision Energy, USA
    nPoints = length(CampbellData);
    opTable = cell(3,nPoints+1);
    opTable{1,1} = 'Operating Points';
    opTable{2,1} = 'Wind Speed (mps)';
    opTable{3,1} = 'Rotor Speed (rpm)';
    for i=1:nPoints
        opTable{2,i+1} = CampbellData{i}.WindSpeed;
        opTable{3,i+1} = CampbellData{i}.RotSpeed_rpm;
    end
end
