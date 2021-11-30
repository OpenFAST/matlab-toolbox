function status = runCommands(commands, runFolder)
% Run a set of system commands
% 
% TODO , parallelization...
%
% INPUTS
%  - commands: cellarray of strings, ech of them forming a system commands

% OPTIONAL INPUTS
%  - runFolder: string, folder where the commands are to be executed
%
% OUPUTS:
%  - status: array of status for each simulation

if ~exist('runFolder','var'); runFolder=pwd; end;

oldFolder = pwd;
% --- Go to run folder
cd(runFolder);

status=zeros(1,length(commands));
% --- Running
for isim = 1:length(commands)
    sCmd= commands{isim};
    fprintf('Running: %s \n',sCmd);
    sim_status = system(sCmd);
    status(isim) = sim_status;
    % we don't abort if one fails
end

% --- Go back to previous folder
cd(oldFolder);


% --- Check
if any(status)
   I=find(status);
   disp('The following simulations failed');
   fprintf('%s\n',commands{I});
   error('%d/%d simulations failed',length(I),length(commands))
end
