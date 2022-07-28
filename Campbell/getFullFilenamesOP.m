function [fullpaths, OP] = getFullFilenamesOP(simulationFolder, OP_file_or_struct)
% Return full names of OpenFAST input files based on a operating point file or structure
%
% INPUTS
%   - simulationFolder:  (ignored if OP.Fullpath is present)
%   - OP_file_or_struct: 
%           path to a csv file that contains information about the Operating points see function readOperatingPoints for more.
%      or   structure with (depending on simulation) fields: RotorSpeed, WindSpeed, GeneratorTorque, 
% OUPUTS:
%   - fullpaths: path to FST files

if isstruct(OP_file_or_struct)
    OP  = OP_file_or_struct;
    if isfield(OP,'Fullpath')
        fullpaths = OP.Fullpath;
    elseif ~isfield(OP,'Filename')
        filenames = defaultFilenames(OP);
    end
else
    OP  = readOperatingPoints(OP_file_or_struct);
    if isfield(OP,'Fullpath')
        fullpaths = OP.Fullpath;
    else
        filenames = OP.Filename;
    end
end

% Go from filenames to fullpath (if user didn't specify fullpaths)
if ~exist('fullpaths', 'var')
    nOP = length(filenames);
    fullpaths = cell(1,nOP);
    for iOP = 1:nOP
        filename = strtrim(regexprep(filenames{iOP}, '('')|(")', '')); % remove unncessary quotes
        fullpaths{iOP} = strrep(strrep([simulationFolder '/' filename], '//','/'),'\','/');
    end
end

OP.Fullpath=fullpaths;
OP.nOP=length(fullpaths);
