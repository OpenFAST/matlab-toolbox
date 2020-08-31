function status = runFASTForVisualization(simulationFolder, OP_file_or_struct, FASTexe, varargin)
% Loop through simulations, looking for *.postmb files, if present, VIZ files will be generated based on "best guess values", which may be overriden using varargin
% and FAST will be rerun to generate VTK
%
% INPUTS:
%  - simulationFolder:  folder where linearization files are present.
%  - OP_file_or_struct: 
%          path to a csv file that contains information about the Operating points see function readOperatingPoints for more.
%       OR structure with (depending on simulation) fields: RotorSpeed, {optional: WindSpeed, GeneratorTorque, BladePitch, TowerTopDispFA, Filename}
%  - FASTexe:       fullpath (relative or absolute) to an openfast executable
%
% OPTIONAL INPUTS:
%  - varargin is a set of ('key', value) pairs used to override values found in templateFilenameVIZ
%            Look at `opts` below for the different options, and default values.
%            Look at writeVizualizationFiles for varagin options
%
% OUTPUTS:
%  - status: array of status for each simulation
%
% Loop through simulations, looking for *.postmb files, if present FAST will be rerun to generate VTK
VIZfilenames = writeVizualizationFiles(simulationFolder, OP_file_or_struct, varargin{:});

if length(VIZfilenames)==0
    fprintf('Warning: no *ModeShapeVTK.postmbc files found\n');
else
    fprintf('Running visualization for %d files...\n',length(VIZfilenames));
    status = runFAST(VIZfilenames, FASTexe, 'flag','-VTKLin');
end
end


