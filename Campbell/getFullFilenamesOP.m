function [filenames, OP] = getFullFilenamesOP(simulationFolder, OP_file_or_struct)
% INPUTS
%   - simulationFolder: 
%   - OP_file_or_struct: 
%           path to a csv file that contains information about the Operating points see function readOperatingPoints for more.
%      or   structure with (depending on simulation) fields: RotorSpeed, WindSpeed, GeneratorTorque, 
% OUPUTS:
%   - filenames: path to FST files

if isstruct(OP_file_or_struct)
    OP  = OP_file_or_struct;
    OP.nOP = length(OP.RotorSpeed);
    if ~isfield(Filename)
        OP.Filenames = defaultFilenames(OP);
    end
else
    OP  = readOperatingPoints(OP_file_or_struct);
end
filenames = cell(1,OP.nOP);
for iOP = 1:OP.nOP
    filenames{iOP} = strrep(strrep([simulationFolder '/' OP.Filename{iOP}], '//','/'),'\','/');
end
OP.Fullpath=filenames;
