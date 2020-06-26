function status = runFAST(FASTfilenames, FASTexe, varargin)
% Run a set of FAST simulations using FAST exe.
% 
% TODO , parallelization...
%
% INPUTS
%  - FASTfilenames: list of fullpath (relative or absolute) to fst flies
%  - FASTexe:       fullpath (relative or absolute) to an openfast executable
%
% OPTIONAL INPUTS:
%  - varargin is a set of ('key', value) pairs.
%            Look at `opts` below for the different options, and default values.
%
% OUPUTS:
%  - status: array of status for each simulation


% --- Optional arguments
OptsFields={'flag',};
opts=struct();
% Default values
opts.flag = ''   ; % Extra flag passed as command line argument
% Values input by users % NOTE: inputParser not available in Octave
if mod(length(varargin),2)~=0; error('Varargin should have an even number of values, for key/values pairs'); end
for iVar = 1:2:length(varargin)
    i = find( strcmp( OptsFields, varargin{iVar}) == 1);
    if ~isempty(i)
        opts.(OptsFields{i}) = varargin{iVar + 1};
    else
        warning('Optional key `%s` not supported by function %s',varargin{iVar},mfilename)
    end
end
% --- Inputs sanity
if ispc()
    FASTexe = strrep(FASTexe,'/','\');
end

status=zeros(1,length(FASTfilenames));

% --- Creating a list of commands
commands=cell(1,length(FASTfilenames));
for isim = 1:length(FASTfilenames)
    FASTfile = FASTfilenames{isim};
    if ispc()
        FASTfile = strrep(FASTfile,'/','\');
    end
    sCmd= [FASTexe ' ' opts.flag ' ' FASTfile];
    commands{isim}=sCmd;
end

% --- Running
status = runCommands(commands);

