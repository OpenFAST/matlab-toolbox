function PlotFASToutput(FASTfiles,FASTfilesDesc,Channels,ShowLegend)
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
if nargin < 4
    ShowLegend = true;
end

ReferenceFile = numFiles;


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
if nargin < 3 || (~iscell(Channels) && strcmpi(Channels,'all'))
    Channels = 2:size(data{ReferenceFile},2); % use the number of columns        
elseif ~isnumeric(Channels)
    if iscell(Channels)
        ChannelIndx = zeros(1,length(Channels));
        for i=1:length(Channels)
            ChannelIndx(i) = getColIndx( Channels{i}, columnTitles{ReferenceFile}, FASTfiles{ReferenceFile} );            
        end
        Channels = ChannelIndx;
    else
        Channels = getColIndx( Channels, columnTitles{ReferenceFile}, FASTfiles{ReferenceFile} );
    end
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
Markers        = {'o'    ,'s'    ,'d'    ,'v'    ,'^'    ,'.'    };
% LineColors{iFile}*0.75

if numFiles > length(LineColors)
    tmp=jet(numFiles);
    for i=1:numFiles
        LineColors{i}=tmp(i,:);
    end
    n=length(Markers);
    for i=n+1:numFiles
        Markers{i}=Markers{n};
    end
end
    
titleText = char(DescStr{ReferenceFile});
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
        ChannelName = columnTitles{ReferenceFile}{iChannel};        
        scaleFact   = 1;
        
        
%         if iFile == 1
%             [ChannelName,scaleFact] = getOldFASTv8ChannelName(ChannelName);
%         elseif iFile == 2
%             [ChannelName,scaleFact] = getFASTv7ChannelName(ChannelName);
%         if iFile == numFiles
%              [ChannelName,scaleFact] = getFASTv7ChannelName(ChannelName);
%         end
        
        [ChannelIndx, err] = getColIndx( ChannelName, columnTitles{iFile}, FASTfiles{iFile} );
        if err 
            plot(0,NaN, ...
                'DisplayName', [strrep(FASTfiles{iFile},'\','_\'), ' (' ChannelName ' not found)'],...
                'LineStyle','none',...
                'Marker','.');
        else
            plot(data{iFile}(:,1), data{iFile}(:,ChannelIndx)*scaleFact ...
                 ,'LineStyle','-' ...
                 ,'Marker',Markers{iFile} ...
                 ,'MarkerSize',4 ...
                 ,'DisplayName',[FASTfilesDesc{iFile} ' (' ChannelName ')'] ...
                 ,'Color',LineColors{iFile} ...
                 ,'LineWidth',LineWidthConst);
        end
        hold on;      
    end
    set(gca,'FontSize',FntSz-2,'gridlinestyle','-');
    ylabel({columnTitles{ReferenceFile}{iChannel}     columnUnits{ReferenceFile}{iChannel}},'FontSize',FntSz); %cell array = print on two lines
    xlabel([columnTitles{ReferenceFile}{1       } ' ' columnUnits{ReferenceFile}{1       }],'FontSize',FntSz); %string = print on one line
    title( titleText,'FontSize',FntSz )    
    grid on;
    
    if numFiles > 1 && ShowLegend
        legend show %(FASTfilesDesc{:});
    end
    
    set(f,'Name',columnTitles{ReferenceFile}{iChannel} ...
         ,'paperorientation','landscape' ...
         ,'paperposition',[0.25 0.25 10.5 8]);   
%      xlim([0, .02])
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
function [Indx,err] = getColIndx( ColToFind, colNames, fileName )
    err = false;
    Indx = find( strcmpi(ColToFind, colNames), 1, 'first' );
    if isempty(Indx)
        disp(['Error: ' ColToFind ' not found in ' fileName ]);
        err = true;
    end
return
end

function [ChannelName_old,scaleFact] = getFASTv7ChannelName(ChannelName)

    scaleFact = 1.0;

    if strcmpi(ChannelName,'Wave1Elev')
        ChannelName_old = 'WaveElev';                        
    elseif strcmpi(ChannelName,'TwHt1TPxi')
        ChannelName_old = 'TTDspFA';            
    elseif strcmpi(ChannelName,'TwHt1TPyi')
        ChannelName_old = 'TTDspSS';                    
    elseif strcmpi(ChannelName,'ReactFXss')
        ChannelName_old = '-TwrBsFxt';
        scaleFact = 1000;
    elseif strcmpi(ChannelName,'ReactFYss')
        ChannelName_old = '-TwrBsFyt';
        scaleFact = 1000;
    elseif strcmpi(ChannelName,'ReactFZss')
        ChannelName_old = '-TwrBsFzt';
        scaleFact = 1000;
    elseif strcmpi(ChannelName,'ReactMXss')
        ChannelName_old = '-TwrBsMxt';
        scaleFact = 1000;
    elseif strcmpi(ChannelName,'ReactMYss')
        ChannelName_old = '-TwrBsMyt';
        scaleFact = 1000;
    elseif strcmpi(ChannelName,'ReactMZss')
        ChannelName_old = '-TwrBsMzt';       
        scaleFact = 1000;                                                                                  
    else
        ChannelName_old = strrep(ChannelName,'M1N1V','Wave1V');
        ChannelName_old = strrep(ChannelName_old,'M1N1A','Wave1A');
    end
                                
    return 

end

function [ChannelName_old,scaleFact] = getOldFASTv8ChannelName(ChannelName)

    scaleFact = 1.0;

    if strcmpi(ChannelName,'IntfFXss')
        ChannelName_old = 'IntfXss';            
    elseif strcmpi(ChannelName,'IntfFYss')
        ChannelName_old = 'IntfYss';            
    elseif strcmpi(ChannelName,'IntfFZss')
        ChannelName_old = 'IntfZss';            
    elseif strcmpi(ChannelName,'ReactFXss')
        ChannelName_old = 'ReactXss';            
    elseif strcmpi(ChannelName,'ReactFYss')
        ChannelName_old = 'ReactYss';            
    elseif strcmpi(ChannelName,'ReactFZss')
        ChannelName_old = 'ReactZss'; 
    else
        ChannelName_old = ChannelName;
    end
                                
    return 

end


function [ChannelName_new,scaleFact] = getNewChannelName(ChannelName)
        
        scaleFact = 1.0;
        ChannelName_new = ChannelName;
        
        
%         if strcmpi(ChannelName,'WaveElev')
%             ChannelName_new = 'Wave1Elev';
%         elseif strncmpi( ChannelName,'Fair',4 ) && strcmpi( ChannelName((end-2):end), 'Ten') %TFair[i] = FairiTen
%             ChannelName_new = strrep( strrep( ChannelName,'Fair','TFair['),'Ten',']');
%         elseif strncmpi( ChannelName,'Anch',4 ) && strcmpi( ChannelName((end-2):end), 'Ten') %TAnch[i] = AnchiTen
%             ChannelName_new = strrep( strrep( ChannelName,'Anch','TAnch['),'Ten',']');
%         elseif strncmpi( ChannelName,'Anch',4 ) && strcmpi( ChannelName((end-2):end), 'Ten') %TAnch[i] = AnchiTen
%             ChannelName_new = strrep( strrep( ChannelName,'Anch','TAnch['),'Ten',']');
%         elseif strcmpi(ChannelName,'IntfXss')
%             ChannelName_new = 'IntfFXss';            
%         elseif strcmpi(ChannelName,'IntfYss')
%             ChannelName_new = 'IntfFYss';            
%         elseif strcmpi(ChannelName,'IntfZss')
%             ChannelName_new = 'IntfFZss';            
%         elseif strcmpi(ChannelName,'ReactXss')
%             ChannelName_new = 'ReactFXss';            
%         elseif strcmpi(ChannelName,'ReactYss')
%             ChannelName_new = 'ReactFYss';            
%         elseif strcmpi(ChannelName,'ReactZss')
%             ChannelName_new = 'ReactFZss';            
%             
%             
%         elseif strcmpi(ChannelName,'TTDspFA')
%             ChannelName_new = 'TwHt1TPxi';            
%         elseif strcmpi(ChannelName,'TTDspSS')
%             ChannelName_new = 'TwHt1TPyi';                    
%         elseif strcmpi(ChannelName,'-TwrBsFxt')
%             ChannelName_new = 'ReactFXss';
%             scaleFact = 1000;
%         elseif strcmpi(ChannelName,'-TwrBsFyt')
%             ChannelName_new = 'ReactFYss';
%             scaleFact = 1000;
%         elseif strcmpi(ChannelName,'-TwrBsFzt')
%             ChannelName_new = 'ReactFZss';
%             scaleFact = 1000;
%         elseif strcmpi(ChannelName,'-TwrBsMxt')
%             ChannelName_new = 'ReactMXss';
%             scaleFact = 1000;
%         elseif strcmpi(ChannelName,'-TwrBsMyt')
%             ChannelName_new = 'ReactMYss';
%             scaleFact = 1000;
%         elseif strcmpi(ChannelName,'-TwrBsMzt')
%             ChannelName_new = 'ReactMZss';       
%             scaleFact = 1000;
%             
%             
%                                                           
%         else
%             ChannelName_new = strrep(ChannelName,'Wave1V','M1N1V');
%             ChannelName_new = strrep(ChannelName_new,'Wave1A','M1N1A');
%             %ChannelName_new = ChannelName_new;              
%         end
                        
        
return     
end 

%% ------------------------------------------------------------------------
