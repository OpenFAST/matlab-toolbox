function [commands, batchFilename, batchDir] = writeBatch(batchFile, inputFiles, exe, varargin)
% Write a batch file for commands of the form : exe {Flag} inputFile {extraArgs}
% The command and input files will be changed so that they are relative to the location of the batch file. 
%
% INPUTS
%  - batchFile  : filename of batch file to be written
%  - inputsFiles: list of fullpath (relative or absolute) to input files
%  - exe:         fullpath (relative or absolute) to an executable
%
% OPTIONAL INPUTS:
%  - varargin is a set of ('key', value) pairs.
%            Look at `opts` below for the different options, and default values.
%
% OUPUTS:
%  - : array of status for each simulation


% --- Optional arguments
OptsFields={'flag','extraArgs'};
opts=struct();
% Default values
opts.flag      = ''   ; % Extra flag passed as command line argument
opts.extraArgs = ''   ; % Extra arguments passed after inputfile
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

% --- Extracting batch directory and making path relative to batchdir
batchFilename  = os_path.basename(batchFile)       ;
batchFile_abs  = os_path.abspath(batchFile)        ;
batchDir       = os_path.dirname(batchFile_abs)    ;
exe_abs        = os_path.abspath(exe)              ;
exe_rel        = os_path.relpath(exe_abs, batchDir);
% --- Write batch file
commands=cell(1,length(inputFiles));
fid=fopen(batchFile,'w');
for isim = 1:length(inputFiles)
    inputfile = inputFiles{isim};
    file_abs = os_path.abspath(inputfile);
    file_rel = os_path.relpath(file_abs, batchDir);
    command=sprintf('%s %s %s %s', exe_rel, opts.flag, file_rel, opts.extraArgs);
    fprintf(fid,'%s\n', command);
    commands{isim} = command;
end
fclose(fid);



