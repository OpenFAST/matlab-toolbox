function [outData]=PlotFASToutput(FASTfiles,FASTfilesDesc,ReferenceFile,Channels,ShowLegend,CustomHdr,PlotPSDs)
%..........................................................................
%function PlotFASToutput(FASTfiles,FASTfilesDesc,ReferenceFile,Channels)
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
% ReferenceFile - scalar (index into FASTfiles) that denotes which file is 
%                 considered the reference. The channels from this file 
%                 will be plotted, and the channel names from this file 
%                 will be used. If omitted, ReferenceFile is the last file 
%                 in FASTfiles. 
% Channels      - an array of channel numbers or cell array of names, 
%                 indicating which channels from the ReferenceFile
%                 should be plotted. If omitted, or is the string 'all', 
%                 all channels except time (the first one) are plotted.
%                 
% Note: the channels in the files need not be in the same order, but the
%  channel names must be identical. (i.e., it does not search for alternate
%  column names)
%..........................................................................


numFiles = length(FASTfiles);
if numFiles < 1 
    disp('PlotFASToutput:No files to plot.')
    return
end

if nargin < 7 || isempty(PlotPSDs)
    PlotPSDs = false;
end
if nargin < 6 || isempty(CustomHdr)
    useCustomHdr=false;
else
    useCustomHdr=true;
end
if nargin < 5 || isempty(ShowLegend) 
    ShowLegend = true;
end
if nargin < 4 || isempty(Channels) 
    Channels = 'all';
end
if nargin < 3 || isempty(ReferenceFile) || (ReferenceFile < 1) || (ReferenceFile > numFiles)
    ReferenceFile = 1;
end
if nargin < 2 
    FASTfilesDesc = ''; %empty string
end


%% -----------------------------------------------------------
% Read the FAST file(s):
% ------------------------------------------------------------
data         = cell(numFiles,1);
columnTitles = cell(numFiles,1);
columnUnits  = cell(numFiles,1);
DescStr      = cell(numFiles,1);

outData      = cell(numFiles,2);

for iFile=1:numFiles

    if length(FASTfiles{iFile}) > 4 && strcmpi( FASTfiles{iFile}((end-4):end),'.outb' )
        [data{iFile}, columnTitles{iFile}, columnUnits{iFile}, ~, DescStr{iFile}] = ReadFASTbinary(FASTfiles{iFile});
    elseif ~useCustomHdr
        [data{iFile}, columnTitles{iFile}, columnUnits{iFile},    DescStr{iFile}] = ReadFASTtext(FASTfiles{iFile});        
    else % allow other files 
        delim     = CustomHdr{1};
        HeaderRows= CustomHdr{2};
        NameLine  = CustomHdr{3};
        UnitsLine = CustomHdr{4};
        DescStr{iFile} = '';
        
        [data{iFile}, columnTitles{iFile}, columnUnits{iFile} ] = ReadFASTtext(FASTfiles{iFile}, delim, HeaderRows, NameLine, UnitsLine );    
    end
    
end

%% -----------------------------------------------------------
% Set some default values, if it wasn't input to this routine:
% ------------------------------------------------------------
if ~iscell(Channels) && strcmpi(Channels,'all')
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
    
if isempty(FASTfilesDesc)
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
% save data for output
for iFile=1:numFiles
    outData{iFile,1} = data{iFile}(:,1);
    outData{iFile,2} = zeros( length(outData{iFile,1}), length(Channels));
end

i=0;
for iChannel = Channels
    i = i+1;
    for iFile=1:numFiles
        ChannelName = columnTitles{ReferenceFile}{iChannel};       
        [ChannelIndx, err, ChannelName, scaleFact] = getColIndx( ChannelName, columnTitles{iFile}, FASTfiles{iFile} );
        
%         if iFile == 1
%             [ChannelName,scaleFact] = getOldFASTv8ChannelName(ChannelName);
%         elseif iFile == 2
%             [ChannelName,scaleFact] = getFASTv7ChannelName(ChannelName);
%         if iFile == numFiles
%              [ChannelName,scaleFact] = getFASTv7ChannelName(ChannelName);
%         end
        
        if err 
            outData{iFile,2}(:,i) = NaN;
            outData{iFile,3}{i}   = [ ChannelName '(not found)'];
        else
            outData{iFile,2}(:,i) = data{iFile}(:,ChannelIndx)*scaleFact;
            if scaleFact ~= 1
                outData{iFile,3}{i} = [ ChannelName ' x ' num2str(scaleFact) ];
            else
                outData{iFile,3}{i}   = ChannelName;
            end
        end
    end
end



%% -----------------------------------------------------------
% Plot the time series from each file, with each channel in 
%      a separate figure:
% ------------------------------------------------------------
plotTimeSeriesData( outData, FASTfilesDesc, Markers, LineColors, ...
                    columnTitles{ReferenceFile}([1 Channels]), ...
                    columnUnits{ReferenceFile}([1 Channels]), titleText, ...
                    ShowLegend, LineWidthConst, FntSz );


%% -----------------------------------------------------------
% Plot the psd from each file, with each channel in 
%      a separate figure:
% ------------------------------------------------------------
if PlotPSDs
    plotPSDData( outData, FASTfilesDesc, Markers, LineColors, ...
                        columnTitles{ReferenceFile}([1 Channels]), ...
                        columnUnits{ReferenceFile}([1 Channels]), titleText, ...
                        ShowLegend, LineWidthConst, FntSz );                
end

return
end
      
function [] = savePlots( f, outFigName, ReferenceFile )

    [pathstr] = fileparts(ReferenceFile );
    
    OutFilePath = [pathstr filesep 'Plots' ];
    OutFileRoot = [OutFilePath filesep outFigName];
        % make sure the directory exists; if not, create it
    if ~exist(OutFilePath, 'dir')
        mkdir( OutFilePath );
    end 
                
    print(['-f' num2str(f)],'-dpng','-r150',[OutFileRoot '.png']);
    close(f)

return
end

function [] = plotTimeSeriesData( outData, FASTfilesDesc, Markers, LineColors, ...
                RefColumnTitles, RefColumnUnits, titleText, ShowLegend, LineWidthConst, FntSz )

numCols  = size(outData{1,2},2) ;
numFiles = size(outData,1);
% RefColumnTitles= columnTitles{ReferenceFile}(Channels);
% RefColumnUnits = columnUnits{ReferenceFile}(Channels);
%% -----------------------------------------------------------
% Plot the time series from each file, with each channel in 
%      a separate figure:
% ------------------------------------------------------------
    for i = 1:numCols    
        f=figure;
        for iFile=1:numFiles
            plot(outData{iFile,1}, outData{iFile,2}(:,i) ...
                 ,'LineStyle','-' ...
                 ,'Marker',Markers{iFile} ...
                 ,'MarkerSize',4 ...
                 ,'DisplayName',[FASTfilesDesc{iFile} ' (' outData{iFile,3}{i} ')' ] ...
                 ,'Color',LineColors{iFile} ...
                 ,'LineWidth',LineWidthConst);
            hold on;      
        end
        set(gca,'FontSize',FntSz-2,'gridlinestyle','-');
        ylabel({RefColumnTitles{i+1}     RefColumnUnits{i+1}},'FontSize',FntSz); %cell array = print on two lines
        xlabel([RefColumnTitles{1  } ' ' RefColumnUnits{1  }],'FontSize',FntSz); %string = print on one line
        title( titleText,'FontSize',FntSz )    
        grid on;

        if numFiles > 1 && ShowLegend
            legend show %(FASTfilesDesc{:});
        end
%  xlim([0,0.1])
        set(f,'Name',RefColumnTitles{i+1} ...
             ,'paperorientation','landscape' ...
             ,'paperposition',[0.25 0.25 10.5 8]);   
    end





return
end


function [] = plotPSDData( outData, FASTfilesDesc, Markers, LineColors, ...
                    RefColumnTitles, RefColumnUnits, titleText, ShowLegend, LineWidthConst, FntSz )
numCols  = size(outData{1,2},2) ;
numFiles = size(outData,1);

%% -----------------------------------------------------------
% Plot the psd from each file, with each channel in 
%      a separate figure:
% ------------------------------------------------------------
    for i = 1:numCols    
        f=figure;
        for iFile=1:numFiles
            
            n=length(outData{iFile,2}(:,i));
            if mod(n,2)==1
                n=n-1;
            end
            
            [ f1, Sf1 ] = getPSD( outData{iFile,2}(1:n,i), 1/outData{iFile,1}(n) );
            semilogy(f1, Sf1 ...
                 ,'LineStyle','-' ...
                 ,'Marker',Markers{iFile} ...
                 ,'MarkerSize',4 ...
                 ,'DisplayName',[FASTfilesDesc{iFile} ' (' outData{iFile,3}{i} ')' ] ...
                 ,'Color',LineColors{iFile} ...
                 ,'LineWidth',LineWidthConst);
            hold on;      
        end
        set(gca,'FontSize',FntSz-2,'gridlinestyle','-');
        ylabel({' PSD of ' RefColumnTitles{i+1}     RefColumnUnits{i+1}},'FontSize',FntSz); %cell array = print on two lines
        xlabel(['1/' RefColumnUnits{1  }],'FontSize',FntSz); %string = print on one line
        title( titleText,'FontSize',FntSz )    
        grid on;

        if numFiles > 1 && ShowLegend
            legend show %(FASTfilesDesc{:});
        end

        set(f,'Name',[RefColumnTitles{i+1} ' PSD']...
             ,'paperorientation','landscape' ...
             ,'paperposition',[0.25 0.25 10.5 8]);   
         
%          xlim([0,60]);
    end





return
end

%% possibly use this to make sure the channel names are the same....
%% ------------------------------------------------------------------------
function [Indx,err,ColToFind,scaleFact] = getColIndx( ColToFind, colNames, fileName )
    err = false;
    scaleFact = 1;
    Indx = find( strcmpi(ColToFind, colNames), 1, 'first' );
    
    if isempty(Indx) % let's try the negative of this column        
        if strncmp(ColToFind,'-',1)
            ColToFind = ColToFind(2:end);
            scaleFact = -1;
        else
            ColToFind = strcat('-',ColToFind);
            scaleFact = -1;
        end        
        Indx = find( strcmpi(ColToFind, colNames), 1, 'first' );
    end
        
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
