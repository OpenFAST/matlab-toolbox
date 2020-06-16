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
