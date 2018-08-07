function [num,txt,CampbellPlotData] = Plot_CampbellData(xlsx_file,SheetName,TitleText)
% 
% if SheetName is not used, function will use the first worksheet
if nargin < 3
    TitleText = 'Campbell Diagram';
    
    if nargin < 2
        SheetName = '';
    end
end

[num,txt] = xlsread(xlsx_file,SheetName);

% remove table name (so indices between num and txt match better)
txt = txt(2:end,:);

%%
xAxisLabel  = txt{1,1};
CampbellPlotData.xValues = num(1,:)';
nx = length(CampbellPlotData.xValues);

lineIndices = num(2:end,:);
nLines = size(lineIndices,1);
CampbellPlotData.lineLabels  = txt(2: nLines+1, 1);

%% for each column (wind or rotor speed), open the worksheet and get the frequencies and damping
PlotRevs = false;
CampbellData = cell( nx, 1);
if strcmpi(xAxisLabel(1:5),'Rotor')
    ending = ' RPM';
    PlotRevs = true;
elseif strcmpi(xAxisLabel(1:4),'Wind')
    ending = ' mps';
else
    ending = '';
end
    
for i=1:nx
    WorksheetName = [ num2str(CampbellPlotData.xValues(i)) ending ];
    d = xlsread(xlsx_file, WorksheetName);
    
    CampbellData{i}.NaturalFreq_Hz = d(2, 1:4:end);
    CampbellData{i}.DampedFreqs_Hz = d(3, 1:4:end);
    CampbellData{i}.DampRatios     = d(4, 1:4:end);    
end

%%
for i= 1:nx
    NotAvail = isnan( lineIndices(:,i) );
    lineIndices(NotAvail,i) = 1;
   
    CampbellPlotData.NaturalFreq_Hz(:,i) = CampbellData{i}.NaturalFreq_Hz( lineIndices(:,i) );
    CampbellPlotData.DampRatios(    :,i) = CampbellData{i}.DampRatios(     lineIndices(:,i) );
    
    CampbellPlotData.NaturalFreq_Hz(NotAvail,i) = NaN;
    CampbellPlotData.DampRatios(    NotAvail,i) = NaN;    
end

%%
LineStyles = {'g:', '-', '-+', '-o', '-^', '-s', '-x', '-d', '-.', ...
                    ':', ':+', ':o', ':^', ':s', ':x', ':d', ':.', ...
                   '--','--+','--o','--^','--s','--x','--d','--.'  };
figure;

for p=1:2
    ax=subplot(1,2,p);
    hold on;
    ax.Box = 'on';
    ax.FontSize = 15;
    xlabel( xAxisLabel )
end

for i=1:nLines
    
    if isempty( strfind( CampbellPlotData.lineLabels{i},'(not shown)' ) )        
        subplot(1,2,1)    
        plot( CampbellPlotData.xValues, CampbellPlotData.NaturalFreq_Hz(i,:), LineStyles{i}, 'DisplayName',CampbellPlotData.lineLabels{i} );

        subplot(1,2,2)    
        plot( CampbellPlotData.xValues, CampbellPlotData.DampRatios(i,:), LineStyles{i}, 'DisplayName',CampbellPlotData.lineLabels{i} );        
    end
    
end


subplot(1,2,1)
ylabel( 'Natural Frequency (Hz)' )
if PlotRevs
    PerRev = [1 3:3:15];
    Revs = (CampbellPlotData.xValues) * PerRev /60;
    
    plot(CampbellPlotData.xValues,Revs,'k-');
    for i=1:length(PerRev)
        text( 'String',[num2str(PerRev(i)) 'P'],'Position',[CampbellPlotData.xValues(end) Revs(end,i) 0]);
    end
end

subplot(1,2,2)
ylabel( 'Damping Ratio (-)' )
legend show;


axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.5, 0.96,TitleText, 'FontSize',20, 'HorizontalAlignment','Center');


%%    
return;
end
