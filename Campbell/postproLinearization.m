function [ModesData, outputFiles] = postproLinearization(folder, OP_file_or_struct, outputFormat, prefix)
% Postprocess a set of linearization outputs, where the operating points are defined in a file. 
%
%
% The scripts generates either one Excel file or a set of csv files:
%     ExcelFileName   =  [folder 'CampbellDataSummary.xlsx'];
%     CSVFileNames(1) =  [folder 'CampbellOP.csv'];
%     CSVFileNames(2) =  [folder 'CampbellModesID.csv'];
%     CSVFileNames(3:) = [folder 'CampbellPointsI.csv'];
% 
% INPUTS:
%   - OP_file_or_struct: 
%           path to a csv file that contains information about the Operating points see function readOperatingPoints for more.
%      OR   structure with (depending on simulation) fields: RotorSpeed, WindSpeed, GeneratorTorque, 
%
%   - folder: path to a folder where .lin and .fst files may be found
%
% OPTIONAL INPUTS:
%   - ouputFormat : 'csv' or 'xls', choose between output as CSV files or one Excel file
%
% OUTPUTS:
%   - ModesData: structure with field (see IdentifyModes for more)
%        - modeID_table
%        - modeID_name
%        - opTable
%        - ModesTable (one per OP)
%        - ModesTable_names (one per OP)

% Printing a banner since this might be run in terminal and might not be obvious
disp('--------------- START of MATLAB function postproLinearization -------------')
if ~exist('outputFormat','var'); outputFormat='csv'; end
if ~exist('prefix','var'); prefix=''; end

% % % TODO remove me
if ~exist('folder','var');
    folder='C:/Work/IEA29/DanAero/Phase_IV.4/4.3_Campbell_ED/'; 
    operatingPointsFile='C:/Work/IEA29/DanAero/Phase_IV.4/TrimPoints.csv';
    outputFormat='xls';
    outputFormat='csv';
    addpath(genpath('C:/Work/FAST/matlab-toolbox'));
end

%% --- Init
folder = strrep(strrep([folder '/'], '//','/'),'\','/');
outbase = [folder prefix 'Campbell'];  % Base for all files that will be generated 

if ~isstruct(OP_file_or_struct)
    fprintf('OP file:    %s\n',OP_file_or_struct);
end
fprintf('Folder:     %s\n',folder);

%% --- Extract operating points to know FAST filenames
[FastFiles, OP] = getFullFilenamesOP(folder, OP_file_or_struct);
fprintf('Points:     %d operating points\n',OP.nOP)

%% --- Get Campbell data (perform MBC on lin files)
if isfield(OP,'WindSpeed')
    CampbellData = getCampbellData(FastFiles, OP.WindSpeed);
else
    CampbellData = getCampbellData(FastFiles);
end
campbellData2TXT([outbase '_Summary.txt'],CampbellData)
fprintf('Written:    %s\n',[outbase '_Summary.txt']);

%% --- Match mode names / identify modes
[ModesData] = identifyModes(CampbellData);

%% --- Write tables to csv or Excel
if isequal(lower(outputFormat),'csv')
    outputFiles = modesData2CSV(outbase, ModesData);
    fprintf('Written:    %s\n',[outbase '*.csv']);
else
    XLSname = [outbase '_DataSummary.xlsx'];
    modesData2XLS(XLSname, ModesData);
    outputFiles = {XLSname};
    fprintf('Written:    %s\n',XLSname);

end

% Printing a banner since this might be run in terminal
disp('--------------- END of MATLAB function postproLinearization -------------')
