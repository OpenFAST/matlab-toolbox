%% Documentation   
% Example script to create a Campbell diagram with OpenFAST
% This script does not use the "trim" option, which means the user needs to provide a large simulation time (simTime) after which linearization will be done.
%
% NOTE: This script is only an example.
%       The example data is suitable for OpenFAST 2.5.
%
% Adapt this script to your need, by calling the different subfunctions presented.
%
%% Initialization
clear all; close all; clc; 
restoredefaultpath;
addpath(genpath('C:/Work/FAST/matlab-toolbox'));

%% Parameters

% Main Flags
writeFSTfiles = logical(1); % write FAST input files for linearization
runFST        = logical(1); % run FAST simulations
postproLin    = logical(1); % Postprocess .lin files, perform MBC, and write XLS or CSV files
outputFormat  ='CSV';       % Output format XLS, or CSV
% Linearization options
simTime   = 500; % Time at which the system is expected to have reached a periodic equilibrium (should be large enough)
nLinTimes = 36 ; % Number of linearization done over one rotor rotation (e.g. 12 to 36)
% Main Inputs
FASTexe = '../../_ExampleData/openfast3.0_x64s.exe'; % path to an openfast executable
templateFstFile     = '../../_ExampleData/5MW_Land_Lin_Templates/Main_5MW_Land_Lin.fst'; 
%      Template file used to create linearization files. 
%      This template file should point to a valid ElastoDyn file, and,
%      depending on the linearization type, valid AeroDyn, InflowWind and Servodyn files.
%      The template files can be in the `simulationFolder` or a separate folder.

simulationFolder    = '../../_ExampleData/5MW_Land_Lin/';
%      Folder where OpenFAST simulations will be run for the linearization.
%      OpenFAST input files for each operating point will be created there.
%      Should contain all the necessary files for a OpenFAST simulation.
%      Will be created if does not exists.

operatingPointsFile = 'LinearizationPoints_NoServo.csv'; 
%      File defining the operating conditions for linearization (e.g. RotorSpeeed, WindSpeed).
%      If special filenames are needed, the filenames can be defined in this file as well.
%      See function `readOperatingPoints` for more info.
%      You can also define this data using a matlab structure, but an input file is recommended.

%% --- Step 1: Write OpenFAST inputs files for each operating points 
% NOTE: 
%      The function can take an operatingPointsFile or the structure OP 
%      Comment this section if the inputs files were already generated
%      See function writeLinearizationFiles for key/value arguments available: 
%      The key/values are used to:
%        - override options of the main fst file (e.g. CompServo, CompAero) 
%        - set some linearization options (e.g. simTime, NLinTimes)
if writeFSTfiles
    FSTfilenames = writeLinearizationFiles(templateFstFile, simulationFolder, operatingPointsFile, 'simTime',simTime,'NLinTimes',nLinTimes, 'calcSteady', false);
end
%% --- Step 2: run OpenFAST 
% NOTE: 
%      Comment this section if the simulations were already run
%      Potentially write a batch file for external run (can be more conveninet for many simulations).
%      Batch and commands are relative to the parent directory of the batch file.
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
