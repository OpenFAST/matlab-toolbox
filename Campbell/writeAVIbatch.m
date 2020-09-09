function commands=writeAVIbatch(batchFile, simulationFolder, OP_file_or_struct, pvpython, pythonPlotScript, paraviewStateFile)
% Write a batch file to generate AVI
% The command and input files will be changed so that they are relative to the location of the batch file. 
%
% NOTE:  This is experimental and may need tuning from users
%

% --- OpenFAST
[FSTfilenames, OP] = getFullFilenamesOP(simulationFolder, OP_file_or_struct);

% --- Extracting batch directory and making allpaths relative to batchdir
batchFilename  = os_path.basename(batchFile)       ;
batchFile_abs  = os_path.abspath(batchFile)        ;
batchDir       = os_path.dirname(batchFile_abs)    ;

% exe_abs        = os_path.abspath(exe)              ;
% exe_rel        = os_path.relpath(exe_abs, batchDir);

pythonPlotScript_abs = os_path.abspath(pythonPlotScript);
pythonPlotScript_rel = os_path.relpath(pythonPlotScript_abs, batchDir);

paraviewStateFile_abs = os_path.abspath(paraviewStateFile);
paraviewStateFile_rel = os_path.relpath(paraviewStateFile_abs, batchDir);

% --- Write batch file
commands=cell(1,length(FSTfilenames));
fid=fopen(batchFile,'w');
for isim = 1:length(FSTfilenames)

    fst = FSTfilenames{isim};
    fst_abs = os_path.abspath(fst);
    fst_rel = os_path.relpath(fst_abs, batchDir);

    [parentdir,base,ext] = fileparts(fst_rel);
    vtk_root= os_path.join(parentdir,'vtk',base);

    %file_abs = os_path.abspath(inputfile);
    %file_rel = os_path.relpath(file_abs, batchDir);

    command=sprintf('%s %s %s %s', pvpython, pythonPlotScript_rel, vtk_root, paraviewStateFile_rel);
    fprintf(fid,'%s\n', command);
    commands{isim} = command;
end
fclose(fid);



