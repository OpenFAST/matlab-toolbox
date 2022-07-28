%% Documentation   
% Given an fst file/lin file, perform the necessary steps to visualize modes  
%
% NOTE: this script is work in progress..
%
%% Initialization
clear all; close all; clc; 
restoredefaultpath;

%% Script Parameters
nModes = 15
Scale  = 200
fstFilename    = './FreeFree_OneBeam.fst'              ; % Full path to .fst file.
FASTexe        = './openfast_x64d_2022-07-12_dev.exe'; % path to an openfast executable
MATLAB_TOOLBOX = 'C:/Work/FAST/matlab-toolbox/'      ; % Full path to openFAST matlab toolbox
addpath(genpath(MATLAB_TOOLBOX));
runFST        = logical(1); % run FAST simulations
postproLin    = logical(1); % Postprocess .lin files, perform MBC, and write XLS or CSV files
writeVIZ      = logical(1);
runVIZ        = logical(1);
writeAVI      = logical(1);
% Parameters for AVI
pvPython       = 'pvpython'; % path to paraview-python binary
pythonPlotScript  = os_path.join(MATLAB_TOOLBOX,'Campbell/plotModeShapes.py'); % path to python plot script
paraviewStateFile = os_path.join(MATLAB_TOOLBOX,'Campbell/ED_Surfaces.pvsm');  % path  to paraview State file


% --- Derived Parameters
simulationFolder=os_path.dirname(fstFilename);
FSTfilenames ={fstFilename};
OP= struct();
OP.Fullpath=FSTfilenames;

%% --- Step 1: Check OpenFAST inputs file
FP = FAST2Matlab(fstFilename,2); % Parse FAST input file, 2 lines of header
if GetFASTPar(FP,'Linearize')!='true'; error('Linearize needs to be true in the .fst file.'); end
if GetFASTPar(FP,'WrVTK')!=3;          error('The parameter `WrVTK` needs to be 3 in the .fst file for visualization.'); end
if GetFASTPar(FP,'CompAero')!=2
    % Then surface visualization is not available, so need to set VTK_type=2
    % (unless OpenFAST compiled with -DUSE_DEFAULT_BLADE_SURFACE)
end

%% --- Step 2: run OpenFAST 
% TODO, leave it to the user for now
if runFST
    % --- Option 1: Batch
    [FASTcommands, batchFilename, runFolder] = writeBatch([simulationFolder '/_Run1_FAST.bat'], FSTfilenames, FASTexe);
    %runBatch(batchFilename, runFolder); 
    % --- Option 2: direct calls
    %runFAST(FSTfilenames, FASTexe); 
    fprintf('\nTODO: execute batch %s\n', [simulationFolder '/_Run1_FAST.bat'])
    fprintf('        or run the following command:\n\n');
    fprintf('  %s \n\n', FASTcommands{1,1})
end

%% --- Step 3: Run MBC, identify modes, generate .postMBC file (if .chkp present)
if postproLin
    CampbellData = getCampbellData(FSTfilenames);
end

%% --- Step 5a: Write VIZ files
%Generate visualization data
% Optional arguments:
%  VTKLinModes = 15  ;% Number of modes to visualize (0 <= VTKLinModes <= NumModes)
%  VTKModes    = '1,';% List of which VTKLinModes modes will be visualized (modes will be added sequentially from the last value entered)
%  VTKLinScale = NaN; % Mode shape visualization scaling factor (exaggerates mode shapes). If NaN, the following is used: 10 for ElastoDyn; 0.1 for BeamDyn.
%  VTKLinTim   = NaN; % Switch to make one animation for all LinTimes together (VTKLinTim=1) or separate animations for each LinTimes (VTKLinTim=2); If NaN, VTKLinTimes set to 2
%  VTKLinTimes1= '' ; % If VTKLinTim=2, visualize modes at LinTimes(1) only? (if false, files will be generated at all LinTimes); If empty, set to true
%  VTKLinPhase = 0  ; % If VTKLinTim=2, visualize modes at LinTimes(1) only? (if false, files will be generated at all LinTimes)
if writeVIZ
    [VIZfilenames] = writeVizualizationFiles(simulationFolder, OP, 'VTKLinModes', nModes, 'VTKLinScale',Scale);
end

%% --- Step 5b: Run FAST with VIZ files to generate VTKs
if runVIZ
    % --- Option 1: batch
    [VIZcommands, VIZbatch, runFolder] = writeBatch([simulationFolder '/_Run2_VIZ.bat'], VIZfilenames, FASTexe, 'flag','-VTKLin');
    %runBatch(batchFilename, runFolder); 
    % --- Option 2: direct calls
    % runFAST(VIZfilenames, FASTexe, 'flag','-VTKLin');
    % NOTE: runBatch and runFAST now fail on windows it seems
    fprintf('\nTODO: Run the following command in the terminal\n'); 
    fprintf('      (you can try to automate this by uncommenting `runFAST` or `runBatch`\n')
    fprintf('       in the MATLAB script but it migth not work on windows.)\n\n')
    fprintf('  %s \n\n', VIZcommands{1,1})
end

%% --- Step 5c: Convert VTKs to AVI
% NOTE: this generates the batch file only
%       Also, this is experimental and users might need to adapt the inputs and batchfile content
%       pvpython is ParaView Python, can be downloaded from paraview website
if writeAVI
    [AVIcommands] = writeAVIbatch([simulationFolder '/_Run3_AVI.bat'], simulationFolder, OP, pvPython, pythonPlotScript, paraviewStateFile);
    fprintf('\nTODO: execute batch %s\n', [simulationFolder '/_Run3_AVI.bat'])
    fprintf('        or run the following command:\n\n');
    fprintf('  %s \n\n', AVIcommands{1,1})
    fprintf('        or use plotModeShapesSimple.py\n');
end


