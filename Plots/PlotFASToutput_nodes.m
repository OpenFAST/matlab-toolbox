function [outData_struct]=PlotFASToutput_nodes(FASTfiles) %,FASTfilesDesc,ReferenceFile,Channels,ShowLegend,CustomHdr,PlotPSDs,OnePlot)
if ~iscell(FASTfiles)
    FASTfiles = {FASTfiles};
end

nf = 1;

[outData_struct] = loadNodalData(FASTfiles{nf});


n = fieldnames(outData_struct);


nr = 2; % number of rows on figure
nc = 3; % number of columns on figure

%%
np = 0;
for i=1:length(n)
    if strcmp( n{i}, 'time' ) || strcmp( n{i}, 'nodeDistances' )
        continue;
    end
    
    np = mod(np,nr*nc)+1;
    if np==1
        figure;
    end
    subplot(nr,nc,np)
    hold on;
    
    if size(outData_struct.(n{i}).timeSer,3)==1 || size(outData_struct.(n{i}).timeSer,2)==1 % one blade or one node
%      'displayname',[FASTfiles{nf} ': blade ' num2str(outData_struct.(n{i}),3)) ', node ' num2str(size(outData_struct.(n{i}),2))] );
        numLines = numel( outData_struct.(n{i}).timeSer(1,:,:) );
        set(gca,'ColorOrder',jet(numLines));
        
        plot(outData_struct.time.timeSer, squeeze( outData_struct.(n{i}).timeSer ),':.','displayname',FASTfiles{nf} );
        xlabel([outData_struct.time.name ' ' outData_struct.time.unit]);
        ylabel([outData_struct.(n{i}).name ' ' outData_struct.(n{i}).unit], 'interpreter','none');
        
    else % multiple blades
        mesh(outData_struct.(n{i}).timeSer,'displayname',FASTfiles{nf});
    end
    title(n{i},'interpreter','none')
    grid on
    %legend show
end




end 