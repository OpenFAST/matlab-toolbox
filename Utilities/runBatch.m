function status = runBatch(batchFile, runFolder)
% Run a set of FAST simulations using FAST exe.
% 
% TODO , parallelization...
%
% INPUTS
%  - batchFile  : filename of batch file to be run
%
% OPTIONAL INPUTS:
%  - runFolder: string, folder where the commands are to be executed
%
% OUPUTS:
%  - status: array of status for each simulation



oldFolder = pwd;
% --- Go to run folder and launch batch
cd(runFolder);
status = system(batchFile);

% --- Go back to previous folder
cd(oldFolder);


% --- Check
if status~=0;
   I=find(status);
   error('The batch file failed')
end
