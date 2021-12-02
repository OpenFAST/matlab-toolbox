%% Documentation   
% Example script to run a set of FAST simulations using FAST exe.
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
FASTexe = '../../_ExampleData/openfast3.0_x64s.exe'; % path to an OpenFAST executable
OUText  = '.outb'; % Output extension

FSTfilenames={ % path to OpenFAST input files
'../../_ExampleData/5MW_Land_Simulations/Main_5MW_Land_8mps.fst',
'../../_ExampleData/5MW_Land_Simulations/Main_5MW_Land_10mps.fst',
};


%% Run FAST an all fst files 
runFAST(FSTfilenames, FASTexe); %, 'flag','-VTKLin');

%% List of output files
OUTfilenames =  cellfun(@(s)strrep(s,'.fst',OUText),  FSTfilenames, 'UniformOutput',false);

for i = 1:length(OUTfilenames)
    if ~exist(OUTfilenames{i},'file')
        warning('Simulation failed: %s', FSTfilenames{i})
    end
end
