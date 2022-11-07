%% Documentation   
% This script is used to illustrate how the function MATLAB2FAST and FAST2MATLAB can be used to:
% - read a .fst file
% - extract data from a fst file, or a subfile (such as inflow wind)
% - modify the fst file or subfiles
% - writing the files back to another location

%% Initialization
clear all; close all; clc; 
restoredefaultpath;
addpath(genpath('C:/Work/FAST/matlab-toolbox')); % TODO adapt me


%% Parameters
oldFSTName = '../../_ExampleData/5MW_Land_Lin_Templates/Main_5MW_Land_Lin.fst'
newFSTName = './_Modified.fst'


%% Derived Parameters
[templateDir, baseName, ext ] = fileparts(oldFSTName);
if strcmp(templateDir, filesep)
    templateDir = ['.' filesep];
end

%% Read and setup path of new files
% Read template FST file 
FP = FAST2Matlab(oldFSTName, 2); %FP are the FST parameters, specify 2 lines of header

% Path and basename for modified files
[fdir, base,~]  = fileparts(newFSTName)       ; % Basename for subfiles
fullBase        = [fdir filesep  base]         ; % Full basename for subfiles
fullPathIW  = [fullBase '_IW.dat']             ; % New InflowWind file
filenameIW  = [base     '_IW.dat'];            ; % New InflowWind file relative to new fst file


%% Read or modify a sub file (InflowWind)
% Read the inflow wind file
[paramIW, templateFilenameIW] = GetFASTPar_Subfile(FP, 'InflowFile', templateDir, templateDir);

% Modify some parameters in this file (setting the wind the a steady wind at 12m/s
paramIW_mod = SetFASTPar(paramIW    ,'WindType'  ,1);
paramIW_mod = SetFASTPar(paramIW_mod,'HWindSpeed',12);

% Write the new inflow wind file
Matlab2FAST(paramIW_mod, templateFilenameIW, fullPathIW, 2); %contains 2 header lines


%% Extract data from the FST file and modify it
% Extract a given parameter in the FST file
CompInflow = GetFASTPar(FP,'CompInflow');

% Set a given parameter in the FST file
FP_mod = SetFASTPar(FP,'CalcSteady','True');

% Change the path to the inflow file to point to the newly created one
FP_mod = SetFASTPar(FP_mod,'InflowFile',['"' filenameIW '"']);


%% Write FST file
Matlab2FAST(FP_mod, oldFSTName, newFSTName, 2); %contains 2 header lines
