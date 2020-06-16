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
