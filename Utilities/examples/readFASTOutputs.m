%% Documentation   
% Example script to read OpenFAST outputs (ASCII or Binary)
% and plot a channel.
%
%% Initialization
clear all; close all; clc; 
restoredefaultpath;
addpath(genpath('C:/Work/FAST/matlab-toolbox')); % TODO adapt me

%% Read an ASCII output file and plot data
% Read file
outfile = '../../_ExampleData/ExampleFiles/FASTOut.out';
[Channels, ChanName, ChanUnit,DescStr] = ReadFASTtext(outfile);
time = Channels(:,1);

% Plot Channel 2
iChan=2
figure()
plot(time, Channels(:,iChan))
xlabel('Time (s)')
ylabel([ChanName(iChan) ChanUnit(iChan)])


%% Read a binary output file
% Read file
outbfile = '../../_ExampleData/ExampleFiles/FASTOutBin.outb';
[Channels, ChanName, ChanUnit, FileID, DescStr] = ReadFASTbinary(outbfile);
time = Channels(:,1);

% Plot Channel 5
iChan=5
figure()
plot(time, Channels(:,iChan))
xlabel('Time (s)')
ylabel([ChanName(iChan) ChanUnit(iChan)])
