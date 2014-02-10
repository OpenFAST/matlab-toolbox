function PlotFASToutput(FASTfiles,FASTfilesDesc,Channels)
%..........................................................................
%function PlotFASToutput(FASTfiles,FASTfilesDesc,Channels)
%
% (c) 2014 National Renewable Energy Laboratory
%  Author: B. Jonkman, NREL/NWTC
%
% This routine produces time-series plots of FAST output
%..........................................................................
% Required Inputs:
% FASTfiles     - a cell array of strings, listing FAST .out or .outb file 
%                 names, whose channels are to be plotted
% Optional Inputs:
% FASTfilesDesc - a cell array of strings describing the FAST files 
%                 listed in FASTfiles, used in the plot legend. If omitted,  
%                 the routine will list them as File 1, File 2, etc.
% Channels      - an array of channel numbers, indicating which channels
%                 from File 1 should be plotted. If omitted, all channels 
%                 except time (the first one) are plotted.
% Note: the channels in the files need not be in the same order, but the
%  channel names must be identical. (i.e., it does not search for alternate
%  column names)
%..........................................................................

numFiles = length(FASTfiles);
if numFiles < 1 
    disp('PlotFASToutput:No files to plot.')
    return
end

%% -----------------------------------------------------------
% Read the FAST file(s):
% ------------------------------------------------------------

for iFile=1:numFiles
        
    if length(FASTfiles{iFile}) > 4 && strcmpi( FASTfiles{iFile}((end-4):end),'.outb' )
        [data{iFile}, columnTitles{iFile}, columnUnits{iFile}, ~, DescStr{iFile}] = ReadFASTbinary(FASTfiles{iFile});
    else
        [data{iFile}, columnTitles{iFile}, columnUnits{iFile},    DescStr{iFile}] = ReadFASTtext(FASTfiles{iFile});
    end
    
end

%% -----------------------------------------------------------
% Set some default values, if it wasn't input to this routine:
% ------------------------------------------------------------

if nargin < 3 || strcmpi(Channels,'all')
    Channels = 2:size(data{1},2); % use the number of columns        
end
    
if nargin < 2 || isempty(FASTfilesDesc)
    for i=1:numFiles
        FASTfilesDesc{i} = sprintf('File %i',i);
    end
end

%% -----------------------------------------------------------
% Set some default values for the plots:
% ------------------------------------------------------------
LineWidthConst = 3;
FntSz          = 17;

LineColors     = {[0 0 0],[0 1 1],[1 0 1],[0 1 0],[0 0 1],[1 0 0]};
% LineColors{iFile}*0.75

if numFiles > length(LineColors)
    tmp=jet(numFiles);
    for i=1:numFiles
        LineColors{i}=tmp(i,:);
    end
end
    
titleText = char(DescStr{1});
FASTv8Text='Description from the FAST input file:';
indx=strfind(titleText,FASTv8Text);
if ~isempty(indx)
    titleText=titleText((indx+length(FASTv8Text)):end);
end

%% -----------------------------------------------------------
% Plot the time series from each file, with each channel in 
%      a separate figure:
% ------------------------------------------------------------
for iChannel = Channels

    f=figure;
    for iFile=1:numFiles
        ChannelIndx = getColIndx( columnTitles{1}{iChannel}, columnTitles{iFile}, FASTfiles{iFile} );
        plot(data{iFile}(:,1), data{iFile}(:,ChannelIndx) ...
             ,'LineStyle','-' ...
             ,'DisplayName',[FASTfiles{iFile}] ...
             ,'Color',LineColors{iFile} ...
             ,'LineWidth',LineWidthConst);
        hold on;               
    end
    set(gca,'FontSize',FntSz-2,'gridlinestyle','-');
    ylabel({columnTitles{1}{iChannel}     columnUnits{1}{iChannel}},'FontSize',FntSz); %cell array = print on two lines
    xlabel([columnTitles{1}{1       } ' ' columnUnits{1}{1       }],'FontSize',FntSz); %string = print on one line
    title( titleText,'FontSize',FntSz )    
    grid on;
    
    if numFiles > 1
        legend(FASTfilesDesc{:});
    end
    
    set(f,'Name',columnTitles{1}{iChannel} ...
         ,'paperorientation','landscape' ...
         ,'paperposition',[0.25 0.25 10.5 8]);    
end

%             if savePlts
%                 [pathstr, name ] = fileparts(FASTfiles{1} );
%                 if nargin < 8 
%                     saveName = name;
%                 end
%                 OutFilePath = [pathstr filesep 'Plots' ];
%                 OutFileRoot = [OutFilePath filesep saveName];
%                     % make sure the directory exists; if not, create it
%                 if ~exist(OutFilePath, 'dir')
%                     mkdir( OutFilePath );
%                 end 
%                 
%                 print(['-f' num2str(f)],'-dpng','-r150',[OutFileRoot '_' num2str(iPlot-1) '.png']);
%                 close(f)
%             end

return
end
           
%% possibly use this to make sure the channel names are the same....
%% ------------------------------------------------------------------------
function [Indx] = getColIndx( ColToFind, colNames, fileName )
    
    Indx = find( strcmpi(ColToFind, colNames), 1, 'first' );
    if isempty(Indx)
        error(['Error: ' ColToFind ' not found in ' fileName ]);
    end
return
end
%% ------------------------------------------------------------------------
