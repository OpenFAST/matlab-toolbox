function filenames = defaultFilenames(OP, rpmSweep)
% Generate default filenames for linearization based on RotorSpeed (for rpmSweep) or WindSpeed 
% If RotorSpeed is a field, windspeed is preferred for filenames, unless, rpmSweep is set to true as input
% 
% INPUTS:
%   - OP: structure with field RotorSpeed, and optionally WindSpeed
% OPTIONAL INPUTS:
%   - rpmSweep : if present, overrides the logic: if true, rpm is used, otherwise ws
% OUTPUTS:
%   - filenames: cell-array of strings with default filenames for linearization simulations

% --- optional arguments
if ~exist('rpmSweep','var'); 
    rpmSweep = isfield(OP,'WindSpeed');
end


%
nOP=length(OP.RotorSpeed);
filenames=cell(1,nOP);
for iOP=1:nOP
    if rpmSweep
        filenames{iOP}=sprintf('rpm%05.2f.fst',OP.RotSpeed(iOP));
    else
        filenames{iOP}=sprintf('ws%04.1f.fst',OP.WindSpeed(iOP));
    end
end
