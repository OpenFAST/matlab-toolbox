%% Documentation   
% This script is used to illustrate how the function SD2Matlab and Matlab2SD can be used to:
% - Change tables in SubDyn file
% - Change variable in SubDyn file

%% Initialization
clear all; close all; clc; 
restoredefaultpath;
addpath(genpath('C:/Work/FAST/matlab-toolbox')); % TODO adapt me

%% Parameters
oldSDName = '../../_ExampleData/5MW_Baseline/NRELOffshrBsline5MW_OC4Jacket_SubDyn.dat';
newSDName = './_SD_Modified.dat';

%% Read SD file
SD = SD2Matlab(oldSDName, 2);

%% Modify data in the file
% Multiply Young's modulus by 2
SD.MemberSectionProp(:,2) = SD.MemberSectionProp(:,2)*2; 
% Change RayleighDamping
SD = SetFASTPar(SD    ,'RayleighDamp'  ,[0.1, 0.2]);

%% Write Modified SD file
Matlab2SD(SD, oldSDName, newSDName, 2);

