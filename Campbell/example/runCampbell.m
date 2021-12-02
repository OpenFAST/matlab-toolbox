%% Documentation   
% Example script to create a Campbell diagram with OpenFAST
%
% NOTE: This script is only an example. 
%       The example data is suitable for a given version of OpenFAST and might need to be adapted
%     
% Adapt this script to your need, by calling the different subfunctions presented.
%
%% Initialization
clear all; close all; clc; 
restoredefaultpath;
addpath(genpath('C:/Work/FAST/matlab-toolbox')); % TODO adapt me

%% Parameters

% Main Flags
writeFSTfiles = logical(1); % write FAST input files for linearization
runFST        = logical(1); % run FAST simulations
postproLin    = logical(1); % Postprocess .lin files, perform MBC, and write XLS or CSV files
writeVIZ      = logical(1);
runVIZ        = logical(0);
writeAVI      = logical(0);
outputFormat  ='CSV';       % Output format XLS, or CSV
% Linearization options
simTime   = 500; % Time after which the simulation will stop if no periodic steady state is found by the trim solution
nLinTimes = 36 ; % Number of linearization done over one rotor rotation (e.g. 12 to 36)
% Main Inputs
FASTexe = '..\..\_ExampleData\openfast2.5_x64.exe'; % path to an openfast executable
templateFstFile     = '../../_ExampleData/5MW_Land_Lin_Templates/Main_5MW_Land_Lin.fst'; 
%      Template file used to create linearization files. 
%      This template file should point to a valid ElastoDyn file, and,
%      depending on the linearization type, valid AeroDyn, InflowWind and Servodyn files.
%      The template files can be in the `simulationFolder` or a separate folder.

simulationFolder    = '../../_ExampleData/5MW_Land_Lin_Trim/';
%      Folder where OpenFAST simulations will be run for the linearization.
%      OpenFAST input files for each operating point will be created there.
%      Should contain all the necessary files for a OpenFAST simulation.
%      Will be created if does not exists.

operatingPointsFile = 'LinearizationPoints_NoServo.csv'; 
%      File defining the operating conditions for linearization (e.g. RotorSpeeed, WindSpeed).
%      See function `readOperatingPoints` for more info.
%      You can define this data using a matlab structure, but an input file is recommended.
   

%% --- Step 1: Write OpenFAST inputs files for each operating points 
% NOTE: 
%      The function can take an operatingPointsFile or the structure OP 
%      Comment this section if the inputs files were already generated
%      See function writeLinearizationFiles for key/value arguments available: 
%      The key/values are used to:
%        - override options of the main fst file (e.g. CompServo, CompAero) 
%        - set some linearization options (e.g. simTime, NLinTimes)
%      `simTime` needs to be large enough for a periodic equilibrium to be reached
if writeFSTfiles
    FSTfilenames = writeLinearizationFiles(templateFstFile, simulationFolder, operatingPointsFile, 'simTime', simTime, 'NLinTimes', nLinTimes,'writeVTKmodes',true);
end
%% --- Step 2: run OpenFAST 
% NOTE: 
%      Comment this section if the simulations were already run
%      Potentially write a batch file for external run (can be more conveninet for many simulations).
%       Batch and commands are relative to the parent directory of the batch file.
if runFST
    [FASTfilenames] = getFullFilenamesOP(simulationFolder, operatingPointsFile);
    % --- Option 1: Batch
    [FASTcommands, batchFilename, runFolder] = writeBatch([simulationFolder '/_RunFAST.bat'], FSTfilenames, FASTexe);
    %runBatch(batchFilename, runFolder); 
    % --- Option 2: direct calls
    runFAST(FSTfilenames, FASTexe); 
end

%% --- Step 3: Run MBC, identify modes and generate XLS or CSV file
% NOTE:  
%      Select CSV output format if XLS is not available
%        - XLS: one output file is generated (existing sheets will be overriden, not new sheets)
%        - CSV: several output files are generated
%      The mode identification currently needs manual tuning (modes might be swapped): 
%        - XLS: modify the `ModesID` sheet of the Excel file generated to do this tuning
%        - CSV: modify the csv file `*_ModesID.csv` if you chose CSV output.
%      To avoid the manual identification to be overriden, you can: 
%        - XLS: use a new sheet , e.g. 'ModesID_Sorted` and use this in Step 4
%        - CSV: create a new file, e.g. 'Campbell_ModesID_Sorted.csv` and this for step 4
if postproLin
    [ModesData, outputFiles] = postproLinearization(simulationFolder, operatingPointsFile, outputFormat);
end


%% --- Step 4: Campbell diagram plot
if isequal(lower(outputFormat),'xls')

    %  NOTE: more work is currently needed for the function below
    plotCampbellData([simulationFolder '/Campbell_DataSummary.xlsx'], 'WS_ModesID');

elseif isequal(lower(outputFormat),'csv')

    % python script is used for CSV (or XLS)
    fprintf('\nUse python script to visualize CSV data: \n\n')
    fprintf('usage:  \n')
    fprintf('python plotCampbellData.py XLS_OR_CSV_File [WS_OR_RPM] [sheetname]\n\n')
    fprintf('\n')
    fprintf('for instance:  python plotCampbellData.py Campbell_ModesID.csv \n')

end



%% --- Step 5: Generate visualization data
% --- Step 5a: Write VIZ files
if writeVIZ
    [VIZfilenames] = writeVizualizationFiles(simulationFolder, operatingPointsFile,'VTKLinModes',12);
end
% --- Step 5b: Run FAST with VIZ files to generate VTKs
if runVIZ
    % --- Option 1: batch
    [VIZcommands, VIZbatch, runFolder] = writeBatch([simulationFolder '/_RunVIZ.bat'], VIZfilenames, FASTexe, 'flag','-VTKLin');
    %runBatch(batchFilename, runFolder); 
    % --- Option 2: direct calls
    %runFAST(VIZfilenames, FASTexe, 'flag','-VTKLin');
end
% --- Step 5c: Convert VTKs to AVI
% NOTE: this generates the batch file only
%       Also, this is experimental and users might need to adapt the inputs and batchfile content
if writeAVI
    pvPython          = 'pvpython'; % path to paraview-python binary
    pythonPlotScript  = 'C:/Work/FAST/matlab-toolbox/Campbell/plotModeShapes.py'; % path to python plot script
    paraviewStateFile = 'C:/Work/FAST/matlab-toolbox/Campbell/ED_Surfaces.pvsm';  % path  to paraview State file
    writeAVIbatch([simulationFolder '/_RunAVI.bat'], simulationFolder, operatingPointsFile, pvPython, pythonPlotScript, paraviewStateFile);
end


