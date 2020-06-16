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
OptsFields={'flag'};
opts=struct();
% Default values
opts.flag = ''   ; % Extra flag
% Values input by users % NOTE: inputParser not available in Octave
if nargin >=3
    for iOpts = 1:length(OptsFields)
        i = find( strcmp( varargin, OptsFields{iOpts}) == 1);
        if ~isempty(i)
            opts.(OptsFields{iOpts}) = varargin{i + 1};
        end
    end
end

% --- Inputs sanity
if ispc()
    FASTexe = strrep(FASTexe,'/','\');
end

status=zeros(1,length(FASTfilenames));

% --- Running
for isim = 1:length(FASTfilenames)
    FASTfile = FASTfilenames{isim};
    if ispc()
        FASTfile = strrep(FASTfile,'/','\');
    end
    sCmd= [FASTexe ' ' opts.flag ' ' FASTfile];
    fprintf('Running: %s \n',sCmd);
    sim_status = system(sCmd);
    status(isim) = sim_status;
    % we don't abort if one fails
end

% --- Check
if any(status);
   I=find(status);
   disp('The following simulations failed');
   disp(FASTfilenames(I));
   error('%d/%d simulations failed',length(I),length(FASTfilenames))
end
